import 'package:drift/drift.dart';

class PlayersTable extends Table {
  @override
  String get tableName => 'players';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get shadowName => text().withDefault(const Constant('Sombra'))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get xpToNext => integer().withDefault(const Constant(100))();
  IntColumn get hp => integer().withDefault(const Constant(100))();
  IntColumn get maxHp => integer().withDefault(const Constant(100))();
  IntColumn get mp => integer().withDefault(const Constant(100))();
  IntColumn get maxMp => integer().withDefault(const Constant(100))();
  IntColumn get gold => integer().withDefault(const Constant(0))();
  IntColumn get gems => integer().withDefault(const Constant(0))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  IntColumn get caelumDay => integer().withDefault(const Constant(1))();
  TextColumn get shadowState => text().withDefault(const Constant('stable'))();
  TextColumn get classType => text().nullable()();
  TextColumn get factionType => text().nullable()();
  TextColumn get narrativeMode => text().withDefault(const Constant('longa'))();
  BoolColumn get onboardingDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLoginAt => dateTime().withDefault(currentDateAndTime)();
}
