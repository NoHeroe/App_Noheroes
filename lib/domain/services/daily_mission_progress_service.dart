import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/daily_mission_events.dart';
import '../../core/events/player_events.dart';
import '../enums/mission_category.dart';
import '../models/daily_mission.dart';
import '../models/daily_mission_status.dart';
import '../models/daily_sub_task_instance.dart';
import 'faction_buff_service.dart';

/// Época 2 (ADR-0024) — port full-online (Supabase) do progress service.
///
/// **Operações atômicas viram RPCs** (`confirm_daily_mission`,
/// `apply_partial_daily_reward`, `apply_auto_completed_daily`). Essas
/// RPCs encapsulam: resolve status + computa reward (fórmula linear
/// hotfix-2) + credita xp/gold (add_xp/add_gold) + fecha a missão, tudo
/// numa transação server-side. O cliente só lê o JSON de retorno e
/// publica os eventos client-side.
///
/// **Reward (regra final, linear)** — vive agora em `_daily_compute_reward`
/// no Postgres (rpc_daily.sql). Os helpers estáticos [missionFactor] /
/// [partialFactor] / [computeReward] / [previewStatus] permanecem aqui
/// porque a UI/notifier os consomem pra preview SEM tocar o servidor.
///
/// **FACTION BUFFS:** o path Drift aplicava `_applyBuffs` (xpMult/goldMult)
/// por cima do reward. As RPCs creditam o reward BASE — o buff de facção
/// NÃO é mais aplicado no path de dailies nesta conversão (ver 'risks'
/// no resumo). `_factionBuff` é mantido opcional só pra compat de
/// religação de providers; não é usado.
///
/// **`incrementSubTask` e `markFailed`** não têm RPC dedicada — são
/// read-modify-write client-side (ver 'unresolved').
class DailyMissionProgressService {
  final SupabaseClient _client;
  final AppEventBus _bus;

  /// Mantido por compat de providers — NÃO usado no path full-online (as
  /// RPCs creditam reward base; buff de facção fica fora). Ver 'risks'.
  // ignore: unused_field
  final FactionBuffService? _factionBuff;

  DailyMissionProgressService({
    required SupabaseClient client,
    required AppEventBus bus,
    FactionBuffService? factionBuff,
  })  : _client = client,
        _bus = bus,
        _factionBuff = factionBuff;

  static const Map<String, DailyRankReward> rewardByRank = {
    'E': DailyRankReward(xp: 8, gold: 5),
    'D': DailyRankReward(xp: 16, gold: 12),
    'C': DailyRankReward(xp: 28, gold: 20),
    'B': DailyRankReward(xp: 45, gold: 32),
    'A': DailyRankReward(xp: 72, gold: 50),
    'S': DailyRankReward(xp: 120, gold: 80),
  };

  static const int streakBonusThreshold = 10;
  static const double streakBonusFactor = 1.5;

  /// Cap individual de excedência por sub-tarefa: 3× o alvo. Aplica no
  /// clamp de [incrementSubTask] e no [missionFactor] (cap por sub).
  static const double subTaskMaxFactor = 3.0;

  /// Inclinação da fórmula linear acima de 100%: cada 100% extra acima
  /// do alvo médio adiciona 45% ao reward.
  static const double overshootSlope = 0.45;

  /// Limite que separa `partial` de `failed`. Sub-tarefa abaixo de 25%
  /// do alvo conta como "abandonada"; se TODAS as 3 estão abaixo disso,
  /// a missão vira `failed`.
  static const double failureThreshold = 0.25;

  // ─── increment ──────────────────────────────────────────────────────

