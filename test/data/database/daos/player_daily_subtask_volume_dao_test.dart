import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_daily_subtask_volume_dao.dart';

/// Sprint 3.3 Etapa 2.1a — DAO de volume por sub-task.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PlayerDailySubtaskVolumeDao dao;
  const playerId = 1;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = PlayerDailySubtaskVolumeDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('getVolume retorna 0 pra key inexistente', () async {
    expect(await dao.getVolume(playerId, 'flexao'), 0);
  });

  test('incrementVolume primeira chamada cria row', () async {
    await dao.incrementVolume(playerId, 'flexao', 20);
    expect(await dao.getVolume(playerId, 'flexao'), 20);
  });

  test('incrementVolume chamadas seguintes incrementam (UPSERT)', () async {
    await dao.incrementVolume(playerId, 'flexao', 20);
    await dao.incrementVolume(playerId, 'flexao', 15);
    await dao.incrementVolume(playerId, 'flexao', 5);
    expect(await dao.getVolume(playerId, 'flexao'), 40);
  });

  test('incrementVolume com delta=0 é noop', () async {
    await dao.incrementVolume(playerId, 'flexao', 10);
    await dao.incrementVolume(playerId, 'flexao', 0);
    expect(await dao.getVolume(playerId, 'flexao'), 10);
  });

  test('keys diferentes são independentes', () async {
    await dao.incrementVolume(playerId, 'flexao', 10);
    await dao.incrementVolume(playerId, 'abdominal', 25);
    await dao.incrementVolume(playerId, 'flexao', 5);
    expect(await dao.getVolume(playerId, 'flexao'), 15);
    expect(await dao.getVolume(playerId, 'abdominal'), 25);
  });

  test('getTotalVolume soma de todas as keys do player', () async {
    await dao.incrementVolume(playerId, 'flexao', 10);
    await dao.incrementVolume(playerId, 'abdominal', 25);
    await dao.incrementVolume(playerId, 'meditacao', 30);
    expect(await dao.getTotalVolume(playerId), 65);
  });

  test('getTotalVolume retorna 0 pra player sem rows', () async {
    expect(await dao.getTotalVolume(playerId), 0);
  });

  test('listByPlayer retorna todas as rows do player', () async {
    await dao.incrementVolume(playerId, 'flexao', 10);
    await dao.incrementVolume(playerId, 'abdominal', 25);
    await dao.incrementVolume(2, 'flexao', 999); // outro player
    final list = await dao.listByPlayer(playerId);
    expect(list.length, 2);
    final keys = list.map((v) => v.subTaskKey).toSet();
    expect(keys, {'flexao', 'abdominal'});
  });
}
