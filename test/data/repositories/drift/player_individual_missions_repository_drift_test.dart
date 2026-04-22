import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/player_individual_missions_repository_drift.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/models/individual_mission_spec.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';

import '_repo_test_helpers.dart';

IndividualMissionSpec _spec({
  int playerId = 1,
  String name = 'Ler 30 páginas',
  MissionCategory category = MissionCategory.mental,
  int intensity = 2,
  IndividualMissionFrequency freq = IndividualMissionFrequency.daily,
  bool repeats = true,
  DateTime? deletedAt,
}) {
  return IndividualMissionSpec(
    id: 0,
    playerId: playerId,
    name: name,
    category: category,
    intensityIndex: intensity,
    frequency: freq,
    repeats: repeats,
    reward: const RewardDeclared(xp: 40, gold: 15),
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    deletedAt: deletedAt,
  );
}

void main() {
  late AppDatabase db;
  late PlayerIndividualMissionsRepositoryDrift repo;

  setUp(() {
    db = newTestDb();
    repo = PlayerIndividualMissionsRepositoryDrift(db);
  });
  tearDown(() async => db.close());

  test('insert + findById retorna com tipos fortes', () async {
    final id = await repo.insert(_spec());
    final loaded = await repo.findById(id);
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Ler 30 páginas');
    expect(loaded.category, MissionCategory.mental);
    expect(loaded.intensityIndex, 2);
    expect(loaded.frequency, IndividualMissionFrequency.daily);
    expect(loaded.reward.xp, 40);
    expect(loaded.isDeleted, isFalse);
  });

  test('findActive filtra deletadas', () async {
    final activeId = await repo.insert(_spec(name: 'A'));
    final deletedId = await repo.insert(_spec(name: 'B'));
    await repo.softDelete(deletedId,
        at: DateTime.fromMillisecondsSinceEpoch(1700001000000));

    final list = await repo.findActive(1);
    expect(list.map((m) => m.id).toSet(), {activeId});
  });

  test('findActive ordena por createdAt desc', () async {
    // A inserido primeiro (created_at menor).
    await repo.insert(_spec(name: 'A'));
    // Segunda inserção com created_at explicitamente maior.
    final later = IndividualMissionSpec(
      id: 0,
      playerId: 1,
      name: 'B',
      category: MissionCategory.mental,
      intensityIndex: 2,
      frequency: IndividualMissionFrequency.daily,
      reward: const RewardDeclared(xp: 40, gold: 15),
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700002000000),
    );
    await repo.insert(later);

    final list = await repo.findActive(1);
    expect(list.first.name, 'B', reason: 'mais recente no topo');
    expect(list.last.name, 'A');
  });

  test('softDelete preserva linha com deletedAt preenchido', () async {
    final id = await repo.insert(_spec());
    await repo.softDelete(id,
        at: DateTime.fromMillisecondsSinceEpoch(1700003000000));

    final loaded = await repo.findById(id);
    expect(loaded, isNotNull);
    expect(loaded!.isDeleted, isTrue);
    expect(loaded.deletedAt?.millisecondsSinceEpoch, 1700003000000);
  });

  test('updateCounters atualiza completionCount e failureCount', () async {
    final id = await repo.insert(_spec());
    await repo.updateCounters(id, completionCount: 3, failureCount: 1);

    final loaded = await repo.findById(id);
    expect(loaded!.completionCount, 3);
    expect(loaded.failureCount, 1);
  });

  test('countActive só conta não-deletadas do player', () async {
    await repo.insert(_spec(name: 'A'));
    await repo.insert(_spec(name: 'B'));
    final deletedId = await repo.insert(_spec(name: 'C'));
    await repo.softDelete(deletedId, at: DateTime.now());
    await repo.insert(_spec(playerId: 2, name: 'D'));

    expect(await repo.countActive(1), 2);
    expect(await repo.countActive(2), 1);
    expect(await repo.countActive(999), 0);
  });
}
