import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/enums/intensity.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/enums/mission_style.dart';
import '../../../domain/models/mission_preferences.dart';
import '../../../domain/repositories/mission_preferences_repository.dart';
import '../../database/app_database.dart';

class MissionPreferencesRepositoryDrift
    implements MissionPreferencesRepository {
  final AppDatabase _db;
  MissionPreferencesRepositoryDrift(this._db);

  MissionPreferences _toDomain(PlayerMissionPreferencesData row) {
    return MissionPreferences.fromJson({
      'player_id': row.playerId,
      'primary_focus': row.primaryFocus,
      'intensity': row.intensity,
      'mission_style': row.missionStyle,
      // Subfocus vem como TEXT JSON no DB — fromJson parseia.
      'physical_subfocus': row.physicalSubfocus,
      'mental_subfocus': row.mentalSubfocus,
      'spiritual_subfocus': row.spiritualSubfocus,
      'time_daily_minutes': row.timeDailyMinutes,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'updates_count': row.updatesCount,
    });
  }

  @override
  Future<MissionPreferences?> findByPlayerId(int playerId) async {
    final row = await (_db.select(_db.playerMissionPreferencesTable)
          ..where((t) => t.playerId.equals(playerId)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsert(MissionPreferences prefs) async {
    await _db.into(_db.playerMissionPreferencesTable).insertOnConflictUpdate(
          PlayerMissionPreferencesTableCompanion(
            playerId: Value(prefs.playerId),
            primaryFocus: Value(prefs.primaryFocus.storage),
            intensity: Value(prefs.intensity.storage),
            missionStyle: Value(prefs.missionStyle.storage),
            physicalSubfocus: Value(jsonEncode(prefs.physicalSubfocus)),
            mentalSubfocus: Value(jsonEncode(prefs.mentalSubfocus)),
            spiritualSubfocus: Value(jsonEncode(prefs.spiritualSubfocus)),
            timeDailyMinutes: Value(prefs.timeDailyMinutes),
            createdAt: Value(prefs.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(prefs.updatedAt.millisecondsSinceEpoch),
            updatesCount: Value(prefs.updatesCount),
          ),
        );
  }

  @override
  Future<int> updatesCountOf(int playerId) async {
    final row = await (_db.select(_db.playerMissionPreferencesTable)
          ..where((t) => t.playerId.equals(playerId)))
        .getSingleOrNull();
    return row?.updatesCount ?? 0;
  }
}
