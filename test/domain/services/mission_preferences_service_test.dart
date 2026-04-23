import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/mission_preferences_repository_drift.dart';
import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_style.dart';
import 'package:noheroes_app/domain/exceptions/reward_exceptions.dart';
import 'package:noheroes_app/domain/models/mission_preferences.dart';
import 'package:noheroes_app/domain/services/mission_preferences_service.dart';

Future<int> _seedPlayer(AppDatabase db, {int level = 5, int gems = 0}) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp) "
    "VALUES (?, ?, 'Sombra', ?, 0, 100, 0, ?, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withInt(level),
      Variable.withInt(gems),
    ],
  );
}

MissionPreferences _samplePrefs(int playerId, {
  MissionCategory focus = MissionCategory.fisico,
  List<String> physical = const ['Força'],
  List<String> mental = const [],
  List<String> spiritual = const [],
  int time = 30,
}) {
  final now = DateTime.now();
  return MissionPreferences(
    playerId: playerId,
    primaryFocus: focus,
    intensity: Intensity.medium,
    missionStyle: MissionStyle.real,
    physicalSubfocus: physical,
    mentalSubfocus: mental,
    spiritualSubfocus: spiritual,
    timeDailyMinutes: time,
    createdAt: now,
    updatedAt: now,
  );
}

