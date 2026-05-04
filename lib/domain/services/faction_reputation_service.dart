import 'package:drift/drift.dart' show Variable;

import '../../core/config/faction_alliances.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/events/faction_events.dart';
import '../../data/database/app_database.dart';
import '../repositories/player_faction_reputation_repository.dart';
import 'faction_buff_service.dart';

/// Sprint 3.1 Bloco 13b — CRUD + propagação via alianças.
///
/// Reputação 0-100 por `(playerId, factionId)`. Default 50 (neutro).
/// `adjustReputation(playerId, factionId, delta)`:
///
///   1. Lê reputação atual da facção alvo
///   2. Aplica delta (clamp 0-100 via repo.delta)
///   3. Emite `FactionReputationChanged` pra facção alvo
///   4. Itera `kFactionAlliances[factionId]` — pra cada (aliada/rival,
///      multiplier): aplica `delta × multiplier` na aliada + emit evento
///
/// Matrix vazia (neutra) → passo 4 é noop. Código pronto; dados placeholder.
///
/// Multiplier pode ser negativo (rival) — `repo.delta` aceita delta
/// negativo e faz clamp 0 na base.
class FactionReputationService {
  final PlayerFactionReputationRepository _repo;
  final AppEventBus _bus;

  /// Sprint 3.4 Etapa C — xpMult universal: buff de facção aplica em
  /// reputação ganha (delta > 0) com mesma porcentagem do XP. Opcional
  /// pra retrocompat de testes.
  final FactionBuffService? _factionBuff;
  final AppDatabase? _db;

  FactionReputationService({
    required PlayerFactionReputationRepository repo,
    required AppEventBus bus,
    AppDatabase? db,
    FactionBuffService? factionBuff,
  })  : _repo = repo,
        _bus = bus,
        _db = db,
        _factionBuff = factionBuff;

  /// Reputação atual (cria lazy default 50 se não existe).
  Future<int> current(int playerId, String factionId) =>
      _repo.getOrDefault(playerId, factionId);

  /// Todas as reputações do jogador.
  Future<Map<String, int>> all(int playerId) =>
      _repo.findAllByPlayer(playerId);

  /// Aplica [delta] em [factionId] + propaga via matrix.
  ///
  /// Delta positivo = subiu reputação. Matrix aliada aplica sinal
  /// preservado; matrix rival aplica sinal invertido via multiplier
  /// negativo.
  ///
  /// Emite `FactionReputationChanged` pra cada facção afetada.
  ///
  /// Sprint 3.4 Etapa C — xpMult universal aplica em delta GANHO
  /// (positivo). Penalidades (delta < 0) e propagações negativas via
  /// matrix passam cru. Regra OPÇÃO A: Guilda member ganhando rep
  /// **da Guilda** não recebe buff (buff só aplica em outras facções).
  Future<void> adjustReputation({
    required int playerId,
    required String factionId,
    required int delta,
  }) async {
    if (delta == 0) return;

    final adjustedMain = await _applyBuff(playerId, factionId, delta);

    // 1. Aplica delta principal.
    await _adjustSingle(
      playerId: playerId,
      factionId: factionId,
      delta: adjustedMain,
    );

    // 2. Propaga via matrix de alianças (neutra = noop).
    //    Propagação usa o delta ORIGINAL como base (não o buffed) —
    //    semântica: matrix amplifica o gesto original, não o ganho
    //    pessoal já buffado. Após propagação, aplica buff individual
    //    em cada aliada propagada (mesma regra OPÇÃO A).
    final allies = kFactionAlliances[factionId] ?? const <String, double>{};
    for (final entry in allies.entries) {
      final ally = entry.key;
      final mult = entry.value;
      final propagated = (delta * mult).round();
      if (propagated == 0) continue;
      final adjustedProp = await _applyBuff(playerId, ally, propagated);
      await _adjustSingle(
        playerId: playerId,
        factionId: ally,
        delta: adjustedProp,
      );
    }
  }

  /// xpMult em delta positivo, com OPÇÃO A pra Guilda. Sem dependências
  /// injetadas (buff/db nulos) → retorna delta cru (path legacy/teste).
  Future<int> _applyBuff(
      int playerId, String targetFactionId, int delta) async {
    if (delta <= 0) return delta;
    final buff = _factionBuff;
    final db = _db;
    if (buff == null || db == null) return delta;

    final mults = await buff.getActiveMultipliers(playerId);
    if (mults.xpMult == 1.0) return delta;

    if (targetFactionId == 'guild') {
      final rows = await db.customSelect(
        'SELECT faction_type FROM players WHERE id = ? LIMIT 1',
        variables: [Variable.withInt(playerId)],
      ).get();
      if (rows.isNotEmpty &&
          rows.first.read<String?>('faction_type') == 'guild') {
        return delta; // Guilda member ganhando rep da Guilda — sem buff
      }
    }
    return (delta * mults.xpMult).round();
  }

  Future<void> _adjustSingle({
    required int playerId,
    required String factionId,
    required int delta,
  }) async {
    final before = await _repo.getOrDefault(playerId, factionId);
    await _repo.delta(playerId, factionId, delta);
    final after = await _repo.getOrDefault(playerId, factionId);
    // Só emite se houve mudança real (clamp 0-100 pode engolir delta).
    if (after != before) {
      _bus.publish(FactionReputationChanged(
        playerId: playerId,
        factionId: factionId,
        newValue: after,
        previousValue: before,
      ));
    }
  }
}
