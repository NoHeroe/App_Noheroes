import 'package:drift/drift.dart';

class PlayerAchievementsTable extends Table {
  @override
  String get tableName => 'player_achievements';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get achievementKey => text()();
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();
}
