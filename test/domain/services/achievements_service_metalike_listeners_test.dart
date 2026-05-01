import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/core/events/reward_events.dart';
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
import 'package:noheroes_app/domain/services/achievements_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

/// Sprint 3.3 Etapa 2.2 hotfix — testes de integração do
/// `attachMetaLikeListeners`. Cobre os 3 trigger types legacy que
/// ficavam unreachable no formato JSON novo: `meta`, `threshold_stat`,
/// `event_count`.

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

Future<int> seedPlayer(AppDatabase db, {int level = 1}) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp, total_quests_completed) "
    "VALUES (?, ?, 'Sombra', ?, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withInt(level),
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
  int? overrideLevel,
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
        level: overrideLevel ?? row.level,
        totalQuestsCompleted: row.totalQuestsCompleted,
        snapshot: PlayerSnapshot(
          level: overrideLevel ?? row.level,
          rank: GuildRank.e,
        ),
      );
    },
    assetBundle: _FakeBundle(bundleContents),
  );
}

String catalogJson(List<Map<String, dynamic>> entries) =>
    jsonEncode({'achievements': entries});

Map<String, dynamic> metaAch(String key, int targetCount) => {
      'key': key,
      'name': key,
      'description': key,
      'category': 'meta',
      'trigger': {'type': 'meta', 'target_count': targetCount},
    };

