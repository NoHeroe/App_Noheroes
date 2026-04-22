import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/mission_preferences_repository_drift.dart';
import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_style.dart';
import 'package:noheroes_app/domain/models/mission_preferences.dart';

import '_repo_test_helpers.dart';

MissionPreferences _prefs({
  int playerId = 1,
  MissionCategory primary = MissionCategory.vitalismo,
  Intensity intensity = Intensity.medium,
  MissionStyle style = MissionStyle.mixed,
  int updatesCount = 0,
  List<String> physical = const [],
  List<String> mental = const [],
  List<String> spiritual = const [],
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return MissionPreferences(
    playerId: playerId,
    primaryFocus: primary,
    intensity: intensity,
    missionStyle: style,
    physicalSubfocus: physical,
    mentalSubfocus: mental,
    spiritualSubfocus: spiritual,
    timeDailyMinutes: 30,
    createdAt: now,
    updatedAt: now,
    updatesCount: updatesCount,
  );
}

void main() {
  late AppDatabase db;
  late MissionPreferencesRepositoryDrift repo;

  setUp(() {
    db = newTestDb();
    repo = MissionPreferencesRepositoryDrift(db);
  });
  tearDown(() async => db.close());

  test('findByPlayerId de jogador sem prefs → null', () async {
    expect(await repo.findByPlayerId(1), isNull);
  });

  test('upsert cria e findByPlayerId retorna com subfocus parseado',
      () async {
    await repo.upsert(_prefs(
      physical: ['forca', 'cardio'],
      mental: ['leitura'],
      spiritual: ['meditacao'],
    ));
    final loaded = await repo.findByPlayerId(1);
    expect(loaded, isNotNull);
    expect(loaded!.primaryFocus, MissionCategory.vitalismo);
    expect(loaded.physicalSubfocus, ['forca', 'cardio']);
    expect(loaded.mentalSubfocus, ['leitura']);
    expect(loaded.spiritualSubfocus, ['meditacao']);
    expect(loaded.updatesCount, 0);
  });

  test('upsert 2x atualiza em vez de duplicar', () async {
    await repo.upsert(_prefs(intensity: Intensity.light, updatesCount: 0));
    await repo.upsert(_prefs(intensity: Intensity.heavy, updatesCount: 1));
    final loaded = await repo.findByPlayerId(1);
    expect(loaded!.intensity, Intensity.heavy);
    expect(loaded.updatesCount, 1);
  });

  test('updatesCountOf retorna 0 quando não calibrou', () async {
    expect(await repo.updatesCountOf(1), 0);
  });

  test('updatesCountOf retorna valor atual', () async {
    await repo.upsert(_prefs(updatesCount: 2));
    expect(await repo.updatesCountOf(1), 2);
  });
}
