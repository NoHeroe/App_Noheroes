import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/balance/individual_delete_cost.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/exceptions/reward_exceptions.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/services/individual_delete_service.dart';

Future<int> _seedPlayer(AppDatabase db,
    {int gold = 0, int gems = 0}) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp) "
    "VALUES (?, ?, 'S', 1, 0, 100, ?, ?, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withInt(gold),
      Variable.withInt(gems),
    ],
  );
}

Future<int> _seedIndividual(
  MissionRepositoryDrift repo,
  int playerId, {
  GuildRank rank = GuildRank.e,
}) async {
  return repo.insert(MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: 'IND_TEST',
    modality: MissionModality.individual,
    tabOrigin: MissionTabOrigin.extras,
    rank: rank,
    targetValue: 10,
    currentValue: 0,
    reward: const RewardDeclared(),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: '{}',
  ));
}

Future<int> _seedInternal(
  MissionRepositoryDrift repo,
  int playerId,
) async {
  return repo.insert(MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: 'CLS_TEST',
    modality: MissionModality.internal,
    tabOrigin: MissionTabOrigin.classTab,
    rank: GuildRank.e,
    targetValue: 1,
    currentValue: 0,
    reward: const RewardDeclared(),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: '{}',
  ));
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late MissionRepositoryDrift repo;
  late IndividualDeleteService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    repo = MissionRepositoryDrift(db);
    service = IndividualDeleteService(db: db, missionRepo: repo, bus: bus);
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('IndividualDeleteService.costFor', () {
    test('rank E → 50 gold + 20 gems (placeholder)', () async {
      final playerId = await _seedPlayer(db);
      final mId = await _seedIndividual(repo, playerId, rank: GuildRank.e);
      final mission = (await repo.findById(mId))!;
      final cost = service.costFor(mission);
      expect(cost, const IndividualDeleteCost(gold: 50, gems: 20));
    });

    test('rank S → 1600 gold + 640 gems (placeholder)', () async {
      final playerId = await _seedPlayer(db);
      final mId = await _seedIndividual(repo, playerId, rank: GuildRank.s);
      final mission = (await repo.findById(mId))!;
      final cost = service.costFor(mission);
      expect(cost, const IndividualDeleteCost(gold: 1600, gems: 640));
    });
  });

  group('IndividualDeleteService.deleteIndividual', () {
    test('feliz: debita gold+gems, marca failed_at, emite 3 eventos',
        () async {
      final playerId = await _seedPlayer(db, gold: 100, gems: 50);
      final mId = await _seedIndividual(repo, playerId, rank: GuildRank.e);

      final gold = <GoldSpent>[];
      final gems = <GemsSpent>[];
      final fails = <MissionFailed>[];
      final subs = [
        bus.on<GoldSpent>().listen(gold.add),
        bus.on<GemsSpent>().listen(gems.add),
        bus.on<MissionFailed>().listen(fails.add),
      ];

      await service.deleteIndividual(
          playerId: playerId, missionProgressId: mId);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Saldo debitado (cost rank E = 50g + 20g).
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gold, 50);
      expect(row.gems, 30);

      // Mission marcada como failed (via markFailed do repo).
      final mission = await repo.findById(mId);
      expect(mission!.failedAt, isNotNull);

      // 3 eventos emitidos, corretos.
      expect(gold.single.amount, 50);
      expect(gold.single.source, GoldSink.individualDelete);
      expect(gems.single.amount, 20);
      expect(gems.single.source, GemSink.individualDelete);
      expect(fails.single.reason, MissionFailureReason.deletedByUser);
      expect(fails.single.missionKey, 'IND_TEST');

      for (final s in subs) {
        await s.cancel();
      }
    });

    test('gold insuficiente → InsufficientGoldException, nada muda',
        () async {
      final playerId = await _seedPlayer(db, gold: 30, gems: 50);
      final mId = await _seedIndividual(repo, playerId, rank: GuildRank.e);

      expect(
        () => service.deleteIndividual(
            playerId: playerId, missionProgressId: mId),
        throwsA(isA<InsufficientGoldException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Saldo intacto.
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gold, 30);
      expect(row.gems, 50);

      // Mission não foi marcada.
      final mission = await repo.findById(mId);
      expect(mission!.failedAt, isNull);
    });

    test('gems insuficientes → InsufficientGemsException, nada muda',
        () async {
      final playerId = await _seedPlayer(db, gold: 100, gems: 5);
      final mId = await _seedIndividual(repo, playerId, rank: GuildRank.e);

      expect(
        () => service.deleteIndividual(
            playerId: playerId, missionProgressId: mId),
        throwsA(isA<InsufficientGemsException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gold, 100);
      expect(row.gems, 5);
    });

    test('mission não-individual → NotIndividualMissionException', () async {
      final playerId = await _seedPlayer(db, gold: 1000, gems: 1000);
      final mId = await _seedInternal(repo, playerId);

      expect(
        () => service.deleteIndividual(
            playerId: playerId, missionProgressId: mId),
        throwsA(isA<NotIndividualMissionException>()),
      );
    });
  });
}
