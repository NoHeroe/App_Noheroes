import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/mission_catalogs_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/data/repositories/drift/active_faction_quests_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/mission_preferences_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_achievements_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/data/services/reward_grant_service.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/services/daily_reset_service.dart';
import 'package:noheroes_app/domain/services/mission_assignment_service.dart';
import 'package:noheroes_app/domain/services/mission_preferences_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

Future<int> _seedPlayer(AppDatabase db, {int? lastDailyReset}) async {
  final id = await db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp) "
    "VALUES (?, ?, 'S', 5, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
    ],
  );
  if (lastDailyReset != null) {
    await db.customUpdate(
      'UPDATE players SET last_daily_reset = ? WHERE id = ?',
      variables: [Variable.withInt(lastDailyReset), Variable.withInt(id)],
      updates: {db.playersTable},
    );
  }
  return id;
}

Future<int> _seedActiveDaily(
  MissionRepositoryDrift repo,
  int playerId, {
  int currentValue = 0,
  int targetValue = 10,
  String? metaJson,
}) async {
  return repo.insert(MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: 'DAILY_TEST_${DateTime.now().microsecondsSinceEpoch}',
    modality: MissionModality.real,
    tabOrigin: MissionTabOrigin.daily,
    rank: GuildRank.e,
    targetValue: targetValue,
    currentValue: currentValue,
    reward: const RewardDeclared(xp: 10, gold: 5),
    startedAt: DateTime.now().subtract(const Duration(hours: 25)),
    rewardClaimed: false,
    metaJson: metaJson ?? '{}',
  ));
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late MissionRepositoryDrift repo;
  late PlayerDao playerDao;
  late DailyResetService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    repo = MissionRepositoryDrift(db);
    playerDao = PlayerDao(db);
    final catalog = ItemsCatalogService(db);
    final prefsService = MissionPreferencesService(
      repo: MissionPreferencesRepositoryDrift(db),
      bus: bus,
      db: db,
    );
    final assignment = MissionAssignmentService(
      missionRepo: repo,
      prefsService: prefsService,
      catalogs: MissionCatalogsService(), // não lê seeds neste teste
      factionRepo: ActiveFactionQuestsRepositoryDrift(db),
      bus: bus,
    );
    service = DailyResetService(
      db: db,
      missionRepo: repo,
      resolver: RewardResolveService(catalog),
      granter: RewardGrantService(
        db: db,
        missionRepo: repo,
        achievementsRepo: PlayerAchievementsRepositoryDrift(db),
        inventory: PlayerInventoryService(db, catalog),
        recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
        factionRep: PlayerFactionReputationRepositoryDrift(db),
        eventBus: bus,
      ),
      assignment: assignment,
      playerDao: playerDao,
      bus: bus,
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('DailyResetService.checkAndApply', () {
    test('<24h desde last_reset → noop', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final playerId = await _seedPlayer(db, lastDailyReset: now);

      final result = await service.checkAndApply(playerId);
      expect(result.applied, isFalse);
    });

    test(
        '≥24h + missão ≥25% → MissionPartial emit + completed, marks last_reset',
        () async {
      final playerId = await _seedPlayer(db);
      // currentValue=3 / targetValue=10 = 30% (>= 25% threshold)
      final missionId = await _seedActiveDaily(repo, playerId,
          currentValue: 3, targetValue: 10);

      final partials = <MissionPartial>[];
      final sub = bus.on<MissionPartial>().listen(partials.add);

      final result = await service.checkAndApply(playerId);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(result.applied, isTrue);
      expect(partials.length, greaterThanOrEqualTo(1));

      final mission = await repo.findById(missionId);
      expect(mission!.completedAt, isNotNull);
      // Verifica metaJson['partial'] = true
      final meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
      expect(meta['partial'], isTrue);

      // last_daily_reset atualizado
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.lastDailyReset, isNotNull);

      await sub.cancel();
    });

    test('≥24h + missão <25% → MissionFailed(expired)', () async {
      final playerId = await _seedPlayer(db);
      // currentValue=1 / targetValue=10 = 10% (< 25%)
      final missionId = await _seedActiveDaily(repo, playerId,
          currentValue: 1, targetValue: 10);

      final failures = <MissionFailed>[];
      final sub = bus.on<MissionFailed>().listen(failures.add);

      await service.checkAndApply(playerId);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(failures.any((e) => e.reason == MissionFailureReason.expired),
          isTrue);
      final mission = await repo.findById(missionId);
      expect(mission!.failedAt, isNotNull);
      expect(mission.completedAt, isNull);

      await sub.cancel();
    });

    test('sweep expired: deadline_at < now marca failed(expired)',
        () async {
      final playerId = await _seedPlayer(db);
      // Missão individual c/ deadline passado.
      final pastDeadline = DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      final metaJson = jsonEncode({'deadline_at': pastDeadline});
      final missionId = await repo.insert(MissionProgress(
        id: 0,
        playerId: playerId,
        missionKey: 'IND_EXPIRED',
        modality: MissionModality.individual,
        tabOrigin: MissionTabOrigin.extras,
        rank: GuildRank.e,
        targetValue: 10,
        currentValue: 0,
        reward: const RewardDeclared(xp: 5),
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        rewardClaimed: false,
        metaJson: metaJson,
      ));

      await service.checkAndApply(playerId);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final mission = await repo.findById(missionId);
      expect(mission!.failedAt, isNotNull,
          reason: 'deadline_at no passado deve disparar sweep');
    });
  });
}
