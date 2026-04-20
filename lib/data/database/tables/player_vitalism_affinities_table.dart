import 'package:drift/drift.dart';

class PlayerVitalismAffinitiesTable extends Table {
  @override
  String get tableName => 'player_vitalism_affinities';

  IntColumn get playerId => integer()();
  TextColumn get vitalismId => text()();
  IntColumn get acquiredAt => integer()(); // millis since epoch
  TextColumn get acquiredVia => text()(); // 'crystal' | 'pvp_steal' | 'life_ritual'

  @override
  Set<Column> get primaryKey => {playerId, vitalismId};
}
