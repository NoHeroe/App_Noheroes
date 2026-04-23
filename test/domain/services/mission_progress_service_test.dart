import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/crafting_events.dart';
import 'package:noheroes_app/core/events/reward_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/data/services/reward_grant_service.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/services/mission_progress_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';
import 'package:noheroes_app/domain/strategies/individual_modality_strategy.dart';
import 'package:noheroes_app/domain/strategies/internal_modality_strategy.dart';
import 'package:noheroes_app/domain/strategies/mission_strategy.dart';
import 'package:noheroes_app/domain/strategies/mixed_modality_strategy.dart';
import 'package:noheroes_app/domain/strategies/real_task_modality_strategy.dart';

Future<int> _seedPlayer(AppDatabase db) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, constitution, "
    "spirit, charisma, attribute_points, shadow_corruption, vitalism_level, "
    "vitalism_xp, guild_rank) "
    "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 'e')",
    variables: [
      Variable.withString('test@test.com'),
      Variable.withString('hash'),
    ],
  );
}

Future<int> _seedMission(
  AppDatabase db, {
  required int playerId,
  required MissionModality modality,
  int current = 0,
  int target = 20,
  String metaJson = '{}',
  MissionTabOrigin tab = MissionTabOrigin.daily,
}) async {
  final repo = MissionRepositoryDrift(db);
  return repo.insert(MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: 'TEST',
    modality: modality,
    tabOrigin: tab,
    rank: GuildRank.e,
    targetValue: target,
    currentValue: current,
    reward: const RewardDeclared(xp: 100, gold: 50),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: metaJson,
  ));
}

