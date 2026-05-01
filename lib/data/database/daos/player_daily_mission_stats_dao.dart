import 'package:drift/drift.dart';

import '../../../domain/models/player_daily_mission_stats.dart';
import '../app_database.dart';
import '../tables/player_daily_mission_stats_table.dart';

part 'player_daily_mission_stats_dao.g.dart';

/// Sprint 3.3 Etapa 2.1a — DAO da tabela
/// [PlayerDailyMissionStatsTable]. Acessado **só** pelo
/// `DailyMissionStatsService` (writer único). Reads futuros pelo
/// `AchievementsService` em 2.1b.
///
/// Increments são atômicos via `customUpdate` direto (`SET col = col + ?`)
/// pra evitar race entre fetch+write quando múltiplos eventos terminais
/// chegam no mesmo tick.
@DriftAccessor(tables: [PlayerDailyMissionStatsTable])
class PlayerDailyMissionStatsDao
    extends DatabaseAccessor<AppDatabase>
    with _$PlayerDailyMissionStatsDaoMixin {
  PlayerDailyMissionStatsDao(super.db);

  /// Lê a row do jogador. Retorna `null` se não existe.
  Future<PlayerDailyMissionStats?> findByPlayerId(int playerId) async {
    final row = await (select(playerDailyMissionStatsTable)
          ..where((t) => t.playerId.equals(playerId)))
        .getSingleOrNull();
    return row == null ? null : PlayerDailyMissionStats.fromRow(row);
  }

  /// Lê a row do jogador, criando uma row zerada se não existe. Garante
  /// que callers de increment sempre encontrem uma base. Idempotente
  /// via `insertOrIgnore`.
  Future<PlayerDailyMissionStats> findOrCreate(int playerId) async {
    final existing = await findByPlayerId(playerId);
    if (existing != null) return existing;
    await into(playerDailyMissionStatsTable).insert(
      PlayerDailyMissionStatsTableCompanion(
        playerId: Value(playerId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    final row = await (select(playerDailyMissionStatsTable)
          ..where((t) => t.playerId.equals(playerId)))
        .getSingle();
    return PlayerDailyMissionStats.fromRow(row);
  }

  /// Atualiza/insere uma row completa. Usado por testes e migrações
  /// raras; produção usa os métodos de increment específicos.
  Future<void> upsert(
      PlayerDailyMissionStatsTableCompanion stat) async {
    await into(playerDailyMissionStatsTable).insertOnConflictUpdate(stat);
  }

  /// `DailyMissionGenerated` → `totalGenerated++`.
  Future<void> incrementGenerated(int playerId) async {
    await findOrCreate(playerId);
    await customUpdate(
      'UPDATE player_daily_mission_stats '
      'SET total_generated = total_generated + 1, updated_at = ? '
      'WHERE player_id = ?',
      variables: [
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withInt(playerId),
      ],
      updates: {playerDailyMissionStatsTable},
    );
  }

  /// `DailyMissionPartial` (ou `DailyMissionCompleted` com partial=true).
  /// Conta como evento terminal sem ser falha — incrementa `totalPartial`
  /// e reseta `consecutiveFailsCount`.
  Future<void> incrementPartial(int playerId) async {
    await findOrCreate(playerId);
    await customUpdate(
      'UPDATE player_daily_mission_stats '
      'SET total_partial = total_partial + 1, '
      '    consecutive_fails_count = 0, '
      '    updated_at = ? '
      'WHERE player_id = ?',
      variables: [
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withInt(playerId),
      ],
      updates: {playerDailyMissionStatsTable},
    );
  }

  /// `DailyMissionFailed` → incrementa fails + reseta daysWithoutFailing.
  /// Atualiza `maxConsecutiveFails` se atingir novo recorde. Não toca
  /// em `lastCompletedAt` (failed não é completion).
  Future<void> incrementFailed(int playerId) async {
    await findOrCreate(playerId);
    final now = DateTime.now().millisecondsSinceEpoch;
    await customUpdate(
      'UPDATE player_daily_mission_stats '
      'SET total_failed = total_failed + 1, '
      '    consecutive_fails_count = consecutive_fails_count + 1, '
      '    max_consecutive_fails = MAX(max_consecutive_fails, '
      '                                consecutive_fails_count + 1), '
      '    days_without_failing = 0, '
      '    updated_at = ? '
      'WHERE player_id = ?',
      variables: [Variable.withInt(now), Variable.withInt(playerId)],
      updates: {playerDailyMissionStatsTable},
    );
  }

  /// `DailyMissionCompleted` — incremento composto. Caller (service)
  /// computa flags a partir do estado da missão e dos helpers.
  ///
  /// Atualiza atomicamente:
  /// - totalCompleted++, totalConfirmed++
  /// - totalPerfect++ se [isPerfect]
  /// - totalSuperPerfect++ se [isSuperPerfect] (perfect implica super)
  /// - totalSubTasksCompleted += [subTasksCompleted]
  /// - totalSubTasksOvershoot += [subTasksOvershoot]
  /// - janelas temporais (before8AM/after10PM/weekend)
  /// - daysOfWeekCompletedBitmask |= (1 << [dayOfWeek])
  /// - consecutiveFailsCount = 0 (reseta — completou)
  /// - totalZeroProgressConfirms++ se [zeroProgress]
  /// - totalSpeedrunCompletions++ se [isSpeedrun]
  /// - firstCompletedAt = COALESCE(firstCompletedAt, now)
  /// - lastCompletedAt = now
  ///
  /// `daysWithoutFailing` e `consecutiveActiveDays` ficam em métodos
  /// separados (transição diária) chamados pelo service quando detecta
  /// virada de dia.
  ///
  /// Sprint 3.3 Etapa 2.1c-β:
  /// - [wasAutoConfirmed] = true → bumps `total_auto_confirm_completions`
  /// - [wasAutoConfirmed] = false E [zeroProgress] = true → bumps
  ///   `total_zero_progress_manual_confirms` (anti-cheese)
  /// - `total_zero_progress_confirms` (legacy) bumps em qualquer zero,
  ///   manual ou auto.
  Future<void> incrementOnCompleted(
    int playerId, {
    required bool isPerfect,
    required bool isSuperPerfect,
    required int subTasksCompleted,
    required int subTasksOvershoot,
    required DateTime confirmedAt,
    required int dayOfWeek,
    required bool isBefore8AM,
    required bool isAfter10PM,
    required bool isWeekend,
    required bool isSpeedrun,
    required bool zeroProgress,
    bool wasAutoConfirmed = false,
  }) async {
    await findOrCreate(playerId);
    final ms = confirmedAt.millisecondsSinceEpoch;
    final dowMask = 1 << dayOfWeek;
    final manualZero = zeroProgress && !wasAutoConfirmed;
    await customUpdate(
      'UPDATE player_daily_mission_stats SET '
      'total_completed = total_completed + 1, '
      'total_confirmed = total_confirmed + 1, '
      'total_perfect = total_perfect + ?, '
      'total_super_perfect = total_super_perfect + ?, '
      'total_sub_tasks_completed = total_sub_tasks_completed + ?, '
      'total_sub_tasks_overshoot = total_sub_tasks_overshoot + ?, '
      'total_confirmed_before_8am = total_confirmed_before_8am + ?, '
      'total_confirmed_after_10pm = total_confirmed_after_10pm + ?, '
      'total_confirmed_on_weekend = total_confirmed_on_weekend + ?, '
      'days_of_week_completed_bitmask = days_of_week_completed_bitmask | ?, '
      'consecutive_fails_count = 0, '
      'total_zero_progress_confirms = total_zero_progress_confirms + ?, '
      'total_zero_progress_manual_confirms = '
      '    total_zero_progress_manual_confirms + ?, '
      'total_speedrun_completions = total_speedrun_completions + ?, '
      'total_auto_confirm_completions = '
      '    total_auto_confirm_completions + ?, '
      'first_completed_at = COALESCE(first_completed_at, ?), '
      'last_completed_at = ?, '
      'updated_at = ? '
      'WHERE player_id = ?',
      variables: [
        Variable.withInt(isPerfect ? 1 : 0),
        Variable.withInt(isSuperPerfect ? 1 : 0),
        Variable.withInt(subTasksCompleted),
        Variable.withInt(subTasksOvershoot),
        Variable.withInt(isBefore8AM ? 1 : 0),
        Variable.withInt(isAfter10PM ? 1 : 0),
        Variable.withInt(isWeekend ? 1 : 0),
        Variable.withInt(dowMask),
        Variable.withInt(zeroProgress ? 1 : 0),
        Variable.withInt(manualZero ? 1 : 0),
        Variable.withInt(isSpeedrun ? 1 : 0),
        Variable.withInt(wasAutoConfirmed ? 1 : 0),
        Variable.withInt(ms),
        Variable.withInt(ms),
        Variable.withInt(ms),
        Variable.withInt(playerId),
      ],
      updates: {playerDailyMissionStatsTable},
    );
  }

  /// Atualiza `bestStreak` se [currentStreak] superar o atual. No-op
  /// caso contrário. Chamado pelo service após `incrementOnCompleted`
  /// (lê `player.dailyMissionsStreak` que já reflete o novo valor).
  Future<void> updateBestStreak(int playerId, int currentStreak) async {
    await findOrCreate(playerId);
    await customUpdate(
      'UPDATE player_daily_mission_stats '
      'SET best_streak = MAX(best_streak, ?), updated_at = ? '
      'WHERE player_id = ?',
      variables: [
        Variable.withInt(currentStreak),
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withInt(playerId),
      ],
      updates: {playerDailyMissionStatsTable},
    );
  }

  /// Bump de `daysWithoutFailing` quando o service detecta primeiro
  /// completed de um novo dia sem fails. Atualiza `bestDaysWithoutFailing`.
  Future<void> bumpDaysWithoutFailing(int playerId) async {
    await findOrCreate(playerId);
    await customUpdate(
      'UPDATE player_daily_mission_stats '
      'SET days_without_failing = days_without_failing + 1, '
      '    best_days_without_failing = MAX(best_days_without_failing, '
      '                                     days_without_failing + 1), '
      '    updated_at = ? '
      'WHERE player_id = ?',
      variables: [
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withInt(playerId),
      ],
      updates: {playerDailyMissionStatsTable},
    );
  }

  /// `DailyMissionFailed` zera daysWithoutFailing — método explícito pra
  /// callers que queiram resetar sem incrementar (ex: rollover).
  Future<void> resetDaysWithoutFailing(int playerId) async {
    await findOrCreate(playerId);
    await customUpdate(
      'UPDATE player_daily_mission_stats '
      'SET days_without_failing = 0, updated_at = ? '
      'WHERE player_id = ?',
      variables: [
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withInt(playerId),
      ],
      updates: {playerDailyMissionStatsTable},
    );
  }

  /// Detecta virada de dia em `consecutiveActiveDays`. Service decide
  /// se é continuação (consecutive++) ou reset (= 1).
  Future<void> updateConsecutiveActiveDays(
    int playerId, {
    required String today,
    required bool consecutive,
  }) async {
    await findOrCreate(playerId);
    if (consecutive) {
      await customUpdate(
        'UPDATE player_daily_mission_stats SET '
        'consecutive_active_days = consecutive_active_days + 1, '
        'best_consecutive_active_days = MAX(best_consecutive_active_days, '
        '                                    consecutive_active_days + 1), '
        'last_active_day = ?, '
        'updated_at = ? '
        'WHERE player_id = ?',
        variables: [
          Variable.withString(today),
          Variable.withInt(DateTime.now().millisecondsSinceEpoch),
          Variable.withInt(playerId),
        ],
        updates: {playerDailyMissionStatsTable},
      );
    } else {
      await customUpdate(
        'UPDATE player_daily_mission_stats SET '
        'consecutive_active_days = 1, '
        'best_consecutive_active_days = MAX(best_consecutive_active_days, 1), '
        'last_active_day = ?, '
        'updated_at = ? '
        'WHERE player_id = ?',
        variables: [
          Variable.withString(today),
          Variable.withInt(DateTime.now().millisecondsSinceEpoch),
          Variable.withInt(playerId),
        ],
        updates: {playerDailyMissionStatsTable},
      );
    }
  }

  /// Marca o dia [today] como pilar-balance e incrementa
  /// `totalDaysAllPilars`. Idempotente: se `last_pilar_balance_day == today`,
  /// no-op (guard contra duplo count).
  Future<void> markPilarBalanceDay(
      int playerId, String today) async {
    await findOrCreate(playerId);
    await customUpdate(
      'UPDATE player_daily_mission_stats SET '
      'total_days_all_pilars = total_days_all_pilars + 1, '
      'last_pilar_balance_day = ?, '
      'updated_at = ? '
      'WHERE player_id = ? AND '
      '      (last_pilar_balance_day IS NULL OR '
      '       last_pilar_balance_day != ?)',
      variables: [
        Variable.withString(today),
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withInt(playerId),
        Variable.withString(today),
      ],
      updates: {playerDailyMissionStatsTable},
    );
  }

  /// Sprint 3.3 Etapa 2.1c-δ — incrementa `daily_today_count` com reset
  /// lazy YYYY-MM-DD. Caller (service) computa [resetTo1IfDayChanged]
  /// comparando `stats.lastTodayCountDate` com `formatDay(now)` antes
  /// de chamar.
  ///
  /// - [resetTo1IfDayChanged] = true → SET count=1 + last_date=today
  ///   (zera + incrementa atomicamente — virada de dia)
  /// - false → SET count=count+1 + last_date=today (mesmo dia)
  ///
  /// Sempre escreve `last_today_count_date` pra cobrir o edge case de
  /// 1ª chamada (era NULL → vira `todayDate`).
  Future<void> incrementTodayCount(
    int playerId, {
    required bool resetTo1IfDayChanged,
    required String todayDate,
  }) async {
    await findOrCreate(playerId);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (resetTo1IfDayChanged) {
      await customUpdate(
        'UPDATE player_daily_mission_stats SET '
        'daily_today_count = 1, '
        'last_today_count_date = ?, '
        'updated_at = ? '
        'WHERE player_id = ?',
        variables: [
          Variable.withString(todayDate),
          Variable.withInt(now),
          Variable.withInt(playerId),
        ],
        updates: {playerDailyMissionStatsTable},
      );
    } else {
      await customUpdate(
        'UPDATE player_daily_mission_stats SET '
        'daily_today_count = daily_today_count + 1, '
        'last_today_count_date = ?, '
        'updated_at = ? '
        'WHERE player_id = ?',
        variables: [
          Variable.withString(todayDate),
          Variable.withInt(now),
          Variable.withInt(playerId),
        ],
        updates: {playerDailyMissionStatsTable},
      );
    }
  }
}