  /// Adiciona [delta] ao progresso de uma sub-tarefa. **NÃO fecha a
  /// missão** mesmo que 3/3 batam — o jogador precisa clicar ✓ pra
  /// confirmar via [confirmCompletion].
  ///
  /// Época 2: read-modify-write client-side (sem RPC dedicada). RLS
  /// garante que só o dono escreve. Risco de lost-update sob escrita
  /// concorrente (ver 'unresolved' — falta RPC `increment_daily_subtask`).
  Future<void> incrementSubTask({
    required int missionId,
    required String subTaskKey,
    required int delta,
  }) async {
    final mission = await _findMissionById(missionId);
    if (mission == null) {
      throw StateError('Missão $missionId não existe');
    }
    if (mission.rewardClaimed) {
      // Já fechada — incrementos extras viram noop.
      return;
    }

    final subs = mission.subTarefas;
    final idx = subs.indexWhere((s) => s.subTaskKey == subTaskKey);
    if (idx == -1) {
      throw StateError(
          'Sub-tarefa "$subTaskKey" não pertence à missão $missionId');
    }

    final current = subs[idx];
    final maxProgresso = current.escalaAlvo <= 0
        ? 0
        : (current.escalaAlvo * subTaskMaxFactor).floor();
    final progresso = (current.progressoAtual + delta).clamp(0, maxProgresso);
    final updatedSub = current.copyWith(
      progressoAtual: progresso,
      completed: progresso >= current.escalaAlvo,
    );

    final newSubs = List<DailySubTaskInstance>.from(subs);
    newSubs[idx] = updatedSub;
    final updated = mission.copyWith(subTarefas: newSubs);

    await _client.from('daily_missions').update({
      'sub_tarefas_json': updated.encodeSubTarefas(),
    }).eq('id', missionId);

    _bus.publish(DailyMissionProgressed(
      playerId: mission.playerId,
      missionId: missionId,
      subTaskKey: subTaskKey,
      novoProgresso: progresso,
    ));
  }

  // ─── confirm ────────────────────────────────────────────────────────

  /// Fecha a missão manualmente (clique no ✓) via RPC
  /// `confirm_daily_mission`. A RPC resolve status, credita reward e
  /// fecha atomicamente. Aqui só publicamos os eventos client-side a
  /// partir do JSON de retorno.
  ///
  /// Idempotência: a RPC lança `unique_violation` se a missão já foi
  /// fechada → traduzimos em [RewardAlreadyGrantedException].
  Future<void> confirmCompletion({required int missionId}) async {
    final Map<String, dynamic> res;
    try {
      res = (await _client.rpc('confirm_daily_mission', params: {
        'p_mission_id': missionId,
      })) as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      // RPC: errcode unique_violation (23505) => já fechada.
      if (e.code == '23505') {
        throw RewardAlreadyGrantedException(missionId: missionId);
      }
      rethrow;
    }

    final status = DailyMissionStatusCodec.fromStorage(res['status'] as String);
    final playerId = res['player_id'] as String;
    final modalidade =
        MissionCategoryCodec.fromStorage(res['modalidade'] as String);
    final goldEarned = (res['gold_earned'] as num?)?.toInt() ?? 0;

    if (status == DailyMissionStatus.failed) {
      _bus.publish(DailyMissionFailed(
        playerId: playerId,
        missionId: missionId,
        reason: 'manual-confirm-zero',
      ));
    } else {
      _bus.publish(DailyMissionCompleted(
        playerId: playerId,
        missionId: missionId,
        modalidade: modalidade,
        fullCompleted: status == DailyMissionStatus.completed,
        partial: status == DailyMissionStatus.partial,
        goldEarned: goldEarned,
      ));
    }
    _publishLevelUp(res, playerId);
  }

  /// Marca como `failed` administrativamente (sem reward). Sem RPC
  /// dedicada — guard + update client-side. RLS protege a linha.
  Future<void> markFailed({
    required int missionId,
    required String reason,
  }) async {
    final mission = await _findMissionById(missionId);
    if (mission == null) return;
    if (mission.rewardClaimed || mission.status == DailyMissionStatus.failed) {
      return;
    }
    await _client.from('daily_missions').update({
      'status': DailyMissionStatus.failed.storage,
      'completed_at': DateTime.now().millisecondsSinceEpoch,
      'reward_claimed': false,
    }).eq('id', missionId);

    _bus.publish(DailyMissionFailed(
      playerId: mission.playerId,
      missionId: mission.id,
      reason: reason,
    ));
  }

