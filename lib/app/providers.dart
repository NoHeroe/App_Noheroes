import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/events/app_event_bus.dart';
import '../core/utils/guild_rank.dart';
import '../data/datasources/local/class_quest_service.dart';
import '../data/datasources/local/ascension_service.dart';
import '../data/datasources/local/guild_ascension_progress_service.dart';
import '../data/datasources/local/guild_ascension_service.dart';
import '../data/datasources/local/diary_service.dart';
import '../data/datasources/local/faction_quest_service.dart';
import '../data/datasources/local/quest_admission_service.dart';
import '../core/events/reward_events.dart';
import '../data/services/reward_grant_service.dart';
import '../domain/enums/mission_modality.dart';
import '../domain/enums/rank_codec.dart';
import '../domain/models/player_snapshot.dart';
import '../data/datasources/local/extras_catalog_service.dart';
import '../data/datasources/local/mission_catalogs_service.dart';
import '../domain/services/achievements_service.dart';
import '../domain/services/body_metrics_service.dart';
import '../domain/services/daily_mission_generator_service.dart';
import '../domain/services/daily_mission_progress_service.dart';
import '../domain/services/daily_mission_rollover_service.dart';
import '../domain/services/daily_mission_stats_service.dart';
import '../domain/services/daily_pool_service.dart';
import '../domain/services/player_currency_stats_service.dart';
import '../data/datasources/local/faction_admission_progress_service.dart';
import '../data/datasources/local/leave_faction_service.dart';
import '../data/datasources/local/quest_reward_stats_service.dart';
import '../domain/models/faction_buff_multipliers.dart';
import '../domain/services/faction_admission_validator.dart';
import '../domain/services/faction_buff_service.dart';
import '../domain/services/weekly_faction_validator.dart';
import '../domain/services/weekly_faction_progress_service.dart';
import '../domain/services/player_screens_visited_service.dart';
import '../domain/services/faction_reputation_service.dart';
import '../domain/services/mission_assignment_service.dart';
import '../domain/services/individual_creation_service.dart';
import '../domain/services/individual_delete_service.dart';
import '../domain/services/mission_balancer_service.dart';
import '../domain/services/mission_progress_service.dart';
import '../domain/services/reward_resolve_service.dart';
import '../domain/services/weekly_reset_service.dart';
import '../domain/strategies/individual_modality_strategy.dart';
import '../domain/strategies/internal_modality_strategy.dart';
import '../domain/strategies/mission_strategy.dart';
import '../domain/strategies/mixed_modality_strategy.dart';
import '../domain/strategies/real_task_modality_strategy.dart';
import '../data/repositories/supabase/active_faction_quests_repository_supabase.dart';
import '../data/repositories/supabase/mission_repository_supabase.dart';
import '../data/repositories/supabase/player_achievements_repository_supabase.dart';
import '../data/repositories/supabase/player_faction_reputation_repository_supabase.dart';
import '../data/repositories/supabase/player_individual_missions_repository_supabase.dart';
import '../domain/models/mission_progress.dart';
import '../domain/repositories/active_faction_quests_repository.dart';
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
// Época 2 (full-online — ADR-0024): raiz Supabase.
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/player.dart';
import '../domain/repositories/player_repository.dart';
import '../data/repositories/supabase/player_repository_supabase.dart';
import '../data/datasources/remote/supabase_auth_service.dart';

// Época 2 (ADR-0024): Drift APOSENTADO — appDatabaseProvider removido.
// Fonte única é o Supabase (supabaseClientProvider abaixo).

// Época 2 — cliente Supabase (fonte única full-online). Já inicializado em
// main.dart (Supabase.initialize). Sem onDispose (lifecycle é do app).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Época 2 — repositório do jogador (tabela players via PostgREST).
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepositorySupabase(ref.watch(supabaseClientProvider));
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
  return VitalismUniqueService(ref.watch(supabaseClientProvider));
});

