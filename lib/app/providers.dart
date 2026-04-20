import '../data/database/daos/achievement_dao.dart';
import '../data/database/tables/player_achievements_table.dart';
import '../data/database/tables/achievements_table.dart';
import '../data/database/daos/inventory_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/tables/players_table.dart';
import '../data/datasources/local/auth_local_ds.dart';
import '../data/datasources/local/habit_local_ds.dart';
import '../data/datasources/local/class_quest_service.dart';
import '../data/datasources/local/faction_quest_service.dart';
import '../data/datasources/local/vitalism_unique_service.dart';

// Banco singleton
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Vitalismos Únicos — orquestra pool, despertar, ritual e stubs de PvP.
final vitalismUniqueServiceProvider = Provider<VitalismUniqueService>((ref) {
  return VitalismUniqueService(ref.watch(appDatabaseProvider));
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

// ── Class Quest Providers ──
final classQuestServiceProvider = Provider<ClassQuestService>((ref) {
  return ClassQuestService(ref.read(appDatabaseProvider));
});

final todayClassQuestsProvider = FutureProvider.autoDispose<List<ClassQuestsTableData>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  if (player.level < 5) return [];
  if (player.classType == null || player.classType!.isEmpty) return [];
  final service = ref.read(classQuestServiceProvider);
  await service.assignDailyQuests(player.id, player.classType!);
  return service.getTodayQuests(player.id);
});

// ── Faction Quest Providers ──
final factionQuestServiceProvider = Provider<FactionQuestService>((ref) {
  return FactionQuestService(ref.read(appDatabaseProvider));
});

final activeFactionQuestProvider = FutureProvider.autoDispose<FactionQuestsTableData?>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return null;
  if (player.level < 7) return null;
  final faction = player.factionType ?? '';
  if (faction.isEmpty || faction == 'none' || faction.startsWith('pending:')) return null;
  final service = ref.read(factionQuestServiceProvider);
  return service.assignWeeklyQuest(player.id, faction);
});

// Conta de habitos completados hoje (inclui pausados/nao-repetiveis ja concluidos)
final todayCompletedCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return 0;
  final db = ref.read(appDatabaseProvider);
  final logs = await db.habitDao.getTodayLogs(player.id);
  // Conta unicos por habitId, apenas completados ou parciais
  final completed = logs.where(
      (l) => l.status == 'completed' || l.status == 'partial');
  return completed.map((l) => l.habitId).toSet().length;
});

