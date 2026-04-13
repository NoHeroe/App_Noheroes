import 'package:drift/drift.dart';

class InventoryTable extends Table {
  @override
  String get tableName => 'inventory';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  IntColumn get itemId => integer()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  BoolColumn get isEquipped => boolean().withDefault(const Constant(false))();
  TextColumn get equippedSlot => text().nullable()();
  DateTimeColumn get acquiredAt => dateTime().withDefault(currentDateAndTime)();
}
