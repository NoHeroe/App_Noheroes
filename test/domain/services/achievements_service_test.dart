import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/reward_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_achievements_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/data/services/reward_grant_service.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import 'package:noheroes_app/domain/models/reward_resolved.dart';
import 'package:noheroes_app/domain/services/achievements_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

/// AssetBundle de teste — retorna strings pré-configuradas por path.
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

Future<int> _seedPlayer(AppDatabase db, {int level = 1}) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp, total_quests_completed) "
    "VALUES (?, ?, 'Sombra', ?, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, "
    "0, 0)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withInt(level),
    ],
  );
}

/// Seta total_quests_completed direto (simula estado pós-N missões).
Future<void> _setTotalQuests(AppDatabase db, int playerId, int n) async {
  await db.customUpdate(
    'UPDATE players SET total_quests_completed = ? WHERE id = ?',
    variables: [Variable.withInt(n), Variable.withInt(playerId)],
    updates: {db.playersTable},
  );
}

Future<void> _setLevel(AppDatabase db, int playerId, int level) async {
  await db.customUpdate(
    'UPDATE players SET level = ? WHERE id = ?',
    variables: [Variable.withInt(level), Variable.withInt(playerId)],
    updates: {db.playersTable},
  );
}

RewardGrantService _newGrant(AppDatabase db, AppEventBus bus) {
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

AchievementsService _newService(
  AppDatabase db,
  AppEventBus bus,
  Map<String, String> bundleContents, {
  PlayerFacts Function(int playerId, AppDatabase db)? factsBuilder,
}) {
  return AchievementsService(
    achievementsRepo: PlayerAchievementsRepositoryDrift(db),
    rewardResolve: RewardResolveService(ItemsCatalogService(db)),
    rewardGrant: _newGrant(db, bus),
    bus: bus,
    resolvePlayerFacts: (playerId) async {
      if (factsBuilder != null) return factsBuilder(playerId, db);
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      return PlayerFacts(
        level: row.level,
        totalQuestsCompleted: row.totalQuestsCompleted,
        snapshot: PlayerSnapshot(
          level: row.level,
          rank: GuildRank.e,
        ),
      );
    },
    assetBundle: _FakeBundle(bundleContents),
  );
}

String _catalogJson(List<Map<String, dynamic>> entries) =>
    jsonEncode({'achievements': entries});

void main() {
  late AppDatabase db;
  late AppEventBus bus;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('AchievementsService.ensureLoaded', () {
    test('catálogo vazio — sem entries carregadas, não lança', () async {
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath:
            _catalogJson(const []),
      });
      await service.ensureLoaded();
      expect(service.catalog, isEmpty);
    });

    test('catálogo ausente no bundle — service fica silencioso', () async {
      final service = _newService(db, bus, const {});
      await service.ensureLoaded();
      expect(service.catalog, isEmpty);
    });

    test('catálogo com 2 entries — expostas via getter', () async {
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'A',
            'name': 'A',
            'description': 'a',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 1},
          },
          {
            'key': 'B',
            'name': 'B',
            'description': 'b',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 2},
          },
        ]),
      });
      await service.ensureLoaded();
      expect(service.catalog.keys, containsAll(['A', 'B']));
    });

    test('catálogo com key duplicada — lança FormatException', () async {
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'DUP',
            'name': 'x',
            'description': 'y',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 1},
          },
          {
            'key': 'DUP',
            'name': 'y',
            'description': 'z',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 2},
          },
        ]),
      });
      expect(service.ensureLoaded, throwsA(isA<FormatException>()));
    });

    test('ensureLoaded é idempotente — 2ª chamada é noop', () async {
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'A',
            'name': 'A',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 1},
          },
        ]),
      });
      await service.ensureLoaded();
      await service.ensureLoaded();
      expect(service.catalog.length, 1);
    });
  });

  group('AchievementsService — handler + validators', () {
    late int playerId;

    setUp(() async {
      playerId = await _seedPlayer(db);
    });

    test('RewardGranted com key fantasma — skip sem emitir', () async {
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson(const []),
      });
      final sub = await service.attach();
      final events = <AchievementUnlocked>[];
      final evSub = bus.on<AchievementUnlocked>().listen(events.add);

      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['ACH_GHOST'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events, isEmpty);
      await sub.cancel();
      await evSub.cancel();
    });

    test('trigger meta não satisfeito — não desbloqueia', () async {
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'ACH_META_5',
            'name': 'x',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 5},
          },
        ]),
      });
      final sub = await service.attach();
      final repo = PlayerAchievementsRepositoryDrift(db);
      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['ACH_META_5'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await repo.isCompleted(playerId, 'ACH_META_5'), isFalse);
      await sub.cancel();
    });

    test('event_count MissionCompleted satisfeito — unlock + emit + grant',
        () async {
      await _setTotalQuests(db, playerId, 10);
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'ACH_TEN',
            'name': 'Ten',
            'description': '',
            'category': 'c',
            'trigger': {
              'type': 'event_count',
              'event': 'MissionCompleted',
              'count': 10,
            },
            'reward': {'gold': 100},
          },
        ]),
      });
      final sub = await service.attach();
      final unlocked = <AchievementUnlocked>[];
      final evSub = bus.on<AchievementUnlocked>().listen(unlocked.add);

      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['ACH_TEN'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final repo = PlayerAchievementsRepositoryDrift(db);
      expect(await repo.isCompleted(playerId, 'ACH_TEN'), isTrue);
      expect(await repo.isRewardClaimed(playerId, 'ACH_TEN'), isTrue);
      expect(unlocked.map((e) => e.achievementKey), contains('ACH_TEN'));

      // Gold creditado com SOULSLIKE 0.35 → 100 * 0.35 = 35
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gold, 35);

      await sub.cancel();
      await evSub.cancel();
    });

    test('threshold_stat level satisfeito', () async {
      await _setLevel(db, playerId, 5);
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'ACH_LV5',
            'name': 'x',
            'description': '',
            'category': 'c',
            'trigger': {
              'type': 'threshold_stat',
              'stat': 'level',
              'value': 5,
            },
          },
        ]),
      });
      final sub = await service.attach();
      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['ACH_LV5'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final repo = PlayerAchievementsRepositoryDrift(db);
      expect(await repo.isCompleted(playerId, 'ACH_LV5'), isTrue);
      await sub.cancel();
    });

    test('threshold_stat stat "gold" — fail-safe retorna false', () async {
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'ACH_GOLD',
            'name': 'x',
            'description': '',
            'category': 'c',
            'trigger': {
              'type': 'threshold_stat',
              'stat': 'gold',
              'value': 100,
            },
          },
        ]),
      });
      final sub = await service.attach();
      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['ACH_GOLD'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final repo = PlayerAchievementsRepositoryDrift(db);
      expect(await repo.isCompleted(playerId, 'ACH_GOLD'), isFalse);
      await sub.cancel();
    });

    test('UnknownAchievementTrigger (sequence) — fail-safe retorna false',
        () async {
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'ACH_SEQ',
            'name': 'x',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'sequence', 'events': []},
          },
        ]),
      });
      final sub = await service.attach();
      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['ACH_SEQ'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final repo = PlayerAchievementsRepositoryDrift(db);
      expect(await repo.isCompleted(playerId, 'ACH_SEQ'), isFalse);
      await sub.cancel();
    });

    test('idempotência — 2 RewardGranted com mesma key emitem 1 unlock',
        () async {
      await _setTotalQuests(db, playerId, 1);
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'ACH_FIRST',
            'name': 'x',
            'description': '',
            'category': 'c',
            'trigger': {
              'type': 'event_count',
              'event': 'MissionCompleted',
              'count': 1,
            },
            'reward': {'gold': 10},
          },
        ]),
      });
      final sub = await service.attach();
      final unlocked = <AchievementUnlocked>[];
      final evSub = bus.on<AchievementUnlocked>().listen(unlocked.add);

      final payload = const RewardResolved(
              achievementsToCheck: ['ACH_FIRST'])
          .toJsonString();
      bus.publish(RewardGranted(
          playerId: playerId, rewardResolvedJson: payload));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bus.publish(RewardGranted(
          playerId: playerId, rewardResolvedJson: payload));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final firstUnlocks =
          unlocked.where((e) => e.achievementKey == 'ACH_FIRST').length;
      expect(firstUnlocks, 1);
      await sub.cancel();
      await evSub.cancel();
    });

    test('reward null — emite AchievementUnlocked sem tocar em gold',
        () async {
      // Seeda uma conquista prévia pra satisfazer meta target_count=1.
      await PlayerAchievementsRepositoryDrift(db).markCompleted(
        playerId,
        'ACH_PRE',
        at: DateTime.now(),
      );
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'ACH_NO_REWARD',
            'name': 'x',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 1},
          },
        ]),
      });
      final sub = await service.attach();
      final unlocked = <AchievementUnlocked>[];
      final evSub = bus.on<AchievementUnlocked>().listen(unlocked.add);

      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['ACH_NO_REWARD'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(unlocked.any((e) => e.achievementKey == 'ACH_NO_REWARD'),
          isTrue);
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gold, 0);
      await sub.cancel();
      await evSub.cancel();
    });
  });

  group('AchievementsService — cascata', () {
    test('cascata profundidade 3 OK (A→B→C via achievementsToCheck)',
        () async {
      // Setup: A trigger meta 0-ish (seed prévio), reward de A aponta pra B,
      // B aponta pra C. Usamos meta/countCompleted crescente.
      final playerId = await _seedPlayer(db);
      await PlayerAchievementsRepositoryDrift(db).markCompleted(
        playerId,
        'ACH_SEED',
        at: DateTime.now(),
      ); // countCompleted=1

      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          // A: meta target 1 (já satisfeito por ACH_SEED)
          {
            'key': 'ACH_A',
            'name': 'A',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 1},
            'reward': {'gold': 10, 'achievements_to_check': ['ACH_B']},
          },
          // B: meta target 2 (A recém-completado → count=2)
          {
            'key': 'ACH_B',
            'name': 'B',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 2},
            'reward': {'gold': 20, 'achievements_to_check': ['ACH_C']},
          },
          // C: meta target 3 (B → count=3)
          {
            'key': 'ACH_C',
            'name': 'C',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 3},
          },
        ]),
      });
      final sub = await service.attach();
      final unlocked = <AchievementUnlocked>[];
      final evSub = bus.on<AchievementUnlocked>().listen(unlocked.add);

      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['ACH_A'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final keys = unlocked.map((e) => e.achievementKey).toSet();
      expect(keys, containsAll(['ACH_A', 'ACH_B', 'ACH_C']));
      await sub.cancel();
      await evSub.cancel();
    });

    test('cascata depth limit — 4º nível NÃO desbloqueia', () async {
      final playerId = await _seedPlayer(db);
      // Seeda 0 prévias. Cada unlock eleva o count.
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          // depth 0: count ≥ 0 (sempre true já que target_count deve ser ≥1
          // usamos seeds pra simular)
          {
            'key': 'A0',
            'name': 'n',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 1},
            'reward': {'achievements_to_check': ['A1']},
          },
          {
            'key': 'A1',
            'name': 'n',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 2},
            'reward': {'achievements_to_check': ['A2']},
          },
          {
            'key': 'A2',
            'name': 'n',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 3},
            'reward': {'achievements_to_check': ['A3']},
          },
          {
            'key': 'A3',
            'name': 'n',
            'description': '',
            'category': 'c',
            'trigger': {'type': 'meta', 'target_count': 4},
          },
        ]),
      });
      // Seed pra A0 passar (target 1).
      await PlayerAchievementsRepositoryDrift(db).markCompleted(
        playerId,
        'SEED',
        at: DateTime.now(),
      );
      final sub = await service.attach();
      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['A0'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final repo = PlayerAchievementsRepositoryDrift(db);
      // A0/A1/A2 desbloqueiam (depth 0/1/2). A3 (depth 3) é bloqueado.
      expect(await repo.isCompleted(playerId, 'A0'), isTrue);
      expect(await repo.isCompleted(playerId, 'A1'), isTrue);
      expect(await repo.isCompleted(playerId, 'A2'), isTrue);
      expect(await repo.isCompleted(playerId, 'A3'), isFalse);
      await sub.cancel();
    });
  });

  group('AchievementsService — integração listener via bus', () {
    test('RewardGranted com múltiplas keys processa todas', () async {
      final playerId = await _seedPlayer(db);
      await _setTotalQuests(db, playerId, 5);
      final service = _newService(db, bus, {
        AchievementsService.catalogAssetPath: _catalogJson([
          {
            'key': 'K1',
            'name': 'n',
            'description': '',
            'category': 'c',
            'trigger': {
              'type': 'event_count',
              'event': 'MissionCompleted',
              'count': 1,
            },
          },
          {
            'key': 'K5',
            'name': 'n',
            'description': '',
            'category': 'c',
            'trigger': {
              'type': 'event_count',
              'event': 'MissionCompleted',
              'count': 5,
            },
          },
        ]),
      });
      final sub = await service.attach();
      bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: const RewardResolved(
                achievementsToCheck: ['K1', 'K5'])
            .toJsonString(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final repo = PlayerAchievementsRepositoryDrift(db);
      expect(await repo.isCompleted(playerId, 'K1'), isTrue);
      expect(await repo.isCompleted(playerId, 'K5'), isTrue);
      await sub.cancel();
    });
  });
}
