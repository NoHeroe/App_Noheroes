import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_daily_mission_stats_dao.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';

/// Sprint 3.3 Etapa 2.1a — DAO de stats agregadas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PlayerDailyMissionStatsDao dao;
  const playerId = 1;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = PlayerDailyMissionStatsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('findOrCreate cria row zerada na primeira chamada', () async {
    expect(await dao.findByPlayerId(playerId), isNull);
    final row = await dao.findOrCreate(playerId);
    expect(row.playerId, playerId);
    expect(row.totalCompleted, 0);
    expect(row.bestStreak, 0);
    expect(row.firstCompletedAt, isNull);
  });

  test('findOrCreate é idempotente — não duplica row', () async {
    await dao.findOrCreate(playerId);
    await dao.findOrCreate(playerId);
    final row = await dao.findByPlayerId(playerId);
    expect(row, isNotNull);
  });

  test('incrementOnCompleted bump totais + flags + bitmask + speedrun',
      () async {
    final at = DateTime(2026, 4, 29, 7, 30); // Quarta-feira (3) 07:30 (before8AM=true)
    await dao.incrementOnCompleted(
      playerId,
      isPerfect: true,
      isSuperPerfect: true,
      subTasksCompleted: 3,
      subTasksOvershoot: 2,
      confirmedAt: at,
      dayOfWeek: 3,
      isBefore8AM: true,
      isAfter10PM: false,
      isWeekend: false,
      isSpeedrun: true,
      zeroProgress: false,
    );
    final row = await dao.findByPlayerId(playerId);
    expect(row, isNotNull);
    expect(row!.totalCompleted, 1);
    expect(row.totalConfirmed, 1);
    expect(row.totalPerfect, 1);
    expect(row.totalSuperPerfect, 1);
    expect(row.totalSubTasksCompleted, 3);
    expect(row.totalSubTasksOvershoot, 2);
    expect(row.totalConfirmedBefore8AM, 1);
    expect(row.totalConfirmedAfter10PM, 0);
    expect(row.totalConfirmedOnWeekend, 0);
    expect(row.daysOfWeekCompletedBitmask, 1 << 3);
    expect(row.totalSpeedrunCompletions, 1);
    expect(row.totalZeroProgressConfirms, 0);
    expect(row.consecutiveFailsCount, 0);
    expect(row.firstCompletedAt, at);
    expect(row.lastCompletedAt, at);
  });

  test('incrementOnCompleted preserva firstCompletedAt em re-completion',
      () async {
    final t1 = DateTime(2026, 4, 29, 10, 0);
    final t2 = DateTime(2026, 4, 30, 10, 0);
    await dao.incrementOnCompleted(playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 3,
        subTasksOvershoot: 0,
        confirmedAt: t1,
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false);
    await dao.incrementOnCompleted(playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 3,
        subTasksOvershoot: 0,
        confirmedAt: t2,
        dayOfWeek: 4,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false);
    final row = await dao.findByPlayerId(playerId);
    expect(row!.totalCompleted, 2);
    expect(row.firstCompletedAt, t1);
    expect(row.lastCompletedAt, t2);
    expect(row.daysOfWeekCompletedBitmask, (1 << 3) | (1 << 4));
  });

  test('incrementFailed bump fails + max_consecutive_fails + reseta '
      'days_without_failing', () async {
    await dao.findOrCreate(playerId);
    await dao.bumpDaysWithoutFailing(playerId); // 1
    await dao.bumpDaysWithoutFailing(playerId); // 2
    await dao.incrementFailed(playerId);
    await dao.incrementFailed(playerId);
    final row = await dao.findByPlayerId(playerId);
    expect(row!.totalFailed, 2);
    expect(row.consecutiveFailsCount, 2);
    expect(row.maxConsecutiveFails, 2);
    expect(row.daysWithoutFailing, 0);
  });

  test('incrementOnCompleted reseta consecutive_fails_count', () async {
    await dao.incrementFailed(playerId); // 1
    await dao.incrementFailed(playerId); // 2
    var row = await dao.findByPlayerId(playerId);
    expect(row!.consecutiveFailsCount, 2);
    expect(row.maxConsecutiveFails, 2);

    await dao.incrementOnCompleted(playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 3,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 29, 10),
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false);
    row = await dao.findByPlayerId(playerId);
    expect(row!.consecutiveFailsCount, 0);
    // max preserva o pico anterior
    expect(row.maxConsecutiveFails, 2);
  });

  test('updateBestStreak só atualiza se maior', () async {
    await dao.findOrCreate(playerId);
    await dao.updateBestStreak(playerId, 5);
    expect((await dao.findByPlayerId(playerId))!.bestStreak, 5);
    await dao.updateBestStreak(playerId, 3);
    expect((await dao.findByPlayerId(playerId))!.bestStreak, 5);
    await dao.updateBestStreak(playerId, 10);
    expect((await dao.findByPlayerId(playerId))!.bestStreak, 10);
  });

  test('bumpDaysWithoutFailing também atualiza best', () async {
    await dao.findOrCreate(playerId);
    await dao.bumpDaysWithoutFailing(playerId);
    await dao.bumpDaysWithoutFailing(playerId);
    await dao.bumpDaysWithoutFailing(playerId);
    final row = await dao.findByPlayerId(playerId);
    expect(row!.daysWithoutFailing, 3);
    expect(row.bestDaysWithoutFailing, 3);
    // Reset volta zero mas best mantém.
    await dao.resetDaysWithoutFailing(playerId);
    final after = await dao.findByPlayerId(playerId);
    expect(after!.daysWithoutFailing, 0);
    expect(after.bestDaysWithoutFailing, 3);
  });

  test('updateConsecutiveActiveDays consecutive incrementa, gap reseta',
      () async {
    await dao.updateConsecutiveActiveDays(playerId,
        today: '2026-04-28', consecutive: false);
    expect((await dao.findByPlayerId(playerId))!.consecutiveActiveDays, 1);
    await dao.updateConsecutiveActiveDays(playerId,
        today: '2026-04-29', consecutive: true);
    expect((await dao.findByPlayerId(playerId))!.consecutiveActiveDays, 2);
    // Gap de 3 dias — service decide consecutive=false.
    await dao.updateConsecutiveActiveDays(playerId,
        today: '2026-05-02', consecutive: false);
    final row = await dao.findByPlayerId(playerId);
    expect(row!.consecutiveActiveDays, 1);
    expect(row.bestConsecutiveActiveDays, 2);
  });

  test('markPilarBalanceDay é idempotente no mesmo dia', () async {
    await dao.findOrCreate(playerId);
    await dao.markPilarBalanceDay(playerId, '2026-04-29');
    await dao.markPilarBalanceDay(playerId, '2026-04-29'); // duplo no mesmo dia
    expect(
        (await dao.findByPlayerId(playerId))!.totalDaysAllPilars, 1);
    await dao.markPilarBalanceDay(playerId, '2026-04-30');
    expect(
        (await dao.findByPlayerId(playerId))!.totalDaysAllPilars, 2);
  });

  test('incrementPartial bump partial e reseta consecutive_fails', () async {
    await dao.incrementFailed(playerId); // 1
    await dao.incrementPartial(playerId);
    final row = await dao.findByPlayerId(playerId);
    expect(row!.totalPartial, 1);
    expect(row.consecutiveFailsCount, 0);
  });

  test('incrementGenerated bump simples', () async {
    await dao.incrementGenerated(playerId);
    await dao.incrementGenerated(playerId);
    await dao.incrementGenerated(playerId);
    expect((await dao.findByPlayerId(playerId))!.totalGenerated, 3);
  });

  // ─── Sprint 3.3 Etapa 2.1c-δ — daily_today_count ────────────────────

  test(
      'caelum_day intocado: 3 logins (em dias distintos) via PlayerDao '
      'não afetam dailyTodayCount nem lastTodayCountDate', () async {
    // `touchLastLogin` tem guard de "mesmo dia" — só incrementa 1× por
    // dia civil. Pra simular 3 logins em dias distintos, voltamos
    // `last_login_at` no tempo entre chamadas (forçando lastLoginDay !=
    // today) — equivalente a "jogador abriu o app em D, D+1 e D+2".
    final pid = await db.customInsert(
      "INSERT INTO players (email, password_hash, shadow_name, "
      "last_login_at, created_at) VALUES (?, ?, ?, 0, 0)",
      variables: [
        Variable.withString('caelum@t'),
        Variable.withString('h'),
        Variable.withString('Sombra'),
      ],
    );
    final playerDao = PlayerDao(db);

    var player = await playerDao.findById(pid);
    expect(player!.caelumDay, 1, reason: 'default = 1');
    await dao.findOrCreate(pid);
    var stats = await dao.findByPlayerId(pid);
    expect(stats!.dailyTodayCount, 0);
    expect(stats.lastTodayCountDate, isNull);

    // Helper: força lastLoginAt pra ontem-no-tempo, depois chama
    // touchLastLogin pra incrementar caelum_day.
    Future<void> simulateNewDayLogin() async {
      // -2 dias garante que lastLoginDay != today (e tolera fusos
      // horários que mudam o início do dia).
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await db.customUpdate(
        'UPDATE players SET last_login_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(twoDaysAgo.millisecondsSinceEpoch),
          Variable.withInt(pid),
        ],
      );
      await playerDao.touchLastLogin(pid);
    }

    // 3 logins em "dias diferentes" → caelum_day deveria virar 4.
    await simulateNewDayLogin();
    await simulateNewDayLogin();
    await simulateNewDayLogin();
    player = await playerDao.findById(pid);
    expect(player!.caelumDay, 4,
        reason: 'caelum_day deve incrementar 1× por dia distinto — '
            'sistema de lore narrativa, intocado pela Etapa 2.1c-δ');

    // E o today_count NÃO foi tocado por touchLastLogin.
    stats = await dao.findByPlayerId(pid);
    expect(stats!.dailyTodayCount, 0,
        reason: 'incrementos em players.caelum_day não devem afetar '
            'player_daily_mission_stats.daily_today_count (sistemas '
            'paralelos por design)');
    expect(stats.lastTodayCountDate, isNull);
  });
}
