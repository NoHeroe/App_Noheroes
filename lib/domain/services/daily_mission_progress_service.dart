import 'package:drift/drift.dart' show Variable;

import '../../core/events/app_event_bus.dart';
import '../../core/events/daily_mission_events.dart';
import '../../core/events/player_events.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/daily_missions_dao.dart';
import '../../data/database/daos/player_dao.dart';
import '../models/daily_mission.dart';
import '../models/daily_mission_status.dart';
import '../models/daily_sub_task_instance.dart';

/// Sprint 3.2 Etapa 1.2 — acumulador de progresso e cálculo de reward.
///
/// `incrementSubTask(missionId, subTaskKey, delta)` atualiza
/// `progressoAtual` da sub-tarefa, marca `completed` quando atinge a
/// escala alvo, e quando todas as 3 sub-tarefas fecharam dispara o
/// reward inline (XP via `PlayerDao.addXp`, gold via `customUpdate`)
/// numa transação Drift.
///
/// `delta` pode ser negativo — usado pra desfazer toques acidentais. O
/// progresso nunca vai abaixo de 0.
///
/// Reward inline (sem RewardGrantService — esse só atende
/// MissionProgress legacy). Idempotência: `reward_claimed` é setada na
/// transação; chamadas após completar não regrantam.
class DailyMissionProgressService {
  final AppDatabase _db;
  final DailyMissionsDao _missionsDao;
  final PlayerDao _playerDao;
  final AppEventBus _bus;

  DailyMissionProgressService({
    required AppDatabase db,
    required DailyMissionsDao missionsDao,
    required PlayerDao playerDao,
    required AppEventBus bus,
  })  : _db = db,
        _missionsDao = missionsDao,
        _playerDao = playerDao,
        _bus = bus;

  static const Map<String, DailyRankReward> rewardByRank = {
    'E': DailyRankReward(xp: 8, gold: 5),
    'D': DailyRankReward(xp: 16, gold: 12),
    'C': DailyRankReward(xp: 28, gold: 20),
    'B': DailyRankReward(xp: 45, gold: 32),
    'A': DailyRankReward(xp: 72, gold: 50),
    'S': DailyRankReward(xp: 120, gold: 80),
  };

  /// Streak ≥ este valor adiciona +50% no reward.
  static const int streakBonusThreshold = 10;
  static const double streakBonusFactor = 1.5;
  static const double overshootBonusFactor = 1.2;
  static const double rewardCapFactor = 3.0;

  Future<void> incrementSubTask({
    required int missionId,
    required String subTaskKey,
    required int delta,
  }) async {
    LevelUp? levelUp;
    DailyMission? closedMission;

    await _db.transaction(() async {
      final mission = await _missionsDao.findById(missionId);
      if (mission == null) {
        throw StateError('Missão $missionId não existe');
      }
      if (mission.rewardClaimed) {
        // Já fechada e premiada — incrementos extras viram noop.
        return;
      }

      final subs = mission.subTarefas;
      final idx = subs.indexWhere((s) => s.subTaskKey == subTaskKey);
      if (idx == -1) {
        throw StateError(
            'Sub-tarefa "$subTaskKey" não pertence à missão $missionId');
      }

      final current = subs[idx];
      final newProgresso = (current.progressoAtual + delta).clamp(0, 1 << 30);
      final newCompleted = newProgresso >= current.escalaAlvo;
      final updatedSub = current.copyWith(
        progressoAtual: newProgresso,
        completed: newCompleted,
      );

      final newSubs = List<DailySubTaskInstance>.from(subs);
      newSubs[idx] = updatedSub;

      final allComplete = newSubs.every((s) => s.completed);
      DailyMission updated;

      if (allComplete) {
        // Fecha + grant reward dentro da mesma transação.
        final player = await _playerDao.findById(mission.playerId);
        if (player == null) {
          throw StateError('Player ${mission.playerId} sumiu mid-flight');
        }
        final reward = computeReward(
          rank: _normalizeRank(player.guildRank),
          missionWithFinalProgress: mission.copyWith(subTarefas: newSubs),
          partial: false,
          subCompletas: 3,
          dailyMissionsStreak: player.dailyMissionsStreak,
        );

        // 1) XP via PlayerDao.addXp (recalcula level/HP/MP/atributos).
        if (reward.xp > 0) {
          levelUp = await _playerDao.addXp(mission.playerId, reward.xp);
        }
        // 2) Gold via customUpdate atômica (entra na tx corrente
        //    automaticamente — Drift propaga via Zone).
        if (reward.gold > 0) {
          await _db.customUpdate(
            'UPDATE players SET gold = gold + ? WHERE id = ?',
            variables: [
              Variable.withInt(reward.gold),
              Variable.withInt(mission.playerId),
            ],
            updates: {_db.playersTable},
          );
        }

        updated = mission.copyWith(
          subTarefas: newSubs,
          status: DailyMissionStatus.completed,
          completedAt: DateTime.now(),
          rewardClaimed: true,
        );
        closedMission = updated;
      } else {
        updated = mission.copyWith(subTarefas: newSubs);
      }

      await _missionsDao.updateMission(updated);

      _bus.publish(DailyMissionProgressed(
        playerId: mission.playerId,
        missionId: mission.id,
        subTaskKey: subTaskKey,
        novoProgresso: newProgresso,
      ));
    });

    if (closedMission != null) {
      _bus.publish(DailyMissionCompleted(
        playerId: closedMission!.playerId,
        missionId: closedMission!.id,
        modalidade: closedMission!.modalidade,
        fullCompleted: true,
        partial: false,
      ));
    }
    if (levelUp != null) {
      _bus.publish(levelUp!);
    }
  }

