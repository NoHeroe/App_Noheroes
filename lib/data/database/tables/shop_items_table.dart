import 'package:drift/drift.dart';

class ShopItemsTable extends Table {
  @override
  String get tableName => 'shop_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer()();
  TextColumn get currency => text().withDefault(const Constant('gold'))(); // gold, gems
  IntColumn get price => integer()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  IntColumn get requiredLevel => integer().withDefault(const Constant(1))();
}
