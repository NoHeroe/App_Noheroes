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
import 'daos/inventory_dao.dart';
import 'daos/achievement_dao.dart';
import 'daos/guild_dao.dart';
import 'tables/guild_status_table.dart';
import 'tables/npc_reputation_table.dart';
import 'tables/diary_entries_table.dart';

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
  ],
  daos: [PlayerDao, HabitDao, InventoryDao, AchievementDao, GuildDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedShopItems();
      await _seedAchievements();
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
        await _seedShopItems();
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
    },
  );

  Future<void> _seedShopItems() async {
    try {
      final raw = await rootBundle.loadString('assets/data/items.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = (data['items'] as List).cast<Map<String, dynamic>>();
      for (final item in list) {
        // Verifica se já existe pelo nome
        final existing = await (select(itemsTable)
              ..where((t) => t.name.equals(item['name'] as String)))
            .getSingleOrNull();
        if (existing != null) continue;

        final id = await into(itemsTable).insert(ItemsTableCompanion(
          name:        Value(item['name'] as String),
          description: Value(item['description'] as String),
          type:        Value(item['type'] as String),
          rarity:      Value(item['rarity'] as String? ?? 'common'),
          slot:        Value(item['slot'] as String?),
          goldValue:   Value(item['gold_value'] as int? ?? 0),
          hpBonus:     Value(item['hp_bonus'] as int? ?? 0),
          mpBonus:     Value(item['mp_bonus'] as int? ?? 0),
          strBonus:    Value(item['str_bonus'] as int? ?? 0),
          dexBonus:    Value(item['dex_bonus'] as int? ?? 0),
          intBonus:    Value(item['int_bonus'] as int? ?? 0),
          conBonus:    Value(item['con_bonus'] as int? ?? 0),
          spiBonus:    Value(item['spi_bonus'] as int? ?? 0),
          isConsumable: Value(item['is_consumable'] as bool? ?? false),
          isStackable:  Value(item['is_stackable'] as bool? ?? false),
          iconName:    Value(item['icon'] as String? ?? 'item'),
        ));

        // Adiciona à loja se shop == true
        if (item['shop'] == true) {
          await into(shopItemsTable).insert(ShopItemsTableCompanion(
            itemId:        Value(id),
            price:         Value(item['gold_value'] as int? ?? 0),
            requiredLevel: Value(item['required_level'] as int? ?? 1),
          ));
        }
      }
    } catch (e) {
      // Fallback silencioso
    }
  }

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
