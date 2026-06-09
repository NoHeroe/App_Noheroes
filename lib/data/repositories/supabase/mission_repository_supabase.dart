import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/repositories/mission_repository.dart';

/// Época 2 full-online (ADR-0024) — implementação Supabase do
/// [MissionRepository] (`player_mission_progress`). Substitui
/// `MissionRepositoryDrift`.
///
/// Leituras/escritas simples de linha vão via PostgREST. A operação
/// ATÔMICA da família (markCompleted + grant da reward, ADR-0011) NÃO é
/// reimplementada aqui: o caller canônico `RewardGrantService.grant`
/// chama a RPC `grant_mission_reward`, que dentro de 1 transação faz
/// markCompleted(reward_claimed=true) + credita XP/gold/items/recipes/rep.
/// [markCompleted] deste repo cobre só o caso NÃO-transacional
/// (reward_claimed=false, sem grant) usado por fluxos que apenas fecham a
/// missão sem pagar — ver nota em [markCompleted].
///
/// CONFLITO playerId (ver 'unresolved' da Fase 3): a interface ainda
/// declara `String playerId`, mas a coluna é uuid. [_pid] faz a ponte
/// stringificando; só funciona de verdade quando o caller passar o uuid
/// real (interface migrada pra String, como PlayerAchievements já está).
class MissionRepositorySupabase implements MissionRepository {
  final SupabaseClient _client;
  MissionRepositorySupabase(this._client);

  static const _table = 'player_mission_progress';

  /// Ponte int->uuid enquanto a interface não migra pra String playerId.

  @override
  Future<MissionProgress?> findById(int id) async {
    final row =
        await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : MissionProgress.fromMap(row);
  }

  @override
  Future<List<MissionProgress>> findActive(String playerId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('player_id', playerId)
        .isFilter('completed_at', null)
        .isFilter('failed_at', null)
        .order('started_at', ascending: true);
    return rows
        .map((r) => MissionProgress.fromMap(r))
        .toList(growable: false);
  }

  @override
  Future<List<MissionProgress>> findByTab(
    String playerId,
    MissionTabOrigin tab,
  ) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('player_id', playerId)
        .eq('tab_origin', tab.storage)
        .order('started_at', ascending: false);
    return rows
        .map((r) => MissionProgress.fromMap(r))
        .toList(growable: false);
  }

  @override
  Future<List<MissionProgress>> findHistorical(String playerId) async {
    // Não-ativas (completadas OU falhadas) de todas as abas, ordenadas
    // DESC por COALESCE(completed_at, failed_at). PostgREST não expõe
    // COALESCE no .order(); ordenamos client-side após filtrar.
    final rows = await _client
        .from(_table)
        .select()
        .eq('player_id', playerId)
        .or('completed_at.not.is.null,failed_at.not.is.null');
    final list = rows
        .map((r) => MissionProgress.fromMap(r))
        .toList(growable: true);
    _sortByClosureDesc(list);
    return List.unmodifiable(list);
  }

  @override
  Future<List<MissionProgress>> findCompletedInWindow(
    String playerId, {
    required DateTime from,
    required DateTime to,
  }) async {
    // Janela inclusiva sobre COALESCE(completed_at, failed_at). PostgREST
    // não filtra por COALESCE diretamente; trazemos as não-ativas e
    // filtramos/ordenamos client-side pela mesma regra do Drift.
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    final rows = await _client
        .from(_table)
        .select()
        .eq('player_id', playerId)
        .or('completed_at.not.is.null,failed_at.not.is.null');
    final list = rows
        .map((r) => MissionProgress.fromMap(r))
        .where((m) {
          final ts = _closureMs(m);
          return ts != null && ts >= fromMs && ts <= toMs;
        })
        .toList(growable: true);
    _sortByClosureDesc(list);
    return List.unmodifiable(list);
  }

  @override
  Stream<List<MissionProgress>> watchActive(String playerId) {
    // Realtime stream das rows do jogador; filtramos ativas + ordenamos
    // client-side (o .stream do supabase aceita só eq + order simples).
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('player_id', playerId)
        .order('started_at')
        .map((rows) {
          return rows
              .where((r) => r['completed_at'] == null && r['failed_at'] == null)
              .map((r) => MissionProgress.fromMap(r))
              .toList(growable: false);
        });
  }

  @override
  Future<int> insert(MissionProgress progress) async {
    // Reusa MissionProgress.toJson (já serializa modality/tab_origin/rank em
    // snake_case canônico) e só sobrescreve player_id (uuid) + remove o id
    // (bigserial gerado pelo banco).
    final payload = progress.toJson()
      ..remove('id')
      ..['player_id'] = progress.playerId;
    payload.removeWhere((k, v) => v == null); // não enviar completed/failed null
    final row =
        await _client.from(_table).insert(payload).select('id').single();
    return row['id'] as int;
  }

  @override
  Future<void> updateProgress(
    int id, {
    required int currentValue,
    String? metaJson,
  }) async {
    await _client.from(_table).update({
      'current_value': currentValue,
      if (metaJson != null) 'meta_json': metaJson,
    }).eq('id', id);
  }

  @override
  Future<void> markCompleted(
    int id, {
    required DateTime at,
    required bool rewardClaimed,
  }) async {
    // ADR-0011: o caminho COM grant de reward é atômico via RPC
    // grant_mission_reward (chamado pelo RewardGrantService.grant), que já
    // seta completed_at + reward_claimed=true dentro da transação. Este
    // método cobre só o write puro de fechamento (sem grant acoplado) —
    // p.ex. fluxos que marcam completa sem pagar. NÃO usar como metade de
    // um grant manual no cliente: isso reintroduziria a não-atomicidade
    // que a RPC elimina.
    await _client.from(_table).update({
      'completed_at': at.millisecondsSinceEpoch,
      'reward_claimed': rewardClaimed,
    }).eq('id', id);
  }

  @override
  Future<void> markFailed(int id, {required DateTime at}) async {
    await _client
        .from(_table)
        .update({'failed_at': at.millisecondsSinceEpoch})
        .eq('id', id);
  }

  // --- helpers client-side pra ordenação por COALESCE(completed,failed) ---

  int? _closureMs(MissionProgress m) =>
      m.completedAt?.millisecondsSinceEpoch ??
      m.failedAt?.millisecondsSinceEpoch;

  void _sortByClosureDesc(List<MissionProgress> list) {
    list.sort((a, b) {
      final ta = _closureMs(a) ?? 0;
      final tb = _closureMs(b) ?? 0;
      return tb.compareTo(ta);
    });
  }
}
