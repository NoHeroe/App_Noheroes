import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.2 Etapa 1.0 — valida schema 26.
///
/// Cobre:
/// - Fresh install aplica schema 26 sem erro (players tem `weight_kg`
///   + `height_cm` nullable).
/// - Upgrade 25→26 adiciona as 2 colunas preservando rows existentes
///   (pattern Bloco 7-preclean idêntico ao schema_25_test).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // Pattern Bloco 7-preclean: simula schema 25 seedando tabela players
  // schema-25 (sem as 2 colunas novas) + PRAGMA user_version=25. Drift
  // detecta 25 < schemaVersion=26 e chama onUpgrade 25→26 (addColumn nullable).
  group('Sprint 3.2 — upgrade 25→26 (2 columns nullable)', () {
    late AppDatabase legacyDb;

    setUp(() {
      legacyDb = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
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
            created_at INTEGER NOT NULL,
            last_daily_reset INTEGER,
            last_weekly_reset INTEGER
          );
        ''');
        raw.execute(
            "INSERT INTO players (email, password_hash, shadow_name, "
            "level, xp, xp_to_next, gold, gems, strength, dexterity, "
            "intelligence, constitution, spirit, charisma, "
            "attribute_points, shadow_corruption, vitalism_level, "
            "vitalism_xp, last_login_at, created_at) "
            "VALUES ('legacy26@test', 'h', 'L', 5, 0, 100, 0, 0, 1, 1, 1, "
            "1, 1, 1, 0, 0, 0, 0, 0, 0);");
        raw.execute('PRAGMA user_version = 25;');
      }));
    });

    tearDown(() async => legacyDb.close());

    test('onUpgrade 25→26 não lança', () async {
      await expectLater(
        legacyDb.customSelect('SELECT 1 AS x').get(),
        completes,
      );
    });

    test('player pré-migration preservado; colunas novas vêm null',
        () async {
      final rows = await legacyDb
          .customSelect('SELECT * FROM players WHERE email = ?',
              variables: [Variable.withString('legacy26@test')])
          .get();
      expect(rows.length, 1);
      expect(rows.single.read<int?>('weight_kg'), isNull);
      expect(rows.single.read<int?>('height_cm'), isNull);
    });
  });

  group('Schema 26 fresh install', () {
    test('schemaVersion é 26', () {
      expect(db.schemaVersion, 26);
    });

    test('players tem weight_kg + height_cm nullable', () async {
      final id = await db.customInsert(
        "INSERT INTO players (email, password_hash, shadow_name, level, "
        "xp, xp_to_next, gold, gems, strength, dexterity, intelligence, "
        "constitution, spirit, charisma, attribute_points, "
        "shadow_corruption, vitalism_level, vitalism_xp) "
        "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, "
        "0, 0, 0)",
        variables: [
          Variable.withString('s26@t'),
          Variable.withString('h'),
        ],
      );
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.weightKg, isNull);
      expect(row.heightCm, isNull);
    });

    test('UPDATE weight_kg + height_cm persiste', () async {
      final id = await db.customInsert(
        "INSERT INTO players (email, password_hash, shadow_name, level, "
        "xp, xp_to_next, gold, gems, strength, dexterity, intelligence, "
        "constitution, spirit, charisma, attribute_points, "
        "shadow_corruption, vitalism_level, vitalism_xp) "
        "VALUES (?, ?, 'S', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
        variables: [
          Variable.withString('u26@t'),
          Variable.withString('h'),
        ],
      );
      await db.customUpdate(
        'UPDATE players SET weight_kg = ?, height_cm = ? WHERE id = ?',
        variables: [
          Variable.withInt(72),
          Variable.withInt(178),
          Variable.withInt(id),
        ],
        updates: {db.playersTable},
      );
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.weightKg, 72);
      expect(row.heightCm, 178);
    });
  });
}