  // ─── reward calc (preview client-side — espelha _daily_compute_reward) ─

  /// Cálculo público de reward por status (fórmula linear hotfix-2).
  /// Usado pela UI/notifier pra preview SEM tocar o servidor. O crédito
  /// real é feito pelas RPCs (`_daily_compute_reward` no Postgres).
  ///
  /// - `failed` / `pending`: zero.
  /// - `completed` / `partial`: usa [missionFactor] (cap 3.0 por sub).
  ///   - `mult = factor` se `factor <= 1.0`.
  ///   - `mult = 1 + 0.45 × (factor - 1)` se `factor > 1.0`.
  ///   - Streak bonus (×1.5) só em `completed` com streak ≥ 10.
  /// - Truncamento final via `floor()`.
  static DailyResolvedReward computeReward({
    required String rank,
    required DailyMission mission,
    required DailyMissionStatus status,
    required int dailyMissionsStreak,
  }) {
    final base = rewardByRank[rank] ?? rewardByRank['E']!;

    if (status == DailyMissionStatus.failed ||
        status == DailyMissionStatus.pending) {
      return const DailyResolvedReward(xp: 0, gold: 0);
    }

    final factor = missionFactor(mission);
    final mult =
        factor <= 1.0 ? factor : 1.0 + overshootSlope * (factor - 1.0);
    final streakBonus = (status == DailyMissionStatus.completed &&
            dailyMissionsStreak >= streakBonusThreshold)
        ? streakBonusFactor
        : 1.0;

    return DailyResolvedReward(
      xp: (base.xp * mult * streakBonus).floor(),
      gold: (base.gold * mult * streakBonus).floor(),
    );
  }

  /// `factor = soma(min(progresso_i / alvo_i, 3.0)) / 3`
  ///
  /// Cap em 300% por sub-tarefa — excedência conta linearmente. Usado em
  /// [computeReward]. Para preview de progresso na UI use [partialFactor]
  /// (cap 100% por sub).
  static double missionFactor(DailyMission mission) {
    final subs = mission.subTarefas;
    if (subs.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in subs) {
      if (s.escalaAlvo <= 0) continue;
      final ratio = s.progressoAtual / s.escalaAlvo;
      sum += ratio.clamp(0.0, subTaskMaxFactor);
    }
    return sum / subs.length;
  }

  /// `factor = soma(min(progresso_i, alvo_i) / alvo_i) / 3`
  ///
  /// Cap em 100% por sub-tarefa. Usado pela UI pra mostrar % concluído da
  /// missão (sem inflar com excedência). Reward usa [missionFactor].
  static double partialFactor(DailyMission mission) {
    final subs = mission.subTarefas;
    if (subs.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in subs) {
      if (s.escalaAlvo <= 0) continue;
      final ratio = s.progressoAtual >= s.escalaAlvo
          ? 1.0
          : s.progressoAtual / s.escalaAlvo;
      sum += ratio;
    }
    return sum / subs.length;
  }

  /// Decide o status final pra confirmação manual / rollover, baseado
  /// no progresso atual de cada sub-tarefa. Espelha `_daily_resolve_status`.
  static DailyMissionStatus _resolveStatus(DailyMission mission) {
    final subs = mission.subTarefas;
    if (subs.isEmpty) return DailyMissionStatus.failed;

    var allFull = true;
    var allBelowThreshold = true;
    for (final s in subs) {
      if (s.escalaAlvo <= 0) continue;
      final ratio = s.progressoAtual / s.escalaAlvo;
      if (ratio < 1.0) allFull = false;
      if (ratio >= failureThreshold) allBelowThreshold = false;
    }

    if (allFull) return DailyMissionStatus.completed;
    if (allBelowThreshold) return DailyMissionStatus.failed;
    return DailyMissionStatus.partial;
  }

