import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habits_table.dart';
import '../tables/habit_logs_table.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [HabitsTable, HabitLogsTable])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  // Busca todos os hábitos do jogador
  Future<List<HabitsTableData>> getHabits(int playerId) {
    return (select(habitsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.isPaused.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  // Busca hábitos do sistema
  Future<List<HabitsTableData>> getSystemHabits(int playerId) {
    return (select(habitsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.isSystemHabit.equals(true))
          ..where((t) => t.isPaused.equals(false)))
        .get();
  }

  // Busca missões individuais
  Future<List<HabitsTableData>> getPersonalHabits(int playerId) {
    return (select(habitsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.isSystemHabit.equals(false))
          ..where((t) => t.isPaused.equals(false)))
        .get();
  }

  // Cria hábito
  Future<int> createHabit(HabitsTableCompanion habit) {
    return into(habitsTable).insert(habit);
  }

  // Deleta hábito
  Future<int> deleteHabit(int id) {
    return (delete(habitsTable)..where((t) => t.id.equals(id))).go();
  }

  // Pausa hábito
  Future<void> pauseHabit(int id, bool paused) {
    return (update(habitsTable)..where((t) => t.id.equals(id)))
        .write(HabitsTableCompanion(isPaused: Value(paused)));
  }

  // Log do dia — verifica se hábito já foi registrado hoje
  Future<HabitLogsTableData?> getTodayLog(int habitId, int playerId) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(habitLogsTable)
          ..where((t) => t.habitId.equals(habitId))
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.logDate.isBetweenValues(start, end)))
        .getSingleOrNull();
  }

  // Busca todos os logs do dia
  Future<List<HabitLogsTableData>> getTodayLogs(int playerId) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(habitLogsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.logDate.isBetweenValues(start, end)))
        .get();
  }

  // Registra conclusão
  Future<void> logHabit({
    required int habitId,
    required int playerId,
    required String status,
    required int xpGained,
    required int goldGained,
    required int shadowImpact,
  }) async {
    // Remove log anterior do dia se existir
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    await (delete(habitLogsTable)
          ..where((t) => t.habitId.equals(habitId))
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.logDate.isBetweenValues(start, end)))
        .go();

    await into(habitLogsTable).insert(HabitLogsTableCompanion(
      habitId: Value(habitId),
      playerId: Value(playerId),
      status: Value(status),
      xpGained: Value(xpGained),
      goldGained: Value(goldGained),
      shadowImpact: Value(shadowImpact),
    ));

    // Atualiza streak e total se completado
    if (status == 'completed' || status == 'partial') {
      final habit = await (select(habitsTable)
            ..where((t) => t.id.equals(habitId)))
          .getSingleOrNull();
      if (habit != null) {
        await (update(habitsTable)..where((t) => t.id.equals(habitId)))
            .write(HabitsTableCompanion(
          totalCompleted: Value(habit.totalCompleted + 1),
          streakCount: Value(
              status == 'completed' ? habit.streakCount + 1 : habit.streakCount),
        ));
      }
    }
  }

  // Conta hábitos do jogador
  Future<int> countPersonalHabits(int playerId) async {
    final habits = await getPersonalHabits(playerId);
    return habits.length;
  }
}
