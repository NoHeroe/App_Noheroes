import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/daily_mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_daily_mission_stats_dao.dart';
import 'package:noheroes_app/data/database/daos/player_daily_subtask_volume_dao.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_achievements_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/data/services/reward_grant_service.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import 'package:noheroes_app/domain/services/achievement_trigger_types.dart';
import 'package:noheroes_app/domain/services/achievements_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

/// Sprint 3.3 Etapa 2.1b — testes dos 15 sub-tipos de trigger daily +
/// integration via DailyStatsUpdated.
///
/// Cada subType tem 1 teste positivo (stats >= target → unlock) + 1
/// negativo (< target → no unlock). Triggers que precisam de `params`
/// (subtask_volume, time_window) testam o caminho válido + o fail-safe
/// de params malformado.

class _FakeBundle extends AssetBundle {
  final Map<String, String> contents;
  _FakeBundle(this.contents);

  @override
  Future<ByteData> load(String key) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(s)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return s;
  }
}

Future<int> seedPlayer(AppDatabase db, {int dailyStreak = 0}) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp, total_quests_completed, "
    "daily_missions_streak) "
    "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, "
    "0, 0, ?)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withInt(dailyStreak),
    ],
  );
}

RewardGrantService newGrant(AppDatabase db, AppEventBus bus) {
  final catalog = ItemsCatalogService(db);
  return RewardGrantService(
    db: db,
    missionRepo: MissionRepositoryDrift(db),
    achievementsRepo: PlayerAchievementsRepositoryDrift(db),
    inventory: PlayerInventoryService(db, catalog),
    recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
    factionRep: PlayerFactionReputationRepositoryDrift(db),
    eventBus: bus,
  );
}

AchievementsService newService(
  AppDatabase db,
  AppEventBus bus,
  Map<String, String> bundleContents, {
  int? overrideDailyStreak,
}) {
  return AchievementsService(
    achievementsRepo: PlayerAchievementsRepositoryDrift(db),
    rewardResolve: RewardResolveService(ItemsCatalogService(db)),
    rewardGrant: newGrant(db, bus),
    bus: bus,
    statsDao: PlayerDailyMissionStatsDao(db),
    volumeDao: PlayerDailySubtaskVolumeDao(db),
    resolvePlayerFacts: (playerId) async {
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      return PlayerFacts(
        level: row.level,
        totalQuestsCompleted: row.totalQuestsCompleted,
        dailyMissionsStreak:
            overrideDailyStreak ?? row.dailyMissionsStreak,
        snapshot: PlayerSnapshot(
          level: row.level,
          rank: GuildRank.e,
        ),
      );
    },
    assetBundle: _FakeBundle(bundleContents),
  );
}

String catalogJson(List<Map<String, dynamic>> entries) =>
    jsonEncode({'achievements': entries});

