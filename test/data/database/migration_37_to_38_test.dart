import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Fase B.1 — migration MANUAL 37→38: cria `guild_ascension_state`,
/// adiciona `players.total_gold_earned_lifetime` e faz backfill
/// (= total_gold_earned_via_quests).
///
/// Estratégia (igual ao migration_29_to_30_test): monta o schema 37 à mão
/// via `NativeDatabase.memory(setup: ...)` + `PRAGMA user_version = 37`.
/// Ao abrir AppDatabase (schemaVersion=38), Drift roda onUpgrade → só o
/// bloco `if (from < 38)`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// players no schema 37 = todas as colunas ATÉ a 37 (inclui insignias,
  /// screens_visited_keys, auto_confirm_enabled, total_gold_earned_via_quests)
  /// MENOS `total_gold_earned_lifetime` (que a 37→38 adiciona).
  /// recipes_catalog/items_catalog vazias pro beforeOpen self-heal.
  String setupSchema37({required int viaQuests}) {
    final buf = StringBuffer();
    buf.writeln('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        shadow_name TEXT NOT NULL DEFAULT 'Sombra',
        level INTEGER NOT NULL DEFAULT 1,
        xp INTEGER NOT NULL DEFAULT 0,
        xp_to_next INTEGER NOT NULL DEFAULT 100,
        attribute_points INTEGER NOT NULL DEFAULT 0,
        vitalism_level INTEGER NOT NULL DEFAULT 0,
        vitalism_xp INTEGER NOT NULL DEFAULT 0,
        strength INTEGER NOT NULL DEFAULT 1,
        dexterity INTEGER NOT NULL DEFAULT 1,
        intelligence INTEGER NOT NULL DEFAULT 1,
        constitution INTEGER NOT NULL DEFAULT 1,
        spirit INTEGER NOT NULL DEFAULT 1,
        charisma INTEGER NOT NULL DEFAULT 1,
        hp INTEGER NOT NULL DEFAULT 100,
        max_hp INTEGER NOT NULL DEFAULT 100,
        mp INTEGER NOT NULL DEFAULT 90,
        max_mp INTEGER NOT NULL DEFAULT 90,
        current_vitalism INTEGER NOT NULL DEFAULT 0,
        gold INTEGER NOT NULL DEFAULT 0,
        gems INTEGER NOT NULL DEFAULT 0,
        insignias INTEGER NOT NULL DEFAULT 0,
        streak_days INTEGER NOT NULL DEFAULT 0,
        caelum_day INTEGER NOT NULL DEFAULT 1,
        shadow_state TEXT NOT NULL DEFAULT 'stable',
        shadow_corruption INTEGER NOT NULL DEFAULT 0,
        class_type TEXT,
        faction_type TEXT,
        guild_rank TEXT NOT NULL DEFAULT 'none',
        total_quests_completed INTEGER NOT NULL DEFAULT 0,
        narrative_mode TEXT NOT NULL DEFAULT 'longa',
        onboarding_done INTEGER NOT NULL DEFAULT 0,
        play_style TEXT NOT NULL DEFAULT 'none',
        created_at INTEGER NOT NULL,
        last_login_at INTEGER NOT NULL,
        last_streak_date INTEGER,
        last_daily_reset INTEGER,
        last_weekly_reset INTEGER,
        weight_kg INTEGER,
        height_cm INTEGER,
        last_daily_mission_rollover INTEGER,
        daily_missions_streak INTEGER NOT NULL DEFAULT 0,
        total_gems_spent INTEGER NOT NULL DEFAULT 0,
        peak_level INTEGER NOT NULL DEFAULT 1,
        total_attribute_points_spent INTEGER NOT NULL DEFAULT 0,
        screens_visited_keys TEXT NOT NULL DEFAULT '',
        auto_confirm_enabled INTEGER NOT NULL DEFAULT 0,
        total_gold_earned_via_quests INTEGER NOT NULL DEFAULT 0
      );
    ''');
    buf.writeln('''
      CREATE TABLE recipes_catalog (
        key TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        result_item_key TEXT NOT NULL,
        materials_json TEXT NOT NULL,
        gates_json TEXT NOT NULL,
        unlock_sources_json TEXT NOT NULL,
        gold_cost INTEGER NOT NULL DEFAULT 0,
        gem_cost INTEGER NOT NULL DEFAULT 0,
        is_starter INTEGER NOT NULL DEFAULT 0
      );
    ''');
    buf.writeln('''
      CREATE TABLE items_catalog (
        key TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL,
        rarity TEXT NOT NULL,
        rank TEXT,
        sources_json TEXT NOT NULL DEFAULT '[]'
      );
    ''');
    // Player com ouro-via-quests pra validar o backfill.
    buf.writeln('''
      INSERT INTO players (email, password_hash, last_login_at, created_at,
        total_gold_earned_via_quests)
      VALUES ('p1@t', 'h', 0, 0, $viaQuests);
    ''');
    buf.writeln('PRAGMA user_version = 37;');
    return buf.toString();
  }

  group('migration 37→38', () {
    test('cria guild_ascension_state + coluna total_gold_earned_lifetime + '
        'backfill = total_gold_earned_via_quests', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        for (final stmt in setupSchema37(viaQuests: 777).split(';')) {
          final s = stmt.trim();
          if (s.isNotEmpty) raw.execute(s);
        }
      }));

      // Trigger open + onUpgrade (from=37 → só o bloco from<38).
      await db.customSelect('SELECT 1').get();

      // 1. Tabela nova criada.
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table' "
              "AND name = 'guild_ascension_state'")
          .get();
      expect(tables.length, 1, reason: 'guild_ascension_state criada');

      // 2. Coluna adicionada em players.
      final cols = await db
          .customSelect("PRAGMA table_info('players')")
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, contains('total_gold_earned_lifetime'));

      // 3. Backfill = total_gold_earned_via_quests.
      final rows = await db
          .customSelect('SELECT total_gold_earned_lifetime AS life '
              'FROM players WHERE id = 1')
          .get();
      expect(rows.first.read<int>('life'), 777,
          reason: 'backfill copiou total_gold_earned_via_quests');

      await db.close();
    });

    test('schema da guild_ascension_state bate com a tabela canônica do Drift',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        for (final stmt in setupSchema37(viaQuests: 0).split(';')) {
          final s = stmt.trim();
          if (s.isNotEmpty) raw.execute(s);
        }
      }));
      await db.customSelect('SELECT 1').get();

      // DB virgem schema 38 (createAll) como referência.
      final reference = AppDatabase.forTesting(NativeDatabase.memory());
      await reference.customSelect('SELECT 1').get();

      final migrated = await db
          .customSelect("PRAGMA table_info('guild_ascension_state')")
          .get();
      final canonical = await reference
          .customSelect("PRAGMA table_info('guild_ascension_state')")
          .get();

      expect(migrated.map((r) => r.read<String>('name')).toSet(),
          canonical.map((r) => r.read<String>('name')).toSet(),
          reason: 'colunas iguais');
      expect(
          migrated.where((r) => r.read<int>('pk') > 0)
              .map((r) => r.read<String>('name'))
              .toSet(),
          canonical.where((r) => r.read<int>('pk') > 0)
              .map((r) => r.read<String>('name'))
              .toSet(),
          reason: 'PK composta (player_id, rank_from)');

      await db.close();
      await reference.close();
    });
  });
}
