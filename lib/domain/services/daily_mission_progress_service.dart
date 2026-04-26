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

/// Sprint 3.2 Etapa 1.2 + Hotfix 1.3.A — acumulador e fechamento manual.
///
/// **Mudou no hotfix:**
/// - `incrementSubTask` NÃO fecha mais a missão automaticamente ao 3/3.
///   Sub-tarefas marcam `completed=true` individuais; o status da missão
///   só muda em [confirmCompletion] (clique manual no ✓) ou em rollover.
/// - Novo método [confirmCompletion]: calcula status final + reward com
///   `partial` proporcional ao progresso real da missão.
///
/// **Reward partial (regra final):**
/// `factor = soma(min(progresso_i, alvo_i) / alvo_i) / 3`
///
/// Excedência (+20%) e streak (×1.5) só se aplicam em `completed`.
/// Partial é só o factor proporcional (sem ×0.5, sem bônus).
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

  static const int streakBonusThreshold = 10;
  static const double streakBonusFactor = 1.5;
  static const double overshootBonusFactor = 1.2;
  static const double rewardCapFactor = 3.0;

  /// Limite que separa `partial` de `failed`. Sub-tarefa abaixo de 25%
  /// do alvo conta como "abandonada"; se TODAS as 3 estão abaixo disso,
  /// a missão vira `failed`.
  static const double failureThreshold = 0.25;

  // ─── increment ──────────────────────────────────────────────────────

  /// Adiciona [delta] ao progresso de uma sub-tarefa. **NÃO fecha a
  /// missão** mesmo que 3/3 batam — o jogador precisa clicar ✓ pra
  /// confirmar via [confirmCompletion].
  ///
  /// Sub-tarefa individual marca `completed=true` quando
  /// `progressoAtual >= escalaAlvo` (a flag fica visível na UI). Excesso
  /// (`progresso > alvo`) é acumulado e ativa o bônus de excedência no
  /// [confirmCompletion].
  Future<void> incrementSubTask({
    required int missionId,
    required String subTaskKey,
    required int delta,
  }) async {
    int? newProgresso;
    int? affectedPlayerId;

    await _db.transaction(() async {
      final mission = await _missionsDao.findById(missionId);
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
      final progresso = (current.progressoAtual + delta).clamp(0, 1 << 30);
      final updatedSub = current.copyWith(
        progressoAtual: progresso,
        completed: progresso >= current.escalaAlvo,
      );

      final newSubs = List<DailySubTaskInstance>.from(subs);
      newSubs[idx] = updatedSub;

      await _missionsDao.updateMission(mission.copyWith(subTarefas: newSubs));
      newProgresso = progresso;
      affectedPlayerId = mission.playerId;
    });

    if (newProgresso != null && affectedPlayerId != null) {
      _bus.publish(DailyMissionProgressed(
        playerId: affectedPlayerId!,
        missionId: missionId,
        subTaskKey: subTaskKey,
        novoProgresso: newProgresso!,
      ));
    }
  }

  // ─── confirm ────────────────────────────────────────────────────────

  /// Fecha a missão manualmente (clique no ✓). Calcula status final,
  /// aplica reward correspondente e emite [DailyMissionCompleted].
  ///
  /// Status:
  /// - `completed` se TODAS 3 sub-tarefas têm `progresso ≥ alvo`.
  /// - `failed` se TODAS 3 têm `progresso < 25% do alvo`.
  /// - `partial` em qualquer outra combinação.
  ///
  /// Idempotência: lança [RewardAlreadyGrantedException] se a missão já
  /// foi fechada (status != pending OU rewardClaimed).
  Future<void> confirmCompletion({required int missionId}) async {
    LevelUp? levelUp;
    DailyMission? closedMission;

    await _db.transaction(() async {
      final mission = await _missionsDao.findById(missionId);
      if (mission == null) {
        throw StateError('Missão $missionId não existe');
      }
      if (mission.rewardClaimed ||
          mission.status != DailyMissionStatus.pending) {
        throw RewardAlreadyGrantedException(missionId: missionId);
      }

      final status = _resolveStatus(mission);
      final player = await _playerDao.findById(mission.playerId);
      if (player == null) {
        throw StateError('Player ${mission.playerId} sumiu mid-flight');
      }

      final reward = computeReward(
        rank: _normalizeRank(player.guildRank),
        mission: mission,
        status: status,
        dailyMissionsStreak: player.dailyMissionsStreak,
      );

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
        status: status,
        completedAt: DateTime.now(),
        rewardClaimed: true,
      );
      await _missionsDao.updateMission(updated);
      closedMission = updated;
    });

    if (closedMission != null) {
      final m = closedMission!;
      if (m.status == DailyMissionStatus.failed) {
        _bus.publish(DailyMissionFailed(
          playerId: m.playerId,
          missionId: m.id,
          reason: 'manual-confirm-zero',
        ));
      } else {
        _bus.publish(DailyMissionCompleted(
          playerId: m.playerId,
          missionId: m.id,
          modalidade: m.modalidade,
          fullCompleted: m.status == DailyMissionStatus.completed,
          partial: m.status == DailyMissionStatus.partial,
        ));
      }
    }
    if (levelUp != null) {
      _bus.publish(levelUp!);
    }
  }

  /// Marca como `failed` administrativamente (sem reward). O rollover
  /// usa lógica própria via [applyPartialReward] / [forceFailedRollover]
  /// — esse método fica como utilitário.
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

  // ─── reward calc ────────────────────────────────────────────────────

  /// Cálculo público de reward por status.
  ///
  /// - `completed`: base × (1.2 se [DailyMission.allExceeded]) × (1.5 se
  ///   streak ≥ 10), cap 3.0.
  /// - `partial`: base × `partialFactor(mission)` (sem bônus, sem cap).
  /// - `failed` ou `pending`: zero.
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

    if (status == DailyMissionStatus.partial) {
      final factor = partialFactor(mission);
      return DailyResolvedReward(
        xp: (base.xp * factor).round(),
        gold: (base.gold * factor).round(),
      );
    }

    // completed
    double factor = 1.0;
    if (mission.allExceeded) factor *= overshootBonusFactor;
    if (dailyMissionsStreak >= streakBonusThreshold) {
      factor *= streakBonusFactor;
    }
    if (factor > rewardCapFactor) factor = rewardCapFactor;

    return DailyResolvedReward(
      xp: (base.xp * factor).round(),
      gold: (base.gold * factor).round(),
    );
  }

  /// `factor = soma(min(progresso_i, alvo_i) / alvo_i) / 3`
  ///
  /// Cap em 100% por sub-tarefa (excedência só vale em `completed`).
  /// Sub-tarefas com `escalaAlvo == 0` (defensivo) entram como 0.
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
  /// no progresso atual de cada sub-tarefa.
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

  // ─── rollover hook ──────────────────────────────────────────────────

  /// Aplica reward proporcional + marca `partial`. Chamado pelo
  /// rollover (DailyMissionRolloverService) quando ≥1 sub-tarefa fechou.
  ///
  /// Mantém assinatura por compat — `subCompletas` virou opcional/legacy
  /// (a fórmula nova usa `partialFactor` internamente).
  Future<void> applyPartialReward({
    required DailyMission mission,
    required int subCompletas,
  }) async {
    if (mission.rewardClaimed) return;
    final player = await _playerDao.findById(mission.playerId);
    if (player == null) return;

    final reward = computeReward(
      rank: _normalizeRank(player.guildRank),
      mission: mission,
      status: DailyMissionStatus.partial,
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

/// Lançada por [DailyMissionProgressService.confirmCompletion] quando a
/// missão já foi fechada (status != pending OU rewardClaimed). Caller
/// (notifier) silencia — UI já tá no estado correto.
class RewardAlreadyGrantedException implements Exception {
  final int missionId;
  RewardAlreadyGrantedException({required this.missionId});

  @override
  String toString() => 'RewardAlreadyGrantedException(mission=$missionId)';
}
