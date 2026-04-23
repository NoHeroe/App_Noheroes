import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.1 Bloco 13b — valida schema 25.
///
/// Cobre:
/// - Fresh install aplica schema 25 sem erro (tabela `players` tem
///   `last_daily_reset` + `last_weekly_reset` nullable).
/// - Upgrade 24→25 adiciona as 2 colunas preservando rows existentes
///   (pattern Bloco 7-preclean).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // Pattern Bloco 7-preclean: simula schema 24 seedando tabela players
  // schema-24 (sem as 2 colunas novas) + PRAGMA user_version=24. Drift
  // detecta 24 < schemaVersion=25 e chama onUpgrade 24→25 (addColumn
  // nullable).
  group('Sprint 3.1 — upgrade 24→25 (2 columns nullable)', () {
    late AppDatabase legacyDb;

    setUp(() {
      legacyDb = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        // Cria schema 24 completo na mão — players sem last_daily_reset
        // / last_weekly_reset. Drift onUpgrade 24→25 vai addColumn.
        raw.execute('''
          CREATE TABLE players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            shadow_name TEXT NOT NULL,
            level INTEGER NOT NULL,
            xp INTEGER NOT NULL,
            xp_to_next INTEGER NOT NULL,
            gold INTEGER NOT NULL,
            gems INTEGER NOT NULL,
            strength INTEGER NOT NULL,
            dexterity INTEGER NOT NULL,
            intelligence INTEGER NOT NULL,
            constitution INTEGER NOT NULL,
            spirit INTEGER NOT NULL,
            charisma INTEGER NOT NULL,
            attribute_points INTEGER NOT NULL,
            shadow_corruption INTEGER NOT NULL,
            vitalism_level INTEGER NOT NULL,
            vitalism_xp INTEGER NOT NULL,
            current_vitalism INTEGER NOT NULL DEFAULT 0,
            shadow_state TEXT NOT NULL DEFAULT 'stable',
            class_type TEXT,
            faction_type TEXT,
            guild_rank TEXT NOT NULL DEFAULT 'none',
            narrative_mode TEXT NOT NULL DEFAULT 'longa',
            play_style TEXT NOT NULL DEFAULT 'none',
            total_quests_completed INTEGER NOT NULL DEFAULT 0,
            max_hp INTEGER NOT NULL DEFAULT 100,
            hp INTEGER NOT NULL DEFAULT 100,
            max_mp INTEGER NOT NULL DEFAULT 50,
            mp INTEGER NOT NULL DEFAULT 50,
            onboarding_done INTEGER NOT NULL DEFAULT 0,
            last_login_at INTEGER NOT NULL,
            last_streak_date INTEGER,
            streak_days INTEGER NOT NULL DEFAULT 0,
            caelum_day INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          );
        ''');
        raw.execute(
            "INSERT INTO players (email, password_hash, shadow_name, "
            "level, xp, xp_to_next, gold, gems, strength, dexterity, "
            "intelligence, constitution, spirit, charisma, "
            "attribute_points, shadow_corruption, vitalism_level, "
            "vitalism_xp, last_login_at, created_at) "
            "VALUES ('legacy@test', 'h', 'L', 5, 0, 100, 0, 0, 1, 1, 1, "
            "1, 1, 1, 0, 0, 0, 0, 0, 0);");
        raw.execute('PRAGMA user_version = 24;');
      }));
    });

    tearDown(() async => legacyDb.close());

    test('onUpgrade 24→25 não lança', () async {
      await expectLater(
        legacyDb.customSelect('SELECT 1 AS x').get(),
        completes,
      );
    });

    test('player pré-migration preservado; colunas novas vêm null',
        () async {
      // Força open+migration.
      final rows = await legacyDb
          .customSelect('SELECT * FROM players WHERE email = ?',
              variables: [Variable.withString('legacy@test')])
          .get();
      expect(rows.length, 1);
      expect(rows.single.read<int?>('last_daily_reset'), isNull);
      expect(rows.single.read<int?>('last_weekly_reset'), isNull);
    });
  });

  group('Schema 25 fresh install', () {
    test('schemaVersion é 25', () {
      expect(db.schemaVersion, 25);
    });

    test('players tem last_daily_reset + last_weekly_reset nullable',
        () async {
      // Insere player sem specificar os novos campos — defaults nullable.
      final id = await db.customInsert(
        "INSERT INTO players (email, password_hash, shadow_name, level, "
        "xp, xp_to_next, gold, gems, strength, dexterity, intelligence, "
        "constitution, spirit, charisma, attribute_points, "
        "shadow_corruption, vitalism_level, vitalism_xp) "
        "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, "
        "0, 0, 0)",
        variables: [
          Variable.withString('s25@t'),
          Variable.withString('h'),
        ],
      );
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.lastDailyReset, isNull);
      expect(row.lastWeeklyReset, isNull);
    });

    test('UPDATE last_daily_reset persiste', () async {
      final id = await db.customInsert(
        "INSERT INTO players (email, password_hash, shadow_name, level, "
        "xp, xp_to_next, gold, gems, strength, dexterity, intelligence, "
        "constitution, spirit, charisma, attribute_points, "
        "shadow_corruption, vitalism_level, vitalism_xp) "
        "VALUES (?, ?, 'S', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
        variables: [
          Variable.withString('u25@t'),
          Variable.withString('h'),
        ],
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.customUpdate(
        'UPDATE players SET last_daily_reset = ?, last_weekly_reset = ? '
        'WHERE id = ?',
        variables: [
          Variable.withInt(now),
          Variable.withInt(now),
          Variable.withInt(id),
        ],
        updates: {db.playersTable},
      );
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.lastDailyReset, now);
      expect(row.lastWeeklyReset, now);
    });
  });
}
