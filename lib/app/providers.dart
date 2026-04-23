import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/events/app_event_bus.dart';
import '../core/utils/guild_rank.dart';
import '../data/database/app_database.dart';
import '../data/datasources/local/auth_local_ds.dart';
import '../data/datasources/local/class_quest_service.dart';
import '../data/datasources/local/faction_quest_service.dart';
import '../data/datasources/local/quest_admission_service.dart';
import '../core/events/reward_events.dart';
import '../data/services/reward_grant_service.dart';
import '../domain/enums/mission_modality.dart';
import '../domain/enums/rank_codec.dart';
import '../domain/models/player_snapshot.dart';
import '../domain/services/achievements_service.dart';
import '../domain/services/individual_delete_service.dart';
import '../domain/services/mission_preferences_service.dart';
import '../domain/services/mission_progress_service.dart';
import '../domain/services/reward_resolve_service.dart';
import '../domain/strategies/individual_modality_strategy.dart';
import '../domain/strategies/internal_modality_strategy.dart';
import '../domain/strategies/mission_strategy.dart';
import '../domain/strategies/mixed_modality_strategy.dart';
import '../domain/strategies/real_task_modality_strategy.dart';
import '../data/repositories/drift/active_faction_quests_repository_drift.dart';
import '../data/repositories/drift/mission_preferences_repository_drift.dart';
import '../data/repositories/drift/mission_repository_drift.dart';
import '../data/repositories/drift/player_achievements_repository_drift.dart';
import '../data/repositories/drift/player_faction_reputation_repository_drift.dart';
import '../data/repositories/drift/player_individual_missions_repository_drift.dart';
import '../domain/repositories/active_faction_quests_repository.dart';
import '../domain/repositories/mission_preferences_repository.dart';
import '../domain/repositories/mission_repository.dart';
import '../domain/repositories/player_achievements_repository.dart';
import '../domain/repositories/player_faction_reputation_repository.dart';
import '../domain/repositories/player_individual_missions_repository.dart';
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
    ref.watch(appEventBusProvider),
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
    ref.watch(appEventBusProvider),
  );
});

// Sprint 2.3 fix (D.2) — runas migradas pra items_catalog como ItemType.rune.
final enchantServiceProvider = Provider<EnchantService>((ref) {
  return EnchantService(
    ref.watch(appDatabaseProvider),
    ref.watch(itemsCatalogServiceProvider),
    ref.watch(playerInventoryServiceProvider),
    ref.watch(appEventBusProvider),
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

// Sprint 3.1 Bloco 7b — quest services reescritos (Class, Faction,
// QuestAdmission). Todos usam Repository + EventBus; nenhum toca tabelas
// legacy (habits/class_quests/faction_quests foram dropadas na migration
// schema 24).
final classQuestServiceProvider = Provider<ClassQuestService>((ref) {
  return ClassQuestService(ref.watch(missionRepositoryProvider));
});

final factionQuestServiceProvider = Provider<FactionQuestService>((ref) {
  return FactionQuestService(
      ref.watch(activeFactionQuestsRepositoryProvider));
});

final questAdmissionServiceProvider = Provider<QuestAdmissionService>((ref) {
  return QuestAdmissionService(
    ref.watch(appDatabaseProvider),
    ref.watch(missionRepositoryProvider),
    ref.watch(classQuestServiceProvider),
    ref.watch(appEventBusProvider),
  );
});

// Sprint 3.1 Bloco 6 — Strategies + MissionProgressService (ADR 0014).
final internalModalityStrategyProvider =
    Provider<InternalModalityStrategy>((_) => InternalModalityStrategy());

final realTaskModalityStrategyProvider =
    Provider<RealTaskModalityStrategy>((_) => RealTaskModalityStrategy());

final individualModalityStrategyProvider =
    Provider<IndividualModalityStrategy>(
        (_) => IndividualModalityStrategy());

final mixedModalityStrategyProvider =
    Provider<MixedModalityStrategy>((ref) {
  return MixedModalityStrategy(
    ref.watch(internalModalityStrategyProvider),
    ref.watch(realTaskModalityStrategyProvider),
  );
});

final missionProgressServiceProvider =
    Provider<MissionProgressService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = MissionProgressService(
    repo: ref.watch(missionRepositoryProvider),
    resolver: ref.watch(rewardResolveServiceProvider),
    granter: ref.watch(rewardGrantServiceProvider),
    eventBus: ref.watch(appEventBusProvider),
    strategies: <MissionModality, MissionStrategy>{
      MissionModality.internal: ref.watch(internalModalityStrategyProvider),
      MissionModality.real: ref.watch(realTaskModalityStrategyProvider),
      MissionModality.individual:
          ref.watch(individualModalityStrategyProvider),
      MissionModality.mixed: ref.watch(mixedModalityStrategyProvider),
    },
    resolvePlayer: (playerId) async {
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      final rank = row.guildRank == 'none'
          ? null
          : RankCodec.fromString(row.guildRank.toLowerCase());
      return PlayerSnapshot(
        level: row.level,
        rank: rank ?? GuildRank.e,
        classKey: row.classType,
        factionKey: row.factionType,
      );
    },
  );
  ref.onDispose(() {
    // fire-and-forget — dispose é async mas onDispose do Riverpod
    // é síncrono. Flag `_disposed` no service bloqueia chamadas tardias
    // em microtask entre o set e o cancel.
    service.dispose();
  });
  return service;
});

// Sprint 3.1 Bloco 5 — RewardResolve (puro) + RewardGrant (atômico).
final rewardResolveServiceProvider = Provider<RewardResolveService>((ref) {
  return RewardResolveService(ref.watch(itemsCatalogServiceProvider));
});

final rewardGrantServiceProvider = Provider<RewardGrantService>((ref) {
  return RewardGrantService(
    db: ref.watch(appDatabaseProvider),
    missionRepo: ref.watch(missionRepositoryProvider),
    achievementsRepo: ref.watch(playerAchievementsRepositoryProvider),
    inventory: ref.watch(playerInventoryServiceProvider),
    recipes: ref.watch(playerRecipesServiceProvider),
    factionRep: ref.watch(playerFactionReputationRepositoryProvider),
    eventBus: ref.watch(appEventBusProvider),
  );
});

// Sprint 3.1 Bloco 8 — AchievementsService JSON-driven.
//
// Lazy sync: o provider cria o service e dispara `attach()` em
// fire-and-forget. A assinatura do listener é guardada num capture
// local e cancelada em `ref.onDispose`. `ensureLoaded` dentro do service
// é idempotente, então o handler tolera eventos chegando antes do
// carregamento completar (trata como "conquistas not-yet-loaded" →
// noop + log). Em produção o bus começa silencioso até o jogador agir.
final achievementsServiceProvider = Provider<AchievementsService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = AchievementsService(
    achievementsRepo: ref.watch(playerAchievementsRepositoryProvider),
    rewardResolve: ref.watch(rewardResolveServiceProvider),
    rewardGrant: ref.watch(rewardGrantServiceProvider),
    bus: ref.watch(appEventBusProvider),
    resolvePlayerFacts: (playerId) async {
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      final rank = row.guildRank == 'none'
          ? null
          : RankCodec.fromString(row.guildRank.toLowerCase());
      return PlayerFacts(
        level: row.level,
        totalQuestsCompleted: row.totalQuestsCompleted,
        snapshot: PlayerSnapshot(
          level: row.level,
          rank: rank ?? GuildRank.e,
          classKey: row.classType,
          factionKey: row.factionType,
        ),
      );
    },
  );
  StreamSubscription<RewardGranted>? sub;
  // fire-and-forget: carrega catálogo + registra listener em background.
  service.attach().then((s) => sub = s);
  ref.onDispose(() {
    sub?.cancel();
  });
  return service;
});