MissionProgressService _newService(
  AppDatabase db,
  AppEventBus bus, {
  PlayerSnapshot? playerOverride,
}) {
  final catalog = ItemsCatalogService(db);
  final repo = MissionRepositoryDrift(db);
  return MissionProgressService(
    repo: repo,
    resolver: RewardResolveService(catalog),
    granter: RewardGrantService(
      db: db,
      missionRepo: repo,
      inventory: PlayerInventoryService(db, catalog),
      recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
      factionRep: PlayerFactionReputationRepositoryDrift(db),
      eventBus: bus,
    ),
    eventBus: bus,
    strategies: <MissionModality, MissionStrategy>{
      MissionModality.internal: InternalModalityStrategy(),
      MissionModality.real: RealTaskModalityStrategy(),
      MissionModality.individual: IndividualModalityStrategy(),
      MissionModality.mixed: MixedModalityStrategy(
        InternalModalityStrategy(),
        RealTaskModalityStrategy(),
      ),
    },
    resolvePlayer: (_) async =>
        playerOverride ?? const PlayerSnapshot(level: 10, rank: GuildRank.e),
  );
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late MissionProgressService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    service = _newService(db, bus);
  });

  tearDown(() async {
    await service.dispose();
    await bus.dispose();
    await db.close();
  });

  group('MissionProgressService — onUserAction happy path', () {
    test('delta aplica, progress atualiza no DB', () async {
      final playerId = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: playerId, modality: MissionModality.real);
      final result = await service.onUserAction(mid, 5);
      expect(result!.currentValue, 5);
      expect(result.completedAt, matcherIsNull);
    });

    test('delta que atinge target dispara grant + emit', () async {
      final playerId = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: playerId,
          modality: MissionModality.real,
          current: 15,
          target: 20);

      RewardGranted? captured;
      final sub = bus.on<RewardGranted>().listen((e) => captured = e);

      await service.onUserAction(mid, 5);
      await pumpEventQueue();

      final refreshed = await MissionRepositoryDrift(db).findById(mid);
      expect(refreshed!.completedAt, matcherIsNotNull);
      expect(refreshed.rewardClaimed, isTrue);
      expect(refreshed.currentValue, 20);
      expect(captured, matcherIsNotNull);

      await sub.cancel();
    });

    test('missão já completa ignora user action subsequente', () async {
      final playerId = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: playerId,
          modality: MissionModality.real,
          current: 15,
          target: 20);
      await service.onUserAction(mid, 5); // completa
      await pumpEventQueue();

      final before = await MissionRepositoryDrift(db).findById(mid);
      await service.onUserAction(mid, 10);

      final after = await MissionRepositoryDrift(db).findById(mid);
      expect(after!.currentValue, before!.currentValue);
      expect(after.completedAt, before.completedAt);
    });

    test('missão inexistente → null', () async {
      expect(await service.onUserAction(9999, 5), matcherIsNull);
    });

    test('input rejeitado (delta numa internal) retorna mission intacta',
        () async {
      final playerId = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: playerId,
          modality: MissionModality.internal,
          metaJson: '{"internal_event":"ItemCrafted"}');
      final result = await service.onUserAction(mid, 5);
      expect(result!.currentValue, 0, reason: 'internal ignora delta');
    });
  });

  group('MissionProgressService — _onEvent (EventBus)', () {
    test('evento correto avança missão internal', () async {
      final playerId = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: playerId,
          modality: MissionModality.internal,
          target: 3,
          metaJson: '{"internal_event":"ItemCrafted"}');

      bus.publish(ItemCrafted(
          playerId: playerId, itemKey: 'S', recipeKey: 'R'));
      await pumpEventQueue();
      await Future.delayed(Duration.zero);
      await pumpEventQueue();

      final refreshed = await MissionRepositoryDrift(db).findById(mid);
      expect(refreshed!.currentValue, 1);
    });

    test('evento de outro player NÃO avança missão', () async {
      final p1 = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: p1,
          modality: MissionModality.internal,
          target: 3,
          metaJson: '{"internal_event":"ItemCrafted"}');

      bus.publish(ItemCrafted(
          playerId: 99, itemKey: 'S', recipeKey: 'R'));
      await pumpEventQueue();
      await Future.delayed(Duration.zero);
      await pumpEventQueue();

      final refreshed = await MissionRepositoryDrift(db).findById(mid);
      expect(refreshed!.currentValue, 0);
    });

    test('3 eventos completam + grant dispara', () async {
      final playerId = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: playerId,
          modality: MissionModality.internal,
          target: 3,
          metaJson: '{"internal_event":"ItemCrafted"}');

      for (var i = 0; i < 3; i++) {
        bus.publish(ItemCrafted(
            playerId: playerId, itemKey: 'S$i', recipeKey: 'R'));
        await pumpEventQueue();
        await Future.delayed(Duration.zero);
        await pumpEventQueue();
      }

      final refreshed = await MissionRepositoryDrift(db).findById(mid);
      expect(refreshed!.currentValue, 3);
      expect(refreshed.rewardClaimed, isTrue);
    });
  });

  group('MissionProgressService — dispose guard', () {
    test('dispose seta flag antes de cancelar', () async {
      final playerId = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: playerId, modality: MissionModality.real);

      await service.dispose();

      // Chamadas pós-dispose viram noop silencioso.
      expect(await service.onUserAction(mid, 5), matcherIsNull);

      final refreshed = await MissionRepositoryDrift(db).findById(mid);
      expect(refreshed!.currentValue, 0,
          reason: 'dispose guard impediu update');
    });

    test('dispose é idempotente', () async {
      await service.dispose();
      await expectLater(service.dispose(), completes);
    });

    test('publish pós-dispose não crasha', () async {
      await service.dispose();
      expect(
        () => bus.publish(
            ItemCrafted(playerId: 1, itemKey: 'S', recipeKey: 'R')),
        returnsNormally,
      );
    });
  });

  group('MissionProgressService — idempotência sob concorrência '
      '(regressão crítica)', () {
    test('idempotencia: Future.wait([onUserAction, onUserAction]) com '
        '2 chamadas que completariam a missão', () async {
      final playerId = await _seedPlayer(db);
      final mid = await _seedMission(db,
          playerId: playerId,
          modality: MissionModality.real,
          current: 15,
          target: 20);

      // Captura tudo de RewardGranted pra contar emissões.
      final captured = <RewardGranted>[];
      final sub = bus.on<RewardGranted>().listen(captured.add);

      final futures = [
        service.onUserAction(mid, 5),
        service.onUserAction(mid, 5),
      ];
      // 1. Future.wait NÃO lança
      await expectLater(Future.wait(futures), completes);
      await pumpEventQueue();

      // 2. XP creditado EXATAMENTE 1 vez
      final xpRow = await db.customSelect(
          'SELECT xp, gold FROM players WHERE id = ?',
          variables: [Variable.withInt(playerId)]).getSingle();
      expect(xpRow.data['xp'], 40,
          reason: 'SOULSLIKE: 100*0.4=40, NÃO 80');

      // 3. gold creditado 1 vez (18, não 36)
      expect(xpRow.data['gold'], 18);

      // 4. Evento RewardGranted emitido 1 vez
      expect(captured, hasLength(1));

      // 5. rewardClaimed=true, completedAt != null
      final final_ = await MissionRepositoryDrift(db).findById(mid);
      expect(final_!.rewardClaimed, isTrue);
      expect(final_.completedAt, matcherIsNotNull);

      // 6. currentValue final = 20 (não 25, overflow NÃO persistido)
      expect(final_.currentValue, 20);

      await sub.cancel();
    });
  });
}

/// Alias pro matcher do flutter_test — drift/drift.dart exporta um
/// homônimo usado em query building.
const matcherIsNull = isNull;
const matcherIsNotNull = isNotNull;
