import 'package:drift/drift.dart';

class VitalismUniqueCatalogTable extends Table {
  @override
  String get tableName => 'vitalism_unique_catalog';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get carrierName => text()();
  TextColumn get tier => text()(); // 'common' | 'rare' | 'special'
  TextColumn get themeDescription => text()();

  @override
  Set<Column> get primaryKey => {id};
}