// Sprint 3.4 Etapa G.2 (D15) — DiaryService COM bus injetado. Sem o bus,
// `saveEntry` não publica `DiaryEntryCreated` → a sub-task de admissão
// `admission_diary_entry_window` (consumida por
// FactionAdmissionProgressService) não progride. Callers de ESCRITA
// devem usar este provider (não `DiaryService(db)` direto).
final diaryServiceProvider = Provider<DiaryService>((ref) {
  return DiaryService(
    ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
  );
});

// Sprint 2.1 — catálogo, inventário, equipamento e rank do jogador.
final itemsCatalogServiceProvider = Provider<ItemsCatalogService>((ref) {
  return ItemsCatalogService(ref.watch(supabaseClientProvider));
});

final playerInventoryServiceProvider = Provider<PlayerInventoryService>((ref) {
  return PlayerInventoryService(
    ref.watch(supabaseClientProvider),
    ref.watch(itemsCatalogServiceProvider),
  );
});

final playerEquipmentServiceProvider = Provider<PlayerEquipmentService>((ref) {
  return PlayerEquipmentService(
    ref.watch(supabaseClientProvider),
    ref.watch(itemsCatalogServiceProvider),
  );
});

final playerRankServiceProvider = Provider<PlayerRankService>((ref) {
  return PlayerRankService(ref.watch(supabaseClientProvider));
});

// Sprint 2.1 Bloco 7 — lojas (shops.json + validações ADR 0010).
final shopsServiceProvider = Provider<ShopsService>((ref) {
  return ShopsService(
    ref.watch(supabaseClientProvider),
    ref.watch(itemsCatalogServiceProvider),
    ref.watch(playerInventoryServiceProvider),
    ref.watch(appEventBusProvider),
  );
});

// Sprint 2.2 — receitas e forja.
final recipesCatalogServiceProvider = Provider<RecipesCatalogService>((ref) {
  return RecipesCatalogService(ref.watch(supabaseClientProvider));
});

final playerRecipesServiceProvider = Provider<PlayerRecipesService>((ref) {
  return PlayerRecipesService(
    ref.watch(supabaseClientProvider),
    ref.watch(recipesCatalogServiceProvider),
  );
});

final craftingServiceProvider = Provider<CraftingService>((ref) {
  return CraftingService(
    ref.watch(supabaseClientProvider),
    ref.watch(appEventBusProvider),
  );
});

// Sprint 2.3 fix (D.2) — runas migradas pra items_catalog como ItemType.rune.
final enchantServiceProvider = Provider<EnchantService>((ref) {
  return EnchantService(
    ref.watch(supabaseClientProvider),
    ref.watch(itemsCatalogServiceProvider),
    ref.watch(appEventBusProvider),
  );
});

// Auth — Supabase Auth (Época 2). Mantém o nome `authDsProvider` pra reduzir
// churn nos call sites; os métodos (register/login/currentSession/logout/
// completeOnboarding) têm a mesma assinatura de antes, mas retornam Player?.
final authDsProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService(
    ref.watch(supabaseClientProvider),
    ref.watch(playerRepositoryProvider),
  );
});

// Jogador atual — agora Player (id String/uuid). Setado via refetch após login
// e após eventos que mudam o player (LevelUp, etc. — ver PlayerStateSyncService).
final currentPlayerProvider = StateProvider<Player?>((ref) => null);

