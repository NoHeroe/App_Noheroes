import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/datasources/local/extras_catalog_service.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/daily_mission.dart';
import 'package:noheroes_app/domain/models/extras_mission_spec.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/repositories/mission_repository.dart';
import 'package:noheroes_app/domain/services/daily_mission_generator_service.dart';
import 'package:noheroes_app/domain/services/daily_mission_rollover_service.dart';
import 'package:noheroes_app/presentation/quests/providers/quests_screen_notifier.dart';

/// Fake Repository pra testes — seedado por (tab) + rastreia chamadas.
class _FakeMissionRepo implements MissionRepository {
  final Map<MissionTabOrigin, List<MissionProgress>> byTab;
  int findByTabCalls = 0;

  _FakeMissionRepo({this.byTab = const {}});

  @override
  Future<List<MissionProgress>> findByTab(
      int playerId, MissionTabOrigin tab) async {
    findByTabCalls++;
    return byTab[tab] ?? const [];
  }

  @override
  Future<List<MissionProgress>> findHistorical(int playerId) async =>
      const [];

  @override
  Future<List<MissionProgress>> findCompletedInWindow(
    int playerId, {
    required DateTime from,
    required DateTime to,
  }) async =>
      const [];

  @override
  Future<List<MissionProgress>> findActive(int playerId) async => const [];

  @override
  Future<MissionProgress?> findById(int id) async => null;

  @override
  Future<int> insert(MissionProgress progress) async => 0;

  @override
  Future<void> markCompleted(int id,
      {required DateTime at, required bool rewardClaimed}) async {}

  @override
  Future<void> markFailed(int id, {required DateTime at}) async {}

  @override
  Future<void> updateProgress(int id,
      {required int currentValue, String? metaJson}) async {}

  @override
  Stream<List<MissionProgress>> watchActive(int playerId) =>
      const Stream.empty();
}

/// Sprint 3.2 Etapa 1.3.A — fakes pros services de DailyMission.
class _FakeDailyGenerator implements DailyMissionGeneratorService {
  static const List<DailyMission> _empty = <DailyMission>[];

  @override
  Future<List<DailyMission>> getTodayMissions(int playerId) async => _empty;

  @override
  Future<List<DailyMission>> generateForToday(int playerId,
          {DateTime? date, bool force = false}) async =>
      _empty;