MissionPreferencesService _makeService(AppDatabase db, AppEventBus bus) {
  return MissionPreferencesService(
    repo: MissionPreferencesRepositoryDrift(db),
    bus: bus,
    db: db,
  );
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late MissionPreferencesService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    service = _makeService(db, bus);
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('MissionPreferences.withPrimaryFocus (wipe condicional)', () {
    test('Físico → zera mental e spiritual, preserva physical', () {
      final p = _samplePrefs(
        1,
        focus: MissionCategory.vitalismo,
        physical: const ['Força', 'Cardio'],
        mental: const ['Leitura'],
        spiritual: const ['Meditação'],
      );
      final next = p.withPrimaryFocus(MissionCategory.fisico);
      expect(next.primaryFocus, MissionCategory.fisico);
      expect(next.physicalSubfocus, ['Força', 'Cardio']);
      expect(next.mentalSubfocus, isEmpty);
      expect(next.spiritualSubfocus, isEmpty);
    });

    test('Mental → zera physical e spiritual', () {
      final p = _samplePrefs(
        1,
        focus: MissionCategory.vitalismo,
        physical: const ['Força'],
        mental: const ['Leitura', 'Estudo'],
        spiritual: const ['Meditação'],
      );
      final next = p.withPrimaryFocus(MissionCategory.mental);
      expect(next.physicalSubfocus, isEmpty);
      expect(next.mentalSubfocus, ['Leitura', 'Estudo']);
      expect(next.spiritualSubfocus, isEmpty);
    });

    test('Espiritual → zera physical e mental', () {
      final p = _samplePrefs(
        1,
        focus: MissionCategory.vitalismo,
        physical: const ['Força'],
        mental: const ['Leitura'],
        spiritual: const ['Meditação', 'Ritual'],
      );
      final next = p.withPrimaryFocus(MissionCategory.espiritual);
      expect(next.physicalSubfocus, isEmpty);
      expect(next.mentalSubfocus, isEmpty);
      expect(next.spiritualSubfocus, ['Meditação', 'Ritual']);
    });

    test('Vitalismo → preserva TODOS subfocus', () {
      final p = _samplePrefs(
        1,
        focus: MissionCategory.fisico,
        physical: const ['Força'],
      );
      final next = p.withPrimaryFocus(MissionCategory.vitalismo);
      expect(next.primaryFocus, MissionCategory.vitalismo);
      expect(next.physicalSubfocus, ['Força']);
      expect(next.mentalSubfocus, isEmpty);
      expect(next.spiritualSubfocus, isEmpty);
    });
  });

  group('MissionPreferencesService — save + query', () {
    test('save novo → row persistida, updatesCount=0, evento emitido',
        () async {
      final playerId = await _seedPlayer(db);
      final captured = <MissionPreferencesChanged>[];
      final evSub = bus.on<MissionPreferencesChanged>().listen(captured.add);

      await service.save(_samplePrefs(playerId));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final persisted = await service.findCurrent(playerId);
      expect(persisted, isNotNull);
      expect(persisted!.updatesCount, 0);
      expect(captured.length, 1);
      expect(captured.first.playerId, playerId);
      await evSub.cancel();
    });

    test('save existente → incrementa updatesCount + preserva createdAt',
        () async {
      final playerId = await _seedPlayer(db);
      final originalCreatedAt =
          DateTime.now().subtract(const Duration(days: 3));
      final firstPrefs = MissionPreferences(
        playerId: playerId,
        primaryFocus: MissionCategory.fisico,
        intensity: Intensity.medium,
        missionStyle: MissionStyle.real,
        createdAt: originalCreatedAt,
        updatedAt: originalCreatedAt,
      );
      await service.save(firstPrefs);

      final retry = _samplePrefs(
        playerId,
        focus: MissionCategory.mental,
        time: 60,
      );
      await service.save(retry);

      final persisted = await service.findCurrent(playerId);
      expect(persisted!.updatesCount, 1);
      expect(persisted.primaryFocus, MissionCategory.mental);
      expect(persisted.timeDailyMinutes, 60);
      expect(
        persisted.createdAt.millisecondsSinceEpoch,
        originalCreatedAt.millisecondsSinceEpoch,
      );
    });

    test('save 3x → updatesCount chega a 2', () async {
      final playerId = await _seedPlayer(db);
      await service.save(_samplePrefs(playerId));
      await service.save(_samplePrefs(playerId));
      await service.save(_samplePrefs(playerId));
      expect(await service.currentUpdatesCount(playerId), 2);
    });

    test('hasValidPreferences: false antes de save, true depois', () async {
      final playerId = await _seedPlayer(db);
      expect(await service.hasValidPreferences(playerId), isFalse);
      await service.save(_samplePrefs(playerId));
      expect(await service.hasValidPreferences(playerId), isTrue);
    });

    test('currentUpdatesCount=0 quando nunca calibrou', () async {
      final playerId = await _seedPlayer(db);
      expect(await service.currentUpdatesCount(playerId), 0);
    });
  });

  group('MissionPreferencesService — costForRecalibration tiers', () {
    test('updatesCount=0 → free (1ª refazer, grandfathered)', () {
      final cost = service.costForRecalibration(0);
      expect(cost.isFree, isTrue);
      expect(cost.gems, 0);
      expect(cost.seivas, 0);
    });

    test('updatesCount=1 → 100 gems + 1 seiva (2ª refazer)', () {
      final cost = service.costForRecalibration(1);
      expect(cost.gems, 100);
      expect(cost.seivas, 1);
      expect(cost.isFree, isFalse);
    });

    test('updatesCount=2 → 300 gems + 3 seivas (3ª refazer)', () {
      final cost = service.costForRecalibration(2);
      expect(cost.gems, 300);
      expect(cost.seivas, 3);
    });

    test('updatesCount=10 → ainda 300 gems + 3 seivas (cap)', () {
      final cost = service.costForRecalibration(10);
      expect(cost.gems, 300);
      expect(cost.seivas, 3);
    });

    test('updatesCount negativo defensivo → free', () {
      final cost = service.costForRecalibration(-1);
      expect(cost.isFree, isTrue);
    });
  });

  group('MissionPreferencesService — canRecalibrate (gate lvl 10)', () {
    test('lvl 5 → false mesmo com prefs válidas', () async {
      final playerId = await _seedPlayer(db, level: 5);
      await service.save(_samplePrefs(playerId));
      final can = await service.canRecalibrate(
          playerId: playerId, playerLevel: 5);
      expect(can, isFalse);
    });

    test('lvl 10 sem prefs → false (nunca calibrou)', () async {
      final playerId = await _seedPlayer(db, level: 10);
      final can = await service.canRecalibrate(
          playerId: playerId, playerLevel: 10);
      expect(can, isFalse);
    });

    test('lvl 10 com prefs → true', () async {
      final playerId = await _seedPlayer(db, level: 10);
      await service.save(_samplePrefs(playerId));
      final can = await service.canRecalibrate(
          playerId: playerId, playerLevel: 10);
      expect(can, isTrue);
    });

    test('lvl 9 com prefs → false (gate hard)', () async {
      final playerId = await _seedPlayer(db, level: 9);
      await service.save(_samplePrefs(playerId));
      final can = await service.canRecalibrate(
          playerId: playerId, playerLevel: 9);
      expect(can, isFalse);
    });
  });

  group('MissionPreferencesService — chargeRecalibration', () {
    test('cost.free → noop, não debita, sem evento', () async {
      final playerId = await _seedPlayer(db, gems: 50);
      final captured = <GemsSpent>[];
      final evSub = bus.on<GemsSpent>().listen(captured.add);

      await service.chargeRecalibration(playerId,
          const RecalibrationCost.free());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gems, 50);
      expect(captured, isEmpty);
      await evSub.cancel();
    });

    test('cost 100g+1s com saldo 150 → debita gems + emite GemsSpent',
        () async {
      final playerId = await _seedPlayer(db, gems: 150);
      final captured = <GemsSpent>[];
      final evSub = bus.on<GemsSpent>().listen(captured.add);

      await service.chargeRecalibration(playerId,
          const RecalibrationCost(gems: 100, seivas: 1));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gems, 50);
      expect(captured.length, 1);
      expect(captured.first.amount, 100);
      expect(captured.first.source, GemSink.recalibration);
      expect(captured.first.playerId, playerId);
      await evSub.cancel();
    });

    test('cost 100 com saldo 50 → InsufficientGemsException, sem debitar',
        () async {
      final playerId = await _seedPlayer(db, gems: 50);
      expect(
        () => service.chargeRecalibration(playerId,
            const RecalibrationCost(gems: 100, seivas: 1)),
        throwsA(isA<InsufficientGemsException>()),
      );
      // Espera a exception propagar e confere que saldo está intacto.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gems, 50);
    });

    test('cost 300 com saldo exato → debita até zerar', () async {
      final playerId = await _seedPlayer(db, gems: 300);
      await service.chargeRecalibration(playerId,
          const RecalibrationCost(gems: 300, seivas: 3));
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gems, 0);
    });
  });

  group('MissionPreferencesService — edge de subfocus condicional', () {
    test('Vitalismo com 3 subfocus em cada categoria round-trip', () async {
      final playerId = await _seedPlayer(db);
      final prefs = _samplePrefs(
        playerId,
        focus: MissionCategory.vitalismo,
        physical: const ['Força', 'Cardio', 'Sono'],
        mental: const ['Leitura', 'Estudo', 'Criatividade'],
        spiritual: const ['Meditação', 'Journaling', 'Ritual'],
      );
      await service.save(prefs);
      final persisted = await service.findCurrent(playerId);
      expect(persisted!.physicalSubfocus.length, 3);
      expect(persisted.mentalSubfocus.length, 3);
      expect(persisted.spiritualSubfocus.length, 3);
    });

    test('Físico com apenas physicalSubfocus preenchido round-trip',
        () async {
      final playerId = await _seedPlayer(db);
      final prefs = _samplePrefs(
        playerId,
        focus: MissionCategory.fisico,
        physical: const ['Cardio', 'Flexibilidade'],
      );
      await service.save(prefs);
      final persisted = await service.findCurrent(playerId);
      expect(persisted!.physicalSubfocus, ['Cardio', 'Flexibilidade']);
      expect(persisted.mentalSubfocus, isEmpty);
      expect(persisted.spiritualSubfocus, isEmpty);
    });
  });
}
