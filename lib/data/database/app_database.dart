import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/players_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_logs_table.dart';
import 'tables/items_table.dart';
import 'tables/inventory_table.dart';
import 'tables/shop_items_table.dart';
import 'daos/player_dao.dart';
import 'daos/habit_dao.dart';
import 'daos/inventory_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PlayersTable, HabitsTable, HabitLogsTable,
    ItemsTable, InventoryTable, ShopItemsTable,
  ],
  daos: [PlayerDao, HabitDao, InventoryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedShopItems();
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
    },
  );

  // Seed de itens básicos na loja
  Future<void> _seedShopItems() async {
    // Cria itens básicos
    final items = [
      ItemsTableCompanion(
        name: const Value('Poção de Cura Fraca'),
        description: const Value('Restaura 30 HP.'),
        type: const Value('consumable'),
        rarity: const Value('common'),
        goldValue: const Value(25),
        hpBonus: const Value(30),
        isConsumable: const Value(true),
        isStackable: const Value(true),
        iconName: const Value('potion_hp'),
      ),
      ItemsTableCompanion(
        name: const Value('Poção de Mana Fraca'),
        description: const Value('Restaura 30 MP.'),
        type: const Value('consumable'),
        rarity: const Value('common'),
        goldValue: const Value(25),
        mpBonus: const Value(30),
        isConsumable: const Value(true),
        isStackable: const Value(true),
        iconName: const Value('potion_mp'),
      ),
      ItemsTableCompanion(
        name: const Value('Runa do Iniciante'),
        description: const Value('Um fragmento de poder rúnico. +2 Força.'),
        type: const Value('material'),
        rarity: const Value('uncommon'),
        goldValue: const Value(50),
        strBonus: const Value(2),
        isStackable: const Value(true),
        iconName: const Value('rune'),
      ),
      ItemsTableCompanion(
        name: const Value('Adaga das Sombras'),
        description: const Value('Lâmina forjada na escuridão. +3 Destreza.'),
        type: const Value('weapon'),
        rarity: const Value('uncommon'),
        slot: const Value('weapon'),
        goldValue: const Value(120),
        dexBonus: const Value(3),
        iconName: const Value('dagger'),
      ),
      ItemsTableCompanion(
        name: const Value('Manto do Aprendiz'),
        description: const Value('Armadura leve. +2 Constituição.'),
        type: const Value('armor'),
        rarity: const Value('common'),
        slot: const Value('chest'),
        goldValue: const Value(80),
        conBonus: const Value(2),
        iconName: const Value('armor'),
      ),
      ItemsTableCompanion(
        name: const Value('Amuleto Espiritual'),
        description: const Value('Canaliza energia interna. +3 Espírito.'),
        type: const Value('accessory'),
        rarity: const Value('uncommon'),
        slot: const Value('accessory'),
        goldValue: const Value(100),
        spiBonus: const Value(3),
        iconName: const Value('amulet'),
      ),
    ];

    final ids = <int>[];
    for (final item in items) {
      final id = await into(itemsTable).insert(item);
      ids.add(id);
    }

    // Adiciona à loja
    final prices = [25, 25, 50, 120, 80, 100];
    final levels = [1, 1, 3, 5, 3, 5];
    for (var i = 0; i < ids.length; i++) {
      await into(shopItemsTable).insert(ShopItemsTableCompanion(
        itemId: Value(ids[i]),
        price: Value(prices[i]),
        requiredLevel: Value(levels[i]),
      ));
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
