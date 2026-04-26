import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.2 Etapa 1.2 — valida schema 27.
///
/// Cobre:
/// - Fresh install aplica schema 27 (tabela daily_missions presente +
///   2 colunas novas em players com defaults corretos).
/// - Upgrade 26→27 cria tabela + 2 colunas preservando rows existentes.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  group('Sprint 3.2 — upgrade 26→27', () {
    late AppDatabase legacyDb;

    setUp(() {
      legacyDb = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        // Schema 26 = schema 25 + weight_kg + height_cm.
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
            last_weekly_reset INTEGER,
            weight_kg INTEGER,
            height_cm INTEGER
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
        raw.execute('PRAGMA user_version = 26;');
      }));
    });

    tearDown(() async => legacyDb.close());

    test('onUpgrade 26→27 não lança', () async {
      await expectLater(
        legacyDb.customSelect('SELECT 1 AS x').get(),
        completes,
      );
    });

    test('player pré-migration preservado; novas colunas vêm com defaults',
        () async {
      final rows = await legacyDb
          .customSelect('SELECT * FROM players WHERE email = ?',
              variables: [Variable.withString('legacy26@test')])
          .get();
      expect(rows.length, 1);
      expect(rows.single.read<int?>('last_daily_mission_rollover'), isNull);
      expect(rows.single.read<int>('daily_missions_streak'), 0);
    });

    test('tabela daily_missions criada após upgrade', () async {
      // Força open+migration.
      await legacyDb.customSelect('SELECT 1').get();
      final tables = await legacyDb
          .customSelect("SELECT name FROM sqlite_master WHERE type='table' "
              "AND name='daily_missions'")
          .get();
      expect(tables.length, 1);
    });

    test('índice daily_missions(player_id, data) existe', () async {
      await legacyDb.customSelect('SELECT 1').get();
      final idx = await legacyDb
          .customSelect("SELECT name FROM sqlite_master WHERE type='index' "
              "AND name='idx_daily_missions_player_data'")
          .get();
      expect(idx.length, 1);
    });
  });

  group('Schema 27 fresh install', () {
    test('schemaVersion >= 27', () {
      expect(db.schemaVersion, greaterThanOrEqualTo(27));
    });

    test('insert + read em daily_missions', () async {
      // Cria player + insere missão.
      final pid = await db.customInsert(
        "INSERT INTO players (email, password_hash, shadow_name, level, "
        "xp, xp_to_next, gold, gems, strength, dexterity, intelligence, "
        "constitution, spirit, charisma, attribute_points, "
        "shadow_corruption, vitalism_level, vitalism_xp) "
        "VALUES (?, 'h', 'S', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
        variables: [Variable.withString('s27@t')],
      );
      final missionId = await db.into(db.dailyMissionsTable).insert(
            DailyMissionsTableCompanion(
              playerId: Value(pid),
              data: const Value('2026-04-25'),
              modalidade: const Value('fisico'),
              subCategoria: const Value('treino'),
              tituloKey: const Value('Forja do Caçador'),
              tituloResolvido: const Value('Forja do Caçador'),
              quoteResolvida: const Value('q'),
              subTarefasJson: const Value('[]'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      final rows = await (db.select(db.dailyMissionsTable)
            ..where((t) => t.id.equals(missionId)))
          .get();
      expect(rows.length, 1);
      expect(rows.first.modalidade, 'fisico');
      expect(rows.first.status, 'pending');
      expect(rows.first.rewardClaimed, false);
    });

    test('players.daily_missions_streak default = 0', () async {
      final id = await db.customInsert(
        "INSERT INTO players (email, password_hash, shadow_name, level, "
        "xp, xp_to_next, gold, gems, strength, dexterity, intelligence, "
        "constitution, spirit, charisma, attribute_points, "
        "shadow_corruption, vitalism_level, vitalism_xp) "
        "VALUES (?, 'h', 'S', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
        variables: [Variable.withString('streak@t')],
      );
      final p = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(p.dailyMissionsStreak, 0);
      expect(p.lastDailyMissionRollover, isNull);
    });
  });
}
