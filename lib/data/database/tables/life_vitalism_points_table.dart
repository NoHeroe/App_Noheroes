import 'package:drift/drift.dart';

class LifeVitalismPointsTable extends Table {
  @override
  String get tableName => 'life_vitalism_points';

  IntColumn get playerId => integer()();
  IntColumn get totalPoints => integer().withDefault(const Constant(0))();
  TextColumn get sourceLog => text().withDefault(const Constant('[]'))(); // JSON array

  @override
  Set<Column> get primaryKey => {playerId};
}
