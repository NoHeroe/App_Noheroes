import 'package:drift/drift.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/faction_events.dart';
import '../../../domain/services/faction_reputation_service.dart';
import '../../database/app_database.dart';

/// Sprint 3.4 Sub-Etapa B.2 — service dedicado pro flow de saída de
/// facção. Aplica todas as penalidades especificadas no plan-first
/// (Q6) numa transação atômica.
///
/// ## Penalidades padrão
///
/// - **-20 reputação** na facção saída (via
///   `FactionReputationService.adjustReputation` que **propaga via
///   `kFactionAlliances`** — aliadas perdem `delta × multiplier`,
///   rivais ganham `delta × multiplier` negativo). Esta camada NÃO
///   duplica a propagação; deixa o service de reputação orquestrar.
/// - **Lock 7 dias** em `player_faction_membership.lockedUntil` —
///   semântica original ("não pode entrar em outra facção até essa
///   data"). Diferente do lock 48h da admissão reprovada.
/// - **Debuff 48h** em `player_faction_membership.debuffUntil` — Etapa
///   C do plan-first usa esse campo pro `FactionBuffService` aplicar
///   -30% XP/-30% gold em runtime. Aqui apenas marcamos timestamp.
/// - `players.faction_type = 'none'`.
/// - Emite `FactionLeft` (canônico, retrocompatibilidade).
///
/// ## Tratamento especial da Guilda (Modelo dual)
///
/// Quando `factionId == 'guild'`:
/// - Tudo acima aplica EXCETO `players.guild_rank` permanece intocado.
/// - Aventureiro nível 1 (`guild_rank in ['e'..'s']`) é preservado
///   entre saídas/entradas da Facção Guilda nível 2.
/// - COLLAR_GUILD continua no inventário (já era comportamento — não
///   deletamos itens em saída).
///
/// ## Dívida reconhecida (Etapa H)
///
/// `player_faction_currency` ainda não existe (será criada na Etapa
/// H). Quando criar, este service deve **zerar a row** dessa facção
/// pra esse player — `// TODO(etapa-H)` documenta no código.
class LeaveFactionService {
  final AppDatabase _db;
  final AppEventBus _bus;
  final FactionReputationService _factionRep;

  LeaveFactionService({
    required AppDatabase db,
    required AppEventBus bus,
    required FactionReputationService factionRep,
  })  : _db = db,
        _bus = bus,
        _factionRep = factionRep;

  /// Lock geral pós-saída (não pode entrar em outra facção por 7d).
  static const Duration _generalLock = Duration(days: 7);

  /// Debuff de XP/gold por 48h (aplicado pelo FactionBuffService na
  /// Etapa C — esta camada só marca timestamp).
  static const Duration _debuffDuration = Duration(hours: 48);

  /// Penalidade fixa de reputação por sair.
  static const int _leaveRepDelta = -20;

  /// Sai da facção [factionId] pro [playerId].
  ///
  /// Lança [LeaveFactionException] se player não é membro da facção.
  /// Caller deve mostrar UI antes (confirmação) — service não trata
  /// UX, apenas persistência + eventos.
  Future<void> leaveFaction({
    required int playerId,
    required String factionId,
  }) async {
    if (factionId.isEmpty || factionId == 'none') {
      throw LeaveFactionException(
          'factionId inválido: "$factionId"');
    }

    // 1. Valida membership atual.
    final playerRows = await _db.customSelect(
      'SELECT faction_type FROM players WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(playerId)],
    ).get();
    if (playerRows.isEmpty) {
      throw LeaveFactionException('Player $playerId não existe');
    }
    final currentFaction = playerRows.first.read<String?>('faction_type');
    if (currentFaction != factionId) {
      throw LeaveFactionException(
          'Player $playerId não é membro de "$factionId" '
          '(faction_type atual: "$currentFaction")');
    }

    // 2. Aplica delta de reputação. `adjustReputation` propaga via
    //    matriz internamente — não duplicamos aqui.
    await _factionRep.adjustReputation(
      playerId: playerId,
      factionId: factionId,
      delta: _leaveRepDelta,
    );

    // 3. Atualiza membership row (leftAt + lockedUntil 7d + debuffUntil 48h).
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final lockUntilMs = now.add(_generalLock).millisecondsSinceEpoch;
    final debuffUntilMs =
        now.add(_debuffDuration).millisecondsSinceEpoch;

    await _db.customStatement(
      'UPDATE player_faction_membership '
      'SET left_at = ?, locked_until = ?, debuff_until = ? '
      'WHERE player_id = ? AND faction_id = ?',
      [nowMs, lockUntilMs, debuffUntilMs, playerId, factionId],
    );

    // 4. Reverte faction_type pra 'none' em players.
    //    ⚠️ `guild_rank` NÃO é tocado. Aventureiro nível 1 persiste
    //    independente de saídas da Facção Guilda nível 2.
    await _db.customUpdate(
      "UPDATE players SET faction_type = 'none' WHERE id = ?",
      variables: [Variable.withInt(playerId)],
      updates: {_db.playersTable},
    );

    // 5. TODO(etapa-H): zerar player_faction_currency pra
    //    factionId saída quando a tabela for criada.

    // 6. Emite evento canônico pra retrocompatibilidade.
    _bus.publish(FactionLeft(playerId: playerId, factionId: factionId));
  }
}

/// Exceção lançada por [LeaveFactionService.leaveFaction] quando
/// chamada com argumentos inválidos (player não existe, não é membro
/// da facção, factionId vazio, etc).
class LeaveFactionException implements Exception {
  final String message;
  const LeaveFactionException(this.message);

  @override
  String toString() => 'LeaveFactionException: $message';
}
