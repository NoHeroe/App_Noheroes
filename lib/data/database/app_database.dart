import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/players_table.dart';
import 'tables/class_quests_table.dart';
import 'tables/faction_quests_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_logs_table.dart';
import 'tables/items_table.dart';
import 'tables/inventory_table.dart';
import 'tables/shop_items_table.dart';
import 'tables/achievements_table.dart';
import 'tables/player_achievements_table.dart';
import 'daos/player_dao.dart';
import 'daos/habit_dao.dart';
import 'daos/achievement_dao.dart';
import 'daos/guild_dao.dart';
import '../datasources/local/vitalism_catalog_seeder.dart';
import '../datasources/local/items_catalog_seeder.dart';
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

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PlayersTable, HabitsTable, HabitLogsTable,
    ItemsTable, InventoryTable, ShopItemsTable,
    AchievementsTable, PlayerAchievementsTable,
    GuildStatusTable,
    NpcReputationTable,
    DiaryEntriesTable,
    ClassQuestsTable,
    FactionQuestsTable,
    GuildAscensionTable,
    VitalismUniqueCatalogTable,
    PlayerVitalismAffinitiesTable,
    PlayerVitalismTreesTable,
    LifeVitalismPointsTable,
    ItemsCatalogTable,
    PlayerInventoryTable,
    PlayerEquipmentTable,
  ],
  daos: [PlayerDao, HabitDao, AchievementDao, GuildDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 20;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedAchievements();
      await VitalismCatalogSeeder(this).seed();
      await ItemsCatalogSeeder(this).seed();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(habitsTable);
        await m.createTable(habitLogsTable);
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
        await m.createTable(achievementsTable);
        await m.createTable(playerAchievementsTable);
        await _seedAchievements();
      }
      if (from < 7) {
        try {
          await m.addColumn(habitsTable, habitsTable.requirements as GeneratedColumn<Object>);
        } catch (_) {}
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
        try {
          await m.addColumn(playerAchievementsTable,
              playerAchievementsTable.collectedAt);
        } catch (_) {}
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
        try {
          await m.addColumn(achievementsTable, achievementsTable.rarity);
          await m.addColumn(achievementsTable, achievementsTable.titleReward);
          await m.addColumn(achievementsTable, achievementsTable.category2);
        } catch (_) {}
      }
      if (from < 15) {
        try {
          await m.addColumn(playersTable, playersTable.playStyle);
        } catch (_) {}
      }
      if (from < 16) {
        try {
          await m.createTable(classQuestsTable);
          await m.createTable(factionQuestsTable);
        } catch (_) {}
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
    },
  );

  Future<void> _seedAchievements() async {
    try {
      final raw = await rootBundle.loadString('assets/data/achievements.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = (data['achievements'] as List).cast<Map<String, dynamic>>();
      for (final a in list) {
        await into(achievementsTable).insert(
          AchievementsTableCompanion(
            key:         Value(a['key'] as String),
            title:       Value(a['title'] as String),
            description: Value(a['description'] as String),
            category:    Value(a['category'] as String),
            xpReward:    Value(a['xp'] as int? ?? 0),
            goldReward:  Value(a['gold'] as int? ?? 0),
            gemReward:   Value(a['gems'] as int? ?? 0),
            isSecret:    Value(a['secret'] as bool? ?? false),
            rarity:      Value(a['rarity'] as String? ?? 'common'),
            titleReward: Value(a['title_reward'] as String?),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    } catch (e) {
      // Fallback se asset não carregado ainda
    }
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'noheroes.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
