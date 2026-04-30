import '../../data/database/app_database.dart';

/// Sprint 3.3 Etapa 2.1a — read-only mirror imutável da tabela
/// `player_daily_mission_stats`.
///
/// Consumido pelo `AchievementsService` (Etapa 2.1b) pra resolver
/// triggers. O `DailyMissionStatsService` é o **único writer** —
/// callers de domain só leem.
class PlayerDailyMissionStats {
  final int playerId;
  final int totalCompleted;
  final int totalFailed;
  final int totalPartial;
  final int totalPerfect;
  final int totalSuperPerfect;
  final int totalGenerated;
  final int totalConfirmed;
  final int bestStreak;
  final int daysWithoutFailing;
  final int bestDaysWithoutFailing;
  final int consecutiveFailsCount;
  final int maxConsecutiveFails;
  final int consecutiveActiveDays;
  final int bestConsecutiveActiveDays;
  final int totalSubTasksCompleted;
  final int totalSubTasksOvershoot;
  final int totalConfirmedBefore8AM;
  final int totalConfirmedAfter10PM;
  final int totalConfirmedOnWeekend;
  final int daysOfWeekCompletedBitmask;
  final int totalZeroProgressConfirms;
  final int totalDaysAllPilars;
  final int totalSpeedrunCompletions;

  /// Sprint 3.3 Etapa 2.1c-β — confirmações via auto-confirm.
  final int totalAutoConfirmCompletions;

  /// Sprint 3.3 Etapa 2.1c-β — anti-cheese de zero progress (só manual).
  final int totalZeroProgressManualConfirms;

  final DateTime? firstCompletedAt;
  final DateTime? lastCompletedAt;
  final String? lastPilarBalanceDay;
  final String? lastActiveDay;
  final DateTime updatedAt;

  const PlayerDailyMissionStats({
    required this.playerId,
    required this.totalCompleted,
    required this.totalFailed,
    required this.totalPartial,
    required this.totalPerfect,
    required this.totalSuperPerfect,
    required this.totalGenerated,
    required this.totalConfirmed,
    required this.bestStreak,
    required this.daysWithoutFailing,
    required this.bestDaysWithoutFailing,
    required this.consecutiveFailsCount,
    required this.maxConsecutiveFails,
    required this.consecutiveActiveDays,
    required this.bestConsecutiveActiveDays,
    required this.totalSubTasksCompleted,
    required this.totalSubTasksOvershoot,
    required this.totalConfirmedBefore8AM,
    required this.totalConfirmedAfter10PM,
    required this.totalConfirmedOnWeekend,
    required this.daysOfWeekCompletedBitmask,
    required this.totalZeroProgressConfirms,
    required this.totalDaysAllPilars,
    required this.totalSpeedrunCompletions,
    required this.totalAutoConfirmCompletions,
    required this.totalZeroProgressManualConfirms,
    required this.firstCompletedAt,
    required this.lastCompletedAt,
    required this.lastPilarBalanceDay,
    required this.lastActiveDay,
    required this.updatedAt,
  });

  factory PlayerDailyMissionStats.fromRow(
      PlayerDailyMissionStat row) {
    return PlayerDailyMissionStats(
      playerId: row.playerId,
      totalCompleted: row.totalCompleted,
      totalFailed: row.totalFailed,
      totalPartial: row.totalPartial,
      totalPerfect: row.totalPerfect,
      totalSuperPerfect: row.totalSuperPerfect,
      totalGenerated: row.totalGenerated,
      totalConfirmed: row.totalConfirmed,
      bestStreak: row.bestStreak,
      daysWithoutFailing: row.daysWithoutFailing,
      bestDaysWithoutFailing: row.bestDaysWithoutFailing,
      consecutiveFailsCount: row.consecutiveFailsCount,
      maxConsecutiveFails: row.maxConsecutiveFails,
      consecutiveActiveDays: row.consecutiveActiveDays,
      bestConsecutiveActiveDays: row.bestConsecutiveActiveDays,
      totalSubTasksCompleted: row.totalSubTasksCompleted,
      totalSubTasksOvershoot: row.totalSubTasksOvershoot,
      totalConfirmedBefore8AM: row.totalConfirmedBefore8AM,
      totalConfirmedAfter10PM: row.totalConfirmedAfter10PM,
      totalConfirmedOnWeekend: row.totalConfirmedOnWeekend,
      daysOfWeekCompletedBitmask: row.daysOfWeekCompletedBitmask,
      totalZeroProgressConfirms: row.totalZeroProgressConfirms,
      totalDaysAllPilars: row.totalDaysAllPilars,
      totalSpeedrunCompletions: row.totalSpeedrunCompletions,
      totalAutoConfirmCompletions: row.totalAutoConfirmCompletions,
      totalZeroProgressManualConfirms: row.totalZeroProgressManualConfirms,
      firstCompletedAt: row.firstCompletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.firstCompletedAt!),
      lastCompletedAt: row.lastCompletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastCompletedAt!),
      lastPilarBalanceDay: row.lastPilarBalanceDay,
      lastActiveDay: row.lastActiveDay,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