Map<String, dynamic> dailyAch(
  String key,
  String subType,
  int target, {
  Map<String, dynamic>? params,
}) =>
    {
      'key': key,
      'name': key,
      'description': key,
      'category': 'daily',
      'trigger': {
        'type': subType,
        'target': target,
        if (params != null) 'params': params,
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  late int playerId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    playerId = await seedPlayer(db);
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  // ─── helper: roda um par positivo+negativo dado um setup de stats ───

  Future<void> runPosNegPair({
    required String subType,
    required int target,
    Map<String, dynamic>? params,
    required Future<void> Function() makePass,
    required Future<void> Function() makeFail,
  }) async {
    final entries = [dailyAch('ACH_$subType', subType, target, params: params)];
    final positive = newService(db, bus, {
      AchievementsService.catalogAssetPath: catalogJson(entries),
    });
    await positive.ensureLoaded();
    final repo = PlayerAchievementsRepositoryDrift(db);

    // Positivo
    await makePass();
    bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
    await positive.attachDailyListeners();
    bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
    await Future.delayed(const Duration(milliseconds: 50));
    expect(await repo.isCompleted(playerId, 'ACH_$subType'), isTrue,
        reason: '$subType deveria unlock após makePass()');
  }

  // ─── 15 sub-types: positive + negative ──────────────────────────────

  group('daily_mission_count', () {
    test('positive: stats.totalCompleted >= target → unlock', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.findOrCreate(playerId);
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 29, 10),
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false,
      );
      await runPosNegPair(
        subType: AchievementTriggerTypes.dailyMissionCount,
        target: 1,
        makePass: () async {},
        makeFail: () async {},
      );
    });

    test('negative: < target → no unlock', () async {
      final entries = [dailyAch('NEG', AchievementTriggerTypes.dailyMissionCount, 5)];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db).isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_mission_failed_count', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementFailed(playerId);
      await stats.incrementFailed(playerId);
      await runPosNegPair(
        subType: AchievementTriggerTypes.dailyMissionFailedCount,
        target: 2,
        makePass: () async {},
        makeFail: () async {},
      );
    });
    test('negative', () async {
      final entries = [
        dailyAch(
            'NEG', AchievementTriggerTypes.dailyMissionFailedCount, 3),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(
          DailyStatsUpdated(playerId: playerId, eventType: 'failed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_mission_partial_count', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementPartial(playerId);
      await runPosNegPair(
        subType: AchievementTriggerTypes.dailyMissionPartialCount,
        target: 1,
        makePass: () async {},
        makeFail: () async {},
      );
    });
    test('negative', () async {
      final entries = [
        dailyAch(
            'NEG', AchievementTriggerTypes.dailyMissionPartialCount, 2),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(
          DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_mission_streak', () {
    test('positive: player.dailyMissionsStreak >= target → unlock', () async {
      final pid = await seedPlayer(db, dailyStreak: 7);
      final entries = [
        dailyAch('STREAK_7', AchievementTriggerTypes.dailyMissionStreak, 7),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: pid, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'STREAK_7'),
          isTrue);
    });
    test('negative', () async {
      final pid = await seedPlayer(db, dailyStreak: 3);
      final entries = [
        dailyAch('STREAK_10', AchievementTriggerTypes.dailyMissionStreak, 10),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: pid, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'STREAK_10'),
          isFalse);
    });
  });

  group('daily_mission_best_streak', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.findOrCreate(playerId);
      await stats.updateBestStreak(playerId, 30);
      await runPosNegPair(
        subType: AchievementTriggerTypes.dailyMissionBestStreak,
        target: 30,
        makePass: () async {},
        makeFail: () async {},
      );
    });
    test('negative', () async {
      final entries = [
        dailyAch('NEG', AchievementTriggerTypes.dailyMissionBestStreak, 50),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_mission_perfect_count', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: true,
        isSuperPerfect: true,
        subTasksCompleted: 3,
        subTasksOvershoot: 3,
        confirmedAt: DateTime(2026, 4, 29, 10),
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false,
      );
      await runPosNegPair(
        subType: AchievementTriggerTypes.dailyMissionPerfectCount,
        target: 1,
        makePass: () async {},
        makeFail: () async {},
      );
    });
    test('negative', () async {
      final entries = [
        dailyAch('NEG', AchievementTriggerTypes.dailyMissionPerfectCount, 5),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_mission_super_perfect_count', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: true,
        subTasksCompleted: 3,
        subTasksOvershoot: 3,
        confirmedAt: DateTime(2026, 4, 29, 10),
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false,
      );
      await runPosNegPair(
        subType: AchievementTriggerTypes.dailyMissionSuperPerfectCount,
        target: 1,
        makePass: () async {},
        makeFail: () async {},
      );
    });
    test('negative', () async {
      final entries = [
        dailyAch('NEG',
            AchievementTriggerTypes.dailyMissionSuperPerfectCount, 5),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_no_fail_streak', () {
    test('positive (current)', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.findOrCreate(playerId);
      await stats.bumpDaysWithoutFailing(playerId);
      await stats.bumpDaysWithoutFailing(playerId);
      await stats.bumpDaysWithoutFailing(playerId);
      await runPosNegPair(
        subType: AchievementTriggerTypes.dailyNoFailStreak,
        target: 3,
        makePass: () async {},
        makeFail: () async {},
      );
    });
    test('positive (use_best=true)', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.findOrCreate(playerId);
      // Sobe pra 5, depois zera — best fica em 5, current em 0.
      for (var i = 0; i < 5; i++) {
        await stats.bumpDaysWithoutFailing(playerId);
      }
      await stats.resetDaysWithoutFailing(playerId);

      final entries = [
        dailyAch('BEST5', AchievementTriggerTypes.dailyNoFailStreak, 5,
            params: {'use_best': true}),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'BEST5'),
          isTrue);
    });
    test('negative', () async {
      final entries = [
        dailyAch('NEG', AchievementTriggerTypes.dailyNoFailStreak, 7),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_subtask_volume', () {
    test('positive', () async {
      final volume = PlayerDailySubtaskVolumeDao(db);
      await volume.incrementVolume(playerId, 'flexao', 50);
      await volume.incrementVolume(playerId, 'flexao', 50);

      final entries = [
        dailyAch('VOL', AchievementTriggerTypes.dailySubtaskVolume, 100,
            params: {'sub_task_key': 'flexao'}),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'VOL'),
          isTrue);
    });
    test('negative', () async {
      final volume = PlayerDailySubtaskVolumeDao(db);
      await volume.incrementVolume(playerId, 'flexao', 30);
      final entries = [
        dailyAch('NEG', AchievementTriggerTypes.dailySubtaskVolume, 100,
            params: {'sub_task_key': 'flexao'}),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
    test('fail-safe: params.sub_task_key ausente', () async {
      final entries = [
        dailyAch('BAD', AchievementTriggerTypes.dailySubtaskVolume, 100),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'BAD'),
          isFalse);
    });
  });

  group('daily_subtask_total_volume', () {
    test('positive', () async {
      final volume = PlayerDailySubtaskVolumeDao(db);
      await volume.incrementVolume(playerId, 'flexao', 60);
      await volume.incrementVolume(playerId, 'abdominal', 60);
      final entries = [
        dailyAch('TOTAL',
            AchievementTriggerTypes.dailySubtaskTotalVolume, 100),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'TOTAL'),
          isTrue);
    });
    test('negative', () async {
      final volume = PlayerDailySubtaskVolumeDao(db);
      await volume.incrementVolume(playerId, 'flexao', 50);
      final entries = [
        dailyAch('NEG',
            AchievementTriggerTypes.dailySubtaskTotalVolume, 200),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_confirmed_time_window', () {
    test('positive before_8am', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 29, 7, 0),
        dayOfWeek: 3,
        isBefore8AM: true,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false,
      );
      final entries = [
        dailyAch('AM', AchievementTriggerTypes.dailyConfirmedTimeWindow, 1,
            params: {'window': 'before_8am'}),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'AM'),
          isTrue);
    });
    test('positive after_10pm', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 29, 23, 0),
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: true,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false,
      );
      final entries = [
        dailyAch('PM', AchievementTriggerTypes.dailyConfirmedTimeWindow, 1,
            params: {'window': 'after_10pm'}),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'PM'),
          isTrue);
    });
    test('negative + fail-safe window inválido', () async {
      final entries = [
        dailyAch('BAD',
            AchievementTriggerTypes.dailyConfirmedTimeWindow, 1,
            params: {'window': 'midnight'}),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'BAD'),
          isFalse);
    });
  });

  group('daily_confirmed_on_weekend', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 25, 10), // sábado
        dayOfWeek: 6,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: true,
        isSpeedrun: false,
        zeroProgress: false,
      );
      final entries = [
        dailyAch('WK', AchievementTriggerTypes.dailyConfirmedOnWeekend, 1),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'WK'),
          isTrue);
    });
    test('negative', () async {
      final entries = [
        dailyAch('NEG',
            AchievementTriggerTypes.dailyConfirmedOnWeekend, 1),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_pilar_balance', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.markPilarBalanceDay(playerId, '2026-04-29');
      final entries = [
        dailyAch('PILAR', AchievementTriggerTypes.dailyPilarBalance, 1),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'PILAR'),
          isTrue);
    });
    test('negative', () async {
      final entries = [
        dailyAch('NEG', AchievementTriggerTypes.dailyPilarBalance, 7),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_consecutive_days_active', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.updateConsecutiveActiveDays(playerId,
          today: '2026-04-28', consecutive: false);
      await stats.updateConsecutiveActiveDays(playerId,
          today: '2026-04-29', consecutive: true);
      final entries = [
        dailyAch('CONS',
            AchievementTriggerTypes.dailyConsecutiveDaysActive, 2),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'CONS'),
          isTrue);
    });
    test('negative', () async {
      final entries = [
        dailyAch('NEG',
            AchievementTriggerTypes.dailyConsecutiveDaysActive, 5),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  group('daily_speedrun', () {
    test('positive', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 29, 10),
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: true,
        zeroProgress: false,
      );
      final entries = [
        dailyAch('SR', AchievementTriggerTypes.dailySpeedrun, 1),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'SR'),
          isTrue);
    });
    test('negative', () async {
      final entries = [
        dailyAch('NEG', AchievementTriggerTypes.dailySpeedrun, 5),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'NEG'),
          isFalse);
    });
  });

  // ─── integration ────────────────────────────────────────────────────

  group('integration', () {
    test('catálogo carregado popula _dailyAchievements cache', () async {
      final entries = [
        dailyAch('A', AchievementTriggerTypes.dailyMissionCount, 1),
        dailyAch('B', AchievementTriggerTypes.dailyMissionFailedCount, 1),
        // Não-daily — não deve entrar no cache
        {
          'key': 'M',
          'name': 'M',
          'description': 'm',
          'category': 'meta',
          'trigger': {'type': 'meta', 'target_count': 1},
        },
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.ensureLoaded();
      final daily = svc.dailyAchievements;
      expect(daily.length, 2);
      expect(daily.map((d) => d.key).toSet(), {'A', 'B'});
    });

    test('idempotência: 2 publishes serializados não duplicam unlock no DB',
        () async {
      // Idempotência semântica: o repository nunca tem mais de 1 row pra
      // (player, key). Re-publish pode causar 2 emits de
      // AchievementUnlocked se chegarem rapid-fire (ambos passam o
      // isCompleted check antes do primeiro markCompleted persistir),
      // mas o DB state mantém row única via PK composta.
      final stats = PlayerDailyMissionStatsDao(db);
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 29, 10),
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false,
      );
      final entries = [
        dailyAch('IDEMP', AchievementTriggerTypes.dailyMissionCount, 1),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();
      final repo = PlayerAchievementsRepositoryDrift(db);

      // Serializa: aguarda processamento completo entre publishes.
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 80));
      expect(await repo.isCompleted(playerId, 'IDEMP'), isTrue);

      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 80));

      // Conta rows manualmente no DB (deve ser exatamente 1).
      final rows = await db.customSelect(
        'SELECT COUNT(*) AS c FROM player_achievements_completed '
        'WHERE player_id = ? AND achievement_key = ?',
        variables: [Variable.withInt(playerId), Variable.withString('IDEMP')],
      ).get();
      expect(rows.first.read<int>('c'), 1);
    });

    test('subType desconhecido cai em UnknownAchievementTrigger (parser)',
        () async {
      // Tipo inventado, não bate com daily_* nem com legacy → Unknown.
      final entries = [
        {
          'key': 'WEIRD',
          'name': 'W',
          'description': 'w',
          'category': 'meta',
          'trigger': {'type': 'invented_trigger', 'target': 1},
        },
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.ensureLoaded();
      // Não vai estar no cache daily.
      expect(svc.dailyAchievements, isEmpty);
      // E publish do evento não unlocka.
      await svc.attachDailyListeners();
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'WEIRD'),
          isFalse);
    });

    test('end-to-end: stats.publish DailyStatsUpdated → unlock', () async {
      final stats = PlayerDailyMissionStatsDao(db);
      final entries = [
        dailyAch('E2E', AchievementTriggerTypes.dailyMissionCount, 1),
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachDailyListeners();

      // Simula o stats service: incrementa e depois publica.
      await stats.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 29, 10),
        dayOfWeek: 3,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false,
      );
      bus.publish(DailyStatsUpdated(playerId: playerId, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'E2E'),
          isTrue);
    });
  });
}
