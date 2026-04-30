import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/faction_events.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
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
import 'package:noheroes_app/domain/services/body_metrics_service.dart';
import 'package:noheroes_app/domain/services/player_currency_stats_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

/// Sprint 3.3 Etapa 2.1c-α — testes dos 5 sub-tipos de trigger event_*
/// + disabled flag + foundation pra secretas.

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

Future<int> seedPlayer(
  AppDatabase db, {
  String? classType,
  String? factionType,
  int totalGemsSpent = 0,
  int totalAttributePointsSpent = 0,
  int? weightKg,
  int? heightCm,
}) async {
  // Insert mínimo via Companion — handles nullables direito.
  final id = await db.into(db.playersTable).insert(PlayersTableCompanion.insert(
        email: 'p${DateTime.now().microsecondsSinceEpoch}@t',
        passwordHash: 'h',
        classType: classType == null
            ? const Value.absent()
            : Value(classType),
        factionType: factionType == null
            ? const Value.absent()
            : Value(factionType),
        weightKg: weightKg == null ? const Value.absent() : Value(weightKg),
        heightCm: heightCm == null ? const Value.absent() : Value(heightCm),
        totalGemsSpent: Value(totalGemsSpent),
        totalAttributePointsSpent: Value(totalAttributePointsSpent),
      ));
  return id;
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
  Map<String, String> bundleContents,
) {
  return AchievementsService(
    achievementsRepo: PlayerAchievementsRepositoryDrift(db),
    rewardResolve: RewardResolveService(ItemsCatalogService(db)),
    rewardGrant: newGrant(db, bus),
    bus: bus,
    statsDao: PlayerDailyMissionStatsDao(db),
    volumeDao: PlayerDailySubtaskVolumeDao(db),
    playerDao: PlayerDao(db),
    resolvePlayerFacts: (playerId) async {
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      return PlayerFacts(
        level: row.level,
        totalQuestsCompleted: row.totalQuestsCompleted,
        dailyMissionsStreak: row.dailyMissionsStreak,
        snapshot: PlayerSnapshot(level: row.level, rank: GuildRank.e),
      );
    },
    assetBundle: _FakeBundle(bundleContents),
  );
}

String catalogJson(List<Map<String, dynamic>> entries) =>
    jsonEncode({'achievements': entries});

