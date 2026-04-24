import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/extras_catalog_service.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/extras_mission_spec.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/repositories/mission_repository.dart';
import 'package:noheroes_app/presentation/quests/screens/quests_screen.dart';

/// Sprint 3.1 Bloco 14.6c — widget tests do /quests com sanfona.
/// Não testa pixel — testa comportamento: seções renderizam
/// condicionalmente, header agrega contadores, botão inline abre
/// sheet.

class _FakeMissionRepo implements MissionRepository {
  final Map<MissionTabOrigin, List<MissionProgress>> byTab;
  _FakeMissionRepo({this.byTab = const {}});

  @override
  Future<List<MissionProgress>> findByTab(
          int playerId, MissionTabOrigin tab) async =>
      byTab[tab] ?? const [];

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

PlayersTableData _fakePlayer({int streak = 0, int level = 5}) {
  return PlayersTableData(
    id: 1,
    email: 't@t',
    passwordHash: 'h',
    shadowName: 'Sombra',
    level: level,
    xp: 0,
    xpToNext: 100,
    gold: 0,
    gems: 0,
    strength: 1,
    dexterity: 1,
    intelligence: 1,
    constitution: 1,
    spirit: 1,
    charisma: 1,
    attributePoints: 0,
    shadowCorruption: 0,
    vitalismLevel: 0,
    vitalismXp: 0,
    currentVitalism: 0,
    shadowState: 'stable',
    classType: null,
    factionType: null,
    guildRank: 'e',
    narrativeMode: 'standard',
    playStyle: 'none',
    totalQuestsCompleted: 0,
    maxHp: 100,
    hp: 100,
    maxMp: 50,
    mp: 50,
    onboardingDone: true,
    lastLoginAt: DateTime.now(),
    lastStreakDate: DateTime.now(),
    streakDays: streak,
    caelumDay: 0,
    createdAt: DateTime.now(),
  );
}

MissionProgress _mkMission({
  required int id,
  required MissionTabOrigin tab,
  MissionModality modality = MissionModality.real,
  DateTime? completedAt,
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
    reward: const RewardDeclared(),
    startedAt: DateTime.now(),
    completedAt: completedAt,
    rewardClaimed: false,
    metaJson: '{}',
  );
}

Widget _harness({
  required MissionRepository repo,
  required AppEventBus bus,
  PlayersTableData? player,
  List<ExtrasMissionSpec> extras = const [],
}) {
  return ProviderScope(
    overrides: [
      missionRepositoryProvider.overrideWithValue(repo),
      appEventBusProvider.overrideWithValue(bus),
      extrasCatalogServiceProvider
          .overrideWithValue(_FakeExtrasCatalog(items: extras)),
      currentPlayerProvider.overrideWith((_) => player ?? _fakePlayer()),
    ],
    child: const MaterialApp(home: QuestsScreen()),
  );
}

void main() {
  testWidgets(
      'Header renderiza título + contador 0/0 quando vazio; sem streak badge',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(
        _harness(repo: _FakeMissionRepo(), bus: bus));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MISSÕES'), findsOneWidget);
    expect(find.byKey(const ValueKey('quests-header-counter')),
        findsOneWidget);
    expect(find.text('0/0'), findsOneWidget);
    expect(find.byKey(const ValueKey('quests-header-streak')), findsNothing);
  });

  testWidgets('Streak > 0: badge renderiza no header', (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(),
      bus: bus,
      player: _fakePlayer(streak: 7),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('quests-header-streak')), findsOneWidget);
    expect(find.text('7 dias'), findsOneWidget);
  });

  testWidgets('Seções vazias não renderizam header; Individuais sempre aparece',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(
        _harness(repo: _FakeMissionRepo(), bus: bus));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Sem daily/class/faction/admission/extras → headers não aparecem
    expect(find.text('RITUAIS DIÁRIOS'), findsNothing);
    expect(find.text('MISSÕES DE CLASSE'), findsNothing);
    expect(find.text('MISSÃO DA FACÇÃO'), findsNothing);
    expect(find.text('ADMISSÃO DE FACÇÃO'), findsNothing);
    expect(find.text('EXTRAS'), findsNothing);
    // Individuais sempre aparece (jogador cria)
    expect(find.text('MISSÕES INDIVIDUAIS'), findsOneWidget);
    expect(find.text('Nenhuma missão individual ainda.'), findsOneWidget);
  });

  testWidgets('Daily + class + admission: 3 seções com headers renderizam',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(byTab: {
        MissionTabOrigin.daily: [
          _mkMission(id: 1, tab: MissionTabOrigin.daily)
        ],
        MissionTabOrigin.classTab: [
          _mkMission(
              id: 2,
              tab: MissionTabOrigin.classTab,
              modality: MissionModality.internal),
        ],
        MissionTabOrigin.admission: [
          _mkMission(
              id: 3,
              tab: MissionTabOrigin.admission,
              modality: MissionModality.internal),
        ],
      }),
      bus: bus,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('RITUAIS DIÁRIOS'), findsOneWidget);
    expect(find.text('MISSÕES DE CLASSE'), findsOneWidget);
    // Subtitle da classe
    expect(find.text('Concluídas automaticamente ao agir.'), findsOneWidget);
    expect(find.text('ADMISSÃO DE FACÇÃO'), findsOneWidget);
    // Contador soma: 3 missões totais
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('Sanfona colapsa/expande ao tap no header', (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(byTab: {
        MissionTabOrigin.daily: [
          _mkMission(id: 1, tab: MissionTabOrigin.daily),
        ],
      }),
      bus: bus,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Default: expandida. AnimatedCrossFade mantém ambos children no tree
    // durante transição — testamos via `crossFadeState` do widget.
    AnimatedCrossFade findCrossFade() {
      return tester.widget<AnimatedCrossFade>(find
          .ancestor(
            of: find.text('M1'),
            matching: find.byType(AnimatedCrossFade),
          )
          .first);
    }

    expect(findCrossFade().crossFadeState, CrossFadeState.showSecond);

    // Tap no header colapsa
    await tester.tap(find.byKey(const ValueKey('section-header-rituais-diários')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(findCrossFade().crossFadeState, CrossFadeState.showFirst);

    // Tap de novo expande
    await tester.tap(find.byKey(const ValueKey('section-header-rituais-diários')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(findCrossFade().crossFadeState, CrossFadeState.showSecond);
  });

  testWidgets('Botão inline Nova Missão Individual renderiza na seção Individuais',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(
        _harness(repo: _FakeMissionRepo(), bus: bus));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('quests-create-individual-inline')),
        findsOneWidget);
    // Copy v0.28.2 — caixa mista
    expect(find.text('Nova Missão Individual'), findsOneWidget);
  });
}
