import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/data/datasources/local/mission_catalogs_service.dart';
import 'package:noheroes_app/data/repositories/drift/active_faction_quests_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/mission_preferences_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/services/mission_assignment_service.dart';
import 'package:noheroes_app/domain/services/mission_preferences_service.dart';
import 'package:noheroes_app/domain/services/weekly_reset_service.dart';

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

Future<int> _seedPlayer(
  AppDatabase db, {
  String factionType = 'guild',
  int? lastWeeklyReset,
}) async {
  final id = await db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp, faction_type) "
    "VALUES (?, ?, 'S', 7, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, ?)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withString(factionType),
    ],
  );
  if (lastWeeklyReset != null) {
    await db.customUpdate(
      'UPDATE players SET last_weekly_reset = ? WHERE id = ?',
      variables: [Variable.withInt(lastWeeklyReset), Variable.withInt(id)],
      updates: {db.playersTable},
    );
  }
  return id;
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late MissionRepositoryDrift repo;
  late PlayerDao playerDao;
  late WeeklyResetService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    repo = MissionRepositoryDrift(db);
    playerDao = PlayerDao(db);
    final prefsService = MissionPreferencesService(
      repo: MissionPreferencesRepositoryDrift(db),
      bus: bus,
      db: db,
    );
    final assignment = MissionAssignmentService(
      missionRepo: repo,
      prefsService: prefsService,
      catalogs: MissionCatalogsService(
        bundle: _FakeBundle({
          'assets/data/missions_faction_weekly.json': jsonEncode({
            'missions': [
              {
                'key': 'FW_GUILD_1',
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
        }),
      ),
      factionRepo: ActiveFactionQuestsRepositoryDrift(db),
      bus: bus,
    );
    service = WeeklyResetService(
      missionRepo: repo,
      assignment: assignment,
      playerDao: playerDao,
      bus: bus,
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('WeeklyResetService.checkAndApply', () {
    test('<7d desde last_reset → noop', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final playerId = await _seedPlayer(db, lastWeeklyReset: now);
      final result = await service.checkAndApply(playerId);
      expect(result.applied, isFalse);
    });

    test('≥7d + factionType válido → reassigna + markWeeklyReset',
        () async {
      final playerId = await _seedPlayer(db); // factionType='guild', null reset
      final result = await service.checkAndApply(playerId);
      expect(result.applied, isTrue);
      expect(result.reassigned, isTrue);

      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.lastWeeklyReset, isNotNull);
    });

    test('factionType="pending:X" → reassign skipado silencioso', () async {
      final playerId = await _seedPlayer(db, factionType: 'pending:guild');
      final result = await service.checkAndApply(playerId);
      expect(result.applied, isTrue);
      expect(result.reassigned, isFalse,
          reason: 'pending:X não reassigna');
    });

    test('factionType="none" → reassign skipado', () async {
      final playerId = await _seedPlayer(db, factionType: 'none');
      final result = await service.checkAndApply(playerId);
      expect(result.reassigned, isFalse);
    });

    test('expira faction weekly ativas antigas', () async {
      final playerId = await _seedPlayer(db);
      // Missão weekly active antiga (não completa)
      final missionId = await repo.insert(MissionProgress(
        id: 0,
        playerId: playerId,
        missionKey: 'FW_OLD',
        modality: MissionModality.internal,
        tabOrigin: MissionTabOrigin.faction,
        rank: GuildRank.e,
        targetValue: 1,
        currentValue: 0,
        reward: const RewardDeclared(),
        startedAt: DateTime.now().subtract(const Duration(days: 8)),
        rewardClaimed: false,
        metaJson: '{}',
      ));

      final failures = <MissionFailed>[];
      final sub = bus.on<MissionFailed>().listen(failures.add);

      await service.checkAndApply(playerId);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final mission = await repo.findById(missionId);
      expect(mission!.failedAt, isNotNull);
      expect(
          failures.any((e) =>
              e.missionKey == 'FW_OLD' &&
              e.reason == MissionFailureReason.expired),
          isTrue);
      await sub.cancel();
    });
  });
}
