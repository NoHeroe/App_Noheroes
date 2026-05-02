import '../../../data/database/app_database.dart';
import '../../../domain/models/achievement_definition.dart';
import '../../../domain/models/player_daily_mission_stats.dart';
import '../../../domain/services/achievement_trigger_types.dart';

/// Sprint 3.3 Etapa Final-B — progresso atual + alvo de uma conquista,
/// pra renderizar barra de progresso no card Estado A (bloqueada).
class AchievementProgress {
  final int current;
  final int target;

  const AchievementProgress({required this.current, required this.target});

  /// Razão clampada em 0..1. `target=0` (defesa) → 0.
  double get pct {
    if (target <= 0) return 0;
    final raw = current / target;
    if (raw < 0) return 0;
    if (raw > 1) return 1;
    return raw;
  }
}

/// Snapshot de dados consumidos pelo cálculo de progresso. Caller carrega
/// 1× e passa adiante pra evitar N queries na renderização da lista de
/// 85 conquistas.
///
/// `stats` pode ser null (jogador sem row em `player_daily_mission_stats`
/// ainda — `findByPlayerId` retorna null nesse caso). Triggers daily
/// retornam null (sem progresso visível) quando stats é null.
class AchievementProgressContext {
  final PlayersTableData player;
  final PlayerDailyMissionStats? stats;
  final int totalCompletedAchievements;

  const AchievementProgressContext({
    required this.player,
    required this.stats,
    required this.totalCompletedAchievements,
  });
}

/// Sprint 3.3 Etapa Final-B — computa progresso atual+alvo dado um
/// trigger e o contexto. Triggers binários (event_class_selected,
/// event_faction_joined, event_screen_visited com screen_key, etc) não
/// têm progresso — retornam `null` e o card oculta a barra.
///
/// Triggers que precisam do volume DAO (sub_task_volume específico,
/// total_subtask_volume) também retornam null pra evitar N queries
/// extras na renderização. Card mostra só "+target" como meta sem
/// barra (acceptable pra display, jogador vê resultado real ao
/// completar).
class AchievementProgressCalculator {
  const AchievementProgressCalculator._();

  static AchievementProgress? compute(
    AchievementDefinition def,
    AchievementProgressContext ctx,
  ) {
    final trig = def.trigger;

    if (trig is EventCountTrigger) {
      switch (trig.eventName) {
        case 'MissionCompleted':
          return AchievementProgress(
              current: ctx.player.totalQuestsCompleted,
              target: trig.count);
        case 'AchievementUnlocked':
          return AchievementProgress(
              current: ctx.totalCompletedAchievements,
              target: trig.count);
        default:
          return null;
      }
    }

    if (trig is ThresholdStatTrigger && trig.stat == 'level') {
      return AchievementProgress(
          current: ctx.player.level, target: trig.value);
    }

    if (trig is MetaTrigger) {
      return AchievementProgress(
          current: ctx.totalCompletedAchievements,
          target: trig.targetCount);
    }

    if (trig is DailyMissionTrigger) {
      return _dailyProgress(trig, ctx);
    }

    if (trig is EventTrigger) {
      return _eventProgress(trig, ctx);
    }

    return null;
  }

  static AchievementProgress? _dailyProgress(
    DailyMissionTrigger trig,
    AchievementProgressContext ctx,
  ) {
    final stats = ctx.stats;
    if (stats == null) return null;

    int? cur;
    switch (trig.subType) {
      case AchievementTriggerTypes.dailyMissionCount:
        cur = stats.totalCompleted;
        break;
      case AchievementTriggerTypes.dailyMissionFailedCount:
        cur = stats.totalFailed;
        break;
      case AchievementTriggerTypes.dailyMissionPartialCount:
        cur = stats.totalPartial;
        break;
      case AchievementTriggerTypes.dailyMissionStreak:
        cur = ctx.player.dailyMissionsStreak;
        break;
      case AchievementTriggerTypes.dailyMissionBestStreak:
        cur = stats.bestStreak;
        break;
      case AchievementTriggerTypes.dailyMissionPerfectCount:
        cur = stats.totalPerfect;
        break;
      case AchievementTriggerTypes.dailyMissionSuperPerfectCount:
        cur = stats.totalSuperPerfect;
        break;
      case AchievementTriggerTypes.dailyNoFailStreak:
        final useBest = trig.params?['use_best'] == true;
        cur = useBest
            ? stats.bestDaysWithoutFailing
            : stats.daysWithoutFailing;
        break;
      case AchievementTriggerTypes.dailyConfirmedTimeWindow:
        final w = trig.params?['window'];
        if (w == 'before_8am') {
          cur = stats.totalConfirmedBefore8AM;
        } else if (w == 'after_10pm') {
          cur = stats.totalConfirmedAfter10PM;
        }
        break;
      case AchievementTriggerTypes.dailyConfirmedOnWeekend:
        cur = stats.totalConfirmedOnWeekend;
        break;
      case AchievementTriggerTypes.dailyPilarBalance:
        cur = stats.totalDaysAllPilars;
        break;
      case AchievementTriggerTypes.dailyConsecutiveDaysActive:
        final useBest = trig.params?['use_best'] == true;
        cur = useBest
            ? stats.bestConsecutiveActiveDays
            : stats.consecutiveActiveDays;
        break;
      case AchievementTriggerTypes.dailySpeedrun:
        cur = stats.totalSpeedrunCompletions;
        break;
      case AchievementTriggerTypes.dailyAutoConfirmCount:
        cur = stats.totalAutoConfirmCompletions;
        break;
      case AchievementTriggerTypes.dailyZeroProgressManualCount:
        cur = stats.totalZeroProgressManualConfirms;
        break;
      case AchievementTriggerTypes.dailyTodayCount:
        // Stale guard: só vale se lastTodayCountDate é hoje. Sem clock
        // injetável aqui, mostramos o contador cru — é debug/UX, não
        // validação. (Validador real do trigger usa formatDay(now)
        // pra filtrar valores stale; UI mostra valor literal pra
        // jogador entender progresso "do dia atual" sem confundir.)
        cur = stats.dailyTodayCount;
        break;
      // daily_subtask_volume e daily_subtask_total_volume requerem
      // volumeDao — out-of-scope display (1 query por card x 85 cards).
      // Retornam null → card oculta barra.
    }

    if (cur == null) return null;
    return AchievementProgress(current: cur, target: trig.target);
  }

  static AchievementProgress? _eventProgress(
    EventTrigger trig,
    AchievementProgressContext ctx,
  ) {
    // Apenas triggers numéricos têm barra:
    switch (trig.subType) {
      case AchievementTriggerTypes.eventAttributePointSpent:
        return AchievementProgress(
            current: ctx.player.totalAttributePointsSpent,
            target: trig.target);
      case AchievementTriggerTypes.eventGemsSpentTotal:
        return AchievementProgress(
            current: ctx.player.totalGemsSpent, target: trig.target);
    }
    // Demais event_* são binários ou requerem services
    // (event_screen_visited com count → screensVisitedService) → null.
    return null;
  }
}
