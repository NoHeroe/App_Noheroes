import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/players_table.dart';
import 'tables/items_table.dart';
import 'tables/inventory_table.dart';
import 'tables/shop_items_table.dart';
import 'daos/player_dao.dart';
import 'daos/guild_dao.dart';
import 'daos/daily_missions_dao.dart';
import '../datasources/local/vitalism_catalog_seeder.dart';
import '../datasources/local/items_catalog_seeder.dart';
import '../datasources/local/recipes_catalog_seeder.dart';
import 'tables/guild_status_table.dart';
import 'tables/guild_ascension_table.dart';
import 'tables/npc_reputation_table.dart';
import 'tables/diary_entries_table.dart';
import 'tables/vitalism_unique_catalog_table.dart';
import 'tables/player_vitalism_affinities_table.dart';
import 'tables/player_vitalism_trees_table.dart';
import 'tables/life_vitalism_points_table.dart';
import 'tables/items_catalog_table.dart';
import 'tables/player_inventory_table.dart';
import 'tables/player_equipment_table.dart';
import 'tables/recipes_catalog_table.dart';
import 'tables/player_recipes_unlocked_table.dart';
// Sprint 3.1 — schema 24, reset brutal. Novas tabelas unificam hábitos/quests
// e adicionam preferências do quiz, conquistas, reputação e individuais.
import 'tables/player_mission_progress_table.dart';
import 'tables/player_mission_preferences_table.dart';
import 'tables/player_individual_missions_table.dart';
import 'tables/player_achievements_completed_table.dart';
import 'tables/player_faction_reputation_table.dart';
import 'tables/active_faction_quests_table.dart';
// Sprint 3.2 Etapa 1.2 — missões diárias geradas dinamicamente.
import 'tables/daily_missions_table.dart';
// Sprint 3.3 Etapa 2.1a — stats agregadas + volume por sub-task.
// Foundation pros triggers de conquista da Etapa 2.1b.
import 'tables/player_daily_mission_stats_table.dart';
import 'tables/player_daily_subtask_volume_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PlayersTable,
    ItemsTable, InventoryTable, ShopItemsTable,
    GuildStatusTable,
    NpcReputationTable,
    DiaryEntriesTable,
    GuildAscensionTable,
    VitalismUniqueCatalogTable,
    PlayerVitalismAffinitiesTable,
    PlayerVitalismTreesTable,
    LifeVitalismPointsTable,
    ItemsCatalogTable,
    PlayerInventoryTable,
    PlayerEquipmentTable,
    RecipesCatalogTable,
    PlayerRecipesUnlockedTable,
    // Sprint 3.1 — schema 24.
    PlayerMissionProgressTable,
    PlayerMissionPreferencesTable,
    PlayerIndividualMissionsTable,
    PlayerAchievementsCompletedTable,
    PlayerFactionReputationTable,
    ActiveFactionQuestsTable,
    // Sprint 3.2 Etapa 1.2 — schema 27.
    DailyMissionsTable,
    // Sprint 3.3 Etapa 2.1a — schema 28.
    PlayerDailyMissionStatsTable,
    PlayerDailySubtaskVolumeTable,
  ],
  daos: [PlayerDao, GuildDao, DailyMissionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Construtor exclusivo de testes — recebe um `QueryExecutor` arbitrário
  /// (tipicamente `NativeDatabase.memory()` do drift) pra isolar cada caso.
  ///
  /// Adicionado na Sprint 3.1 Bloco 1 pra destravar o teste do schema 24
  /// (`test/data/database/schema_24_test.dart`).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 31;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Sprint 3.1 — _seedAchievements() removido. Catálogo passa a ser o
      // JSON assets/data/achievements.json lido em runtime pelo
      // AchievementsService (Bloco 8).
      await VitalismCatalogSeeder(this).seed();
      await ItemsCatalogSeeder(this).seed();
      await RecipesCatalogSeeder(this).seed();
      // Sprint 2.3 fix (D.3) — runas foram migradas pra items_catalog como
      // ItemType.rune. EnchantsCatalogSeeder removido em schema 23.
    },
    onUpgrade: (m, from, to) async {
      // Sprint 3.1 Bloco 1 — steps com refs a tabelas dropadas (habits,
      // habit_logs, class_quests, active_faction_quests, achievements,
      // player_achievements) ficam como noop: o reset brutal de `from < 24`
      // mais abaixo dropa e recria o modelo novo direto. Manter aqui só
      // pra preservar a ordem das migrações sucessivas de players/etc.
      if (from < 2) {
        // noop — habits e habit_logs dropadas no from<24
      }
      if (from < 3) {
        await m.addColumn(playersTable, playersTable.strength);
        await m.addColumn(playersTable, playersTable.dexterity);
        await m.addColumn(playersTable, playersTable.intelligence);
        await m.addColumn(playersTable, playersTable.constitution);
        await m.addColumn(playersTable, playersTable.spirit);
        await m.addColumn(playersTable, playersTable.charisma);
        await m.addColumn(playersTable, playersTable.attributePoints);
        await m.addColumn(playersTable, playersTable.shadowCorruption);
        await m.addColumn(playersTable, playersTable.lastStreakDate);
      }
      if (from < 4) {
        await m.createTable(itemsTable);
        await m.createTable(inventoryTable);
        await m.createTable(shopItemsTable);
        // _seedShopItems() removido no Sprint 2.1 Bloco 5.8. Tabelas antigas
        // ficam vazias — sistema novo (items_catalog) cuida de tudo a partir
        // da migration 20.
      }
      if (from < 5) {
        // noop — achievements e player_achievements dropadas no from<24
      }
      if (from < 7) {
        // noop — habits.requirements dropada no from<24
      }
      if (from < 6) {
        // Migração segura: adiciona colunas novas sem quebrar dados existentes
        try {
          await m.addColumn(playersTable, playersTable.classType);
        } catch (_) {}
        try {
          await m.addColumn(playersTable, playersTable.factionType);
        } catch (_) {}
        try {
          await m.addColumn(playersTable, playersTable.narrativeMode);
        } catch (_) {}
      }
      if (from < 9) {
        try {
          await m.addColumn(playersTable, playersTable.guildRank);
        } catch (_) {}
      }
      if (from < 10) {
        try {
          await m.createTable(guildStatusTable);
        } catch (_) {}
      }
      if (from < 11) {
        // noop — player_achievements.collectedAt dropada no from<24
      }
      if (from < 12) {
        try {
          await m.createTable(npcReputationTable);
        } catch (_) {}
      }
      if (from < 13) {
        try {
          await m.createTable(diaryEntriesTable);
        } catch (_) {}
      }
      if (from < 14) {
        // noop — colunas em achievements dropadas no from<24
      }
      if (from < 15) {
        try {
          await m.addColumn(playersTable, playersTable.playStyle);
        } catch (_) {}
      }
      if (from < 16) {
        // noop — class_quests e faction_quests dropadas no from<24
      }
      if (from < 17) {
        try {
          await m.createTable(guildAscensionTable);
        } catch (_) {}
      }
      if (from < 18) {
        try {
          await m.addColumn(playersTable, playersTable.vitalismLevel);
        } catch (_) {}
        try {
          await m.addColumn(playersTable, playersTable.vitalismXp);
        } catch (_) {}
        try {
          await m.addColumn(playersTable, playersTable.currentVitalism);
        } catch (_) {}
      }
      if (from < 19) {
        try {
          await m.createTable(vitalismUniqueCatalogTable);
        } catch (_) {}
        try {
          await m.createTable(playerVitalismAffinitiesTable);
        } catch (_) {}
        try {
          await m.createTable(playerVitalismTreesTable);
        } catch (_) {}
        try {
          await m.createTable(lifeVitalismPointsTable);
        } catch (_) {}
        await VitalismCatalogSeeder(this).seed();
      }
      if (from < 20) {
        try {
          await m.createTable(itemsCatalogTable);
        } catch (_) {}
        try {
          await m.createTable(playerInventoryTable);
        } catch (_) {}
        try {
          await m.createTable(playerEquipmentTable);
        } catch (_) {}
        // Normaliza guild_rank: 'e'..'s' → 'E'..'S'. 'none' mantém como sentinela.
        try {
          await customStatement(
            "UPDATE players SET guild_rank = UPPER(guild_rank) "
            "WHERE guild_rank IN ('e','d','c','b','a','s')",
          );
        } catch (e) {
          // ignore: avoid_print
          print('[migration 19→20] guild_rank normalize failed: $e');
        }
        await ItemsCatalogSeeder(this).seed();
      }
      if (from < 21) {
        try {
          await m.createTable(recipesCatalogTable);
        } catch (_) {}
        try {
          await m.createTable(playerRecipesUnlockedTable);
        } catch (_) {}
        try {
          await m.addColumn(
              playersTable, playersTable.totalQuestsCompleted);
        } catch (_) {}
        // Popula recipes_catalog (Sprint 2.2 Bloco 2).
        final seeder = RecipesCatalogSeeder(this);
        await seeder.seed();
        // Desbloqueia starter recipes pra jogadores existentes no upgrade.
        try {
          final existing = await select(playersTable).get();
          for (final p in existing) {
            await seeder.unlockStarterRecipesFor(p.id);
          }
        } catch (e) {
          // ignore: avoid_print
          print('[migration 20→21] starter unlock for existing '
              'players failed: $e');
        }
      }
      if (from < 22) {
        // Sprint 2.3 — colunas de encantamento em player_inventory. Tabelas
        // enchants_catalog e player_enchants_inventory FORAM REMOVIDAS desta
        // migration na Sprint 2.3 fix (D.3) — runas migraram pra items_catalog
        // como ItemType.rune. Quem estiver em schema 21 pula direto pra 23
        // sem nunca ter tabelas enchants. Quem já estava em 22 tem tabelas
        // antigas e vai perdê-las no `if (from < 23)` logo abaixo.
        try {
          await m.addColumn(
              playerInventoryTable, playerInventoryTable.appliedRuneKey);
        } catch (e) {
          // ignore: avoid_print
          print('[migration 21→22] addColumn appliedRuneKey failed: $e');
        }
        try {
          await m.addColumn(
              playerInventoryTable, playerInventoryTable.appliedSapKey);
        } catch (e) {
          // ignore: avoid_print
          print('[migration 21→22] addColumn appliedSapKey failed: $e');
        }
        try {
          await m.addColumn(playerInventoryTable,
              playerInventoryTable.sapChargesRemaining);
        } catch (e) {
          // ignore: avoid_print
          print('[migration 21→22] addColumn sapChargesRemaining failed: $e');
        }
      }
      if (from < 23) {
        // Sprint 2.3 fix (D.3) — runas migradas pra items_catalog.
        // Preserva inventário de runas que estava em player_enchants_inventory
        // copiando pro player_inventory (enchant_key já é a key da runa no
        // items_catalog — mesma nomenclatura: RUNE_FIRE_E, etc.).
        // acquired_at na tabela antiga era DateTime (string ISO via Drift);
        // em player_inventory é int millis — converte via strftime.
        // acquired_via é NOT NULL em player_inventory; usa 'quest_reward'
        // como fonte histórica representativa.
        try {
          await customStatement('''
            INSERT INTO player_inventory
              (player_id, item_key, quantity, acquired_at, acquired_via, is_equipped)
            SELECT player_id, enchant_key, quantity,
                   CAST(strftime('%s', acquired_at) AS INTEGER) * 1000,
                   'quest_reward',
                   0
            FROM player_enchants_inventory
          ''');
          // ignore: avoid_print
          print('[migration 22→23] migrated player_enchants_inventory '
              '→ player_inventory');
        } catch (e) {
          // Tolerante: se a tabela não existe (upgrade 21→23 direto), OK.
          // ignore: avoid_print
          print('[migration 22→23] INSERT player_enchants_inventory skipped: $e');
        }
        try {
          await customStatement('DROP TABLE IF EXISTS player_enchants_inventory');
          await customStatement('DROP TABLE IF EXISTS enchants_catalog');
          // ignore: avoid_print
          print('[migration 22→23] dropped enchants tables');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 22→23] DROP failed: $e');
        }
      }
      if (from < 24) {
        // Sprint 3.1 — RESET BRUTAL. App sem usuários reais (R4-Q1), sem
        // backfill. Dropa hábitos/quests/achievements legacy e cria o novo
        // modelo unificado (ver tabelas em tables/player_mission_*.dart).
        //
        // Achievements (catálogo + player_achievements) removidos da Drift:
        // catálogo passa a ser JSON em runtime (Bloco 8), progresso do
        // jogador vive em player_achievements_completed.
        //
        // active_faction_quests é recriada com UNIQUE
        // (player_id, faction_id, week_start), fechando dívida da Sprint 2.3
        // e eliminando a race condition do assignWeeklyQuest.
        try {
          await customStatement('DROP TABLE IF EXISTS habits');
          await customStatement('DROP TABLE IF EXISTS habit_logs');
          await customStatement('DROP TABLE IF EXISTS class_quests');
          await customStatement('DROP TABLE IF EXISTS active_faction_quests');
          await customStatement('DROP TABLE IF EXISTS achievements');
          await customStatement('DROP TABLE IF EXISTS player_achievements');
          // ignore: avoid_print
          print('[migration 23→24] dropped legacy habit/quest/achievement tables');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 23→24] DROP legacy failed: $e');
        }
        try {
          await m.createTable(playerMissionProgressTable);
          await m.createTable(playerMissionPreferencesTable);
          await m.createTable(playerIndividualMissionsTable);
          await m.createTable(playerAchievementsCompletedTable);
          await m.createTable(playerFactionReputationTable);
          await m.createTable(activeFactionQuestsTable);
          // Índice UNIQUE declarado via @TableIndex na própria tabela — a
          // chamada abaixo garante que ele seja criado mesmo em upgrade
          // (createAll só roda em onCreate).
          await m.createIndex(Index(
            'unique_player_faction_week',
            'CREATE UNIQUE INDEX IF NOT EXISTS unique_player_faction_week '
                'ON active_faction_quests (player_id, faction_id, week_start)',
          ));
          // ignore: avoid_print
          print('[migration 23→24] created 6 new mission tables + UNIQUE');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 23→24] CREATE new failed: $e');
        }
      }
      if (from < 25) {
        // Sprint 3.1 Bloco 13b — adiciona 2 colunas nullable pra persistir
        // boot-check do DailyResetService/WeeklyResetService (ms epoch).
        // Nullable = null aceita pra users pré-reset (tratado como ">24h/7d
        // atrás" no service → primeira chamada aplica reset).
        try {
          await m.addColumn(playersTable, playersTable.lastDailyReset);
          await m.addColumn(playersTable, playersTable.lastWeeklyReset);
          // ignore: avoid_print
          print('[migration 24→25] added last_daily_reset + last_weekly_reset');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 24→25] addColumn failed: $e');
        }
      }
      if (from < 26) {
        // Sprint 3.2 Etapa 1.0 — perfil + IMC. Adiciona weight_kg e height_cm
        // nullable em players. Coletados na scene "Calibração do Sistema" do
        // onboarding (obrigatório pra novos jogadores). Editáveis em /perfil.
        // Null aceita pra jogadores pré-3.2 (tela de perfil exibe categoria
        // "Incompleto" até preencherem).
        try {
          await m.addColumn(playersTable, playersTable.weightKg);
          await m.addColumn(playersTable, playersTable.heightCm);
          // ignore: avoid_print
          print('[migration 25→26] added weight_kg + height_cm');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 25→26] addColumn failed: $e');
        }
      }
      if (from < 27) {
        // Sprint 3.2 Etapa 1.2 — missões diárias dinâmicas. Cria tabela
        // daily_missions + 2 colunas auxiliares em players.
        // Independentes de lastDailyReset/streakDays (que cobrem fluxos
        // legacy de MissionProgress e login streak respectivamente).
        try {
          await m.createTable(dailyMissionsTable);
          await m.createIndex(Index(
            'idx_daily_missions_player_data',
            'CREATE INDEX IF NOT EXISTS idx_daily_missions_player_data '
                'ON daily_missions (player_id, data)',
          ));
          await m.addColumn(
              playersTable, playersTable.lastDailyMissionRollover);
          await m.addColumn(playersTable, playersTable.dailyMissionsStreak);
          // ignore: avoid_print
          print('[migration 26→27] created daily_missions + 2 player cols');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 26→27] failed: $e');
        }
      }
      if (from < 28) {
        // Sprint 3.3 Etapa 2.1a — stats agregadas + volume por sub-task.
        // Foundation pros triggers de conquista (Etapa 2.1b). Bulk insert
        // auto-row pra players existentes; novos players recebem row via
        // lazy `findOrCreate` no DAO.
        try {
          await m.createTable(playerDailyMissionStatsTable);
          await m.createTable(playerDailySubtaskVolumeTable);
          final now = DateTime.now().millisecondsSinceEpoch;
          final players = await select(playersTable).get();
          for (final p in players) {
            await into(playerDailyMissionStatsTable).insert(
              PlayerDailyMissionStatsTableCompanion(
                playerId: Value(p.id),
                updatedAt: Value(now),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
          // ignore: avoid_print
          print('[migration 27→28] created stats tables + '
              '${players.length} initial rows');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 27→28] failed: $e');
        }
      }
      if (from < 29) {
        // Sprint 3.3 Etapa 2.1c-α — contadores all-time pra triggers
        // não-daily. 3 colunas em players. Backfill `peak_level = level`
        // pra players existentes (refletem realidade — não nascem em 1
        // com level 5).
        try {
          await m.addColumn(playersTable, playersTable.totalGemsSpent);
          // ignore: avoid_print
          print('[migration 28→29] added total_gems_spent');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 28→29] addColumn total_gems_spent failed: $e');
        }
        try {
          await m.addColumn(playersTable, playersTable.peakLevel);
          // ignore: avoid_print
          print('[migration 28→29] added peak_level');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 28→29] addColumn peak_level failed: $e');
        }
        try {
          await m.addColumn(
              playersTable, playersTable.totalAttributePointsSpent);
          // ignore: avoid_print
          print('[migration 28→29] added total_attribute_points_spent');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 28→29] addColumn '
              'total_attribute_points_spent failed: $e');
        }
        try {
          // Backfill: players acima do level 1 já têm peak igual ao
          // level atual. Players novos (level=1) ficam com default=1.
          await customStatement(
              'UPDATE players SET peak_level = level WHERE level > 1');
          // ignore: avoid_print
          print('[migration 28→29] backfilled peak_level = level');
        } catch (e) {
          // ignore: avoid_print
          print('[migration 28→29] backfill peak_level failed: $e');
        }
      }
      if (from < 30) {
        // Sprint 3.3 HOTFIX — corretiva da migration 27→28 que falhou
        // silencioso. Ver
        // `.vault/02_ADRs/ADR-0019-drift-migration-dataclass-pitfall.md`.
        await _applyHotfix29To30();
      }
      if (from < 31) {
        // Sprint 3.3 Etapa 2.1c-β — modo automático de daily missions.
        // 4 colunas novas (1 em players + 1 em daily_missions + 2 em
        // player_daily_mission_stats). Aplicação do ADR-0019: usamos
        // só m.addColumn (não chama select(table).get() em data class).
        try {
          await m.addColumn(playersTable, playersTable.autoConfirmEnabled);
          // ignore: avoid_print
          print('[migration 30→31] added auto_confirm_enabled');
        } catch (e, st) {
          // ignore: avoid_print
          print('[migration 30→31] addColumn auto_confirm_enabled '
              'failed: $e\n$st');
        }
        try {
          await m.addColumn(
              dailyMissionsTable, dailyMissionsTable.wasAutoConfirmed);
          // ignore: avoid_print
          print('[migration 30→31] added was_auto_confirmed');
        } catch (e, st) {
          // ignore: avoid_print
          print('[migration 30→31] addColumn was_auto_confirmed '
              'failed: $e\n$st');
        }
        try {
          await m.addColumn(playerDailyMissionStatsTable,
              playerDailyMissionStatsTable.totalAutoConfirmCompletions);
          // ignore: avoid_print
          print('[migration 30→31] added total_auto_confirm_completions');
        } catch (e, st) {
          // ignore: avoid_print
          print('[migration 30→31] addColumn '
              'total_auto_confirm_completions failed: $e\n$st');
        }
        try {
          await m.addColumn(
              playerDailyMissionStatsTable,
              playerDailyMissionStatsTable
                  .totalZeroProgressManualConfirms);
          // ignore: avoid_print
          print('[migration 30→31] added '
              'total_zero_progress_manual_confirms');
        } catch (e, st) {
          // ignore: avoid_print
          print('[migration 30→31] addColumn '
              'total_zero_progress_manual_confirms failed: $e\n$st');
        }
      }
    },
    beforeOpen: (details) async {
      await _selfHealCatalogs();
    },
  );

  /// Sprint 3.3 HOTFIX — corretiva da migration 27→28 que falhou
  /// silencioso em devices que upgradaram 27→29 sequencial. Ver
  /// `.vault/02_ADRs/ADR-0019-drift-migration-dataclass-pitfall.md`
  /// pro contexto completo.
  ///
  /// IDEMPOTENTE:
  ///   - `CREATE TABLE IF NOT EXISTS` cobre devices fresh (no-op porque
  ///     `onCreate.createAll()` já criou) E o edge case onde o
  ///     `m.createTable` original também não rodou.
  ///   - `customSelect('SELECT id FROM players')` evita o pitfall do
  ///     data class (codegen reflete schema atual; `select(playersTable)`
  ///     lança null check em colunas non-null não-existentes).
  ///   - `insertOrIgnore` no bulk insert não duplica rows existentes.
  Future<void> _applyHotfix29To30() async {
    try {
      await customStatement('''
        CREATE TABLE IF NOT EXISTS player_daily_mission_stats (
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
        )
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS player_daily_subtask_volume (
          player_id INTEGER NOT NULL,
          sub_task_key TEXT NOT NULL,
          total_units INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (player_id, sub_task_key)
        )
      ''');

      // customSelect lê só `id` — bypassa o pitfall do data class.
      final result = await customSelect('SELECT id FROM players').get();
      final now = DateTime.now().millisecondsSinceEpoch;
      int processed = 0;
      for (final row in result) {
        final pid = row.read<int>('id');
        await into(playerDailyMissionStatsTable).insert(
          PlayerDailyMissionStatsTableCompanion(
            playerId: Value(pid),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        processed++;
      }
      // ignore: avoid_print
      print('[migration 29→30] hotfix: reaplicada 27→28 (idempotente). '
          'Players processados: $processed');
    } catch (e) {
      // ignore: avoid_print
      print('[migration 29→30] hotfix failed: $e');
    }
  }

  // Rede de proteção contra seeds que falharam silenciosamente por asset
  // missing. Roda 1x por abertura do DB (uma query de contagem). Se detecta
  // catálogo vazio, re-seeda + libera starter recipes pra todos players
  // existentes. Idempotente via insertOrIgnore.
  //
  // Origem: bug reportado na validação manual da Sprint 2.2 — recipes.json
  // não estava declarado em pubspec.yaml, seeder falhava silencioso,
  // recipes_catalog ficava vazia e /forge aparecia sem nada.
  Future<void> _selfHealCatalogs() async {
    try {
      // ─── Recipes ────────────────────────────────────────────────────────
      final recipesCount =
          (await select(recipesCatalogTable).get()).length;
      if (recipesCount == 0) {
        // ignore: avoid_print
        print('[self-heal] recipes_catalog vazia, re-seeding...');
        final seeder = RecipesCatalogSeeder(this);
        await seeder.seed();
        final players = await select(playersTable).get();
        for (final p in players) {
          await seeder.unlockStarterRecipesFor(p.id);
        }
        // ignore: avoid_print
        print('[self-heal] recipes_catalog re-seeded, '
            '${players.length} players updated.');
      }

      // ─── Items ──────────────────────────────────────────────────────────
      // Compara count atual no DB contra count no JSON. Se DB < JSON, algum
      // item novo foi adicionado ao asset sem bumpar schemaVersion (acontece
      // quando catálogo cresce entre sprints). Re-seed é idempotente via
      // insertOrIgnore no ItemsCatalogSeeder.
      final itemsInDb = (await select(itemsCatalogTable).get()).length;
      final rawItems =
          await rootBundle.loadString('assets/data/items_unified.json');
      final dataItems = json.decode(rawItems) as Map<String, dynamic>;
      final itemsInJson = (dataItems['items'] as List).length;
      if (itemsInDb < itemsInJson) {
        // ignore: avoid_print
        print('[self-heal] items_catalog tem $itemsInDb no DB vs '
            '$itemsInJson no JSON — re-seeding...');
        await ItemsCatalogSeeder(this).seed();
        final itemsAfter = (await select(itemsCatalogTable).get()).length;
        // ignore: avoid_print
        print('[self-heal] items_catalog agora com $itemsAfter itens.');
      }

      // Sprint 2.3 fix (D.3) — enchants_catalog dropado na migration 22→23.
      // Runas agora são items no items_catalog (ItemType.rune).
      // Self-heal de runas agora é coberto pelo self-heal de items_catalog
      // logo acima — contagem DB vs JSON pega 50 runas + 191 outros items
      // no total (241) e re-seeda idempotente se algo faltar.
    } catch (e, st) {
      // ignore: avoid_print
      print('[self-heal] failed: $e\n$st');
      // Não propaga — app continua abrindo mesmo se heal falhar.
    }
  }

  // Sprint 3.1 — _seedAchievements() removido. Catálogo agora é JSON em
  // runtime (AchievementsService lê assets/data/achievements.json no Bloco 8).
  // player_achievements_completed guarda apenas a interseção jogador × key.

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'noheroes.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
