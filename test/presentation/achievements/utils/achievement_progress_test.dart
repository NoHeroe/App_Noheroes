import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/models/achievement_definition.dart';
import 'package:noheroes_app/domain/models/player_daily_mission_stats.dart';
import 'package:noheroes_app/presentation/achievements/utils/achievement_progress.dart';

PlayersTableData _player({
  int level = 1,
  int totalQuestsCompleted = 0,
  int totalAttributePointsSpent = 0,
  int totalGemsSpent = 0,
  int dailyMissionsStreak = 0,
}) =>
    PlayersTableData(
      id: 1,
      email: 't@t',
      passwordHash: 'h',
      shadowName: 'S',
      level: level,
      xp: 0,
      xpToNext: 100,
      gold: 0,
      gems: 0,
      strength: 1,
      dexterity: 1,
      intelligence: 1,
      constitution: 1,
      spirit: 1,
      charisma: 1,
      attributePoints: 0,
      shadowCorruption: 0,
      vitalismLevel: 0,
      vitalismXp: 0,
      currentVitalism: 0,
      shadowState: 'stable',
      classType: null,
      factionType: null,
      guildRank: 'e',
      narrativeMode: 'standard',
      playStyle: 'none',
      totalQuestsCompleted: totalQuestsCompleted,
      maxHp: 100,
      hp: 100,
      maxMp: 50,
      mp: 50,
      onboardingDone: true,
      lastLoginAt: DateTime.now(),
      lastStreakDate: DateTime.now(),
      streakDays: 0,
      caelumDay: 0,
      createdAt: DateTime.now(),
      dailyMissionsStreak: dailyMissionsStreak,
      totalGemsSpent: totalGemsSpent,
      peakLevel: level,
      totalAttributePointsSpent: totalAttributePointsSpent,
      autoConfirmEnabled: false,
      screensVisitedKeys: '',
      totalGoldEarnedViaQuests: 0,
    );

PlayerDailyMissionStats _stats({
  int totalCompleted = 0,
  int totalFailed = 0,
}) =>
    PlayerDailyMissionStats(
      playerId: 1,
      totalCompleted: totalCompleted,
      totalFailed: totalFailed,
      totalPartial: 0,
      totalPerfect: 0,
      totalSuperPerfect: 0,
      totalGenerated: 0,
      totalConfirmed: 0,
      bestStreak: 0,
      daysWithoutFailing: 0,
      bestDaysWithoutFailing: 0,
      consecutiveFailsCount: 0,
      maxConsecutiveFails: 0,
      consecutiveActiveDays: 0,
      bestConsecutiveActiveDays: 0,
      totalSubTasksCompleted: 0,
      totalSubTasksOvershoot: 0,
      totalConfirmedBefore8AM: 0,
      totalConfirmedAfter10PM: 0,
      totalConfirmedOnWeekend: 0,
      daysOfWeekCompletedBitmask: 0,
      totalZeroProgressConfirms: 0,
      totalDaysAllPilars: 0,
      totalSpeedrunCompletions: 0,
      totalAutoConfirmCompletions: 0,
      totalZeroProgressManualConfirms: 0,
      dailyTodayCount: 0,
      lastTodayCountDate: null,
      firstCompletedAt: null,
      lastCompletedAt: null,
      lastPilarBalanceDay: null,
      lastActiveDay: null,
      updatedAt: DateTime.now(),
    );

AchievementDefinition _def(AchievementTrigger trig, {bool secret = false}) =>
    AchievementDefinition(
      key: 'K',
      name: 'n',
      description: 'd',
      category: 'c',
      trigger: trig,
      isSecret: secret,
    );

void main() {
  group('AchievementProgressCalculator.compute', () {
    test('threshold_stat:level → progress (current=player.level)', () {
      final ctx = AchievementProgressContext(
        player: _player(level: 3),
        stats: _stats(),
        totalCompletedAchievements: 0,
      );
      final p = AchievementProgressCalculator.compute(
          _def(const ThresholdStatTrigger(stat: 'level', value: 5)), ctx);
      expect(p, isNotNull);
      expect(p!.current, 3);
      expect(p.target, 5);
      expect(p.pct, closeTo(0.6, 0.001));
    });

    test('meta → progress (current=totalCompletedAchievements)', () {
      final ctx = AchievementProgressContext(
        player: _player(),
        stats: _stats(),
        totalCompletedAchievements: 4,
      );
      final p = AchievementProgressCalculator.compute(
          _def(const MetaTrigger(targetCount: 10)), ctx);
      expect(p, isNotNull);
      expect(p!.current, 4);
      expect(p.target, 10);
    });

    test('event_count MissionCompleted → totalQuestsCompleted', () {
      final ctx = AchievementProgressContext(
        player: _player(totalQuestsCompleted: 7),
        stats: _stats(),
        totalCompletedAchievements: 0,
      );
      final p = AchievementProgressCalculator.compute(
          _def(const EventCountTrigger(
              eventName: 'MissionCompleted', count: 10)),
          ctx);
      expect(p!.current, 7);
      expect(p.target, 10);
    });

    test('daily_mission_count → stats.totalCompleted', () {
      final ctx = AchievementProgressContext(
        player: _player(),
        stats: _stats(totalCompleted: 12),
        totalCompletedAchievements: 0,
      );
      final p = AchievementProgressCalculator.compute(
          _def(const DailyMissionTrigger(
              subType: 'daily_mission_count', target: 50)),
          ctx);
      expect(p!.current, 12);
      expect(p.target, 50);
    });

    test('stats=null → daily trigger retorna null', () {
      final ctx = AchievementProgressContext(
        player: _player(),
        stats: null,
        totalCompletedAchievements: 0,
      );
      final p = AchievementProgressCalculator.compute(
          _def(const DailyMissionTrigger(
              subType: 'daily_mission_count', target: 50)),
          ctx);
      expect(p, isNull);
    });

    test('event_class_selected (binário) → null (sem progresso)', () {
      final ctx = AchievementProgressContext(
        player: _player(),
        stats: _stats(),
        totalCompletedAchievements: 0,
      );
      final p = AchievementProgressCalculator.compute(
          _def(const EventTrigger(
              subType: 'event_class_selected', target: 1)),
          ctx);
      expect(p, isNull);
    });

    test('event_attribute_point_spent → progress numérico', () {
      final ctx = AchievementProgressContext(
        player: _player(totalAttributePointsSpent: 3),
        stats: _stats(),
        totalCompletedAchievements: 0,
      );
      final p = AchievementProgressCalculator.compute(
          _def(const EventTrigger(
              subType: 'event_attribute_point_spent', target: 5)),
          ctx);
      expect(p!.current, 3);
      expect(p.target, 5);
    });

    test('pct clampado em 0..1 quando current > target', () {
      final ctx = AchievementProgressContext(
        player: _player(level: 99),
        stats: _stats(),
        totalCompletedAchievements: 0,
      );
      final p = AchievementProgressCalculator.compute(
          _def(const ThresholdStatTrigger(stat: 'level', value: 5)), ctx);
      expect(p!.pct, 1.0);
    });
  });
}
