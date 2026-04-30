import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.3 HOTFIX — testa migration corretiva 29→30 que re-aplica
/// o bulk insert de rows iniciais em `player_daily_mission_stats` que
/// falhou silencioso na 27→28.
///
/// Estratégia: simular DB em estado pós-falha via
/// `NativeDatabase.memory(setup: ...)` que prepara schema 29 manual e
/// `PRAGMA user_version = 29`. Ao abrir AppDatabase (schemaVersion=30),
/// Drift detecta upgrade e roda onUpgrade → bloco `if (from < 30)` →
/// `_applyHotfix29To30()` (privado, exercitado via caminho real).
///
/// Ver `.vault/02_ADRs/ADR-0019-drift-migration-dataclass-pitfall.md`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// SQL completo do schema 29 — replicação manual pra simular o estado
  /// real do device do CEO (tabelas existem, players inseridos, rows
  /// iniciais de stats AUSENTES porque o bulk insert da 27→28 nunca
  /// rodou). `players` inclui as 3 colunas adicionadas em 28→29
  /// (total_gems_spent, peak_level, total_attribute_points_spent).
  ///
  /// Tabelas tocadas pelo `beforeOpen._selfHealCatalogs` precisam existir
  /// (recipes_catalog, items_catalog) — criadas vazias.
  String setupSchema29({
    required int playerCount,
    bool createStatsTable = true,
    bool createVolumeTable = true,
    bool prePopulateOnePlayerStat = false,
  }) {
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
        mp INTEGER NOT NULL DEFAULT 50,
        max_mp INTEGER NOT NULL DEFAULT 50,
        current_vitalism INTEGER NOT NULL DEFAULT 0,
        gold INTEGER NOT NULL DEFAULT 0,
        gems INTEGER NOT NULL DEFAULT 0,
        streak_days INTEGER NOT NULL DEFAULT 0,
        caelum_day INTEGER NOT NULL DEFAULT 0,
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
        total_attribute_points_spent INTEGER NOT NULL DEFAULT 0
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
    if (createStatsTable) {
      buf.writeln('''
        CREATE TABLE player_daily_mission_stats (
          player_id INTEGER NOT NULL,
          total_completed INTEGER NOT NULL DEFAULT 0,
          total_failed INTEGER NOT NULL DEFAULT 0,
          total_partial INTEGER NOT NULL DEFAULT 0,
          total_perfect INTEGER NOT NULL DEFAULT 0,
          total_super_perfect INTEGER NOT NULL DEFAULT 0,
          total_generated INTEGER NOT NULL DEFAULT 0,
          total_confirmed INTEGER NOT NULL DEFAULT 0,
          best_streak INTEGER NOT NULL DEFAULT 0,
          days_without_failing INTEGER NOT NULL DEFAULT 0,
          best_days_without_failing INTEGER NOT NULL DEFAULT 0,
          consecutive_fails_count INTEGER NOT NULL DEFAULT 0,
          max_consecutive_fails INTEGER NOT NULL DEFAULT 0,
          consecutive_active_days INTEGER NOT NULL DEFAULT 0,
          best_consecutive_active_days INTEGER NOT NULL DEFAULT 0,
          total_sub_tasks_completed INTEGER NOT NULL DEFAULT 0,
          total_sub_tasks_overshoot INTEGER NOT NULL DEFAULT 0,
          total_confirmed_before_8am INTEGER NOT NULL DEFAULT 0,
          total_confirmed_after_10pm INTEGER NOT NULL DEFAULT 0,
          total_confirmed_on_weekend INTEGER NOT NULL DEFAULT 0,
          days_of_week_completed_bitmask INTEGER NOT NULL DEFAULT 0,
          total_zero_progress_confirms INTEGER NOT NULL DEFAULT 0,
          total_days_all_pilars INTEGER NOT NULL DEFAULT 0,
          total_speedrun_completions INTEGER NOT NULL DEFAULT 0,
          first_completed_at INTEGER,
          last_completed_at INTEGER,
          last_pilar_balance_day TEXT,
          last_active_day TEXT,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (player_id)
        );
      ''');
    }
    if (createVolumeTable) {
      buf.writeln('''
        CREATE TABLE player_daily_subtask_volume (
          player_id INTEGER NOT NULL,
          sub_task_key TEXT NOT NULL,
          total_units INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (player_id, sub_task_key)
        );
      ''');
    }
    // Insere N players com cols mínimas — emails únicos.
    for (int i = 1; i <= playerCount; i++) {
      buf.writeln('''
        INSERT INTO players (email, password_hash, shadow_name, last_login_at,
          created_at)
        VALUES ('p$i@t', 'h', 'P$i', 0, 0);
      ''');
    }
    if (prePopulateOnePlayerStat && playerCount >= 1) {
      // Simula caso onde 1 player já tem row em stats (ex: jogador novo
      // criou conta após hotfix futuro mas antes da migration rodar).
      buf.writeln('''
        INSERT INTO player_daily_mission_stats (player_id, total_completed, updated_at)
        VALUES (1, 99, 1234567890);
      ''');
    }
    buf.writeln('PRAGMA user_version = 29;');
    return buf.toString();
  }

  group('migration 29→30 (hotfix)', () {
    test('cenário 1 — pós-falha: 3 players sem row em stats → 3 rows após',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        for (final stmt in setupSchema29(playerCount: 3).split(';')) {
          final s = stmt.trim();
          if (s.isNotEmpty) raw.execute(s);
        }
      }));

      // Trigger open + onUpgrade.
      await db.customSelect('SELECT 1').get();

      final rows = await db
          .customSelect('SELECT player_id FROM player_daily_mission_stats '
              'ORDER BY player_id')
          .get();
      expect(rows.length, 3);
      expect(rows.map((r) => r.read<int>('player_id')).toList(),
          [1, 2, 3]);
      await db.close();
    });

    test('cenário 2 — idempotência: row pré-existente preservada', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        for (final stmt
            in setupSchema29(playerCount: 2, prePopulateOnePlayerStat: true)
                .split(';')) {
          final s = stmt.trim();
          if (s.isNotEmpty) raw.execute(s);
        }
      }));

      await db.customSelect('SELECT 1').get();

      final rows = await db
          .customSelect('SELECT player_id, total_completed FROM '
              'player_daily_mission_stats ORDER BY player_id')
          .get();
      expect(rows.length, 2);
      // Player 1 manteve total_completed=99 (insertOrIgnore não sobreescreve).
      expect(rows.first.read<int>('player_id'), 1);
      expect(rows.first.read<int>('total_completed'), 99);
      // Player 2 ganhou row nova com defaults.
      expect(rows.last.read<int>('player_id'), 2);
      expect(rows.last.read<int>('total_completed'), 0);
      await db.close();
    });

    test('cenário 3 — DB sem players: hotfix não crasha', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        for (final stmt in setupSchema29(playerCount: 0).split(';')) {
          final s = stmt.trim();
          if (s.isNotEmpty) raw.execute(s);
        }
      }));

      await db.customSelect('SELECT 1').get();

      final rows = await db
          .customSelect('SELECT * FROM player_daily_mission_stats')
          .get();
      expect(rows, isEmpty);
      await db.close();
    });

    test(
        'cenário 4 — tabelas FALTANDO no DB pré-falha: '
        'CREATE TABLE IF NOT EXISTS cobre',
        () async {
      // Edge case: device hipotético onde o m.createTable original também
      // não rodou (mais grave que o estado real do CEO). Hotfix recria.
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        for (final stmt in setupSchema29(
                playerCount: 2,
                createStatsTable: false,
                createVolumeTable: false)
            .split(';')) {
          final s = stmt.trim();
          if (s.isNotEmpty) raw.execute(s);
        }
      }));

      await db.customSelect('SELECT 1').get();

      // Tabelas existem agora.
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table' "
              "AND name IN ('player_daily_mission_stats', "
              "'player_daily_subtask_volume')")
          .get();
      expect(tables.length, 2);

      // Players têm rows iniciais.
      final stats = await db
          .customSelect('SELECT player_id FROM player_daily_mission_stats')
          .get();
      expect(stats.length, 2);
      await db.close();
    });

    test(
        'cenário 5 — schema check via PRAGMA table_info bate com '
        'PlayerDailyMissionStatsTable',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        for (final stmt in setupSchema29(
                playerCount: 0,
                createStatsTable: false,
                createVolumeTable: false)
            .split(';')) {
          final s = stmt.trim();
          if (s.isNotEmpty) raw.execute(s);
        }
      }));

      // Trigger hotfix → cria via CREATE TABLE IF NOT EXISTS.
      await db.customSelect('SELECT 1').get();

      // Comparação: cria DB virgem schema 30 (createAll do Drift) e
      // confronta esquemas das tabelas via PRAGMA table_info.
      final reference =
          AppDatabase.forTesting(NativeDatabase.memory());
      await reference.customSelect('SELECT 1').get();

      final hotfixCols = await db
          .customSelect("PRAGMA table_info('player_daily_mission_stats')")
          .get();
      final referenceCols = await reference
          .customSelect("PRAGMA table_info('player_daily_mission_stats')")
          .get();

      // Mesmo número de colunas.
      expect(hotfixCols.length, referenceCols.length,
          reason: 'CREATE TABLE bruto do hotfix tem N cols vs '
              'tabela canônica do Drift');

      // Mesmas colunas (nomes).
      final hotfixNames = hotfixCols
          .map((r) => r.read<String>('name'))
          .toSet();
      final referenceNames = referenceCols
          .map((r) => r.read<String>('name'))
          .toSet();
      expect(hotfixNames, referenceNames,
          reason: 'Nomes de colunas divergem entre hotfix SQL e tabela '
              'canônica');

      // Mesmo PK.
      final hotfixPk = hotfixCols
          .where((r) => r.read<int>('pk') > 0)
          .map((r) => r.read<String>('name'))
          .toList();
      final referencePk = referenceCols
          .where((r) => r.read<int>('pk') > 0)
          .map((r) => r.read<String>('name'))
          .toList();
      expect(hotfixPk, referencePk);

      // Mesmas cols NOT NULL (drift gera NOT NULL pra defaults também).
      final hotfixNotNull = hotfixCols
          .where((r) => r.read<int>('notnull') == 1)
          .map((r) => r.read<String>('name'))
          .toSet();
      final referenceNotNull = referenceCols
          .where((r) => r.read<int>('notnull') == 1)
          .map((r) => r.read<String>('name'))
          .toSet();
      expect(hotfixNotNull, referenceNotNull,
          reason: 'NOT NULL flags divergem');

      await db.close();
      await reference.close();
    });
  });
}
