// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_missions_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyMissionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyMissionsTableTable get dailyMissionsTable =>
      attachedDatabase.dailyMissionsTable;
  DailyMissionsDaoManager get managers => DailyMissionsDaoManager(this);
}

class DailyMissionsDaoManager {
  final _$DailyMissionsDaoMixin _db;
  DailyMissionsDaoManager(this._db);
  $$DailyMissionsTableTableTableManager get dailyMissionsTable =>
      $$DailyMissionsTableTableTableManager(
          _db.attachedDatabase, _db.dailyMissionsTable);
}
