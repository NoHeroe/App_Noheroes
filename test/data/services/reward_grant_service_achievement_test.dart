import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/reward_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_achievements_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/data/services/reward_grant_service.dart';
import 'package:noheroes_app/domain/exceptions/reward_exceptions.dart';
import 'package:noheroes_app/domain/models/reward_resolved.dart';

Future<int> _seedPlayer(AppDatabase db) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp, total_quests_completed) "
    "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, "
    "0, 42)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
    ],
  );
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late RewardGrantService grantService;
  late PlayerAchievementsRepositoryDrift achRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    achRepo = PlayerAchievementsRepositoryDrift(db);
    final catalog = ItemsCatalogService(db);
    grantService = RewardGrantService(
      db: db,
      missionRepo: MissionRepositoryDrift(db),
      achievementsRepo: achRepo,
      inventory: PlayerInventoryService(db, catalog),
      recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
      factionRep: PlayerFactionReputationRepositoryDrift(db),
      eventBus: bus,
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('RewardGrantService.grantAchievement', () {
    test('credita xp/gold/gems + marca rewardClaimed + emite RewardGranted',
        () async {
      final playerId = await _seedPlayer(db);
      await achRepo.markCompleted(playerId, 'ACH_K',
          at: DateTime.now());

      final captured = <RewardGranted>[];
      final evSub = bus.on<RewardGranted>().listen(captured.add);

      await grantService.grantAchievement(
        playerId: playerId,
        achievementKey: 'ACH_K',
        resolved: const RewardResolved(xp: 50, gold: 30, gems: 2),
      );

      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.xp, 50);
      expect(row.gold, 30);
      expect(row.gems, 2);
      expect(await achRepo.isRewardClaimed(playerId, 'ACH_K'), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(captured.length, 1);
      expect(captured.first.playerId, playerId);

      await evSub.cancel();
    });

    test('NÃO incrementa total_quests_completed (contador de missões)',
        () async {
      final playerId = await _seedPlayer(db);
      await achRepo.markCompleted(playerId, 'ACH_K',
          at: DateTime.now());
      final beforeRow = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(beforeRow.totalQuestsCompleted, 42);

      await grantService.grantAchievement(
        playerId: playerId,
        achievementKey: 'ACH_K',
        resolved: const RewardResolved(gold: 5),
      );

      final afterRow = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      // Inalterado — contador é pra missões, não conquistas.
      expect(afterRow.totalQuestsCompleted, 42);
    });

    test('conquista não desbloqueada antes → AchievementNotUnlockedException',
        () async {
      final playerId = await _seedPlayer(db);
      expect(
        () => grantService.grantAchievement(
          playerId: playerId,
          achievementKey: 'ACH_X',
          resolved: const RewardResolved(gold: 10),
        ),
        throwsA(isA<AchievementNotUnlockedException>()),
      );
    });

    test('reward já claimed → AchievementRewardAlreadyGrantedException',
        () async {
      final playerId = await _seedPlayer(db);
      await achRepo.markCompleted(playerId, 'ACH_K',
          at: DateTime.now());
      await grantService.grantAchievement(
        playerId: playerId,
        achievementKey: 'ACH_K',
        resolved: const RewardResolved(gold: 10),
      );
      expect(
        () => grantService.grantAchievement(
          playerId: playerId,
          achievementKey: 'ACH_K',
          resolved: const RewardResolved(gold: 10),
        ),
        throwsA(isA<AchievementRewardAlreadyGrantedException>()),
      );
    });
  });
}
