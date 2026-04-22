import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.1 Bloco 1 — valida o schema 24.
///
/// Cobre:
/// - Fresh install aplica schema 24 sem erro (sem backfill — reset brutal).
/// - CRUD mínimo nas 6 tabelas novas.
/// - UNIQUE em `active_faction_quests` rejeita duplicata
///   (player_id, faction_id, week_start).
/// - PK composta em `player_achievements_completed` rejeita duplicata.
/// - PK composta em `player_faction_reputation` rejeita duplicata.
/// - PK simples em `player_mission_preferences` rejeita duplicata.
///
/// Não testa upgrade (reset brutal conforme R4-Q1).
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Sprint 3.1 — schema 24 fresh install', () {
    test('schemaVersion é 24', () {
      expect(db.schemaVersion, 24);
    });

    test('as 6 tabelas novas existem e respondem a COUNT', () async {
      for (final table in [
        'player_mission_progress',
        'player_mission_preferences',
        'player_individual_missions',
        'player_achievements_completed',
        'player_faction_reputation',
        'active_faction_quests',
      ]) {
        final rows = await db
            .customSelect('SELECT COUNT(*) AS c FROM $table')
            .get();
        expect(rows.single.data['c'], 0, reason: '$table deve abrir vazia');
      }
    });

    test('tabelas legacy foram dropadas no fresh install', () async {
      for (final legacy in [
        'habits',
        'habit_logs',
        'class_quests',
        'achievements',
        'player_achievements',
      ]) {
        final rows = await db
            .customSelect(
                "SELECT name FROM sqlite_master WHERE type='table' "
                "AND name='$legacy'")
            .get();
        expect(rows, isEmpty, reason: '$legacy não deveria existir');
      }
    });
  });

  group('player_mission_progress — CRUD', () {
    test('insert + select respeita defaults', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.playerMissionProgressTable).insert(
            PlayerMissionProgressTableCompanion(
              playerId: const Value(1),
              missionKey: const Value('DAILY_PUSHUPS_E'),
              modality: const Value('real'),
              tabOrigin: const Value('daily'),
              rank: const Value('E'),
              targetValue: const Value(20),
              rewardJson: const Value('{"xp":100,"gold":50}'),
              startedAt: Value(now),
            ),
          );
      final rows = await db.select(db.playerMissionProgressTable).get();
      expect(rows, hasLength(1));
      final r = rows.first;
      expect(r.missionKey, 'DAILY_PUSHUPS_E');
      expect(r.currentValue, 0);
      expect(r.rewardClaimed, isFalse);
      expect(r.completedAt, matcherIsNull);
      expect(r.failedAt, matcherIsNull);
      expect(r.metaJson, '{}');
    });
  });

  group('active_faction_quests — UNIQUE (player_id, faction_id, week_start)',
      () {
    ActiveFactionQuestsTableCompanion buildRow({
      required int playerId,
      required String factionId,
      required String weekStart,
      String missionKey = 'FACTION_WEEKLY_TEST',
    }) {
      return ActiveFactionQuestsTableCompanion(
        playerId: Value(playerId),
        factionId: Value(factionId),
        missionKey: Value(missionKey),
        weekStart: Value(weekStart),
        assignedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );
    }

    test('segunda inserção com mesma tripla falha', () async {
      await db.into(db.activeFactionQuestsTable).insert(
          buildRow(playerId: 1, factionId: 'noryan', weekStart: '2026-04-20'));
      await expectLater(
        db.into(db.activeFactionQuestsTable).insert(
            buildRow(playerId: 1, factionId: 'noryan', weekStart: '2026-04-20')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('triplas diferentes convivem', () async {
      await db.into(db.activeFactionQuestsTable).insert(
          buildRow(playerId: 1, factionId: 'noryan', weekStart: '2026-04-20'));
      await db.into(db.activeFactionQuestsTable).insert(
          buildRow(playerId: 1, factionId: 'noryan', weekStart: '2026-04-27'));
      await db.into(db.activeFactionQuestsTable).insert(
          buildRow(playerId: 2, factionId: 'noryan', weekStart: '2026-04-20'));
      await db.into(db.activeFactionQuestsTable).insert(
          buildRow(playerId: 1, factionId: 'outra', weekStart: '2026-04-20'));
      final rows = await db.select(db.activeFactionQuestsTable).get();
      expect(rows, hasLength(4));
    });
  });

  group('player_achievements_completed — PK composta', () {
    test('mesmo (player_id, achievement_key) inserido 2x falha', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final row = PlayerAchievementsCompletedTableCompanion(
        playerId: const Value(1),
        achievementKey: const Value('ACH_FIRST_CRAFT'),
        completedAt: Value(now),
      );
      await db.into(db.playerAchievementsCompletedTable).insert(row);
      await expectLater(
        db.into(db.playerAchievementsCompletedTable).insert(row),
        throwsA(isA<SqliteException>()),
      );
    });

    test('keys diferentes pro mesmo jogador convivem', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.playerAchievementsCompletedTable).insert(
            PlayerAchievementsCompletedTableCompanion(
              playerId: const Value(1),
              achievementKey: const Value('ACH_FIRST_CRAFT'),
              completedAt: Value(now),
            ),
          );
      await db.into(db.playerAchievementsCompletedTable).insert(
            PlayerAchievementsCompletedTableCompanion(
              playerId: const Value(1),
              achievementKey: const Value('ACH_FIRST_ENCHANT'),
              completedAt: Value(now),
            ),
          );
      final rows =
          await db.select(db.playerAchievementsCompletedTable).get();
      expect(rows, hasLength(2));
    });
  });

  group('player_faction_reputation — PK composta', () {
    test('insert com defaults + update + rejeita duplicata', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.playerFactionReputationTable).insert(
            PlayerFactionReputationTableCompanion(
              playerId: const Value(1),
              factionId: const Value('noryan'),
              updatedAt: Value(now),
            ),
          );
      final rep = await (db.select(db.playerFactionReputationTable)
            ..where((t) =>
                t.playerId.equals(1) & t.factionId.equals('noryan')))
          .getSingle();
      expect(rep.reputation, 50);

      await (db.update(db.playerFactionReputationTable)
            ..where((t) =>
                t.playerId.equals(1) & t.factionId.equals('noryan')))
          .write(const PlayerFactionReputationTableCompanion(
        reputation: Value(65),
      ));
      final updated = await (db.select(db.playerFactionReputationTable)
            ..where((t) =>
                t.playerId.equals(1) & t.factionId.equals('noryan')))
          .getSingle();
      expect(updated.reputation, 65);

      await expectLater(
        db.into(db.playerFactionReputationTable).insert(
              PlayerFactionReputationTableCompanion(
                playerId: const Value(1),
                factionId: const Value('noryan'),
                updatedAt: Value(now),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('player_mission_preferences — PK = player_id', () {
    test('mesmo player_id inserido 2x falha', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.playerMissionPreferencesTable).insert(
            PlayerMissionPreferencesTableCompanion(
              playerId: const Value(1),
              primaryFocus: const Value('fisico'),
              intensity: const Value('medium'),
              missionStyle: const Value('mixed'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await expectLater(
        db.into(db.playerMissionPreferencesTable).insert(
              PlayerMissionPreferencesTableCompanion(
                playerId: const Value(1),
                primaryFocus: const Value('mental'),
                intensity: const Value('light'),
                missionStyle: const Value('real'),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('defaults aplicam quando campos omitidos', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.playerMissionPreferencesTable).insert(
            PlayerMissionPreferencesTableCompanion(
              playerId: const Value(42),
              primaryFocus: const Value('vitalismo'),
              intensity: const Value('adaptive'),
              missionStyle: const Value('internal'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      final prefs = await (db.select(db.playerMissionPreferencesTable)
            ..where((t) => t.playerId.equals(42)))
          .getSingle();
      expect(prefs.physicalSubfocus, '[]');
      expect(prefs.mentalSubfocus, '[]');
      expect(prefs.spiritualSubfocus, '[]');
      expect(prefs.timeDailyMinutes, 30);
      expect(prefs.updatesCount, 0);
    });
  });

  group('player_individual_missions — soft delete + defaults', () {
    test('deletedAt nullable + contadores default 0 + repeats=true', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.playerIndividualMissionsTable).insert(
            PlayerIndividualMissionsTableCompanion(
              playerId: const Value(1),
              name: const Value('Ler 30 páginas'),
              category: const Value('mental'),
              intensityIndex: const Value(2),
              frequency: const Value('daily'),
              rewardJson: const Value('{"xp":40,"gold":15}'),
              createdAt: Value(now),
            ),
          );
      final row =
          await db.select(db.playerIndividualMissionsTable).getSingle();
      expect(row.deletedAt, matcherIsNull);
      expect(row.completionCount, 0);
      expect(row.failureCount, 0);
      expect(row.repeats, isTrue);
    });
  });
}

/// Alias local pro matcher `isNull` — drift exporta um homônimo ambíguo
/// quando `package:drift/drift.dart` é importado sem hide (ColumnBuilder).
const matcherIsNull = isNull;