// Loading de auth
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Reatividade do jogador (modelo REFETCH, decisão Época 2 — sem Realtime por
// ora). Espelha o currentPlayerProvider: quem dependia do stream (XP bar)
// reage quando o currentPlayer é refetchado. Migrável p/ Supabase Realtime
// depois sem mudar os consumidores.
final playerStreamProvider = StreamProvider<Player?>((ref) {
  // Stream CONTÍNUO: emite o valor atual e RE-EMITE a cada mudança do
  // currentPlayerProvider — sem resets de loading entre emissões. Antes era
  // `Stream.value(...)` (one-shot): quebrava o listener de level-up do
  // Santuário (classe L5 / facção L7 / vitalismo L25) porque os valores prev/
  // next nunca chegavam como dois AsyncData consecutivos.
  final controller = StreamController<Player?>();
  controller.add(ref.read(currentPlayerProvider));
  final sub = ref.listen<Player?>(
    currentPlayerProvider,
    (_, next) => controller.add(next),
  );
  ref.onDispose(() {
    sub.close();
    controller.close();
  });
  return controller.stream;
});

/// Sprint 3.4 Sub-Etapa B.2 hotfix — stream reativo de uma row de
/// `player_mission_progress` por id. Foundation pro `AdmissionMission
/// Card` reagir imediatamente a mudanças de metaJson (sub-task
/// completada pelo listener, window_start_ms shifted pelo dev panel,
/// is_unlocked promovido por sequenciamento). Sem isso, card só
/// rebuilda quando o widget é remontado — UI fica stale.
final missionProgressStreamProvider =
    StreamProvider.family<MissionProgress?, int>((ref, missionId) {
  final client = ref.watch(supabaseClientProvider);
  // Época 2 (ADR-0024): modelo REFETCH — fetch único da row por id via
  // PostgREST (sem Realtime por ora). O StreamProvider emite 1 valor; o
  // card é re-disparado quando o provider é invalidado/reassistido.
  return Stream.fromFuture(
    client
        .from('player_mission_progress')
        .select()
        .eq('id', missionId)
        .maybeSingle()
        .then((row) => row == null ? null : MissionProgress.fromMap(row)),
  );
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
    ref.watch(supabaseClientProvider),
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
  final playerRepo = ref.watch(playerRepositoryProvider);
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
      // Época 2 (ADR-0024): lê o Player via PostgREST (PlayerRepository).
      final player = await playerRepo.fetchById(playerId);
      final rank = (player == null || player.guildRank == 'none')
          ? null
          : RankCodec.fromString(player.guildRank.toLowerCase());
      return PlayerSnapshot(
        level: player?.level ?? 1,
        rank: rank ?? GuildRank.e,
        classKey: player?.classType,
        factionKey: player?.factionType,
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
    client: ref.watch(supabaseClientProvider),
    eventBus: ref.watch(appEventBusProvider),
    factionBuff: ref.watch(factionBuffServiceProvider),
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
  final client = ref.watch(supabaseClientProvider);
  final playerRepo = ref.watch(playerRepositoryProvider);
  final service = AchievementsService(
    achievementsRepo: ref.watch(playerAchievementsRepositoryProvider),
    rewardResolve: ref.watch(rewardResolveServiceProvider),
    rewardGrant: ref.watch(rewardGrantServiceProvider),
    bus: ref.watch(appEventBusProvider),
    // Época 2 (ADR-0024): cliente Supabase pros triggers daily (antes
    // statsDao/volumeDao). PlayerDao agora Supabase-backed pros event_*.
    client: client,
    playerDao: PlayerDao(client),
    // Sprint 3.3 Etapa 2.1c-γ — service pro trigger event_screen_visited.
    screensVisitedService:
        ref.watch(playerScreensVisitedServiceProvider),
    resolvePlayerFacts: (playerId) async {
      // Época 2 (ADR-0024): lê o Player via PostgREST (PlayerRepository).
      final player = await playerRepo.fetchById(playerId);
      final rank = (player == null || player.guildRank == 'none')
          ? null
          : RankCodec.fromString(player.guildRank.toLowerCase());
      return PlayerFacts(
        level: player?.level ?? 1,
        totalQuestsCompleted: player?.totalQuestsCompleted ?? 0,
        // Sprint 3.3 Etapa 2.1b — alimenta trigger `daily_mission_streak`.
        dailyMissionsStreak: player?.dailyMissionsStreak ?? 0,
        snapshot: PlayerSnapshot(
          level: player?.level ?? 1,
          rank: rank ?? GuildRank.e,
          classKey: player?.classType,
          factionKey: player?.factionType,
        ),
      );
    },
  );
  StreamSubscription<RewardGranted>? rewardSub;
  List<StreamSubscription>? dailySubs;
  List<StreamSubscription>? eventSubs;
  List<StreamSubscription>? metaLikeSubs;
  // fire-and-forget: carrega catálogo + registra listeners em background.
  service.attach().then((s) => rewardSub = s);
  service
      .attachDailyListeners()
      .then((subs) => dailySubs = subs);
  // Sprint 3.3 Etapa 2.1c-α — listeners dos 5 triggers event_*.
  service
      .attachEventListeners()
      .then((subs) => eventSubs = subs);
  // Sprint 3.3 Etapa 2.2 hotfix — listeners pros 3 trigger types legacy
  // (Meta / ThresholdStat / EventCount) que ficavam unreachable no
  // formato JSON novo. Cobre INIT_NIVEL_5 e INIT_CINCO_CONQUISTAS.
  service
      .attachMetaLikeListeners()
      .then((subs) => metaLikeSubs = subs);
  ref.onDispose(() {
    rewardSub?.cancel();
    if (dailySubs != null) {
      for (final s in dailySubs!) {
        s.cancel();
      }
    }
    if (eventSubs != null) {
      for (final s in eventSubs!) {
        s.cancel();
      }
    }
    if (metaLikeSubs != null) {
      for (final s in metaLikeSubs!) {
        s.cancel();
      }
    }
  });
  return service;
});

// Sprint 3.2 Etapa 1.0 — BodyMetricsService (IMC + recomendações diárias).
// Lê/escreve weight_kg + height_cm em players via PlayerDao.
// Sprint 3.3 Etapa 2.1c-α — bus injetado pra publicar BodyMetricsUpdated.
final bodyMetricsServiceProvider = Provider<BodyMetricsService>((ref) {
  return BodyMetricsService(
    dao: PlayerDao(ref.watch(supabaseClientProvider)),
    bus: ref.watch(appEventBusProvider),
  );
});

// Sprint 3.3 Etapa 2.1c-γ — tracking de telas visitadas (CSV em
// players.screens_visited_keys). Single writer chamado pelo router
// listener em routerProvider. Sem bootstrap eager — writer-on-demand.
final playerScreensVisitedServiceProvider =
    Provider<PlayerScreensVisitedService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PlayerScreensVisitedService(
    client: client,
    playerDao: PlayerDao(client),
    bus: ref.watch(appEventBusProvider),
  );
});

