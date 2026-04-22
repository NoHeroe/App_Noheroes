import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/achievements_table.dart';
import '../tables/player_achievements_table.dart';

part 'achievement_dao.g.dart';

@DriftAccessor(tables: [AchievementsTable, PlayerAchievementsTable])
class AchievementDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementDaoMixin {
  AchievementDao(super.db);

  Future<List<AchievementsTableData>> getAllAchievements() {
    return select(achievementsTable).get();
  }

  Future<List<PlayerAchievementsTableData>> getUnlocked(int playerId) {
    return (select(playerAchievementsTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
  }

  Future<bool> isUnlocked(int playerId, String key) async {
    final result = await (select(playerAchievementsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.achievementKey.equals(key)))
        .getSingleOrNull();
    return result != null;
  }

  Future<AchievementsTableData?> getByKey(String key) {
    return (select(achievementsTable)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
  }

  Future<void> unlock(int playerId, String key) async {
    final already = await isUnlocked(playerId, key);
    if (already) return;
    await into(playerAchievementsTable).insert(
      PlayerAchievementsTableCompanion(
        playerId: Value(playerId),
        achievementKey: Value(key),
      ),
    );
  }

  // Conquistas desbloqueadas mas ainda não coletadas
  Future<List<PlayerAchievementsTableData>> getPending(int playerId) {
    return (select(playerAchievementsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.collectedAt.isNull()))
        .get();
  }

  // Marca conquista como coletada
  Future<void> collect(int playerId, String key) async {
    await (update(playerAchievementsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.achievementKey.equals(key)))
        .write(PlayerAchievementsTableCompanion(
      collectedAt: Value(DateTime.now()),
    ));
  }
}
