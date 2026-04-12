import 'package:drift/drift.dart';

class HabitLogsTable extends Table {
  @override
  String get tableName => 'habit_logs';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer()();
  IntColumn get playerId => integer()();
  TextColumn get status => text()(); // completed, partial, failed, niet
  IntColumn get xpGained => integer().withDefault(const Constant(0))();
  IntColumn get goldGained => integer().withDefault(const Constant(0))();
  IntColumn get shadowImpact => integer().withDefault(const Constant(0))(); // -10 a +10
  DateTimeColumn get logDate => dateTime().withDefault(currentDateAndTime)();
}
