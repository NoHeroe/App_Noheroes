/// Sprint 3.3 Etapa 2.1a — read-only mirror imutável da tabela
/// `player_daily_mission_stats`.
///
/// Época 2 (ADR-0024): `playerId` virou uuid (String). `fromRow` (Drift)
/// substituído por [PlayerDailyMissionStats.fromMap] (row snake_case do
/// Postgres via PostgREST/Supabase).
///
/// Consumido pelo `AchievementsService` (Etapa 2.1b) pra resolver
/// triggers. O `DailyMissionStatsService` é o **único writer** — callers
/// de domain só leem.
class PlayerDailyMissionStats {
  final String playerId;
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

  /// Sprint 3.3 Etapa 2.1c-δ — missões completadas no dia atual.
  final int dailyTodayCount;

  /// Sprint 3.3 Etapa 2.1c-δ — última data (YYYY-MM-DD device local) em
  /// que [dailyTodayCount] foi tocado. Validador do trigger compara
  /// com `formatDay(now)` pra rejeitar valores stale.
  final String? lastTodayCountDate;

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
    required this.dailyTodayCount,
    required this.lastTodayCountDate,
    required this.firstCompletedAt,
    required this.lastCompletedAt,
    required this.lastPilarBalanceDay,
    required this.lastActiveDay,
    required this.updatedAt,
  });

  static int _int(Object? v, [int fallback = 0]) =>
      v == null ? fallback : (v as num).toInt();

  static DateTime? _dtMs(Object? v) =>
      v == null ? null : DateTime.fromMillisecondsSinceEpoch((v as num).toInt());

  /// Constrói a partir de uma row do Postgres (chaves snake_case).
  /// Timestamps (`first/last_completed_at`, `updated_at`) são bigint ms.
  factory PlayerDailyMissionStats.fromMap(Map<String, dynamic> m) =>
      PlayerDailyMissionStats(
        playerId: m['player_id'] as String,
        totalCompleted: _int(m['total_completed']),
        totalFailed: _int(m['total_failed']),
        totalPartial: _int(m['total_partial']),
        totalPerfect: _int(m['total_perfect']),
        totalSuperPerfect: _int(m['total_super_perfect']),
        totalGenerated: _int(m['total_generated']),
        totalConfirmed: _int(m['total_confirmed']),
        bestStreak: _int(m['best_streak']),
        daysWithoutFailing: _int(m['days_without_failing']),
        bestDaysWithoutFailing: _int(m['best_days_without_failing']),
        consecutiveFailsCount: _int(m['consecutive_fails_count']),
        maxConsecutiveFails: _int(m['max_consecutive_fails']),
        consecutiveActiveDays: _int(m['consecutive_active_days']),
        bestConsecutiveActiveDays: _int(m['best_consecutive_active_days']),
        totalSubTasksCompleted: _int(m['total_sub_tasks_completed']),
        totalSubTasksOvershoot: _int(m['total_sub_tasks_overshoot']),
        totalConfirmedBefore8AM: _int(m['total_confirmed_before_8am']),
        totalConfirmedAfter10PM: _int(m['total_confirmed_after_10pm']),
        totalConfirmedOnWeekend: _int(m['total_confirmed_on_weekend']),
        daysOfWeekCompletedBitmask: _int(m['days_of_week_completed_bitmask']),
        totalZeroProgressConfirms: _int(m['total_zero_progress_confirms']),
        totalDaysAllPilars: _int(m['total_days_all_pilars']),
        totalSpeedrunCompletions: _int(m['total_speedrun_completions']),
        totalAutoConfirmCompletions: _int(m['total_auto_confirm_completions']),
        totalZeroProgressManualConfirms:
            _int(m['total_zero_progress_manual_confirms']),
        dailyTodayCount: _int(m['daily_today_count']),
        lastTodayCountDate: m['last_today_count_date'] as String?,
        firstCompletedAt: _dtMs(m['first_completed_at']),
        lastCompletedAt: _dtMs(m['last_completed_at']),
        lastPilarBalanceDay: m['last_pilar_balance_day'] as String?,
        lastActiveDay: m['last_active_day'] as String?,
        updatedAt: _dtMs(m['updated_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