// Sprint 3.3 Etapa 2.1c-α — agregador all-time de moedas gastas.
// Listener GemsSpent → players.total_gems_spent → publica
// CurrencyStatsUpdated. AchievementsService escuta esse evento pra
// resolver `event_gems_spent_total` sem race.
final playerCurrencyStatsServiceProvider =
    Provider<PlayerCurrencyStatsService>((ref) {
  final service = PlayerCurrencyStatsService(
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
  );
  service.start();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// Sprint 3.2 Etapa 1.1 — DailyPoolService (pools de missões diárias).
// Carrega lazy os 4 JSONs `daily_pool_*.json` via fire-and-forget.
// Etapa 1.2 implementa a geração; Etapa 1.3, a UI.
final dailyPoolServiceProvider = Provider<DailyPoolService>((ref) {
  final service = DailyPoolService();
  // Fire-and-forget: assets ficam disponíveis ao primeiro consumo
  // (StateError se chamarem antes de loadAll completar).
  service.loadAll();
  return service;
});

// Época 2 (ADR-0024): DAOs Drift `dailyMissionsDaoProvider`,
// `playerDailyMissionStatsDaoProvider` e `playerDailySubtaskVolumeDaoProvider`
// REMOVIDOS — os services daily (generator/progress/rollover/stats) e o
// AchievementsService passaram a falar PostgREST direto via SupabaseClient.

/// Eager-init: bootstrap chama `ref.watch(...)` em `NoHeroesApp.build`
/// pra forçar inicialização no boot da árvore Riverpod (sem isso o
/// service só ouviria eventos depois que algo o lesse).
final dailyMissionStatsServiceProvider =
    Provider<DailyMissionStatsService>((ref) {
  final service = DailyMissionStatsService(
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
  );
  service.start();
  ref.onDispose(() {
    // Fire-and-forget — Riverpod onDispose é síncrono.
    service.dispose();
  });
  return service;
});

/// Sprint 3.4 Etapa B (Sub-Etapa B.1) — single writer de
/// `players.total_gold_earned_via_quests`. Foundation pro sub-type
/// `admission_gold_earned_via_quests_window` do
/// `FactionAdmissionValidator`. Eager bootstrap em
/// `NoHeroesApp.build` — sem isso, listener só ativaria no primeiro
/// consumo do provider.
final questRewardStatsServiceProvider =
    Provider<QuestRewardStatsService>((ref) {
  final service = QuestRewardStatsService(
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
  );
  service.start();
  ref.onDispose(service.stop);
  return service;
});

/// Sprint 3.4 Etapa B (Sub-Etapa B.1) — validador de sub-tasks de
/// admissão. Stateless — caller (Sub-Etapa B.2) consulta `evaluate`
/// pra cada sub-task ativa em listeners de eventos terminais.
final factionAdmissionValidatorProvider =
    Provider<FactionAdmissionValidator>((ref) {
  return FactionAdmissionValidator(ref.watch(supabaseClientProvider));
});

/// FATIA B1 — validador acumulativo do motor SEMANAL de facção.
/// Stateless. Espelha as queries acumulativas da admissão com janela
/// limitada `[weekStartMs, weekEndMs)`.
final weeklyFactionValidatorProvider =
    Provider<WeeklyFactionValidator>((ref) {
  return WeeklyFactionValidator(ref.watch(supabaseClientProvider));
});

/// Sprint 3.4 Etapa C — service que combina catálogo + state do player
/// e produz multipliers efetivos (xp/gold/gems + atributos virtuais).
/// Stateless. Lazy-load do JSON no 1º acesso.
final factionBuffServiceProvider = Provider<FactionBuffService>((ref) {
  return FactionBuffService(ref.watch(supabaseClientProvider));
});

/// Sprint 3.4 Etapa C hotfix #2 (P1-C) — promovido pra escopo global.
/// Snapshot de buffs ativos+pending da facção. Consumido por /personagem
/// (seções "BUFFS ATIVOS" / "FUTUROS") e dev panel.
final factionBuffSnapshotProvider =
    FutureProvider.autoDispose<FactionBuffSnapshot>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return FactionBuffSnapshot.empty;
  return ref.read(factionBuffServiceProvider).getBuffSnapshot(player.id);
});

