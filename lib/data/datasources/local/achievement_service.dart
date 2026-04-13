import '../../../data/database/app_database.dart';
import '../../../data/database/daos/achievement_dao.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../../data/database/tables/players_table.dart';

class AchievementService {
  final AppDatabase _db;

  AchievementService(this._db);

  AchievementDao get _dao => AchievementDao(_db);
  PlayerDao get _playerDao => PlayerDao(_db);

  // Verifica todas as conquistas para o jogador
  Future<List<String>> checkAndUnlock(
      PlayersTableData player, int totalHabitsCompleted) async {
    final unlocked = <String>[];

    Future<void> tryUnlock(String key) async {
      final already = await _dao.isUnlocked(player.id, key);
      if (!already) {
        await _dao.unlock(player.id, key);
        final achievement = await _dao.getByKey(key);
        if (achievement != null) {
          // Recompensa
          if (achievement.xpReward > 0) {
            await _playerDao.addXp(player.id, achievement.xpReward);
          }
          if (achievement.goldReward > 0) {
            await _playerDao.addGold(player.id, achievement.goldReward);
          }
          unlocked.add(achievement.title);
        }
      }
    }

    // Progressão de nível
    if (player.level >= 2)  await tryUnlock('first_level');
    if (player.level >= 5)  await tryUnlock('level_5');
    if (player.level >= 10) await tryUnlock('level_10');

    // Dias em Caelum
    if (player.caelumDay >= 7)  await tryUnlock('caelum_7');
    if (player.caelumDay >= 30) await tryUnlock('caelum_30');

    // Hábitos
    if (totalHabitsCompleted >= 1)   await tryUnlock('first_habit');
    if (totalHabitsCompleted >= 10)  await tryUnlock('habit_10');
    if (totalHabitsCompleted >= 50)  await tryUnlock('habit_50');
    if (totalHabitsCompleted >= 100) await tryUnlock('habit_100');

    // Streak
    if (player.streakDays >= 7)  await tryUnlock('streak_7');
    if (player.streakDays >= 30) await tryUnlock('streak_30');

    // Sombra
    if (player.shadowState == 'ascending') await tryUnlock('shadow_ascend');

    // Ouro
    if (player.gold >= 500) await tryUnlock('gold_500');

    return unlocked;
  }
}