Map<String, dynamic> eventAch(
  String key,
  String subType,
  int target, {
  Map<String, dynamic>? params,
  bool disabled = false,
}) =>
    {
      'key': key,
      'name': key,
      'description': key,
      'category': 'event',
      'trigger': {
        'type': subType,
        'target': target,
        if (params != null) 'params': params,
      },
      if (disabled) 'disabled': disabled,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  int playerId = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  // ─── disabled flag ───────────────────────────────────────────────

  group('disabled flag', () {
    test('parser respeita disabled=true (default false)', () async {
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('A', AchievementTriggerTypes.eventClassSelected, 1),
          eventAch('B', AchievementTriggerTypes.eventClassSelected, 1,
              disabled: true),
        ]),
      });
      await svc.ensureLoaded();
      expect(svc.catalog['A']!.disabled, isFalse);
      expect(svc.catalog['B']!.disabled, isTrue);
    });

    test('disabled fora dos caches _eventAchievements + _dailyAchievements',
        () async {
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('A', AchievementTriggerTypes.eventClassSelected, 1),
          eventAch('B', AchievementTriggerTypes.eventClassSelected, 1,
              disabled: true),
        ]),
      });
      await svc.ensureLoaded();
      expect(svc.eventAchievements.length, 1);
      expect(svc.eventAchievements.first.key, 'A');
    });

    test('disabled bloqueia unlock mesmo via cascata', () async {
      playerId = await seedPlayer(db, classType: 'warrior');
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('SHELL', AchievementTriggerTypes.eventClassSelected, 1,
              disabled: true),
        ]),
      });
      await svc.ensureLoaded();
      // Tenta cascata via bus.
      bus.publish(ClassSelected(playerId: playerId, classId: 'warrior'));
      await svc.attachEventListeners();
      bus.publish(ClassSelected(playerId: playerId, classId: 'warrior'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'SHELL'),
          isFalse);
    });
  });

  // ─── event_class_selected ───────────────────────────────────────

  group('event_class_selected', () {
    test('positive: class_type bate com params.class_key', () async {
      playerId = await seedPlayer(db, classType: 'warrior');
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('CLS_W', AchievementTriggerTypes.eventClassSelected, 1,
              params: {'class_key': 'warrior'}),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(ClassSelected(playerId: playerId, classId: 'warrior'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'CLS_W'),
          isTrue);
    });

    test('negative: class_type diferente do esperado', () async {
      playerId = await seedPlayer(db, classType: 'mage');
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('CLS_W', AchievementTriggerTypes.eventClassSelected, 1,
              params: {'class_key': 'warrior'}),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(ClassSelected(playerId: playerId, classId: 'mage'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'CLS_W'),
          isFalse);
    });

    test('sem params: qualquer classe selecionada conta', () async {
      playerId = await seedPlayer(db, classType: 'rogue');
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('ANY_CLS',
              AchievementTriggerTypes.eventClassSelected, 1),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(ClassSelected(playerId: playerId, classId: 'rogue'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'ANY_CLS'),
          isTrue);
    });
  });

  // ─── event_faction_joined ──────────────────────────────────────

  group('event_faction_joined', () {
    test('positive: faction_type bate com params.faction_id', () async {
      playerId = await seedPlayer(db, factionType: 'error');
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('JOIN_ERR', AchievementTriggerTypes.eventFactionJoined, 1,
              params: {'faction_id': 'error'}),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(FactionJoined(playerId: playerId, factionId: 'error'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'JOIN_ERR'),
          isTrue);
    });

    test('pending:<id> não conta como joined', () async {
      playerId = await seedPlayer(db, factionType: 'pending:error');
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('JOIN_ERR', AchievementTriggerTypes.eventFactionJoined, 1,
              params: {'faction_id': 'error'}),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(FactionJoined(playerId: playerId, factionId: 'error'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'JOIN_ERR'),
          isFalse);
    });
  });

  // ─── event_attribute_point_spent ───────────────────────────────

  group('event_attribute_point_spent', () {
    test('positive: total_attribute_points_spent >= target', () async {
      playerId = await seedPlayer(db, totalAttributePointsSpent: 5);
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('ATR_5',
              AchievementTriggerTypes.eventAttributePointSpent, 5),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(AttributePointSpent(
          playerId: playerId, attributeKey: 'strength', newValue: 6));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'ATR_5'),
          isTrue);
    });

    test('negative: total < target', () async {
      playerId = await seedPlayer(db, totalAttributePointsSpent: 2);
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('ATR_10',
              AchievementTriggerTypes.eventAttributePointSpent, 10),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(AttributePointSpent(
          playerId: playerId, attributeKey: 'strength', newValue: 3));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'ATR_10'),
          isFalse);
    });

    test('PlayerDao.distributePointWithEvent atualiza counter + retorna evento',
        () async {
      playerId = await seedPlayer(db);
      // Dá 1 ponto.
      await db.customUpdate(
        'UPDATE players SET attribute_points = 1 WHERE id = ?',
        variables: [Variable.withInt(playerId)],
        updates: {db.playersTable},
      );
      final result = await PlayerDao(db).distributePointWithEvent(
          playerId, 'strength');
      expect(result.isOk, isTrue);
      expect(result.event!.attributeKey, 'strength');
      expect(result.event!.newValue, 2);

      final player = await PlayerDao(db).findById(playerId);
      expect(player!.totalAttributePointsSpent, 1);
      expect(player.attributePoints, 0);
      expect(player.strength, 2);
    });
  });

  // ─── event_body_metrics_updated ────────────────────────────────

  group('event_body_metrics_updated', () {
    test('positive sem must_be_first_time: qualquer save conta', () async {
      playerId = await seedPlayer(db, weightKg: 70, heightCm: 175);
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('BM',
              AchievementTriggerTypes.eventBodyMetricsUpdated, 1),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(BodyMetricsUpdated(
          playerId: playerId, isFirstTime: false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'BM'),
          isTrue);
    });

    test('must_be_first_time=true: edição posterior não unlock', () async {
      playerId = await seedPlayer(db, weightKg: 70, heightCm: 175);
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('BM_FIRST',
              AchievementTriggerTypes.eventBodyMetricsUpdated, 1,
              params: {'must_be_first_time': true}),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(BodyMetricsUpdated(
          playerId: playerId, isFirstTime: false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'BM_FIRST'),
          isFalse);
    });

    test('must_be_first_time=true: 1ª calibração unlock', () async {
      playerId = await seedPlayer(db, weightKg: 70, heightCm: 175);
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('BM_FIRST',
              AchievementTriggerTypes.eventBodyMetricsUpdated, 1,
              params: {'must_be_first_time': true}),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(BodyMetricsUpdated(
          playerId: playerId, isFirstTime: true));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'BM_FIRST'),
          isTrue);
    });

    test('player sem peso/altura não unlock mesmo com evento', () async {
      playerId = await seedPlayer(db);
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('BM',
              AchievementTriggerTypes.eventBodyMetricsUpdated, 1),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(BodyMetricsUpdated(
          playerId: playerId, isFirstTime: true));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'BM'),
          isFalse);
    });
  });

  // ─── event_gems_spent_total ────────────────────────────────────

  group('event_gems_spent_total', () {
    test('positive: total_gems_spent >= target', () async {
      playerId = await seedPlayer(db, totalGemsSpent: 100);
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('GEMS_100',
              AchievementTriggerTypes.eventGemsSpentTotal, 100),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(CurrencyStatsUpdated(
          playerId: playerId, currencyKind: 'gems_spent'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'GEMS_100'),
          isTrue);
    });

    test('negative: total < target', () async {
      playerId = await seedPlayer(db, totalGemsSpent: 30);
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson([
          eventAch('GEMS_500',
              AchievementTriggerTypes.eventGemsSpentTotal, 500),
        ]),
      });
      await svc.attachEventListeners();
      bus.publish(CurrencyStatsUpdated(
          playerId: playerId, currencyKind: 'gems_spent'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'GEMS_500'),
          isFalse);
    });
  });

  // ─── PlayerDao.addXp atualiza peak_level ───────────────────────

  group('peak_level', () {
    test('addXp atualiza peak_level quando newLevel > peakLevel', () async {
      playerId = await seedPlayer(db);
      // XP suficiente pra subir vários levels.
      final evt = await PlayerDao(db).addXp(playerId, 1000);
      expect(evt, isNotNull);
      final player = await PlayerDao(db).findById(playerId);
      expect(player!.peakLevel, player.level);
      expect(player.peakLevel, greaterThan(1));
    });
  });

  // ─── PlayerCurrencyStatsService ─────────────────────────────────

  group('PlayerCurrencyStatsService', () {
    test('GemsSpent → players.total_gems_spent + CurrencyStatsUpdated',
        () async {
      playerId = await seedPlayer(db);
      final received = <CurrencyStatsUpdated>[];
      bus.on<CurrencyStatsUpdated>().listen(received.add);

      final svc = PlayerCurrencyStatsService(db: db, bus: bus);
      svc.start();

      bus.publish(GemsSpent(
          playerId: playerId, amount: 50, source: GemSink.shop));
      await Future.delayed(const Duration(milliseconds: 80));

      final player = await PlayerDao(db).findById(playerId);
      expect(player!.totalGemsSpent, 50);
      expect(received.length, 1);
      expect(received.first.currencyKind, 'gems_spent');

      await svc.dispose();
    });

    test('múltiplos GemsSpent acumulam', () async {
      playerId = await seedPlayer(db);
      final svc = PlayerCurrencyStatsService(db: db, bus: bus);
      svc.start();

      bus.publish(GemsSpent(
          playerId: playerId, amount: 30, source: GemSink.shop));
      bus.publish(GemsSpent(
          playerId: playerId, amount: 20, source: GemSink.enchant));
      await Future.delayed(const Duration(milliseconds: 100));

      final player = await PlayerDao(db).findById(playerId);
      expect(player!.totalGemsSpent, 50);

      await svc.dispose();
    });
  });

  // ─── BodyMetricsService.save publica isFirstTime correto ───────

  group('BodyMetricsService.save', () {
    test('1ª save com weight+height null → isFirstTime=true', () async {
      playerId = await seedPlayer(db);
      final received = <BodyMetricsUpdated>[];
      bus.on<BodyMetricsUpdated>().listen(received.add);

      final service = BodyMetricsService(dao: PlayerDao(db), bus: bus);
      await service.save(playerId: playerId, weightKg: 70, heightCm: 175);
      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received.first.isFirstTime, isTrue);
    });

    test('save subsequente → isFirstTime=false', () async {
      playerId = await seedPlayer(db, weightKg: 70, heightCm: 175);
      final received = <BodyMetricsUpdated>[];
      bus.on<BodyMetricsUpdated>().listen(received.add);

      final service = BodyMetricsService(dao: PlayerDao(db), bus: bus);
      await service.save(playerId: playerId, weightKg: 75);
      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received.first.isFirstTime, isFalse);
    });
  });
}
