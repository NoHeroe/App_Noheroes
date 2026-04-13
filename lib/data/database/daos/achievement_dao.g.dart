// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_dao.dart';

// ignore_for_file: type=lint
mixin _$AchievementDaoMixin on DatabaseAccessor<AppDatabase> {
  $AchievementsTableTable get achievementsTable =>
      attachedDatabase.achievementsTable;
  $PlayerAchievementsTableTable get playerAchievementsTable =>
      attachedDatabase.playerAchievementsTable;
  AchievementDaoManager get managers => AchievementDaoManager(this);
}

class AchievementDaoManager {
  final _$AchievementDaoMixin _db;
  AchievementDaoManager(this._db);
  $$AchievementsTableTableTableManager get achievementsTable =>
      $$AchievementsTableTableTableManager(
          _db.attachedDatabase, _db.achievementsTable);
  $$PlayerAchievementsTableTableTableManager get playerAchievementsTable =>
      $$PlayerAchievementsTableTableTableManager(
          _db.attachedDatabase, _db.playerAchievementsTable);
}
