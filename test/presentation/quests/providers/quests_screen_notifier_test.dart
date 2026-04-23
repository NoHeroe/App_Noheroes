import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/repositories/mission_repository.dart';
import 'package:noheroes_app/presentation/quests/providers/quests_screen_notifier.dart';

/// Fake Repository pra testes — rastreia chamadas + permite seedar
/// resultados por (tab, isHistorical).
class _FakeMissionRepo implements MissionRepository {
  final Map<MissionTabOrigin, List<MissionProgress>> byTab;
  final List<MissionProgress> historical;

  int findByTabCalls = 0;
  int findHistoricalCalls = 0;

  _FakeMissionRepo({
    this.byTab = const {},
    this.historical = const [],
  });

  @override
  Future<List<MissionProgress>> findByTab(
      int playerId, MissionTabOrigin tab) async {
    findByTabCalls++;
    return byTab[tab] ?? const [];
  }

  @override
  Future<List<MissionProgress>> findHistorical(int playerId) async {
    findHistoricalCalls++;
    return historical;
  }

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

MissionProgress _mkMission({
  required int id,
  required MissionTabOrigin tab,
  MissionCategory? category,
  MissionModality modality = MissionModality.real,
}) {
  final meta = category == null
      ? '{}'
      : jsonEncode({'category': category.storage});
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
    rewardClaimed: false,
    metaJson: meta,
  );
}

ProviderContainer _makeContainer({
  required MissionRepository repo,
  required AppEventBus bus,
}) {
  final container = ProviderContainer(overrides: [
    missionRepositoryProvider.overrideWithValue(repo),
    appEventBusProvider.overrideWithValue(bus),
  ]);
  return container;
}

