import 'package:drift/drift.dart';

class ItemsTable extends Table {
  @override
  String get tableName => 'items';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get type => text()(); // weapon, armor, helmet, boots, gloves, shoulders, chest, legs, relic, accessory, consumable, material
  TextColumn get rarity => text().withDefault(const Constant('common'))(); // common, uncommon, rare, epic, legendary, mythic
  TextColumn get slot => text().nullable()(); // equipment slot
  IntColumn get goldValue => integer().withDefault(const Constant(10))();
  IntColumn get gemValue => integer().withDefault(const Constant(0))();
  IntColumn get strBonus => integer().withDefault(const Constant(0))();
  IntColumn get dexBonus => integer().withDefault(const Constant(0))();
  IntColumn get intBonus => integer().withDefault(const Constant(0))();
  IntColumn get conBonus => integer().withDefault(const Constant(0))();
  IntColumn get spiBonus => integer().withDefault(const Constant(0))();
  IntColumn get hpBonus => integer().withDefault(const Constant(0))();
  IntColumn get mpBonus => integer().withDefault(const Constant(0))();
  BoolColumn get isConsumable => boolean().withDefault(const Constant(false))();
  BoolColumn get isStackable => boolean().withDefault(const Constant(false))();
  TextColumn get iconName => text().withDefault(const Constant('item'))();
}
