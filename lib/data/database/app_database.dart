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
import 'tables/achievements_table.dart';
import 'tables/player_achievements_table.dart';
import 'daos/player_dao.dart';
import 'daos/habit_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/achievement_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PlayersTable, HabitsTable, HabitLogsTable,
    ItemsTable, InventoryTable, ShopItemsTable,
    AchievementsTable, PlayerAchievementsTable,
  ],
  daos: [PlayerDao, HabitDao, InventoryDao, AchievementDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

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
    },
  );

  Future<void> _seedShopItems() async {
    final items = [
      (ItemsTableCompanion(
        name: const Value('Pocao de Cura Fraca'),
        description: const Value('Restaura 30 HP.'),
        type: const Value('consumable'),
        rarity: const Value('common'),
        goldValue: const Value(25),
        hpBonus: const Value(30),
        isConsumable: const Value(true),
        isStackable: const Value(true),
        iconName: const Value('potion_hp'),
      ), 25, 1),
      (ItemsTableCompanion(
        name: const Value('Pocao de Mana Fraca'),
        description: const Value('Restaura 30 MP.'),
        type: const Value('consumable'),
        rarity: const Value('common'),
        goldValue: const Value(25),
        mpBonus: const Value(30),
        isConsumable: const Value(true),
        isStackable: const Value(true),
        iconName: const Value('potion_mp'),
      ), 25, 1),
      (ItemsTableCompanion(
        name: const Value('Runa do Iniciante'),
        description: const Value('Fragmento de poder runico. +2 Forca.'),
        type: const Value('material'),
        rarity: const Value('uncommon'),
        goldValue: const Value(50),
        strBonus: const Value(2),
        isStackable: const Value(true),
        iconName: const Value('rune'),
      ), 50, 3),
      (ItemsTableCompanion(
        name: const Value('Adaga das Sombras'),
        description: const Value('Lamina forjada na escuridao. +3 Destreza.'),
        type: const Value('weapon'),
        rarity: const Value('uncommon'),
        slot: const Value('weapon'),
        goldValue: const Value(120),
        dexBonus: const Value(3),
        iconName: const Value('dagger'),
      ), 120, 5),
      (ItemsTableCompanion(
        name: const Value('Manto do Aprendiz'),
        description: const Value('Armadura leve. +2 Constituicao.'),
        type: const Value('armor'),
        rarity: const Value('common'),
        slot: const Value('chest'),
        goldValue: const Value(80),
        conBonus: const Value(2),
        iconName: const Value('armor'),
      ), 80, 3),
      (ItemsTableCompanion(
        name: const Value('Amuleto Espiritual'),
        description: const Value('Canaliza energia interna. +3 Espirito.'),
        type: const Value('accessory'),
        rarity: const Value('uncommon'),
        slot: const Value('accessory'),
        goldValue: const Value(100),
        spiBonus: const Value(3),
        iconName: const Value('amulet'),
      ), 100, 5),
    ];

    for (final data in items) {
      final id = await into(itemsTable).insert(data.$1);
      await into(shopItemsTable).insert(ShopItemsTableCompanion(
        itemId: Value(id),
        price: Value(data.$2),
        requiredLevel: Value(data.$3),
      ));
    }
  }

  Future<void> _seedAchievements() async {
    final achievements = [
      // Progressão
      ('first_level',    'Primeiro Passo',        'Atingiu o Nivel 2.',              'progression', 50,  25,  0,  false),
      ('level_5',        'Forma Tomando Shape',   'Atingiu o Nivel 5.',              'progression', 150, 75,  1,  false),
      ('level_10',       'Sombra Reconhecida',    'Atingiu o Nivel 10.',             'progression', 300, 150, 2,  false),
      ('caelum_7',       'Uma Semana em Caelum',  '7 dias em Caelum.',               'progression', 100, 50,  1,  false),
      ('caelum_30',      'Um Mes em Caelum',      '30 dias em Caelum.',              'progression', 300, 150, 3,  false),
      // Habitos
      ('first_habit',    'Primeiro Ritual',       'Completou seu primeiro ritual.',  'habits',      50,  25,  0,  false),
      ('habit_10',       'Disciplina Inicial',    '10 rituais completados.',         'habits',      100, 50,  0,  false),
      ('habit_50',       'Caminho da Disciplina', '50 rituais completados.',         'habits',      200, 100, 1,  false),
      ('habit_100',      'Cem Rituais',           '100 rituais completados.',        'habits',      400, 200, 2,  false),
      ('streak_7',       'Semana Impecavel',      '7 dias de streak.',               'habits',      150, 75,  1,  false),
      ('streak_30',      'Mes Sem Falhas',        '30 dias de streak.',              'habits',      500, 250, 3,  false),
      // Sombra
      ('shadow_stable',  'Equilibrio Interno',    'Manteve sombra estavel por 3d.',  'shadow',      100, 50,  0,  false),
      ('shadow_ascend',  'Ascensao',              'Atingiu estado Ascendente.',      'shadow',      200, 100, 2,  true),
      ('shadow_boss',    'Confronto Interno',     'Derrotou um Shadow Boss.',        'shadow',      500, 250, 5,  true),
      // Exploracao
      ('first_item',     'Primeiro Tesouro',      'Adquiriu seu primeiro item.',     'exploration', 75,  35,  0,  false),
      ('first_buy',      'Mercador de Caelum',    'Comprou algo na loja.',           'exploration', 50,  25,  0,  false),
      ('gold_500',       'Acumulador',            'Acumulou 500 de ouro.',           'exploration', 100, 0,   1,  false),
    ];

    for (final a in achievements) {
      await into(achievementsTable).insert(AchievementsTableCompanion(
        key:         Value(a.$1),
        title:       Value(a.$2),
        description: Value(a.$3),
        category:    Value(a.$4),
        xpReward:    Value(a.$5),
        goldReward:  Value(a.$6),
        gemReward:   Value(a.$7),
        isSecret:    Value(a.$8),
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
