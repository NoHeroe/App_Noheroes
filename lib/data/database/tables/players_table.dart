import 'package:drift/drift.dart';

class PlayersTable extends Table {
  @override
  String get tableName => 'players';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get shadowName => text().withDefault(const Constant('Sombra'))();

  // Progressão
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get xpToNext => integer().withDefault(const Constant(100))();
  IntColumn get attributePoints => integer().withDefault(const Constant(0))();

  // Vitalismo (progressão — só usado por classes vitalistas)
  IntColumn get vitalismLevel => integer().withDefault(const Constant(0))();
  IntColumn get vitalismXp => integer().withDefault(const Constant(0))();

  // Atributos base
  IntColumn get strength => integer().withDefault(const Constant(1))();
  IntColumn get dexterity => integer().withDefault(const Constant(1))();
  IntColumn get intelligence => integer().withDefault(const Constant(1))();
  IntColumn get constitution => integer().withDefault(const Constant(1))();
  IntColumn get spirit => integer().withDefault(const Constant(1))();
  IntColumn get charisma => integer().withDefault(const Constant(1))();

  // Status derivados (calculados)
  IntColumn get hp => integer().withDefault(const Constant(100))();
  IntColumn get maxHp => integer().withDefault(const Constant(100))();
  IntColumn get mp => integer().withDefault(const Constant(90))();
  IntColumn get maxMp => integer().withDefault(const Constant(90))();
  IntColumn get currentVitalism => integer().withDefault(const Constant(0))();

  // Economia
  IntColumn get gold => integer().withDefault(const Constant(0))();
  IntColumn get gems => integer().withDefault(const Constant(0))();

  // Progressão narrativa
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  IntColumn get caelumDay => integer().withDefault(const Constant(1))();
  TextColumn get shadowState => text().withDefault(const Constant('stable'))();
  IntColumn get shadowCorruption => integer().withDefault(const Constant(0))();

  // Classe e facção
  TextColumn get classType => text().nullable()();
  TextColumn get factionType => text().nullable()();

  // Rank da Guilda de Aventureiros (e/d/c/b/a/s)
  TextColumn get guildRank => text().withDefault(const Constant('none'))();

  // Preferências
  TextColumn get narrativeMode => text().withDefault(const Constant('longa'))();
  BoolColumn get onboardingDone => boolean().withDefault(const Constant(false))();
  TextColumn get playStyle => text().withDefault(const Constant('none'))(); // none/solo/duo/team

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLoginAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastStreakDate => dateTime().nullable()();
}
