import '../data/database/daos/achievement_dao.dart';
import '../data/database/tables/player_achievements_table.dart';
import '../data/database/tables/achievements_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/tables/players_table.dart';
import '../data/datasources/local/auth_local_ds.dart';
import '../data/datasources/local/habit_local_ds.dart';
import '../data/datasources/local/class_quest_service.dart';
import '../data/datasources/local/faction_quest_service.dart';
import '../data/datasources/local/vitalism_unique_service.dart';
import '../data/datasources/local/items_catalog_service.dart';
import '../data/datasources/local/player_inventory_service.dart';
import '../data/datasources/local/player_equipment_service.dart';
import '../data/datasources/local/player_rank_service.dart';
import '../data/datasources/local/shops_service.dart';
import '../data/datasources/local/recipes_catalog_service.dart';
import '../data/datasources/local/player_recipes_service.dart';
import '../data/datasources/local/crafting_service.dart';
import '../data/datasources/local/enchant_service.dart';
import '../data/datasources/local/factions_service.dart';
import '../data/database/daos/player_dao.dart';

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

// Sprint 2.1 — catálogo, inventário, equipamento e rank do jogador.
final itemsCatalogServiceProvider = Provider<ItemsCatalogService>((ref) {
  return ItemsCatalogService(ref.watch(appDatabaseProvider));
});

final playerInventoryServiceProvider = Provider<PlayerInventoryService>((ref) {
  return PlayerInventoryService(
    ref.watch(appDatabaseProvider),
    ref.watch(itemsCatalogServiceProvider),
  );
});

final playerEquipmentServiceProvider = Provider<PlayerEquipmentService>((ref) {
  return PlayerEquipmentService(
    ref.watch(appDatabaseProvider),
    ref.watch(itemsCatalogServiceProvider),
  );
});

final playerRankServiceProvider = Provider<PlayerRankService>((ref) {
  return PlayerRankService(ref.watch(appDatabaseProvider));
});

// Sprint 2.1 Bloco 7 — lojas (shops.json + validações ADR 0010).
final shopsServiceProvider = Provider<ShopsService>((ref) {
  return ShopsService(
    ref.watch(appDatabaseProvider),
    ref.watch(itemsCatalogServiceProvider),
    ref.watch(playerInventoryServiceProvider),
  );
});

// Sprint 2.2 — receitas e forja.
final recipesCatalogServiceProvider = Provider<RecipesCatalogService>((ref) {
  return RecipesCatalogService(ref.watch(appDatabaseProvider));
});

final playerRecipesServiceProvider = Provider<PlayerRecipesService>((ref) {
  return PlayerRecipesService(
    ref.watch(appDatabaseProvider),
    ref.watch(recipesCatalogServiceProvider),
  );
});

final craftingServiceProvider = Provider<CraftingService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CraftingService(
    db,
    ref.watch(recipesCatalogServiceProvider),
    ref.watch(playerRecipesServiceProvider),
    ref.watch(itemsCatalogServiceProvider),
    ref.watch(playerInventoryServiceProvider),
    PlayerDao(db),
  );
});

// Sprint 2.3 Bloco 0.A — facções filtradas (oculta secretas sem achievement).
final factionsServiceProvider = Provider<FactionsService>((ref) {
  return FactionsService(ref.watch(appDatabaseProvider));
});

// Sprint 2.3 fix (D.2) — runas migradas pra items_catalog como ItemType.rune.
// Providers antigos (enchantsCatalogServiceProvider, playerEnchantsServiceProvider)
// removidos. Tabelas enchants_catalog e player_enchants_inventory serão
// dropadas pela migration 22→23 em F8.
final enchantServiceProvider = Provider<EnchantService>((ref) {
  return EnchantService(
    ref.watch(appDatabaseProvider),
    ref.watch(itemsCatalogServiceProvider),
    ref.watch(playerInventoryServiceProvider),
  );
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

