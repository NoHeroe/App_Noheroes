import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/repositories/player_faction_reputation_repository.dart';

/// Época 2 full-online (ADR-0024) — implementação Supabase do
/// [PlayerFactionReputationRepository] (`player_faction_reputation`).
/// Substitui `PlayerFactionReputationRepositoryDrift`.
///
/// [delta] é read-modify-write atômico (lê atual com default 50, soma,
/// clampa 0..100, upsert) — NÃO reimplementado no cliente: delega à RPC
/// `faction_reputation_delta`, que faz tudo em 1 transação com a mesma
/// semântica de clamp/default. As leituras e o [setAbsolute] são writes
/// simples de linha via PostgREST.
///
/// CONFLITO playerId (ver 'unresolved'): interface declara `String playerId`,
/// coluna é uuid. [_pid] stringifica; só correto com uuid real.
class PlayerFactionReputationRepositorySupabase
    implements PlayerFactionReputationRepository {
  final SupabaseClient _client;
  PlayerFactionReputationRepositorySupabase(this._client);

  static const _table = 'player_faction_reputation';
  static const int _neutralDefault = 50;


  int _clamp(int value) {
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  @override
  Future<int> getOrDefault(String playerId, String factionId) async {
    final row = await _client
        .from(_table)
        .select('reputation')
        .eq('player_id', playerId)
        .eq('faction_id', factionId)
        .maybeSingle();
    return row == null ? _neutralDefault : row['reputation'] as int;
  }

  @override
  Future<Map<String, int>> findAllByPlayer(String playerId) async {
    final rows = await _client
        .from(_table)
        .select('faction_id, reputation')
        .eq('player_id', playerId);
    return {
      for (final r in rows)
        r['faction_id'] as String: r['reputation'] as int,
    };
  }

  @override
  Future<void> setAbsolute(
    String playerId,
    String factionId,
    int reputation,
  ) async {
    // setAbsolute continua sendo upsert simples (1 write). clamp aplicado
    // no cliente, igual ao Drift. NB: delta NÃO usa este método — vai pela
    // RPC pra garantir atomicidade do read-modify-write.
    final clamped = _clamp(reputation);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _client.from(_table).upsert(
      {
        'player_id': playerId,
        'faction_id': factionId,
        'reputation': clamped,
        'updated_at': now,
      },
      onConflict: 'player_id,faction_id',
    );
  }

  @override
  Future<void> delta(String playerId, String factionId, int delta) async {
    // Atômico: getOrDefault(50) + clamp + upsert dentro de 1 transação.
    await _client.rpc(
      'faction_reputation_delta',
      params: {
        'p_player': playerId,
        'p_faction': factionId,
        'p_delta': delta,
      },
    );
  }
}
