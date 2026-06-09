import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/individual_mission_spec.dart';
import '../../../domain/repositories/player_individual_missions_repository.dart';

/// Época 2 full-online (ADR-0024) — implementação Supabase do
/// [PlayerIndividualMissionsRepository] (`player_individual_missions`).
/// Substitui `PlayerIndividualMissionsRepositoryDrift`.
///
/// Todas as operações são writes/reads simples de linha (soft delete via
/// `deleted_at`, sem read-modify-write atômico): PostgREST direto basta,
/// sem RPC. A cobrança de gemas+ouro do soft delete é feita pelo caller
/// ANTES de chamar [softDelete] (contrato da interface) — não há
/// transação acoplada aqui.
///
/// NB: as RPCs `create_individual_mission`/`delete_individual_mission`
/// pertencem a OUTRO fluxo (materializam a individual em
/// `player_mission_progress` com guard de limite/custo) e NÃO são deste
/// repositório, que persiste o catálogo de specs em
/// `player_individual_missions`.
///
/// CONFLITO playerId (ver 'unresolved'): interface declara `String playerId`,
/// coluna é uuid. [_pid] stringifica; só correto com uuid real.
class PlayerIndividualMissionsRepositorySupabase
    implements PlayerIndividualMissionsRepository {
  final SupabaseClient _client;
  PlayerIndividualMissionsRepositorySupabase(this._client);

  static const _table = 'player_individual_missions';


  @override
  Future<List<IndividualMissionSpec>> findActive(String playerId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('player_id', playerId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return rows
        .map((r) => IndividualMissionSpec.fromMap(r))
        .toList(growable: false);
  }

  @override
  Future<IndividualMissionSpec?> findById(int id) async {
    final row =
        await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : IndividualMissionSpec.fromMap(row);
  }

  @override
  Future<int> insert(IndividualMissionSpec mission) async {
    // Reusa IndividualMissionSpec.toJson (snake_case canônico, inclui
    // reward_json via RewardDeclared.toJsonString) e só sobrescreve
    // player_id (uuid) + remove o id (bigserial gerado pelo banco) e os
    // campos nulos (description/deleted_at).
    final payload = mission.toJson()
      ..remove('id')
      ..['player_id'] = mission.playerId;
    payload.removeWhere((k, v) => v == null);
    final row =
        await _client.from(_table).insert(payload).select('id').single();
    return row['id'] as int;
  }

  @override
  Future<void> updateCounters(
    int id, {
    required int completionCount,
    required int failureCount,
  }) async {
    await _client.from(_table).update({
      'completion_count': completionCount,
      'failure_count': failureCount,
    }).eq('id', id);
  }

  @override
  Future<void> softDelete(int id, {required DateTime at}) async {
    await _client
        .from(_table)
        .update({'deleted_at': at.millisecondsSinceEpoch})
        .eq('id', id);
  }

  @override
  Future<int> countActive(String playerId) async {
    final res = await _client
        .from(_table)
        .select('id')
        .eq('player_id', playerId)
        .isFilter('deleted_at', null)
        .count(CountOption.exact);
    return res.count;
  }
}