  /// Helper público pra UI / notifier consultarem o status que a missão
  /// teria se confirmasse agora — sem mutar nada.
  static DailyMissionStatus previewStatus(DailyMission mission) =>
      _resolveStatus(mission);

  // ─── rollover hooks (via RPC) ────────────────────────────────────────

  /// Aplica reward proporcional + marca `partial` via RPC
  /// `apply_partial_daily_reward`. Chamado pelo rollover.
  ///
  /// Mantém assinatura por compat — `subCompletas` virou legacy/ignorado
  /// (a RPC computa o factor internamente). Idempotente server-side
  /// (`applied:false` se já claimed).
  Future<void> applyPartialReward({
    required DailyMission mission,
    required int subCompletas,
  }) async {
    final res = (await _client.rpc('apply_partial_daily_reward', params: {
      'p_mission_id': mission.id,
    })) as Map<String, dynamic>;

    if (res['applied'] != true) return;

    final playerId = res['player_id'] as String;
    _bus.publish(DailyMissionCompleted(
      playerId: playerId,
      missionId: mission.id,
      modalidade: mission.modalidade,
      fullCompleted: false,
      partial: true,
      goldEarned: (res['gold_earned'] as num?)?.toInt() ?? 0,
    ));
    _publishLevelUp(res, playerId);
  }

  /// Fecha como `completed` (com streak bonus) e `was_auto_confirmed=true`
  /// via RPC `apply_auto_completed_daily`. Idempotente server-side.
  Future<void> applyAutoCompleted({required DailyMission mission}) async {
    final res = (await _client.rpc('apply_auto_completed_daily', params: {
      'p_mission_id': mission.id,
    })) as Map<String, dynamic>;

    if (res['applied'] != true) return;

    final playerId = res['player_id'] as String;
    _bus.publish(DailyMissionCompleted(
      playerId: playerId,
      missionId: mission.id,
      modalidade: mission.modalidade,
      fullCompleted: true,
      partial: false,
      wasAutoConfirmed: true,
      goldEarned: (res['gold_earned'] as num?)?.toInt() ?? 0,
    ));
    _publishLevelUp(res, playerId);
  }

  // ─── helpers ──────────────────────────────────────────────────────────

  Future<DailyMission?> _findMissionById(int id) async {
    final row = await _client
        .from('daily_missions')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : DailyMission.fromMap(row);
  }

  /// As RPCs retornam `level_up` como json `{previous_level, new_level}`
  /// (ou null). Traduz pra evento [LevelUp] client-side.
  void _publishLevelUp(Map<String, dynamic> res, String playerId) {
    final lu = res['level_up'];
    if (lu is! Map) return;
    final newLevel = (lu['new_level'] as num?)?.toInt();
    final prevLevel = (lu['previous_level'] as num?)?.toInt();
    if (newLevel == null || prevLevel == null) return;
    _bus.publish(LevelUp(
      playerId: playerId,
      newLevel: newLevel,
      previousLevel: prevLevel,
    ));
  }
}

/// Reward declarada pra um rank.
class DailyRankReward {
  final int xp;
  final int gold;
  const DailyRankReward({required this.xp, required this.gold});
}

/// Reward já calculada (após bônus, streak, cap). Pública pra tests.
class DailyResolvedReward {
  final int xp;
  final int gold;
  const DailyResolvedReward({required this.xp, required this.gold});
}

/// Lançada por [DailyMissionProgressService.confirmCompletion] quando a
/// missão já foi fechada (status != pending OU rewardClaimed). Caller
/// (notifier) silencia — UI já tá no estado correto.
class RewardAlreadyGrantedException implements Exception {
  final int missionId;
  RewardAlreadyGrantedException({required this.missionId});

  @override
  String toString() => 'RewardAlreadyGrantedException(mission=$missionId)';
}
