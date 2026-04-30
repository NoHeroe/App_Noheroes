/// Sprint 3.3 Etapa 2.1b — strings canônicas dos 15 sub-tipos de
/// trigger daily processados pelo `AchievementsService._validateDailyTrigger`.
///
/// Mantidos em uma classe abstract (sem instância) pra evitar typos
/// quando referenciados em testes, JSONs de catálogo ou docs.
///
/// ## Mapeamento
///
/// | Sub-type                          | Resolve contra                           |
/// |-----------------------------------|------------------------------------------|
/// | `daily_mission_count`             | `stats.totalCompleted`                   |
/// | `daily_mission_failed_count`      | `stats.totalFailed`                      |
/// | `daily_mission_partial_count`     | `stats.totalPartial`                     |
/// | `daily_mission_streak`            | `player.dailyMissionsStreak` (current)   |
/// | `daily_mission_best_streak`       | `stats.bestStreak`                       |
/// | `daily_mission_perfect_count`     | `stats.totalPerfect` (avg≥3.0)           |
/// | `daily_mission_super_perfect_count` | `stats.totalSuperPerfect` (avg≥2.0)    |
/// | `daily_no_fail_streak`            | `stats.daysWithoutFailing` (current) ou  |
/// |                                   | `stats.bestDaysWithoutFailing` se        |
/// |                                   | `params.use_best == true`                |
/// | `daily_subtask_volume`            | `volume.getVolume(params.sub_task_key)`  |
/// | `daily_subtask_total_volume`      | `volume.getTotalVolume(player)`          |
/// | `daily_confirmed_time_window`     | `params.window` ∈ {`before_8am`,         |
/// |                                   | `after_10pm`} → contador correspondente   |
/// | `daily_confirmed_on_weekend`      | `stats.totalConfirmedOnWeekend`          |
/// | `daily_pilar_balance`             | `stats.totalDaysAllPilars`               |
/// | `daily_consecutive_days_active`   | `stats.consecutiveActiveDays` ou         |
/// |                                   | `stats.bestConsecutiveActiveDays` se     |
/// |                                   | `params.use_best == true`                |
/// | `daily_speedrun`                  | `stats.totalSpeedrunCompletions` (<12h)  |
abstract class AchievementTriggerTypes {
  AchievementTriggerTypes._();

  static const String dailyMissionCount = 'daily_mission_count';
  static const String dailyMissionFailedCount = 'daily_mission_failed_count';
  static const String dailyMissionPartialCount =
      'daily_mission_partial_count';
  static const String dailyMissionStreak = 'daily_mission_streak';
  static const String dailyMissionBestStreak = 'daily_mission_best_streak';
  static const String dailyMissionPerfectCount =
      'daily_mission_perfect_count';
  static const String dailyMissionSuperPerfectCount =
      'daily_mission_super_perfect_count';
  static const String dailyNoFailStreak = 'daily_no_fail_streak';
  static const String dailySubtaskVolume = 'daily_subtask_volume';
  static const String dailySubtaskTotalVolume =
      'daily_subtask_total_volume';
  static const String dailyConfirmedTimeWindow =
      'daily_confirmed_time_window';
  static const String dailyConfirmedOnWeekend =
      'daily_confirmed_on_weekend';
  static const String dailyPilarBalance = 'daily_pilar_balance';
  static const String dailyConsecutiveDaysActive =
      'daily_consecutive_days_active';
  static const String dailySpeedrun = 'daily_speedrun';

  /// Sprint 3.3 Etapa 2.1c-α — sub-tipos `event_*` resolvidos em
  /// `AchievementsService._validateEventTrigger`.
  static const String eventClassSelected = 'event_class_selected';
  static const String eventFactionJoined = 'event_faction_joined';
  static const String eventAttributePointSpent =
      'event_attribute_point_spent';
  static const String eventBodyMetricsUpdated =
      'event_body_metrics_updated';
  static const String eventGemsSpentTotal = 'event_gems_spent_total';

  /// Set imutável dos 15 daily — usado pelo parser pra detectar
  /// prefixo daily.
  static const Set<String> allDaily = {
    dailyMissionCount,
    dailyMissionFailedCount,
    dailyMissionPartialCount,
    dailyMissionStreak,
    dailyMissionBestStreak,
    dailyMissionPerfectCount,
    dailyMissionSuperPerfectCount,
    dailyNoFailStreak,
    dailySubtaskVolume,
    dailySubtaskTotalVolume,
    dailyConfirmedTimeWindow,
    dailyConfirmedOnWeekend,
    dailyPilarBalance,
    dailyConsecutiveDaysActive,
    dailySpeedrun,
  };

  /// Set imutável dos 5 event-based — paralelo a [allDaily].
  static const Set<String> allEvents = {
    eventClassSelected,
    eventFactionJoined,
    eventAttributePointSpent,
    eventBodyMetricsUpdated,
    eventGemsSpentTotal,
  };
}