/// Sprint 3.4 Etapa C hotfix #2 (P1-C) — promovido pra escopo global.
/// Atributos efetivos pós-buff (str/dex/int/maxHp). Consumido por:
/// - /personagem: render "12 → 13 (+1)" + "HP Máximo: 100 → 110 (+10)"
/// - Santuário (`StatBarsRow`): barra HP usa `maxHpEffective` em vez de
///   `players.maxHp` direto (correção da inconsistência reportada pelo CEO)
final effectiveAttributesProvider =
    FutureProvider.autoDispose<EffectiveAttributes>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return EffectiveAttributes.empty;
  return ref
      .read(factionBuffServiceProvider)
      .getEffectiveAttributes(player.id);
});

/// Sprint 3.4 Sub-Etapa B.2 — flow de saída de facção (-20 rep +
/// propagação matriz + lock 7d + debuff 48h). Tratamento especial pra
/// Guilda preservando guild_rank (Aventureiro nível 1). Sem eager —
/// é chamado on-demand pela UI.
final leaveFactionServiceProvider = Provider<LeaveFactionService>((ref) {
  return LeaveFactionService(
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
    factionRep: ref.watch(factionReputationServiceProvider),
  );
});

/// Sprint 3.4 Sub-Etapa B.2 — listener que re-avalia sub-tasks de
/// admissão a cada evento terminal. Sequenciamento + reset em falha.
/// Eager bootstrap no `NoHeroesApp.build`.
final factionAdmissionProgressServiceProvider =
    Provider<FactionAdmissionProgressService>((ref) {
  final service = FactionAdmissionProgressService(
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
    validator: ref.watch(factionAdmissionValidatorProvider),
    missionRepo: ref.watch(missionRepositoryProvider),
    factionRep: ref.watch(factionReputationServiceProvider),
    factionRepo: ref.watch(playerFactionReputationRepositoryProvider),
    assignment: ref.watch(missionAssignmentServiceProvider),
  );
  service.start();
  ref.onDispose(service.stop);
  return service;
});

