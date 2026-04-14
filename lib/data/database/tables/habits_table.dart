import 'package:drift/drift.dart';
import 'players_table.dart';

class HabitsTable extends Table {
  @override
  String get tableName => 'habits';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text()();
  TextColumn get rank => text().withDefault(const Constant('e'))();
  BoolColumn get isSystemHabit => boolean().withDefault(const Constant(false))();
  BoolColumn get isRepeatable => boolean().withDefault(const Constant(false))();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  IntColumn get xpReward => integer().withDefault(const Constant(20))();
  IntColumn get goldReward => integer().withDefault(const Constant(10))();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  IntColumn get totalCompleted => integer().withDefault(const Constant(0))();
  // JSON: [{"label":"10 flexões","target":10,"done":0}, ...]
  TextColumn get requirements => text().nullable()();
  // Tipo: daily|individual|class|faction|shadow|lore|auto
  TextColumn get questType => text().withDefault(const Constant('individual'))();
  // Unidade métrica: reps|km|min|pages|words|glasses|hours|cycles
  TextColumn get metricUnit => text().withDefault(const Constant('reps'))();
  // Descrição temática automática
  TextColumn get autoDescription => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