  @override
  Future<DailyMission?> getMissionById(int id) async => null;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeDailyRollover implements DailyMissionRolloverService {
  @override
  Future<void> processRollover(int playerId, {DateTime? now}) async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Fake extras catalog — retorna o que for seedado, sem tocar assets.
class _FakeExtrasCatalog implements ExtrasCatalogService {
  final List<ExtrasMissionSpec> items;
  _FakeExtrasCatalog({this.items = const []});

  @override
  Future<List<ExtrasMissionSpec>> loadAll() async => items;

  @override
  Future<List<ExtrasMissionSpec>> loadAllForPlayer(int playerId) async =>
      items;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

MissionProgress _mkMission({
  required int id,
  required MissionTabOrigin tab,
  MissionModality modality = MissionModality.real,
  DateTime? completedAt,
  DateTime? failedAt,
}) {
  return MissionProgress(
    id: id,
    playerId: 1,
    missionKey: 'M$id',
    modality: modality,
    tabOrigin: tab,
    rank: GuildRank.e,
    targetValue: 10,
    currentValue: 0,
    reward: const RewardDeclared(xp: 10),
    startedAt: DateTime.now(),
    completedAt: completedAt,
    failedAt: failedAt,
    rewardClaimed: false,
    metaJson: '{}',
  );
}

ProviderContainer _makeContainer({
  required MissionRepository repo,
  required AppEventBus bus,
  List<ExtrasMissionSpec> extras = const [],
}) {
  return ProviderContainer(overrides: [
    missionRepositoryProvider.overrideWithValue(repo),
    appEventBusProvider.overrideWithValue(bus),
    extrasCatalogServiceProvider.overrideWithValue(
        _FakeExtrasCatalog(items: extras)),
    dailyMissionGeneratorServiceProvider
        .overrideWithValue(_FakeDailyGenerator()),
    dailyMissionRolloverServiceProvider
        .overrideWithValue(_FakeDailyRollover()),
  ]);
}

void main() {
  group('QuestsScreenNotifier Sprint 14.6c', () {
    test('build inicial carrega os 4 grupos legacy + extras + daily new',
        () async {
      final repo = _FakeMissionRepo(byTab: {
        MissionTabOrigin.classTab: [
          _mkMission(id: 2, tab: MissionTabOrigin.classTab)
        ],
        MissionTabOrigin.faction: [],
        MissionTabOrigin.admission: [],
        MissionTabOrigin.extras: [
          _mkMission(
              id: 3,
              tab: MissionTabOrigin.extras,
              modality: MissionModality.individual),
        ],
      });
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      final state = await c.read(questsScreenNotifierProvider(1).future);
      // dailyMissionsNew vem do _FakeDailyGenerator (vazio default).
      expect(state.dailyMissionsNew, isEmpty);
      expect(state.classMissions, hasLength(1));
      expect(state.factionMissions, isEmpty);
      expect(state.admissionMissions, isEmpty);
      expect(state.individualMissions, hasLength(1));
      expect(state.extrasCatalog, isEmpty);
      // Sprint 3.4 Etapa C hotfix #3 (P0-F) — 5 calls: 4 do bloco
      // Future.wait (classTab/faction/admission/extras) + 1 de
      // FactionAdmissionProgressService.evaluatePlayer (lê admission
      // pra re-avaliar expiração de janela). Daily legacy ainda fora
      // da contagem (droppado da UI na Etapa 1.3.A).
      expect(repo.findByTabCalls, 5);
    });

    test('doneCount soma missões `completedAt != null` das seções legacy',
        () async {
      // Etapa 1.3.A — doneCount não conta daily legacy nem dailyMissionsNew
      // (essas têm fluxo próprio via DailyMissionStatus, não MissionProgress).
      final now = DateTime.now();
      final repo = _FakeMissionRepo(byTab: {
        MissionTabOrigin.classTab: [
          _mkMission(id: 3, tab: MissionTabOrigin.classTab, completedAt: now),
        ],
        MissionTabOrigin.extras: [
          _mkMission(
              id: 4,
              tab: MissionTabOrigin.extras,
              modality: MissionModality.individual,
              completedAt: now),
        ],
      });
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      final state = await c.read(questsScreenNotifierProvider(1).future);
      expect(state.doneCount, 2);
      expect(state.totalCount, 2);
    });

    test('MissionCompleted no bus invalida state → rebuild', () async {
      final repo = _FakeMissionRepo(byTab: {
        MissionTabOrigin.classTab: [
          _mkMission(id: 1, tab: MissionTabOrigin.classTab),
        ],
      });
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final callsBeforeEvent = repo.findByTabCalls;

      bus.publish(MissionCompleted(
        playerId: 1,
        missionKey: 'M1',
        rewardResolvedJson: '{}',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await c.read(questsScreenNotifierProvider(1).future);

      expect(repo.findByTabCalls, greaterThan(callsBeforeEvent));
    });

    test('IndividualCreated no bus invalida state → rebuild', () async {
      final repo = _FakeMissionRepo();
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final callsBefore = repo.findByTabCalls;

      bus.publish(IndividualCreated(
        playerId: 1,
        missionProgressId: 42,
        missionKey: 'IND_USER_X',
        categoria: 'fisico',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await c.read(questsScreenNotifierProvider(1).future);

      expect(repo.findByTabCalls, greaterThan(callsBefore));
    });

    test('tab=extras filtra por modality=individual no state', () async {
      final repo = _FakeMissionRepo(byTab: {
        MissionTabOrigin.extras: [
          _mkMission(
              id: 1,
              tab: MissionTabOrigin.extras,
              modality: MissionModality.individual),
          // Não-individual no tab_origin=extras (edge case futuro)
          _mkMission(
              id: 2,
              tab: MissionTabOrigin.extras,
              modality: MissionModality.real),
        ],
      });
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      final state = await c.read(questsScreenNotifierProvider(1).future);
      expect(state.individualMissions, hasLength(1));
      expect(state.individualMissions.single.id, 1);
    });

    test('extras catalog: secretas filtradas fora do state', () async {
      final repo = _FakeMissionRepo();
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(
        repo: repo,
        bus: bus,
        extras: [
          const ExtrasMissionSpec(
            key: 'E1',
            title: 'Visível',
            description: 'd',
            type: ExtraMissionType.npc,
            isSecret: false,
          ),
          const ExtrasMissionSpec(
            key: 'E2',
            title: 'Oculto',
            description: 'd',
            type: ExtraMissionType.secret,
            isSecret: true,
          ),
        ],
      );
      addTearDown(c.dispose);

      final state = await c.read(questsScreenNotifierProvider(1).future);
      expect(state.extrasCatalog, hasLength(1));
      expect(state.extrasCatalog.single.key, 'E1');
    });

    test('refresh força rebuild', () async {
      final repo = _FakeMissionRepo();
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final callsBefore = repo.findByTabCalls;
      await c
          .read(questsScreenNotifierProvider(1).notifier)
          .refresh();
      expect(repo.findByTabCalls, greaterThan(callsBefore));
    });
  });
}
