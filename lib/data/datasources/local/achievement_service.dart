import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/achievement_dao.dart';

class AchievementService {
  final AppDatabase _db;
  AchievementService(this._db);

  AchievementDao get _dao => AchievementDao(_db);
  Future<void> ensureAchievementsSeedExists() async {
    final all = await _dao.getAllAchievements();
    if (all.isEmpty) {
      await _db.transaction(() async {
        await _seedAchievements();
      });
    }
  }

  Future<void> _seedAchievements() async {
    try {
      final raw = await rootBundle.loadString('assets/data/achievements.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = (data['achievements'] as List).cast<Map<String, dynamic>>();
      for (final a in list) {
        await _db.into(_db.achievementsTable).insert(
          AchievementsTableCompanion(
            key:         Value(a['key'] as String),
            title:       Value(a['title'] as String),
            description: Value(a['description'] as String),
            category:    Value(a['category'] as String),
            xpReward:    Value(a['xp'] as int? ?? 0),
            goldReward:  Value(a['gold'] as int? ?? 0),
            gemReward:   Value(a['gems'] as int? ?? 0),
            isSecret:    Value(a['secret'] as bool? ?? false),
            rarity:      Value(a['rarity'] as String? ?? 'common'),
            titleReward: Value(a['title_reward'] as String?),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    } catch (_) {}
  }

  /// Verifica e desbloqueia conquistas. Busca histórico internamente.
  Future<List<String>> checkAndUnlock(PlayersTableData player) async {
    await ensureAchievementsSeedExists();

    // Busca total de hábitos concluídos internamente — sem depender de parâmetro externo
    final allLogs = await (_db.select(_db.habitLogsTable)
          ..where((t) => t.playerId.equals(player.id))
          ..where((t) => t.status.isIn(['completed', 'partial'])))
        .get();
    final totalHabitsCompleted = allLogs.length;

    final unlocked = <String>[];

    Future<void> tryUnlock(String key) async {
      final already = await _dao.isUnlocked(player.id, key);
      if (already) return;
      final achievement = await _dao.getByKey(key);
      if (achievement == null) return;

      await _dao.unlock(player.id, key);
      // Recompensas entregues manualmente pelo jogador na tela de conquistas
      unlocked.add(achievement.title);
    }

    if (player.level >= 2)  await tryUnlock('first_level');
    if (player.level >= 5)  await tryUnlock('level_5');
    if (player.level >= 10) await tryUnlock('level_10');
    if (player.level >= 25) await tryUnlock('level_25');
    if (player.level >= 50) await tryUnlock('level_50');

    if (player.caelumDay >= 7)   await tryUnlock('caelum_7');
    if (player.caelumDay >= 30)  await tryUnlock('caelum_30');
    if (player.caelumDay >= 100) await tryUnlock('caelum_100');

    if (totalHabitsCompleted >= 1)   await tryUnlock('first_habit');
    if (totalHabitsCompleted >= 10)  await tryUnlock('habit_10');
    if (totalHabitsCompleted >= 50)  await tryUnlock('habit_50');
    if (totalHabitsCompleted >= 100) await tryUnlock('habit_100');
    if (totalHabitsCompleted >= 300) await tryUnlock('habit_300');

    if (player.streakDays >= 7)   await tryUnlock('streak_7');
    if (player.streakDays >= 30)  await tryUnlock('streak_30');
    if (player.streakDays >= 100) await tryUnlock('streak_100');

    if (player.shadowState == 'stable' && player.caelumDay >= 3 && totalHabitsCompleted >= 3)
      await tryUnlock('shadow_stable');
    if (player.shadowState == 'ascending') await tryUnlock('shadow_ascend');

    if (player.classType != null && player.classType!.isNotEmpty) {
      await tryUnlock('class_chosen');
    }
    final faction = player.factionType ?? '';
    if (faction.isNotEmpty && !faction.startsWith('pending:')) {
      await tryUnlock('faction_joined');
    }

    final rank = player.guildRank;
    if (['d','c','b','a','s'].contains(rank)) await tryUnlock('guild_rank_d');
    if (['c','b','a','s'].contains(rank))     await tryUnlock('guild_rank_c');
    if (rank == 's')                          await tryUnlock('guild_rank_s');

    if (player.gold >= 500)  await tryUnlock('gold_500');
    if (player.gold >= 5000) await tryUnlock('gold_5000');

    return unlocked;
  }
}