/// FATIA B2b — listener ACUMULATIVO do motor semanal de facção. Soma
/// sub-tasks via eventos terminais (sem reject/-rep/lock), incrementa o
/// contador `equipment_improved` em `ItemCrafted`/`ItemEnchanted`, e paga
/// o reward cheio (com Insígnias — Fatia A) na conclusão antecipada.
/// Eager bootstrap no `NoHeroesApp.build`.
final weeklyFactionProgressServiceProvider =
    Provider<WeeklyFactionProgressService>((ref) {
  final playerRepo = ref.watch(playerRepositoryProvider);
  final service = WeeklyFactionProgressService(
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
    validator: ref.watch(weeklyFactionValidatorProvider),
    missionRepo: ref.watch(missionRepositoryProvider),
    resolver: ref.watch(rewardResolveServiceProvider),
    granter: ref.watch(rewardGrantServiceProvider),
    resolvePlayer: (playerId) async {
      // Época 2 (ADR-0024): lê o Player via PostgREST (PlayerRepository).
      final player = await playerRepo.fetchById(playerId);
      final rank = (player == null || player.guildRank == 'none')
          ? null
          : RankCodec.fromString(player.guildRank.toLowerCase());
      return PlayerSnapshot(
        level: player?.level ?? 1,
        rank: rank ?? GuildRank.e,
        classKey: player?.classType,
        factionKey: player?.factionType,
      );
    },
  );
  service.start();
  ref.onDispose(service.stop);
  return service;
});

/// B.2 — máquina de estados soulslike da ascensão (gates/pay/janela/
/// deadline/ascend). NÃO wire na UI ainda (B.4). Nome distinto do
/// `ascensionServiceProvider` (GuildAscensionService) da AscensionTab.
final ascensionStateServiceProvider = Provider<AscensionService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AscensionService(
    client: client,
    bus: ref.watch(appEventBusProvider),
    ascension: GuildAscensionService(client),
  );
});

/// A.2 — ignição event-driven do motor de ascensão da Guilda. Escuta
/// eventos terminais e avança o progresso dos steps do ciclo (NÃO
/// ascende — o ascend() é manual no botão da AscensionTab). Eager
/// bootstrap no `NoHeroesApp.build`.
final guildAscensionProgressServiceProvider =
    Provider<GuildAscensionProgressService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final service = GuildAscensionProgressService(
    client: client,
    bus: ref.watch(appEventBusProvider),
    ascension: GuildAscensionService(client),
  );
  service.start();
  ref.onDispose(service.stop);
  return service;
});

final dailyMissionGeneratorServiceProvider =
    Provider<DailyMissionGeneratorService>((ref) {
  return DailyMissionGeneratorService(
    client: ref.watch(supabaseClientProvider),
    pools: ref.watch(dailyPoolServiceProvider),
    bodyMetrics: ref.watch(bodyMetricsServiceProvider),
    bus: ref.watch(appEventBusProvider),
  );
});

final dailyMissionProgressServiceProvider =
    Provider<DailyMissionProgressService>((ref) {
  return DailyMissionProgressService(
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
    factionBuff: ref.watch(factionBuffServiceProvider),
  );
});

