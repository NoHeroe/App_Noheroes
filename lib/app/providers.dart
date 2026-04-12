import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/local/habit_local_ds.dart';
import '../data/database/app_database.dart';
import '../data/datasources/local/auth_local_ds.dart';
import '../data/database/tables/players_table.dart';

// Banco de dados singleton
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Auth datasource
final authDsProvider = Provider<AuthLocalDs>((ref) {
  return AuthLocalDs(ref.watch(appDatabaseProvider));
});

// Estado do jogador atual
final currentPlayerProvider = StateProvider<PlayersTableData?>((ref) => null);

// Estado de loading de auth
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Verifica sessão ao iniciar
final sessionCheckProvider = FutureProvider<PlayersTableData?>((ref) async {
  final ds = ref.watch(authDsProvider);
  return ds.currentSession();
});

// Habit datasource
final habitDsProvider = Provider<HabitLocalDs>((ref) {
  return HabitLocalDs(ref.watch(appDatabaseProvider));
});

// Hábitos do jogador com status do dia
final habitsProvider = FutureProvider<List<HabitWithStatus>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  return ref.watch(habitDsProvider).getHabitsWithStatus(player.id);
});
