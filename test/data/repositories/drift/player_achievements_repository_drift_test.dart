import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/player_achievements_repository_drift.dart';

import '_repo_test_helpers.dart';

void main() {
  late AppDatabase db;
  late PlayerAchievementsRepositoryDrift repo;

  setUp(() {
    db = newTestDb();
    repo = PlayerAchievementsRepositoryDrift(db);
  });
  tearDown(() async => db.close());

  test('isCompleted de chave não registrada → false', () async {
    expect(await repo.isCompleted(1, 'ACH_X'), isFalse);
  });

  test('markCompleted + isCompleted funciona', () async {
    await repo.markCompleted(1, 'ACH_FIRST_CRAFT',
        at: DateTime.fromMillisecondsSinceEpoch(1700000000000));
    expect(await repo.isCompleted(1, 'ACH_FIRST_CRAFT'), isTrue);
    expect(await repo.isCompleted(1, 'ACH_OUTRA'), isFalse);
  });

  test('markCompleted é idempotente (insertOrIgnore)', () async {
    await repo.markCompleted(1, 'ACH_DUP',
        at: DateTime.fromMillisecondsSinceEpoch(1700000000000));
    await repo.markCompleted(1, 'ACH_DUP',
        at: DateTime.fromMillisecondsSinceEpoch(1700001000000));
    expect(await repo.countCompleted(1), 1);
  });

  test('listCompletedKeys ordena por completedAt desc (recente primeiro)',
      () async {
    await repo.markCompleted(1, 'A',
        at: DateTime.fromMillisecondsSinceEpoch(1700000000000));
    await repo.markCompleted(1, 'B',
        at: DateTime.fromMillisecondsSinceEpoch(1700002000000));
    await repo.markCompleted(1, 'C',
        at: DateTime.fromMillisecondsSinceEpoch(1700001000000));
    final keys = await repo.listCompletedKeys(1);
    expect(keys, ['B', 'C', 'A']);
  });

  test('listCompletedKeys filtra por player', () async {
    await repo.markCompleted(1, 'A', at: DateTime.now());
    await repo.markCompleted(2, 'B', at: DateTime.now());
    expect(await repo.listCompletedKeys(1), ['A']);
    expect(await repo.listCompletedKeys(2), ['B']);
  });

  test('markRewardClaimed atualiza flag sem mexer em outra linha',
      () async {
    await repo.markCompleted(1, 'A', at: DateTime.now());
    await repo.markCompleted(1, 'B', at: DateTime.now());
    await repo.markRewardClaimed(1, 'A');

    final rows = await db.select(db.playerAchievementsCompletedTable).get();
    final a = rows.firstWhere((r) => r.achievementKey == 'A');
    final b = rows.firstWhere((r) => r.achievementKey == 'B');
    expect(a.rewardClaimed, isTrue);
    expect(b.rewardClaimed, isFalse);
  });

  test('countCompleted por player', () async {
    await repo.markCompleted(1, 'A', at: DateTime.now());
    await repo.markCompleted(1, 'B', at: DateTime.now());
    await repo.markCompleted(2, 'C', at: DateTime.now());
    expect(await repo.countCompleted(1), 2);
    expect(await repo.countCompleted(2), 1);
    expect(await repo.countCompleted(999), 0);
  });
}
