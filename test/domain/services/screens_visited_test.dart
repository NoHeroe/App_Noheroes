import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/navigation_events.dart';
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
import 'package:noheroes_app/domain/services/player_screens_visited_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

/// Sprint 3.3 Etapa 2.1c-γ — testes do tracking de telas visitadas.
///
/// Cobre:
/// - Migration 31→32 (PRAGMA confirma coluna)
/// - PlayerScreensVisitedService.recordVisit (1ª visita, duplicata, exclusão)
/// - hasVisited / visitedCount / listVisited / parseCSV
/// - PlayerDao.setScreensVisitedKeys round-trip
/// - Trigger event_screen_visited (com screen_key + sem param)
/// - Listener integration

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

Future<int> seedPlayer(AppDatabase db, {String? csvSeed}) async {
  return db.into(db.playersTable).insert(PlayersTableCompanion.insert(
        email: 'p${DateTime.now().microsecondsSinceEpoch}@t',
        passwordHash: 'h',
        screensVisitedKeys:
            csvSeed == null ? const Value.absent() : Value(csvSeed),
      ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── 1. Migration 31→32 ──────────────────────────────────────────

  group('migration 31→32', () {
    test('schema 32 fresh install: coluna screens_visited_keys com default',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
      final cols =
          await db.customSelect("PRAGMA table_info('players')").get();
      final names = cols.map((r) => r.read<String>('name')).toSet();
      expect(names.contains('screens_visited_keys'), isTrue);

      // Insere player e checa default vazio.
      final pid = await seedPlayer(db);
      final p = await PlayerDao(db).findById(pid);
      expect(p!.screensVisitedKeys, '');
      await db.close();
    });
  });

  // ─── 2. parseCSV helper ──────────────────────────────────────────

  group('parseCSV', () {
    test('CSV vazio → lista vazia', () {
      expect(PlayerScreensVisitedService.parseCSV(''), isEmpty);
    });

    test('CSV simples', () {
      expect(PlayerScreensVisitedService.parseCSV('/perfil,/quests'),
          ['/perfil', '/quests']);
    });

    test('CSV malformado tolerante: trim + descarta vazios', () {
      expect(
          PlayerScreensVisitedService.parseCSV(
              ' /perfil , ,/quests, '),
          ['/perfil', '/quests']);
    });
  });

  // ─── 3. recordVisit ─────────────────────────────────────────────

  group('PlayerScreensVisitedService.recordVisit', () {
    late AppDatabase db;
    late AppEventBus bus;
    late PlayerScreensVisitedService service;
    late int pid;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      bus = AppEventBus();
      service = PlayerScreensVisitedService(
        db: db,
        playerDao: PlayerDao(db),
        bus: bus,
      );
      pid = await seedPlayer(db);
    });

    tearDown(() async {
      await bus.dispose();
      await db.close();
    });

    test('1ª visita: CSV ganha key + emit isFirstVisit=true', () async {
      final received = <ScreenVisited>[];
      bus.on<ScreenVisited>().listen(received.add);

      await service.recordVisit(pid, '/perfil');
      await Future.delayed(Duration.zero);

      expect(await service.hasVisited(pid, '/perfil'), isTrue);
      expect(received.length, 1);
      expect(received.first.isFirstVisit, isTrue);
      expect(received.first.screenKey, '/perfil');
    });

    test('2ª visita mesma key: CSV inalterado + emit isFirstVisit=false',
        () async {
      await service.recordVisit(pid, '/perfil');
      final received = <ScreenVisited>[];
      bus.on<ScreenVisited>().listen(received.add);

      await service.recordVisit(pid, '/perfil');
      await Future.delayed(Duration.zero);

      expect(await service.visitedCount(pid), 1);
      expect(received.length, 1);
      expect(received.first.isFirstVisit, isFalse);
    });

    test('paths excluídos não persistem nem emitem', () async {
      final received = <ScreenVisited>[];
      bus.on<ScreenVisited>().listen(received.add);

      await service.recordVisit(pid, '/');
      await service.recordVisit(pid, '/login');
      await service.recordVisit(pid, '/register');
      await Future.delayed(Duration.zero);

      expect(await service.visitedCount(pid), 0);
      expect(received, isEmpty);
    });

    test('normalização: query params e fragment removidos', () async {
      await service.recordVisit(pid, '/perfil?recalibrate=true');
      await service.recordVisit(pid, '/perfil#section');
      await Future.delayed(Duration.zero);

      // Mesmo path normalizado: 1 row.
      expect(await service.visitedCount(pid), 1);
      expect(await service.hasVisited(pid, '/perfil'), isTrue);
    });

    test('path vazio/whitespace: noop silencioso', () async {
      final received = <ScreenVisited>[];
      bus.on<ScreenVisited>().listen(received.add);

      await service.recordVisit(pid, '');
      await service.recordVisit(pid, '   ');
      await Future.delayed(Duration.zero);

      expect(await service.visitedCount(pid), 0);
      expect(received, isEmpty);
    });

    test('CSV legacy malformado é tolerado em hasVisited', () async {
      // Player com CSV malformado pré-existente.
      final p2 = await seedPlayer(db, csvSeed: ' /a , ,/b, ,');
      expect(await service.hasVisited(p2, '/a'), isTrue);
      expect(await service.hasVisited(p2, '/b'), isTrue);
      expect(await service.hasVisited(p2, '/c'), isFalse);
      expect(await service.visitedCount(p2), 2);
    });

    test('múltiplas keys distintas acumulam', () async {
      await service.recordVisit(pid, '/perfil');
      await service.recordVisit(pid, '/quests');
      await service.recordVisit(pid, '/shops');

      expect(await service.visitedCount(pid), 3);
      final list = await service.listVisited(pid);
      expect(list, ['/perfil', '/quests', '/shops']);
    });
  });

  // ─── 4. PlayerDao.setScreensVisitedKeys ─────────────────────────

  group('PlayerDao.setScreensVisitedKeys', () {
    test('round-trip', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final pid = await seedPlayer(db);
      await PlayerDao(db).setScreensVisitedKeys(pid, '/a,/b,/c');
      final p = await PlayerDao(db).findById(pid);
      expect(p!.screensVisitedKeys, '/a,/b,/c');
      await db.close();
    });
  });

  // ─── 5. Trigger event_screen_visited ────────────────────────────

  group('event_screen_visited', () {
    late AppDatabase db;
    late AppEventBus bus;
    int pid = 0;

    Future<AchievementsService> newSvc(String catalogJson) async {
      final catalog = ItemsCatalogService(db);
      return AchievementsService(
        achievementsRepo: PlayerAchievementsRepositoryDrift(db),
        rewardResolve: RewardResolveService(catalog),
        rewardGrant: RewardGrantService(
          db: db,
          missionRepo: MissionRepositoryDrift(db),
          achievementsRepo: PlayerAchievementsRepositoryDrift(db),
          inventory: PlayerInventoryService(db, catalog),
          recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
          factionRep: PlayerFactionReputationRepositoryDrift(db),
          eventBus: bus,
        ),
        bus: bus,
        statsDao: PlayerDailyMissionStatsDao(db),
        volumeDao: PlayerDailySubtaskVolumeDao(db),
        playerDao: PlayerDao(db),
        screensVisitedService: PlayerScreensVisitedService(
          db: db,
          playerDao: PlayerDao(db),
          bus: bus,
        ),
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
        assetBundle: _FakeBundle(
            {AchievementsService.catalogAssetPath: catalogJson}),
      );
    }

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      bus = AppEventBus();
      pid = await seedPlayer(db);
    });

    tearDown(() async {
      await bus.dispose();
      await db.close();
    });

    test('com screen_key positive: visita específica unlock', () async {
      await PlayerDao(db).setScreensVisitedKeys(pid, '/achievements');
      final svc = await newSvc(jsonEncode({
        'achievements': [
          {
            'key': 'VISIT_ACH',
            'name': 'VISIT_ACH',
            'description': 'd',
            'category': 'event',
            'trigger': {
              'type': AchievementTriggerTypes.eventScreenVisited,
              'target': 1,
              'params': {'screen_key': '/achievements'},
            },
          },
        ],
      }));
      await svc.attachEventListeners();
      bus.publish(ScreenVisited(
          playerId: pid, screenKey: '/achievements', isFirstVisit: true));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'VISIT_ACH'),
          isTrue);
    });

    test('com screen_key negative: visita diferente NÃO unlock',
        () async {
      await PlayerDao(db).setScreensVisitedKeys(pid, '/perfil');
      final svc = await newSvc(jsonEncode({
        'achievements': [
          {
            'key': 'VISIT_FORGE',
            'name': 'VISIT_FORGE',
            'description': 'd',
            'category': 'event',
            'trigger': {
              'type': AchievementTriggerTypes.eventScreenVisited,
              'target': 1,
              'params': {'screen_key': '/forge'},
            },
          },
        ],
      }));
      await svc.attachEventListeners();
      bus.publish(ScreenVisited(
          playerId: pid, screenKey: '/perfil', isFirstVisit: true));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'VISIT_FORGE'),
          isFalse);
    });

    test('sem param positive: count distinto >= target', () async {
      await PlayerDao(db).setScreensVisitedKeys(
          pid, '/perfil,/quests,/shops,/forge,/inventory');
      final svc = await newSvc(jsonEncode({
        'achievements': [
          {
            'key': 'EXPLORER_5',
            'name': 'EXPLORER_5',
            'description': 'd',
            'category': 'event',
            'trigger': {
              'type': AchievementTriggerTypes.eventScreenVisited,
              'target': 5,
            },
          },
        ],
      }));
      await svc.attachEventListeners();
      bus.publish(ScreenVisited(
          playerId: pid, screenKey: '/inventory', isFirstVisit: false));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'EXPLORER_5'),
          isTrue);
    });

    test('sem param negative: count < target', () async {
      await PlayerDao(db).setScreensVisitedKeys(pid, '/perfil,/quests');
      final svc = await newSvc(jsonEncode({
        'achievements': [
          {
            'key': 'EXPLORER_10',
            'name': 'EXPLORER_10',
            'description': 'd',
            'category': 'event',
            'trigger': {
              'type': AchievementTriggerTypes.eventScreenVisited,
              'target': 10,
            },
          },
        ],
      }));
      await svc.attachEventListeners();
      bus.publish(ScreenVisited(
          playerId: pid, screenKey: '/quests', isFirstVisit: true));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'EXPLORER_10'),
          isFalse);
    });

    test(
        'isFirstVisit=false ainda dispara check '
        '(conquista adicionada após 1ª visita)',
        () async {
      // Player já visitou (5 telas), conquista pra "5 telas" só adicionada
      // agora. Próximo evento (qualquer, incluindo isFirstVisit=false)
      // deve disparar unlock.
      await PlayerDao(db).setScreensVisitedKeys(
          pid, '/perfil,/quests,/shops,/forge,/inventory');
      final svc = await newSvc(jsonEncode({
        'achievements': [
          {
            'key': 'EXPLORER_5',
            'name': 'EXPLORER_5',
            'description': 'd',
            'category': 'event',
            'trigger': {
              'type': AchievementTriggerTypes.eventScreenVisited,
              'target': 5,
            },
          },
        ],
      }));
      await svc.attachEventListeners();
      bus.publish(ScreenVisited(
          playerId: pid,
          screenKey: '/perfil',
          isFirstVisit: false)); // 6ª visita ao /perfil
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'EXPLORER_5'),
          isTrue,
          reason: 'isFirstVisit=false ainda dispara check — design choice');
    });

    test(
        'service degradado (sem screensVisitedService): trigger '
        'fail-safe',
        () async {
      // Cria service sem screensVisitedService → trigger não unlock.
      final catalog = ItemsCatalogService(db);
      final svc = AchievementsService(
        achievementsRepo: PlayerAchievementsRepositoryDrift(db),
        rewardResolve: RewardResolveService(catalog),
        rewardGrant: RewardGrantService(
          db: db,
          missionRepo: MissionRepositoryDrift(db),
          achievementsRepo: PlayerAchievementsRepositoryDrift(db),
          inventory: PlayerInventoryService(db, catalog),
          recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
          factionRep: PlayerFactionReputationRepositoryDrift(db),
          eventBus: bus,
        ),
        bus: bus,
        statsDao: PlayerDailyMissionStatsDao(db),
        volumeDao: PlayerDailySubtaskVolumeDao(db),
        playerDao: PlayerDao(db),
        // screensVisitedService: AUSENTE
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
        assetBundle: _FakeBundle({
          AchievementsService.catalogAssetPath: jsonEncode({
            'achievements': [
              {
                'key': 'NOPE',
                'name': 'NOPE',
                'description': 'd',
                'category': 'event',
                'trigger': {
                  'type': AchievementTriggerTypes.eventScreenVisited,
                  'target': 1,
                  'params': {'screen_key': '/perfil'},
                },
              },
            ],
          }),
        }),
      );

      await PlayerDao(db).setScreensVisitedKeys(pid, '/perfil');
      await svc.attachEventListeners();
      bus.publish(ScreenVisited(
          playerId: pid, screenKey: '/perfil', isFirstVisit: true));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'NOPE'),
          isFalse,
          reason: 'Sem screensVisitedService: fail-safe (warn + return false)');
    });
  });
}
