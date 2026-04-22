import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/events/app_event_bus.dart';
import '../data/database/app_database.dart';
import '../data/datasources/local/auth_local_ds.dart';
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
import '../data/database/daos/player_dao.dart';

// Banco singleton
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Sprint 3.1 Bloco 2 — EventBus local singleton. Consumidores do bus
// (strategies, services refatorados, UI animada) leem via `ref.watch`
// ou `ref.read`. Pós-dispose é noop silencioso — ver `AppEventBus.dispose`.
final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(() {
    // Fire-and-forget: Riverpod `onDispose` é síncrono, mas
    // `AppEventBus.dispose` retorna Future. A microtask resolve na próxima
    // volta do event loop; em produção isso é tudo que precisamos.
    bus.dispose();
  });
  return bus;
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

// Sprint 2.3 fix (D.2) — runas migradas pra items_catalog como ItemType.rune.
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

// ─── Sprint 3.1 (v0.29.0) ─────────────────────────────────────────────────
// Providers legacy removidos neste bloco 1 (schema 24, reset brutal):
//   - habitsProvider, habitDsProvider, todayCompletedCountProvider
//   - achievementsProvider, unlockedAchievementsProvider
//   - classQuestServiceProvider, todayClassQuestsProvider
//   - factionQuestServiceProvider, activeFactionQuestProvider
//   - factionsServiceProvider
// Serão substituídos nos blocos seguintes:
//   - Bloco 4: missionRepositoryProvider, achievementRepositoryProvider,
//     preferencesRepositoryProvider, factionReputationRepositoryProvider
//   - Bloco 6: missionProgressServiceProvider
//   - Bloco 7: classQuestServiceProvider / factionQuestServiceProvider /
//     questAdmissionServiceProvider refatorados
//   - Bloco 8: achievementsServiceProvider (JSON-driven)
//   - Bloco 9: missionPreferencesServiceProvider
