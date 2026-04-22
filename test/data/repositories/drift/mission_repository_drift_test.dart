import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';

import '_repo_test_helpers.dart';

MissionProgress _newPending({
  int playerId = 1,
  String key = 'DAILY_PUSHUPS_E',
  MissionModality modality = MissionModality.real,
  MissionTabOrigin tab = MissionTabOrigin.daily,
  GuildRank rank = GuildRank.e,
  int target = 20,
  int current = 0,
}) {
  return MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: key,
    modality: modality,
    tabOrigin: tab,
    rank: rank,
    targetValue: target,
    currentValue: current,
    reward: const RewardDeclared(xp: 100, gold: 50),
    startedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    rewardClaimed: false,
    metaJson: '{}',
  );
}

void main() {
  late AppDatabase db;
  late MissionRepositoryDrift repo;

  setUp(() {
    db = newTestDb();
    repo = MissionRepositoryDrift(db);
  });
  tearDown(() async => db.close());

  test('insert + findById retorna com tipos fortes convertidos', () async {
    final id = await repo.insert(_newPending());
    final loaded = await repo.findById(id);
    expect(loaded, isNotNull);
    expect(loaded!.id, id);
    expect(loaded.modality, MissionModality.real);
    expect(loaded.tabOrigin, MissionTabOrigin.daily);
    expect(loaded.rank, GuildRank.e);
    expect(loaded.reward.xp, 100);
    expect(loaded.completedAt, isNull);
    expect(loaded.failedAt, isNull);
  });

  test('findById de id inexistente → null', () async {
    expect(await repo.findById(9999), isNull);
  });

  test('findActive filtra completed/failed', () async {
    final activeId = await repo.insert(_newPending(key: 'A'));
    final completedId = await repo.insert(_newPending(key: 'B'));
    final failedId = await repo.insert(_newPending(key: 'C'));
    await repo.markCompleted(completedId,
        at: DateTime.now(), rewardClaimed: true);
    await repo.markFailed(failedId, at: DateTime.now());

    final active = await repo.findActive(1);
    expect(active.map((m) => m.id).toSet(), {activeId});
  });

  test('findByTab retorna só da aba pedida', () async {
    await repo.insert(_newPending(key: 'D1', tab: MissionTabOrigin.daily));
    await repo.insert(_newPending(key: 'D2', tab: MissionTabOrigin.daily));
    await repo.insert(_newPending(key: 'C1', tab: MissionTabOrigin.classTab));

    final daily = await repo.findByTab(1, MissionTabOrigin.daily);
    final classTab = await repo.findByTab(1, MissionTabOrigin.classTab);
    expect(daily, hasLength(2));
    expect(classTab, hasLength(1));
    expect(
        daily.every((m) => m.tabOrigin == MissionTabOrigin.daily), isTrue);
  });

  test('updateProgress muda currentValue e opcionalmente metaJson',
      () async {
    final id = await repo.insert(_newPending());
    await repo.updateProgress(id, currentValue: 10);
    var loaded = await repo.findById(id);
    expect(loaded!.currentValue, 10);
    expect(loaded.metaJson, '{}', reason: 'metaJson preservado');

    await repo.updateProgress(id,
        currentValue: 15, metaJson: '{"requirements":[3,2]}');
    loaded = await repo.findById(id);
    expect(loaded!.currentValue, 15);
    expect(loaded.metaJson, '{"requirements":[3,2]}');
  });

  test('markCompleted seta completedAt e rewardClaimed', () async {
    final id = await repo.insert(_newPending());
    final at = DateTime.fromMillisecondsSinceEpoch(1700001000000);
    await repo.markCompleted(id, at: at, rewardClaimed: true);

    final loaded = await repo.findById(id);
    expect(loaded!.completedAt, at);
    expect(loaded.rewardClaimed, isTrue);
  });

  test('markFailed seta failedAt preservando currentValue', () async {
    final id = await repo.insert(_newPending());
    await repo.updateProgress(id, currentValue: 10);
    final at = DateTime.fromMillisecondsSinceEpoch(1700002000000);
    await repo.markFailed(id, at: at);

    final loaded = await repo.findById(id);
    expect(loaded!.failedAt, at);
    expect(loaded.currentValue, 10,
        reason: 'currentValue preservado pra histórico');
  });

  test('watchActive emite lista reativa', () async {
    final emissions = <int>[];
    final sub = repo
        .watchActive(1)
        .listen((list) => emissions.add(list.length));
    await pumpEventQueue();
    expect(emissions.last, 0);

    await repo.insert(_newPending(key: 'W1'));
    await pumpEventQueue();
    expect(emissions.last, 1);

    final id = await repo.insert(_newPending(key: 'W2'));
    await pumpEventQueue();
    expect(emissions.last, 2);

    await repo.markCompleted(id,
        at: DateTime.now(), rewardClaimed: true);
    await pumpEventQueue();
    expect(emissions.last, 1, reason: 'completa sai do active');

    await sub.cancel();
  });
}