Map<String, dynamic> thresholdAch(
        String key, String stat, int value) =>
    {
      'key': key,
      'name': key,
      'description': key,
      'category': 'progression',
      'trigger': {'type': 'threshold_stat', 'stat': stat, 'value': value},
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

  group('attachMetaLikeListeners — AchievementUnlocked → meta trigger', () {
    test(
        'cenário Tríade: 5 conquistas pré-completadas + AchievementUnlocked '
        '→ INIT_CINCO_CONQUISTAS unlock automaticamente', () async {
      final repo = PlayerAchievementsRepositoryDrift(db);
      // Pré-completa 5 conquistas dummy. countCompleted vai retornar 5.
      for (var i = 1; i <= 5; i++) {
        await repo.markCompleted(playerId, 'DUMMY_$i', at: DateTime.now());
      }
      expect(await repo.countCompleted(playerId), 5);

      // Catálogo: só a meta achievement (target_count=5).
      final entries = [metaAch('META_5', 5)];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachMetaLikeListeners();

      // Confirma que cache pegou a conquista.
      expect(svc.metaLikeAchievements.length, 1);
      expect(svc.metaLikeAchievements.first.key, 'META_5');

      // Sanity: ainda não está completed.
      expect(await repo.isCompleted(playerId, 'META_5'), isFalse);

      // Publica evento que dispara o re-check.
      bus.publish(
          AchievementUnlocked(playerId: playerId, achievementKey: 'DUMMY_1'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(await repo.isCompleted(playerId, 'META_5'), isTrue,
          reason: 'meta trigger deveria unlockar quando '
              'countCompleted >= target_count e AchievementUnlocked dispara');
    });

    test('meta trigger NÃO unlock quando count < target', () async {
      final repo = PlayerAchievementsRepositoryDrift(db);
      // Só 2 conquistas pré-completadas.
      await repo.markCompleted(playerId, 'DUMMY_1', at: DateTime.now());
      await repo.markCompleted(playerId, 'DUMMY_2', at: DateTime.now());

      final entries = [metaAch('META_5', 5)];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachMetaLikeListeners();

      bus.publish(
          AchievementUnlocked(playerId: playerId, achievementKey: 'DUMMY_1'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(await repo.isCompleted(playerId, 'META_5'), isFalse);
    });

    test(
        'idempotência sob storm de events: 10 publishes de AchievementUnlocked '
        'após meta unlock NÃO causam re-grant ou loop', () async {
      final repo = PlayerAchievementsRepositoryDrift(db);
      for (var i = 1; i <= 5; i++) {
        await repo.markCompleted(playerId, 'DUMMY_$i', at: DateTime.now());
      }

      final entries = [metaAch('META_5', 5)];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachMetaLikeListeners();

      // 10 events seguidos.
      for (var i = 0; i < 10; i++) {
        bus.publish(AchievementUnlocked(
            playerId: playerId, achievementKey: 'STORM_$i'));
      }
      await Future.delayed(const Duration(milliseconds: 100));

      expect(await repo.isCompleted(playerId, 'META_5'), isTrue);
      // Idempotência: META_5 aparece apenas 1× nas keys completadas
      // (PK composta na tabela já garante, mas validar aqui captura
      // qualquer regressão de duplicate-insert no caller).
      final all = await repo.listCompletedKeys(playerId);
      expect(all.where((k) => k == 'META_5').length, 1);
    });
  });

  group('attachMetaLikeListeners — LevelUp → threshold_stat trigger', () {
    test(
        'cenário INIT_NIVEL_5: player level=5 + LevelUp event '
        '→ threshold_stat unlock automaticamente', () async {
      // Atualiza level do player pra 5 antes de publicar evento.
      // (LevelUp normalmente é emitido APÓS o DB já refletir o novo level).
      await db.customUpdate(
        'UPDATE players SET level = ? WHERE id = ?',
        variables: [Variable.withInt(5), Variable.withInt(playerId)],
      );

      final entries = [thresholdAch('LVL_5', 'level', 5)];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachMetaLikeListeners();

      expect(svc.metaLikeAchievements.length, 1);
      expect(svc.metaLikeAchievements.first.key, 'LVL_5');

      bus.publish(LevelUp(
          playerId: playerId, newLevel: 5, previousLevel: 4));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'LVL_5'),
          isTrue);
    });

    test('threshold_stat NÃO unlock quando level < value', () async {
      // Player ainda level=1 (default do seed).
      final entries = [thresholdAch('LVL_5', 'level', 5)];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.attachMetaLikeListeners();

      bus.publish(LevelUp(
          playerId: playerId, newLevel: 2, previousLevel: 1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(playerId, 'LVL_5'),
          isFalse);
    });
  });

  group('cache _metaLikeAchievements — cobertura + filtros', () {
    test('catálogo misto: cache pega só meta/threshold_stat/event_count, '
        'NÃO daily/event_*', () async {
      final entries = [
        metaAch('META', 3),
        thresholdAch('LVL', 'level', 10),
        {
          'key': 'EVT_COUNT',
          'name': 'EVT_COUNT',
          'description': 'd',
          'category': 'progression',
          'trigger': {
            'type': 'event_count',
            'event': 'MissionCompleted',
            'count': 5,
          },
        },
        // Daily — NÃO deve entrar no cache metaLike.
        {
          'key': 'DAILY_X',
          'name': 'DAILY_X',
          'description': 'd',
          'category': 'daily',
          'trigger': {'type': 'daily_mission_count', 'target': 1},
        },
        // Event_* — NÃO deve entrar no cache metaLike.
        {
          'key': 'EVENT_CLASS',
          'name': 'EVENT_CLASS',
          'description': 'd',
          'category': 'progression',
          'trigger': {'type': 'event_class_selected', 'target': 1},
        },
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.ensureLoaded();

      final keys =
          svc.metaLikeAchievements.map((d) => d.key).toSet();
      expect(keys, {'META', 'LVL', 'EVT_COUNT'});
    });

    test('disabled=true em metaLike NÃO entra no cache', () async {
      final entries = [
        {
          'key': 'META_ON',
          'name': 'META_ON',
          'description': 'd',
          'category': 'meta',
          'trigger': {'type': 'meta', 'target_count': 1},
        },
        {
          'key': 'META_SHELL',
          'name': 'META_SHELL',
          'description': 'd',
          'category': 'meta',
          'trigger': {'type': 'meta', 'target_count': 1},
          'disabled': true,
        },
      ];
      final svc = newService(db, bus, {
        AchievementsService.catalogAssetPath: catalogJson(entries),
      });
      await svc.ensureLoaded();

      final keys =
          svc.metaLikeAchievements.map((d) => d.key).toSet();
      expect(keys, {'META_ON'});
    });
  });
}
