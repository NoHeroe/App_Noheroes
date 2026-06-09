import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/active_faction_quest.dart';
import '../../../domain/repositories/active_faction_quests_repository.dart';

/// Época 2 full-online (ADR-0024) — implementação Supabase do
/// [ActiveFactionQuestsRepository] (`active_faction_quests`). Substitui
/// `ActiveFactionQuestsRepositoryDrift`.
///
/// [upsertAtomic] é a operação atômica/idempotente do domínio (insere
/// ledger + materializa o progresso 'faction' na MESMA transação, com
/// idempotência sob race via UNIQUE) — NÃO reimplementada no cliente:
/// delega à RPC `assign_weekly_faction_quest`, que retorna
/// `{ledger_id, progress_id}`. [findActiveFor] e [deleteExpiredBefore] são
/// read/delete simples via PostgREST.
///
/// CONFLITO playerId (ver 'unresolved'): interface declara `int playerId`,
/// coluna é uuid. [_pid] stringifica; só correto com uuid real.
class ActiveFactionQuestsRepositorySupabase
    implements ActiveFactionQuestsRepository {
  final SupabaseClient _client;
  ActiveFactionQuestsRepositorySupabase(this._client);

  static const _table = 'active_faction_quests';

  String _pid(int playerId) => playerId.toString();

  @override
  Future<ActiveFactionQuest?> findActiveFor(
    int playerId,
    String factionId,
    String weekStart,
  ) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('player_id', _pid(playerId))
        .eq('faction_id', factionId)
        .eq('week_start', weekStart)
        .maybeSingle();
    return row == null ? null : ActiveFactionQuest.fromMap(row);
  }

  @override
  Future<FactionWeeklyAssignment> upsertAtomic({
    required int playerId,
    required String factionId,
    required String missionKey,
    required String weekStart,
    required Map<String, dynamic> progressSeedJson,
  }) async {
    // Atômico + idempotente sob race: a RPC faz ON CONFLICT no ledger e
    // materializa (ou recupera) o progress 'faction' na mesma transação.
    // O seed (modality/rank/target_value/reward_json/meta_json) é montado
    // pelo caller (_toWeeklyProgressSeed) e passado como jsonb.
    final result = await _client.rpc(
      'assign_weekly_faction_quest',
      params: {
        'p_player': _pid(playerId),
        'p_faction_id': factionId,
        'p_mission_key': missionKey,
        'p_week_start': weekStart,
        'p_seed': progressSeedJson,
      },
    );
    final map = result as Map<String, dynamic>;
    return (
      ledgerId: map['ledger_id'] as int,
      progressId: map['progress_id'] as int,
    );
  }

  @override
  Future<int> deleteExpiredBefore(String weekStart) async {
    // Limpeza de manutenção: deleta ledgers de semanas anteriores. PostgREST
    // não retorna rowcount por padrão; usamos .select() pra contar as rows
    // efetivamente deletadas (paridade com o `int` retornado pelo Drift).
    final deleted = await _client
        .from(_table)
        .delete()
        .lt('week_start', weekStart)
        .select('id');
    return deleted.length;
  }
}
