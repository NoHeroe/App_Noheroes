import 'package:drift/drift.dart';

import '../../../domain/repositories/player_achievements_repository.dart';
import '../../database/app_database.dart';

class PlayerAchievementsRepositoryDrift
    implements PlayerAchievementsRepository {
  final AppDatabase _db;
  PlayerAchievementsRepositoryDrift(this._db);

  @override
  Future<bool> isCompleted(int playerId, String achievementKey) async {
    final row = await (_db.select(_db.playerAchievementsCompletedTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.achievementKey.equals(achievementKey)))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<List<String>> listCompletedKeys(int playerId) async {
    final query = _db.select(_db.playerAchievementsCompletedTable)
      ..where((t) => t.playerId.equals(playerId))
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]);
    final rows = await query.get();
    return rows.map((r) => r.achievementKey).toList(growable: false);
  }

  @override
  Future<void> markCompleted(
    int playerId,
    String achievementKey, {
    required DateTime at,
  }) async {
    await _db.into(_db.playerAchievementsCompletedTable).insert(
          PlayerAchievementsCompletedTableCompanion(
            playerId: Value(playerId),
            achievementKey: Value(achievementKey),
            completedAt: Value(at.millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> markRewardClaimed(
      int playerId, String achievementKey) async {
    await (_db.update(_db.playerAchievementsCompletedTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.achievementKey.equals(achievementKey)))
        .write(
            const PlayerAchievementsCompletedTableCompanion(
          rewardClaimed: Value(true),
        ));
  }

  @override
  Future<bool> isRewardClaimed(int playerId, String achievementKey) async {
    final row = await (_db.select(_db.playerAchievementsCompletedTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.achievementKey.equals(achievementKey)))
        .getSingleOrNull();
    return row != null && row.rewardClaimed;
  }

  @override
  Future<int> countCompleted(int playerId) async {
    final count = _db.playerAchievementsCompletedTable.playerId.count();
    final query = _db.selectOnly(_db.playerAchievementsCompletedTable)
      ..addColumns([count])
      ..where(_db.playerAchievementsCompletedTable.playerId.equals(playerId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<List<String>> listPendingClaims(int playerId) async {
    final query = _db.select(_db.playerAchievementsCompletedTable)
      ..where((t) =>
          t.playerId.equals(playerId) & t.rewardClaimed.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]);
    final rows = await query.get();
    return rows.map((r) => r.achievementKey).toList(growable: false);
  }
}
