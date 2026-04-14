import 'package:drift/drift.dart';

class AchievementsTable extends Table {
  @override
  String get tableName => 'achievements';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get category => text()(); // progression, habits, shadow, exploration, social
  TextColumn get iconName => text().withDefault(const Constant('star'))();
  IntColumn get xpReward => integer().withDefault(const Constant(50))();
  IntColumn get goldReward => integer().withDefault(const Constant(25))();
  IntColumn get gemReward => integer().withDefault(const Constant(0))();
  BoolColumn get isSecret => boolean().withDefault(const Constant(false))();
  TextColumn get rarity => text().withDefault(const Constant('common'))();
  TextColumn get titleReward => text().nullable()();
  TextColumn get category2 => text().nullable()(); // subcategoria
}
