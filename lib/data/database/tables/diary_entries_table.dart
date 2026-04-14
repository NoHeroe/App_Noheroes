import 'package:drift/drift.dart';

class DiaryEntriesTable extends Table {
  @override
  String get tableName => 'diary_entries';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get entryDate => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
