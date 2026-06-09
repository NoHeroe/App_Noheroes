import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/repositories/player_achievements_repository.dart';

/// Época 2 full-online (ADR-0024) — implementação Supabase do
/// [PlayerAchievementsRepository]. Substitui o `PlayerAchievementsRepositoryDrift`.
///
/// Guarda só a interseção jogador × key na tabela
/// `player_achievements_completed` (player_id uuid, achievement_key text,
/// completed_at bigint ms, reward_claimed boolean). Catálogo (metadata,
/// rewards, triggers) continua em `assets/data/achievements.json`, carregado
/// em memória pelo `AchievementsService`.
///
/// Operações são writes/reads simples por linha (sem read-modify-write
/// atômico), então PostgREST direto basta — não há RPC dedicada. A
/// idempotência de [markCompleted] vem do upsert com PK composta
/// (player_id, achievement_key). O guard de reward_claimed do grant de
/// conquista vive na RPC `grant_achievement_reward`.
class PlayerAchievementsRepositorySupabase
    implements PlayerAchievementsRepository {
  final SupabaseClient _client;
  PlayerAchievementsRepositorySupabase(this._client);

  @override
  Future<bool> isCompleted(String playerId, String achievementKey) async {
    final row = await _client
        .from('player_achievements_completed')
        .select('player_id')
        .eq('player_id', playerId)
        .eq('achievement_key', achievementKey)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<List<String>> listCompletedKeys(String playerId) async {
    final rows = await _client
        .from('player_achievements_completed')
        .select('achievement_key')
        .eq('player_id', playerId)
        .order('completed_at', ascending: false);
    return rows
        .map((r) => r['achievement_key'] as String)
        .toList(growable: false);
  }

  @override
  Future<void> markCompleted(
    String playerId,
    String achievementKey, {
    required DateTime at,
  }) async {
    // INSERT OR IGNORE semântico via upsert ignorando duplicatas: se a row
    // já existe (PK composta), não sobrescreve completed_at/reward_claimed.
    await _client.from('player_achievements_completed').upsert(
      {
        'player_id': playerId,
        'achievement_key': achievementKey,
        'completed_at': at.millisecondsSinceEpoch,
      },
      onConflict: 'player_id,achievement_key',
      ignoreDuplicates: true,
    );
  }

  @override
  Future<void> markRewardClaimed(
      String playerId, String achievementKey) async {
    await _client
        .from('player_achievements_completed')
        .update({'reward_claimed': true})
        .eq('player_id', playerId)
        .eq('achievement_key', achievementKey);
  }

  @override
  Future<bool> isRewardClaimed(
      String playerId, String achievementKey) async {
    final row = await _client
        .from('player_achievements_completed')
        .select('reward_claimed')
        .eq('player_id', playerId)
        .eq('achievement_key', achievementKey)
        .maybeSingle();
    return row != null && (row['reward_claimed'] as bool? ?? false);
  }

  @override
  Future<int> countCompleted(String playerId) async {
    final rows = await _client
        .from('player_achievements_completed')
        .select('achievement_key')
        .eq('player_id', playerId)
        .count(CountOption.exact);
    return rows.count;
  }

  @override
  Future<List<String>> listPendingClaims(String playerId) async {
    final rows = await _client
        .from('player_achievements_completed')
        .select('achievement_key')
        .eq('player_id', playerId)
        .eq('reward_claimed', false)
        .order('completed_at', ascending: false);
    return rows
        .map((r) => r['achievement_key'] as String)
        .toList(growable: false);
  }
}
