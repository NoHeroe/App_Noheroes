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
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/services/mission_assignment_service.dart';
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
    final assignment = MissionAssignmentService(
      missionRepo: repo,
      catalogs: MissionCatalogsService(
        bundle: _FakeBundle({
          // FATIA B4 — formato per-facção, SEM rank/reward (vêm do assign).
          'assets/data/missions_faction_weekly.json': jsonEncode({
            'guild': [
              {
                'id': 'WK_GUILD_1',
                'title': 't',
                'description': 'd',
                'sub_tasks': [
                  {
                    'sub_type': 'modality_count_window',
                    'target': 12,
                    'label': '12 quaisquer'
                  },
                ],
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

    test('FATIA B4 self-healing: factionId válido + assign null → NÃO '
        'marca timestamp (re-tenta no próximo boot)', () async {
      // factionType válido (moon_clan ∈ kKnownFactions) MAS sem pool no
      // fixture (só 'guild') → ensureWeeklyFactionQuest retorna null.
      final playerId = await _seedPlayer(db, factionType: 'moon_clan');
      final result = await service.checkAndApply(playerId);
      expect(result.applied, isTrue);
      expect(result.reassigned, isFalse, reason: 'assign retornou null');

      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.lastWeeklyReset, isNull,
          reason: 'NÃO marca → destrava no próximo boot');
    });

    test('factionType="pending:X" → reassign skipado + NÃO marca timestamp',
        () async {
      final playerId = await _seedPlayer(db, factionType: 'pending:guild');
      final result = await service.checkAndApply(playerId);
      // Fix noop-trap: branch sem facção real não completa ciclo nem marca.
      expect(result.applied, isFalse);
      expect(result.reassigned, isFalse,
          reason: 'pending:X não reassigna');

      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.lastWeeklyReset, isNull,
          reason: 'Fix noop-trap: sem facção → NÃO marca (re-tenta no boot)');
    });

    test('factionType="none" → reassign skipado + NÃO marca timestamp '
        '(Fix noop-trap)', () async {
      final playerId = await _seedPlayer(db, factionType: 'none');
      final result = await service.checkAndApply(playerId);
      expect(result.applied, isFalse);
      expect(result.reassigned, isFalse);

      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.lastWeeklyReset, isNull,
          reason: 'sem facção → não trava o player por 7d');
    });

    test('Fix noop-trap REGRESSÃO: boot sem facção (null timestamp) → '
        'entra na facção → próximo boot atribui + marca', () async {
      // Boot #1: player SEM facção (fresh install antes de escolher facção).
      final playerId = await _seedPlayer(db, factionType: 'none');
      final r1 = await service.checkAndApply(playerId);
      expect(r1.reassigned, isFalse);
      var row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.lastWeeklyReset, isNull,
          reason: 'boot sem facção NÃO pode travar o timestamp');

      // Player entra numa facção com pool ('guild' no fixture).
      await db.customUpdate(
        "UPDATE players SET faction_type = 'guild' WHERE id = ?",
        variables: [Variable.withInt(playerId)],
        updates: {db.playersTable},
      );

      // Boot #2: lastWeeklyReset ainda null → NÃO cai no noop → atribui.
      final r2 = await service.checkAndApply(playerId);
      expect(r2.reassigned, isTrue,
          reason: 'destravou: weekly atribuída no boot após entrar na facção');
      row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.lastWeeklyReset, isNotNull,
          reason: 'agora sim marca (ciclo fechou com facção válida)');
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
