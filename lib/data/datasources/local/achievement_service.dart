import '../../../data/database/app_database.dart';
import '../../../data/database/daos/achievement_dao.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../../data/database/tables/players_table.dart';
import 'package:drift/drift.dart';

class AchievementService {
  final AppDatabase _db;
  AchievementService(this._db);

  AchievementDao get _dao => AchievementDao(_db);
  PlayerDao get _playerDao => PlayerDao(_db);

  // Garante que o seed de conquistas existe para usuários antigos
  Future<void> ensureAchievementsSeedExists() async {
    final all = await _dao.getAllAchievements();
    if (all.isEmpty) {
      await _db.transaction(() async {
        await _seedAchievements();
      });
    }
  }

  Future<void> _seedAchievements() async {
    final achievements = [
      ('first_level',   'Primeiro Passo',        'Atingiu o Nível 2.',              'progression', 50,  25,  0, false),
      ('level_5',       'Forma Tomando Shape',   'Atingiu o Nível 5.',              'progression', 150, 75,  1, false),
      ('level_10',      'Sombra Reconhecida',    'Atingiu o Nível 10.',             'progression', 300, 150, 2, false),
      ('level_25',      'Despertar Vitalista',   'Atingiu o Nível 25.',             'progression', 500, 250, 3, false),
      ('level_50',      'Meio Caminho',          'Atingiu o Nível 50.',             'progression', 800, 400, 5, false),
      ('caelum_7',      'Uma Semana em Caelum',  '7 dias em Caelum.',               'progression', 100, 50,  1, false),
      ('caelum_30',     'Um Mês em Caelum',      '30 dias em Caelum.',              'progression', 300, 150, 3, false),
      ('caelum_100',    'Cem Dias em Caelum',    '100 dias em Caelum.',             'progression', 600, 300, 5, false),
      ('first_habit',   'Primeiro Ritual',       'Completou seu primeiro ritual.',  'habits',      50,  25,  0, false),
      ('habit_10',      'Disciplina Inicial',    '10 rituais completados.',         'habits',      100, 50,  0, false),
      ('habit_50',      'Caminho da Disciplina', '50 rituais completados.',         'habits',      200, 100, 1, false),
      ('habit_100',     'Cem Rituais',           '100 rituais completados.',        'habits',      400, 200, 2, false),
      ('habit_300',     'Trezentos Rituais',     '300 rituais completados.',        'habits',      800, 400, 4, false),
      ('streak_7',      'Semana Impecável',      '7 dias de streak.',               'habits',      150, 75,  1, false),
      ('streak_30',     'Mês Sem Falhas',        '30 dias de streak.',              'habits',      500, 250, 3, false),
      ('streak_100',    'Cem Dias Consecutivos', '100 dias de streak.',             'habits',      1000,500, 5, true),
      ('shadow_stable', 'Equilíbrio Interno',    'Manteve sombra estável.',         'shadow',      100, 50,  0, false),
      ('shadow_ascend', 'Ascensão',              'Venceu um Shadow Boss.',          'shadow',      500, 250, 5, true),
      ('shadow_boss',   'Confronto Interno',     'Derrotou o Shadow Boss.',         'shadow',      500, 250, 5, true),
      ('class_chosen',  'Um Caminho Escolhido',  'Escolheu sua classe.',            'progression', 200, 100, 1, false),
      ('faction_joined','Lealdade Jurada',       'Entrou em uma facção.',           'progression', 200, 100, 1, false),
      ('first_item',    'Primeiro Tesouro',      'Adquiriu seu primeiro item.',     'exploration', 75,  35,  0, false),
      ('first_buy',     'Mercador de Caelum',    'Comprou algo na loja.',           'exploration', 50,  25,  0, false),
      ('gold_500',      'Acumulador',            'Acumulou 500 de ouro.',           'exploration', 100, 0,   1, false),
      ('gold_5000',     'Tesouro de Caelum',     'Acumulou 5000 de ouro.',          'exploration', 300, 0,   3, false),
    ];

    for (final a in achievements) {
      try {
        await _db.into(_db.achievementsTable).insert(
          AchievementsTableCompanion(
            key:         Value(a.$1),
            title:       Value(a.$2),
            description: Value(a.$3),
            category:    Value(a.$4),
            xpReward:    Value(a.$5),
            goldReward:  Value(a.$6),
            gemReward:   Value(a.$7),
            isSecret:    Value(a.$8),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      } catch (_) {}
    }
  }

  Future<List<String>> checkAndUnlock(
      PlayersTableData player, int totalHabitsCompleted) async {
    // Garante seed
    await ensureAchievementsSeedExists();

    final unlocked = <String>[];

    Future<void> tryUnlock(String key) async {
      final already = await _dao.isUnlocked(player.id, key);
      if (already) return;
      final achievement = await _dao.getByKey(key);
      if (achievement == null) return;
      await _dao.unlock(player.id, key);
      if (achievement.xpReward > 0) {
        await _playerDao.addXp(player.id, achievement.xpReward);
      }
      if (achievement.goldReward > 0) {
        await _playerDao.addGold(player.id, achievement.goldReward);
      }
      unlocked.add(achievement.title);
    }

    // Progressão de nível
    if (player.level >= 2)  await tryUnlock('first_level');
    if (player.level >= 5)  await tryUnlock('level_5');
    if (player.level >= 10) await tryUnlock('level_10');
    if (player.level >= 25) await tryUnlock('level_25');
    if (player.level >= 50) await tryUnlock('level_50');

    // Dias em Caelum
    if (player.caelumDay >= 7)   await tryUnlock('caelum_7');
    if (player.caelumDay >= 30)  await tryUnlock('caelum_30');
    if (player.caelumDay >= 100) await tryUnlock('caelum_100');

    // Hábitos
    if (totalHabitsCompleted >= 1)   await tryUnlock('first_habit');
    if (totalHabitsCompleted >= 10)  await tryUnlock('habit_10');
    if (totalHabitsCompleted >= 50)  await tryUnlock('habit_50');
    if (totalHabitsCompleted >= 100) await tryUnlock('habit_100');
    if (totalHabitsCompleted >= 300) await tryUnlock('habit_300');

    // Streak
    if (player.streakDays >= 7)   await tryUnlock('streak_7');
    if (player.streakDays >= 30)  await tryUnlock('streak_30');
    if (player.streakDays >= 100) await tryUnlock('streak_100');

    // Sombra
    if (player.shadowState == 'stable')    await tryUnlock('shadow_stable');
    if (player.shadowState == 'ascending') await tryUnlock('shadow_ascend');

    // Classe e facção
    if (player.classType != null && player.classType!.isNotEmpty) {
      await tryUnlock('class_chosen');
    }
    final faction = player.factionType ?? '';
    if (faction.isNotEmpty && !faction.startsWith('pending:')) {
      await tryUnlock('faction_joined');
    }

    // Ouro
    if (player.gold >= 500)  await tryUnlock('gold_500');
    if (player.gold >= 5000) await tryUnlock('gold_5000');

    return unlocked;
  }
}
