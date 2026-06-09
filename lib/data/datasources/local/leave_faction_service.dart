import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/faction_events.dart';
import '../../../domain/services/faction_reputation_service.dart';

/// Sprint 3.4 Sub-Etapa B.2 — service dedicado pro flow de saída de
/// facção.
///
/// Época 2 (ADR-0024) — full-online Supabase. TODO o flow de saída
/// (validação de membership + -20 reputação COM propagação via
/// `kFactionAlliances` + lock 7d + debuff 48h + `faction_type='none'`)
/// é uma única operação ATÔMICA no servidor via RPC `leave_faction` —
/// não reimplementamos a atomicidade nem a propagação no cliente. O
/// caller só calcula os timestamps (paridade com o `DateTime.now()` do
/// Dart) e emite `FactionLeft` client-side após o commit.
///
/// ## Penalidades padrão (aplicadas pela RPC)
///
/// - **-20 reputação** na facção saída, COM propagação via matrix.
/// - **Lock 7 dias** em `player_faction_membership.locked_until`.
/// - **Debuff 48h** em `player_faction_membership.debuff_until` (o
///   `FactionBuffService` lê esse timestamp em runtime).
/// - `players.faction_type = 'none'`.
///
/// ## Tratamento especial da Guilda (Modelo dual)
///
/// `players.guild_rank` permanece intocado pela RPC (Aventureiro nível 1
/// preservado entre saídas/entradas da Facção Guilda nível 2).
///
/// ## Dívida reconhecida (Etapa H)
///
/// `player_faction_currency` ainda não existe; quando criar, a RPC deve
/// zerar a row dessa facção.
class LeaveFactionService {
  final SupabaseClient _client;
  final AppEventBus _bus;
  // Mantido como dep do domínio (a propagação de reputação agora vive
  // dentro da RPC `leave_faction`; este service não a invoca mais
  // diretamente).
  // ignore: unused_field
  final FactionReputationService _factionRep;

  LeaveFactionService({
    required SupabaseClient client,
    required AppEventBus bus,
    required FactionReputationService factionRep,
  })  : _client = client,
        _bus = bus,
        _factionRep = factionRep;

  /// Lock geral pós-saída (não pode entrar em outra facção por 7d).
  static const Duration _generalLock = Duration(days: 7);

  /// Debuff de XP/gold por 48h (aplicado pelo FactionBuffService).
  static const Duration _debuffDuration = Duration(hours: 48);

  /// Sai da facção [factionId] pro [playerId].
  ///
  /// Lança [LeaveFactionException] se player não é membro da facção
  /// (a RPC valida e levanta; mapeamos o erro do Postgres). Caller deve
  /// mostrar UI antes (confirmação) — service não trata UX.
  Future<void> leaveFaction({
    required String playerId,
    required String factionId,
  }) async {
    if (factionId.isEmpty || factionId == 'none') {
      throw LeaveFactionException('factionId inválido: "$factionId"');
    }

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final lockUntilMs = now.add(_generalLock).millisecondsSinceEpoch;
    final debuffUntilMs = now.add(_debuffDuration).millisecondsSinceEpoch;

    try {
      await _client.rpc('leave_faction', params: {
        'p_player': playerId,
        'p_faction': factionId,
        'p_now_ms': nowMs,
        'p_lock_until_ms': lockUntilMs,
        'p_debuff_until_ms': debuffUntilMs,
      });
    } on PostgrestException catch (e) {
      // A RPC levanta `LeaveFactionException: ...` quando o player não é
      // membro / não existe — re-mapeia pra exceção de domínio.
      throw LeaveFactionException(e.message);
    }

    // Emite evento canônico pra retrocompatibilidade (client-side).
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