// Sprint 3.1 Bloco 9 — MissionPreferencesService (quiz de calibração).
final missionPreferencesServiceProvider =
    Provider<MissionPreferencesService>((ref) {
  return MissionPreferencesService(
    repo: ref.watch(missionPreferencesRepositoryProvider),
    bus: ref.watch(appEventBusProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

// Sprint 3.1 Bloco 10a.2 — IndividualDeleteService (apaga individuais).
final individualDeleteServiceProvider =
    Provider<IndividualDeleteService>((ref) {
  return IndividualDeleteService(
    db: ref.watch(appDatabaseProvider),
    missionRepo: ref.watch(missionRepositoryProvider),
    bus: ref.watch(appEventBusProvider),
  );
});

// Sprint 3.1 Bloco 10a.1 — Gate de "Refazer calibração" no SanctuaryDrawer
// (Bloco 10a.2 consome). FutureProvider.family resolve o check async pro
// drawer sem widget rebuild caro. autodispose garante que múltiplas
// aberturas do drawer não acumulam providers.
final canRecalibrateProvider = FutureProvider.autoDispose
    .family<bool, ({int playerId, int playerLevel})>((ref, args) async {
  return ref.watch(missionPreferencesServiceProvider).canRecalibrate(
        playerId: args.playerId,
        playerLevel: args.playerLevel,
      );
});

// Sprint 3.1 Bloco 4 — Repository Pattern (ADR 0016).
//
// Cada provider retorna a **interface** — swap Supabase futuro é trocar
// 1 linha por Repository sem tocar em nenhum consumer. Consumidores
// (strategies Bloco 6, services Bloco 7+) fazem `ref.read(...)` sem
// conhecer a impl concreta.
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepositoryDrift(ref.watch(appDatabaseProvider));
});

final missionPreferencesRepositoryProvider =
    Provider<MissionPreferencesRepository>((ref) {
  return MissionPreferencesRepositoryDrift(ref.watch(appDatabaseProvider));
});

final playerAchievementsRepositoryProvider =
    Provider<PlayerAchievementsRepository>((ref) {
  return PlayerAchievementsRepositoryDrift(ref.watch(appDatabaseProvider));
});

final playerFactionReputationRepositoryProvider =
    Provider<PlayerFactionReputationRepository>((ref) {
  return PlayerFactionReputationRepositoryDrift(
      ref.watch(appDatabaseProvider));
});

final playerIndividualMissionsRepositoryProvider =
    Provider<PlayerIndividualMissionsRepository>((ref) {
  return PlayerIndividualMissionsRepositoryDrift(
      ref.watch(appDatabaseProvider));
});

final activeFactionQuestsRepositoryProvider =
    Provider<ActiveFactionQuestsRepository>((ref) {
  return ActiveFactionQuestsRepositoryDrift(ref.watch(appDatabaseProvider));
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