  /// Marca uma missão como `failed`, sem reward. Útil pro caller forçar
  /// fechamento manual; rollover usa lógica própria que pode chegar a
  /// `partial` (com reward parcial) ou `failed`.
  Future<void> markFailed({
    required int missionId,
    required String reason,
  }) async {
    final mission = await _missionsDao.findById(missionId);
    if (mission == null) return;
    if (mission.rewardClaimed || mission.status == DailyMissionStatus.failed) {
      return;
    }
    final updated = mission.copyWith(
      status: DailyMissionStatus.failed,
      completedAt: DateTime.now(),
      rewardClaimed: false,
    );
    await _missionsDao.updateMission(updated);
    _bus.publish(DailyMissionFailed(
      playerId: mission.playerId,
      missionId: mission.id,
      reason: reason,
    ));
  }

  /// Cálculo público pra rollover reusar sem duplicar lógica.
  ///
  /// - Full (3/3): reward base × overshoot? × streak?
  /// - Partial (1-2/3): reward base × (subs/3) × 0.5 × overshoot? × streak?
  /// - Failed (0/3): zero
  /// - Cap: 300% do base
  static DailyResolvedReward computeReward({
    required String rank,
    required DailyMission missionWithFinalProgress,
    required bool partial,
    required int subCompletas,
    required int dailyMissionsStreak,
  }) {
    final base = rewardByRank[rank] ?? rewardByRank['E']!;
    if (subCompletas == 0) {
      return const DailyResolvedReward(xp: 0, gold: 0);
    }

    double factor = partial ? (subCompletas / 3.0) * 0.5 : 1.0;

    if (!partial && missionWithFinalProgress.allExceeded) {
      factor *= overshootBonusFactor;
    }
    if (dailyMissionsStreak >= streakBonusThreshold) {
      factor *= streakBonusFactor;
    }
    if (factor > rewardCapFactor) factor = rewardCapFactor;

    return DailyResolvedReward(
      xp: (base.xp * factor).round(),
      gold: (base.gold * factor).round(),
    );
  }

  /// Aplica reward parcial num [DailyMission] do rollover. Chamado
  /// dentro de transação pelo [DailyMissionRolloverService].
  Future<void> applyPartialReward({
    required DailyMission mission,
    required int subCompletas,
  }) async {
    if (mission.rewardClaimed) return;
    final player = await _playerDao.findById(mission.playerId);
    if (player == null) return;

    final reward = computeReward(
      rank: _normalizeRank(player.guildRank),
      missionWithFinalProgress: mission,
      partial: true,
      subCompletas: subCompletas,
      dailyMissionsStreak: player.dailyMissionsStreak,
    );

    LevelUp? levelUp;
    if (reward.xp > 0) {
      levelUp = await _playerDao.addXp(mission.playerId, reward.xp);
    }
    if (reward.gold > 0) {
      await _db.customUpdate(
        'UPDATE players SET gold = gold + ? WHERE id = ?',
        variables: [
          Variable.withInt(reward.gold),
          Variable.withInt(mission.playerId),
        ],
        updates: {_db.playersTable},
      );
    }

    final updated = mission.copyWith(
      status: DailyMissionStatus.partial,
      completedAt: DateTime.now(),
      rewardClaimed: true,
    );
    await _missionsDao.updateMission(updated);

    _bus.publish(DailyMissionCompleted(
      playerId: mission.playerId,
      missionId: mission.id,
      modalidade: mission.modalidade,
      fullCompleted: false,
      partial: true,
    ));
    if (levelUp != null) _bus.publish(levelUp);
  }

  String _normalizeRank(String raw) {
    if (raw == 'none' || raw.isEmpty) return 'E';
    return raw.toUpperCase();
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