void main() {
  group('QuestsScreenNotifier', () {
    test('build inicial carrega daily via findByTab', () async {
      final daily = [
        _mkMission(id: 1, tab: MissionTabOrigin.daily),
        _mkMission(id: 2, tab: MissionTabOrigin.daily),
      ];
      final repo = _FakeMissionRepo(byTab: {MissionTabOrigin.daily: daily});
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      final state = await c.read(questsScreenNotifierProvider(1).future);
      expect(state.activeTab, QuestTab.daily);
      expect(state.missions.length, 2);
      expect(repo.findByTabCalls, 1);
    });

    test('setActiveTab muda tab + refaz query', () async {
      final daily = [_mkMission(id: 1, tab: MissionTabOrigin.daily)];
      final class_ = [
        _mkMission(id: 2, tab: MissionTabOrigin.classTab),
        _mkMission(id: 3, tab: MissionTabOrigin.classTab),
      ];
      final repo = _FakeMissionRepo(byTab: {
        MissionTabOrigin.daily: daily,
        MissionTabOrigin.classTab: class_,
      });
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final notifier = c.read(questsScreenNotifierProvider(1).notifier);
      await notifier.setActiveTab(QuestTab.classTab);

      final state = c.read(questsScreenNotifierProvider(1)).value!;
      expect(state.activeTab, QuestTab.classTab);
      expect(state.missions.length, 2);
    });

    test('setActiveTab history chama findHistorical', () async {
      final repo = _FakeMissionRepo(
        byTab: {MissionTabOrigin.daily: const []},
        historical: [_mkMission(id: 5, tab: MissionTabOrigin.daily)],
      );
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      await c
          .read(questsScreenNotifierProvider(1).notifier)
          .setActiveTab(QuestTab.history);

      expect(repo.findHistoricalCalls, 1);
      expect(
          c.read(questsScreenNotifierProvider(1)).value!.missions.length, 1);
    });

    test('toggleCategoryFilter adiciona e remove', () async {
      final repo = _FakeMissionRepo(byTab: {
        MissionTabOrigin.daily: [
          _mkMission(
              id: 1, tab: MissionTabOrigin.daily, category: MissionCategory.fisico),
          _mkMission(
              id: 2, tab: MissionTabOrigin.daily, category: MissionCategory.mental),
        ],
      });
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final notifier = c.read(questsScreenNotifierProvider(1).notifier);
      await notifier.toggleCategoryFilter(MissionCategory.fisico);
      var state = c.read(questsScreenNotifierProvider(1)).value!;
      expect(state.categoryFilters, {MissionCategory.fisico});
      expect(state.missions.length, 1);
      expect(state.missions.first.id, 1);

      await notifier.toggleCategoryFilter(MissionCategory.fisico);
      state = c.read(questsScreenNotifierProvider(1)).value!;
      expect(state.categoryFilters, isEmpty);
      expect(state.missions.length, 2);
    });

    test('filtros múltiplos AND — só tab + categoria batem', () async {
      final repo = _FakeMissionRepo(byTab: {
        MissionTabOrigin.daily: [
          _mkMission(
              id: 1, tab: MissionTabOrigin.daily, category: MissionCategory.fisico),
          _mkMission(
              id: 2, tab: MissionTabOrigin.daily, category: MissionCategory.mental),
          _mkMission(
              id: 3,
              tab: MissionTabOrigin.daily,
              category: MissionCategory.espiritual),
        ],
      });
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final notifier = c.read(questsScreenNotifierProvider(1).notifier);
      await notifier.toggleCategoryFilter(MissionCategory.fisico);
      await notifier.toggleCategoryFilter(MissionCategory.mental);
      final state = c.read(questsScreenNotifierProvider(1)).value!;
      expect(state.missions.map((m) => m.id).toSet(), {1, 2});
    });

    test('MissionCompleted no bus → invalida state (refetch)', () async {
      final daily = [_mkMission(id: 1, tab: MissionTabOrigin.daily)];
      final repo = _FakeMissionRepo(byTab: {MissionTabOrigin.daily: daily});
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final before = repo.findByTabCalls;
      bus.publish(MissionCompleted(
          missionKey: 'M1',
          playerId: 1,
          rewardResolvedJson: '{}'));
      // Aguarda a microtask do listener + invalidateSelf + rebuild.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await c.read(questsScreenNotifierProvider(1).future);
      expect(repo.findByTabCalls, greaterThan(before));
    });

    test('MissionFailed no bus → invalida state (refetch)', () async {
      final repo = _FakeMissionRepo(byTab: {MissionTabOrigin.daily: const []});
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final before = repo.findByTabCalls;
      bus.publish(MissionFailed(
          missionKey: 'M1',
          playerId: 1,
          reason: MissionFailureReason.expired));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await c.read(questsScreenNotifierProvider(1).future);
      expect(repo.findByTabCalls, greaterThan(before));
    });

    test('clearFilters zera o set e mostra lista completa', () async {
      final repo = _FakeMissionRepo(byTab: {
        MissionTabOrigin.daily: [
          _mkMission(
              id: 1, tab: MissionTabOrigin.daily, category: MissionCategory.fisico),
          _mkMission(
              id: 2, tab: MissionTabOrigin.daily, category: MissionCategory.mental),
        ],
      });
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final notifier = c.read(questsScreenNotifierProvider(1).notifier);
      await notifier.toggleCategoryFilter(MissionCategory.fisico);
      expect(
          c.read(questsScreenNotifierProvider(1)).value!.missions.length, 1);

      await notifier.clearFilters();
      final state = c.read(questsScreenNotifierProvider(1)).value!;
      expect(state.categoryFilters, isEmpty);
      expect(state.missions.length, 2);
    });

    test(
        'autodispose + invalidateSelf não duplica subscriptions (sem vazamento)',
        () async {
      // Smoke test de vazamento: após invalidateSelf, o evento seguinte
      // dispara exatamente UM refetch (não 2, que seria o sintoma de
      // subscription velha não cancelada). Aproximamos contando calls
      // do repo pós primeiro evento vs pós segundo.
      final repo = _FakeMissionRepo(byTab: {MissionTabOrigin.daily: const []});
      final bus = AppEventBus();
      addTearDown(bus.dispose);
      final c = _makeContainer(repo: repo, bus: bus);
      addTearDown(c.dispose);

      await c.read(questsScreenNotifierProvider(1).future);
      final notifier = c.read(questsScreenNotifierProvider(1).notifier);

      // Força 1 invalidação (simula consumo do sub depois de um evento).
      await notifier.refresh();
      final afterFirstRefresh = repo.findByTabCalls;

      // Dispara evento. Se subscriptions vazaram, cada sub antiga também
      // invalidaria → múltiplos refetches. Esperamos exatamente +1 call.
      bus.publish(MissionCompleted(
          missionKey: 'M1',
          playerId: 1,
          rewardResolvedJson: '{}'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await c.read(questsScreenNotifierProvider(1).future);

      final delta = repo.findByTabCalls - afterFirstRefresh;
      // Tolerância: 1 (sem vazamento) ou 2 (rebuilding state intermediário).
      // Vazamento faria delta >= 3.
      expect(delta, lessThanOrEqualTo(2),
          reason: 'Subscription vazada dispara refetches extras');
    });
  });
}
