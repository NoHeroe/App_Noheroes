import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../database/daos/habit_dao.dart';
import '../../database/daos/player_dao.dart';
import '../../database/tables/habits_table.dart';
import '../../database/tables/habit_logs_table.dart';
import '../../database/tables/players_table.dart';

class HabitLocalDs {
  final AppDatabase _db;

  HabitLocalDs(this._db);

  HabitDao get _habitDao => HabitDao(_db);
  PlayerDao get _playerDao => PlayerDao(_db);

  int _calcXp(String rank, String status) {
    final base = switch (rank) {
      'e' => 20, 'd' => 35, 'c' => 55,
      'b' => 80, 'a' => 120, 's' => 180, _ => 20,
    };
    return switch (status) {
      'completed' => base,
      'partial'   => (base * 0.5).round(),
      'niet'      => (base * 0.1).round(),
      _           => 0,
    };
  }

  int _calcGold(String rank, String status) {
    final base = switch (rank) {
      'e' => 10, 'd' => 18, 'c' => 28,
      'b' => 40, 'a' => 60, 's' => 90, _ => 10,
    };
    return switch (status) {
      'completed' => base,
      'partial'   => (base * 0.5).round(),
      _           => 0,
    };
  }

  int _calcShadowImpact(String status) => switch (status) {
    'completed' => 5,
    'partial'   => 2,
    'niet'      => -3,
    'failed'    => -8,
    _           => 0,
  };

  // Verifica e aplica falhas automáticas do dia anterior
  Future<void> applyDailyReset(int playerId) async {
    final habits = await _habitDao.getHabits(playerId);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final yEnd = yStart.add(const Duration(days: 1));

    for (final habit in habits) {
      // Verifica se tem log de ontem
      final log = await (_db.select(_db.habitLogsTable)
            ..where((t) => t.habitId.equals(habit.id))
            ..where((t) => t.playerId.equals(playerId))
            ..where((t) => t.logDate.isBetweenValues(yStart, yEnd)))
          .getSingleOrNull();

      // Se não tem log de ontem, marca como failed
      if (log == null) {
        await _db.into(_db.habitLogsTable).insert(
          HabitLogsTableCompanion(
            habitId: Value(habit.id),
            playerId: Value(playerId),
            status: const Value('failed'),
            xpGained: const Value(0),
            goldGained: const Value(0),
            shadowImpact: const Value(-8),
            logDate: Value(yStart.add(const Duration(hours: 23, minutes: 59))),
          ),
        );
      }
    }
  }

  Future<List<HabitWithStatus>> getHabitsWithStatus(int playerId) async {
    final habits = await _habitDao.getHabits(playerId);
    final logs = await _habitDao.getTodayLogs(playerId);
    final logMap = {for (var l in logs) l.habitId: l};
    return habits.map((h) => HabitWithStatus(
      habit: h,
      todayLog: logMap[h.id],
    )).toList();
  }

  Future<void> createSystemHabit({
    required int playerId,
    required String title,
    required String category,
  }) async {
    await _habitDao.createHabit(HabitsTableCompanion(
      playerId: Value(playerId),
      title: Value(title),
      category: Value(category),
      isSystemHabit: const Value(true),
      isRepeatable: const Value(false), // 1x por dia sempre
      xpReward: const Value(20),
      goldReward: const Value(10),
    ));
  }

  Future<String?> createPersonalHabit({
    required int playerId,
    required String title,
    required String description,
    required String category,
    required String rank,
    required bool isFreeUser,
  }) async {
    if (isFreeUser) {
      final count = await _habitDao.countPersonalHabits(playerId);
      if (count >= 5) {
        return 'Limite de 5 missões individuais atingido. Seja PRO para ilimitado.';
      }
    }
    final xp = _calcXp(rank, 'completed');
    final gold = _calcGold(rank, 'completed');
    await _habitDao.createHabit(HabitsTableCompanion(
      playerId: Value(playerId),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      rank: Value(rank),
      isSystemHabit: const Value(false),
      isRepeatable: const Value(false), // 1x por dia
      xpReward: Value(xp),
      goldReward: Value(gold),
    ));
    return null;
  }

  Future<HabitResult> completeHabit({
    required int habitId,
    required int playerId,
    required String rank,
    required String status,
  }) async {
    // Verifica se já foi feita hoje
    final existingLog = await _habitDao.getTodayLog(habitId, playerId);
    if (existingLog != null) {
      return HabitResult(
        xpGained: 0, goldGained: 0,
        shadowImpact: 0, status: 'already_done',
      );
    }

    final xp = _calcXp(rank, status);
    final gold = _calcGold(rank, status);
    final shadowImpact = _calcShadowImpact(status);

    await _habitDao.logHabit(
      habitId: habitId,
      playerId: playerId,
      status: status,
      xpGained: xp,
      goldGained: gold,
      shadowImpact: shadowImpact,
    );

    if (xp > 0 || gold > 0) {
      final player = await _playerDao.findById(playerId);
      if (player != null) {
        int newXp = player.xp + xp;
        int newGold = player.gold + gold;
        int newLevel = player.level;
        int newXpToNext = player.xpToNext;

        while (newXp >= newXpToNext) {
          newXp -= newXpToNext;
          newLevel++;
          newXpToNext = (newXpToNext * 1.5).round();
        }

        await (_db.update(_db.playersTable)
              ..where((t) => t.id.equals(playerId)))
            .write(PlayersTableCompanion(
          xp: Value(newXp),
          gold: Value(newGold),
          level: Value(newLevel),
          xpToNext: Value(newXpToNext),
        ));
      }
    }

    return HabitResult(
      xpGained: xp,
      goldGained: gold,
      shadowImpact: shadowImpact,
      status: status,
    );
  }

  Future<void> deletePersonalHabit(int habitId) =>
      _habitDao.deleteHabit(habitId);
}

class HabitWithStatus {
  final HabitsTableData habit;
  final HabitLogsTableData? todayLog;

  HabitWithStatus({required this.habit, required this.todayLog});

  bool get isDone =>
      todayLog != null &&
      (todayLog!.status == 'completed' || todayLog!.status == 'partial');

  bool get isLocked => todayLog != null; // já tem log hoje

  String get todayStatus => todayLog?.status ?? 'pending';
}

class HabitResult {
  final int xpGained;
  final int goldGained;
  final int shadowImpact;
  final String status;
  HabitResult({
    required this.xpGained,
    required this.goldGained,
    required this.shadowImpact,
    required this.status,
  });
}
