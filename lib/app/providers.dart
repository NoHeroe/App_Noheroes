import '../data/database/daos/achievement_dao.dart';
import '../data/database/tables/player_achievements_table.dart';
import '../data/database/tables/achievements_table.dart';
import '../data/database/daos/inventory_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/tables/players_table.dart';
import '../data/datasources/local/auth_local_ds.dart';
import '../data/datasources/local/habit_local_ds.dart';

// Banco singleton
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Auth datasource
final authDsProvider = Provider<AuthLocalDs>((ref) {
  return AuthLocalDs(ref.watch(appDatabaseProvider));
});

// Habit datasource
final habitDsProvider = Provider<HabitLocalDs>((ref) {
  return HabitLocalDs(ref.watch(appDatabaseProvider));
});

// Jogador atual — StateProvider simples
final currentPlayerProvider = StateProvider<PlayersTableData?>((ref) => null);

// Loading de auth
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Stream reativo do jogador — atualiza automaticamente quando banco muda
final playerStreamProvider = StreamProvider<PlayersTableData?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return Stream.value(null);

  return (db.select(db.playersTable)
        ..where((t) => t.id.equals(player.id)))
      .watchSingleOrNull();
});

// Hábitos do jogador com status do dia
final habitsProvider = FutureProvider<List<HabitWithStatus>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  return ref.watch(habitDsProvider).getHabitsWithStatus(player.id);
});

// Inventory DAO provider
final inventoryDaoProvider = Provider((ref) {
  return InventoryDao(ref.watch(appDatabaseProvider));
});

// Inventário do jogador
final inventoryProvider = FutureProvider<List<InventoryWithItem>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  return ref.watch(inventoryDaoProvider).getInventory(player.id);
});

// Loja
final shopProvider = FutureProvider<List<ShopWithItem>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  return ref.watch(inventoryDaoProvider).getShopItems(player.level);
});

// Achievement providers
final achievementsProvider = FutureProvider<List<AchievementsTableData>>((ref) {
  return AchievementDao(ref.watch(appDatabaseProvider)).getAllAchievements();
});

final unlockedAchievementsProvider =
    FutureProvider<List<PlayerAchievementsTableData>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  return AchievementDao(ref.watch(appDatabaseProvider)).getUnlocked(player.id);
});
