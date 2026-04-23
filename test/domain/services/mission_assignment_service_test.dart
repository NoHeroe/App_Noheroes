import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/mission_catalogs_service.dart';
import 'package:noheroes_app/data/repositories/drift/active_faction_quests_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/mission_preferences_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_style.dart';
import 'package:noheroes_app/domain/models/mission_preferences.dart';
import 'package:noheroes_app/domain/services/mission_assignment_service.dart';
import 'package:noheroes_app/domain/services/mission_preferences_service.dart';

class _FakeBundle extends AssetBundle {
  final Map<String, String> contents;
  _FakeBundle(this.contents);

  @override
  Future<ByteData> load(String key) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(s)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return s;
  }
}

Future<int> _seedPlayer(AppDatabase db) async {
  return db.customInsert(
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
}

MissionPreferences _prefs(int playerId, {
  MissionCategory focus = MissionCategory.fisico,
  MissionStyle style = MissionStyle.real,
}) {
  final now = DateTime.now();
  return MissionPreferences(
    playerId: playerId,
    primaryFocus: focus,
    intensity: Intensity.medium,
    missionStyle: style,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late MissionRepositoryDrift missionRepo;
  late MissionPreferencesService prefsService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    missionRepo = MissionRepositoryDrift(db);
    prefsService = MissionPreferencesService(
      repo: MissionPreferencesRepositoryDrift(db),
      bus: bus,
      db: db,
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  MissionAssignmentService makeService(_FakeBundle bundle) {
    return MissionAssignmentService(
      missionRepo: missionRepo,
      prefsService: prefsService,
      catalogs: MissionCatalogsService(bundle: bundle),
      factionRepo: ActiveFactionQuestsRepositoryDrift(db),
      bus: bus,
      random: Random(42),
    );
  }

  group('assignDailyForPlayer', () {
    test('sem prefs → lista vazia', () async {
      final playerId = await _seedPlayer(db);
      final service = makeService(_FakeBundle({
        'assets/data/missions_daily.json': jsonEncode({
          'missions': [
            {
              'key': 'D_E',
              'title': 't',
              'description': 'd',
              'modality': 'real',
              'category': 'fisico',
              'rank': 'e',
              'target_value': 10,
              'reward': {'xp': 10}
            },
          ],
        }),
      }));
      final ids = await service.assignDailyForPlayer(
          playerId: playerId, playerRank: GuildRank.e);
      expect(ids, isEmpty);
    });

    test('feliz: 3 missões criadas + MissionStarted emit', () async {
      final playerId = await _seedPlayer(db);
      await prefsService.save(_prefs(playerId));
      final captured = <MissionStarted>[];
      final sub = bus.on<MissionStarted>().listen(captured.add);

      final service = makeService(_FakeBundle({
        'assets/data/missions_daily.json': jsonEncode({
          'missions': [
            for (var i = 0; i < 5; i++)
              {
                'key': 'D_$i',
                'title': 't$i',
                'description': 'd',
                'modality': 'real',
                'category': 'fisico',
                'rank': 'e',
                'target_value': 10,
                'reward': {'xp': 10}
              },
          ],
        }),
      }));
      final ids = await service.assignDailyForPlayer(
          playerId: playerId, playerRank: GuildRank.e);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(ids.length, 3);
      expect(captured.length, 3);
      final active = await missionRepo.findActive(playerId);
      expect(active.length, 3);
      await sub.cancel();
    });

    test('rank gating: jogador E NÃO recebe rank B', () async {
      final playerId = await _seedPlayer(db);
      await prefsService.save(_prefs(playerId));
      final service = makeService(_FakeBundle({
        'assets/data/missions_daily.json': jsonEncode({
          'missions': [
            for (var i = 0; i < 3; i++)
              {
                'key': 'D_B_$i',
                'title': 't',
                'description': 'd',
                'modality': 'real',
                'category': 'fisico',
                'rank': 'b',
                'target_value': 10,
                'reward': {'xp': 10}
              },
          ],
        }),
      }));
      final ids = await service.assignDailyForPlayer(
          playerId: playerId, playerRank: GuildRank.e);
      expect(ids, isEmpty,
          reason: 'jogador E não pode receber rank B');
    });

    test('mission_style=internal filtra só modality=internal',
        () async {
      final playerId = await _seedPlayer(db);
      await prefsService.save(_prefs(playerId, style: MissionStyle.internal));
      final service = makeService(_FakeBundle({
        'assets/data/missions_daily.json': jsonEncode({
          'missions': [
            {
              'key': 'REAL',
              'title': 't',
              'description': 'd',
              'modality': 'real',
              'category': 'fisico',
              'rank': 'e',
              'target_value': 10,
              'reward': {'xp': 10}
            },
            {
              'key': 'INT1',
              'title': 't',
              'description': 'd',
              'modality': 'internal',
              'category': 'fisico',
              'rank': 'e',
              'target_value': 1,
              'reward': {'xp': 10}
            },
            {
              'key': 'INT2',
              'title': 't',
              'description': 'd',
              'modality': 'internal',
              'category': 'fisico',
              'rank': 'e',
              'target_value': 1,
              'reward': {'xp': 10}
            },
          ],
        }),
      }));
      final ids = await service.assignDailyForPlayer(
          playerId: playerId, playerRank: GuildRank.e);
      // 2 internal + 1 real → filtro retira real → só 2 internal passam
      expect(ids.length, 2);
      final active = await missionRepo.findActive(playerId);
      expect(active.every((m) => m.modality == MissionModality.internal),
          isTrue);
    });
  });

  group('assignClassDaily', () {
    test('filtra por classKey + cria 3 missions', () async {
      final playerId = await _seedPlayer(db);
      final service = makeService(_FakeBundle({
        'assets/data/missions_class.json': jsonEncode({
          'missions': [
            for (var i = 0; i < 3; i++)
              {
                'key': 'CW_$i',
                'title': 't',
                'description': 'd',
                'modality': 'internal',
                'class_key': 'warrior',
                'rank': 'e',
                'target_value': 1,
                'reward': {'xp': 50}
              },
            // Entry de outra classe — não deve entrar
            {
              'key': 'CM_1',
              'title': 't',
              'description': 'd',
              'modality': 'internal',
              'class_key': 'monk',
              'rank': 'e',
              'target_value': 1,
              'reward': {'xp': 50}
            },
          ],
        }),
      }));
      final ids = await service.assignClassDaily(
        playerId: playerId,
        classKey: 'warrior',
        playerRank: GuildRank.e,
      );
      expect(ids.length, 3);
      final active = await missionRepo.findActive(playerId);
      expect(
          active.every((m) => m.missionKey.startsWith('CW_')), isTrue);
    });
  });

  group('ensureWeeklyFactionQuest', () {
    test('idempotente: chamada 2x na mesma semana → 1 row criada',
        () async {
      final playerId = await _seedPlayer(db);
      final service = makeService(_FakeBundle({
        'assets/data/missions_faction_weekly.json': jsonEncode({
          'missions': [
            {
              'key': 'FW_1',
              'title': 't',
              'description': 'd',
              'modality': 'internal',
              'faction_key': 'guild',
              'rank': 'e',
              'target_value': 1,
              'reward': {'xp': 100}
            },
          ],
        }),
      }));
      final id1 = await service.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: 'guild',
        playerRank: GuildRank.e,
      );
      final id2 = await service.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: 'guild',
        playerRank: GuildRank.e,
      );
      expect(id1, isNotNull);
      expect(id2, isNotNull);
      expect(id1, id2, reason: 'idempotência pela UNIQUE constraint');
    });
  });
}