final dailyMissionRolloverServiceProvider =
    Provider<DailyMissionRolloverService>((ref) {
  return DailyMissionRolloverService(
    client: ref.watch(supabaseClientProvider),
  );
});

// Sprint 3.1 Bloco 10a.2 — IndividualDeleteService (apaga individuais).
final individualDeleteServiceProvider =
    Provider<IndividualDeleteService>((ref) {
  return IndividualDeleteService(
    client: ref.watch(supabaseClientProvider),
    missionRepo: ref.watch(missionRepositoryProvider),
    bus: ref.watch(appEventBusProvider),
  );
});

// Sprint 3.1 Bloco 11a — MissionBalancer (pure logic) + IndividualCreation
// (atomic) + ExtrasCatalog (lê JSONs).
final missionBalancerServiceProvider =
    Provider<MissionBalancerService>((_) => const MissionBalancerService());

final individualCreationServiceProvider =
    Provider<IndividualCreationService>((ref) {
  return IndividualCreationService(
    client: ref.watch(supabaseClientProvider),
    balancer: ref.watch(missionBalancerServiceProvider),
    bus: ref.watch(appEventBusProvider),
  );
});

final extrasCatalogServiceProvider = Provider<ExtrasCatalogService>((_) {
  return ExtrasCatalogService();
});

// Sprint 3.1 Bloco 13a — catálogos estáticos de missões (daily/class/
// faction-weekly/ascension) + MissionAssignmentService.
final missionCatalogsServiceProvider =
    Provider<MissionCatalogsService>((_) => MissionCatalogsService());

final missionAssignmentServiceProvider =
    Provider<MissionAssignmentService>((ref) {
  return MissionAssignmentService(
    client: ref.watch(supabaseClientProvider),
    catalogs: ref.watch(missionCatalogsServiceProvider),
    bus: ref.watch(appEventBusProvider),
  );
});

// Sprint 3.1 Bloco 13b — daily/weekly reset + faction reputation.
final factionReputationServiceProvider =
    Provider<FactionReputationService>((ref) {
  return FactionReputationService(
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
    factionBuff: ref.watch(factionBuffServiceProvider),
  );
});

// Época 2 (ADR-0024): DailyResetService (legacy, operava o player_mission_progress
// antigo) APOSENTADO junto com o Drift — o rollover diário roda via
// DailyMissionRolloverService (schema 37).

final weeklyResetServiceProvider = Provider<WeeklyResetService>((ref) {
  return WeeklyResetService(
    missionRepo: ref.watch(missionRepositoryProvider),
    assignment: ref.watch(missionAssignmentServiceProvider),
    client: ref.watch(supabaseClientProvider),
    bus: ref.watch(appEventBusProvider),
  );
});

// Sprint 3.1 Bloco 4 — Repository Pattern (ADR 0016).
//
// Cada provider retorna a **interface** — swap Supabase futuro é trocar
// 1 linha por Repository sem tocar em nenhum consumer. Consumidores
// (strategies Bloco 6, services Bloco 7+) fazem `ref.read(...)` sem
// conhecer a impl concreta.
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepositorySupabase(ref.watch(supabaseClientProvider));
});

final playerAchievementsRepositoryProvider =
    Provider<PlayerAchievementsRepository>((ref) {
  return PlayerAchievementsRepositorySupabase(
      ref.watch(supabaseClientProvider));
});

final playerFactionReputationRepositoryProvider =
    Provider<PlayerFactionReputationRepository>((ref) {
  return PlayerFactionReputationRepositorySupabase(
      ref.watch(supabaseClientProvider));
});

final playerIndividualMissionsRepositoryProvider =
    Provider<PlayerIndividualMissionsRepository>((ref) {
  return PlayerIndividualMissionsRepositorySupabase(
      ref.watch(supabaseClientProvider));
});

final activeFactionQuestsRepositoryProvider =
    Provider<ActiveFactionQuestsRepository>((ref) {
  return ActiveFactionQuestsRepositorySupabase(
      ref.watch(supabaseClientProvider));
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
