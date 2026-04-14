import 'package:drift/drift.dart';

class NpcReputationTable extends Table {
  @override
  String get tableName => 'npc_reputation';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get npcId => text()();
  IntColumn get reputation => integer().withDefault(const Constant(50))();
  DateTimeColumn get lastGainAt => dateTime().nullable()();
  IntColumn get dailyGained => integer().withDefault(const Constant(0))();
}
