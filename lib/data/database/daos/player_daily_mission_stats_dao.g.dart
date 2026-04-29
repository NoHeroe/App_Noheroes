// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_daily_mission_stats_dao.dart';

// ignore_for_file: type=lint
mixin _$PlayerDailyMissionStatsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlayerDailyMissionStatsTableTable get playerDailyMissionStatsTable =>
      attachedDatabase.playerDailyMissionStatsTable;
  PlayerDailyMissionStatsDaoManager get managers =>
      PlayerDailyMissionStatsDaoManager(this);
}

class PlayerDailyMissionStatsDaoManager {
  final _$PlayerDailyMissionStatsDaoMixin _db;
  PlayerDailyMissionStatsDaoManager(this._db);
  $$PlayerDailyMissionStatsTableTableTableManager
      get playerDailyMissionStatsTable =>
          $$PlayerDailyMissionStatsTableTableTableManager(
              _db.attachedDatabase, _db.playerDailyMissionStatsTable);
}
