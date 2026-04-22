import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';

import '_repo_test_helpers.dart';

void main() {
  late AppDatabase db;
  late PlayerFactionReputationRepositoryDrift repo;

  setUp(() {
    db = newTestDb();
    repo = PlayerFactionReputationRepositoryDrift(db);
  });
  tearDown(() async => db.close());

  test('getOrDefault sem linha → 50 neutro', () async {
    expect(await repo.getOrDefault(1, 'noryan'), 50);
  });

  test('setAbsolute cria e getOrDefault lê', () async {
    await repo.setAbsolute(1, 'noryan', 70);
    expect(await repo.getOrDefault(1, 'noryan'), 70);
  });

  test('setAbsolute clampa em 0..100', () async {
    await repo.setAbsolute(1, 'noryan', 150);
    expect(await repo.getOrDefault(1, 'noryan'), 100);
    await repo.setAbsolute(1, 'noryan', -20);
    expect(await repo.getOrDefault(1, 'noryan'), 0);
  });

  test('setAbsolute em linha existente faz update', () async {
    await repo.setAbsolute(1, 'noryan', 30);
    await repo.setAbsolute(1, 'noryan', 40);
    expect(await repo.getOrDefault(1, 'noryan'), 40);
  });

  test('delta cria linha com default e aplica', () async {
    await repo.delta(1, 'noryan', 5);
    expect(await repo.getOrDefault(1, 'noryan'), 55);
  });

  test('delta clampa', () async {
    await repo.setAbsolute(1, 'noryan', 95);
    await repo.delta(1, 'noryan', 20);
    expect(await repo.getOrDefault(1, 'noryan'), 100);

    await repo.setAbsolute(1, 'noryan', 5);
    await repo.delta(1, 'noryan', -20);
    expect(await repo.getOrDefault(1, 'noryan'), 0);
  });

  test('findAllByPlayer retorna todas facções do jogador', () async {
    await repo.setAbsolute(1, 'noryan', 70);
    await repo.setAbsolute(1, 'silente', 30);
    await repo.setAbsolute(2, 'noryan', 100);

    final all = await repo.findAllByPlayer(1);
    expect(all, {'noryan': 70, 'silente': 30});
  });
}
