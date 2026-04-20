import 'package:drift/drift.dart';

class PlayerVitalismTreesTable extends Table {
  @override
  String get tableName => 'player_vitalism_trees';

  IntColumn get playerId => integer()();
  TextColumn get vitalismId => text()();
  TextColumn get nodeId => text()();
  BoolColumn get unlocked => boolean().withDefault(const Constant(false))();
  IntColumn get unlockedAt => integer().nullable()(); // millis since epoch

  @override
  Set<Column> get primaryKey => {playerId, vitalismId, nodeId};
}
