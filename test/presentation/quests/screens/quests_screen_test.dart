import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/repositories/mission_repository.dart';
import 'package:noheroes_app/presentation/quests/screens/quests_screen.dart';

/// Widget tests focam em COMPORTAMENTO, não pixel.
/// - render dos chips (tabs + categorias)
/// - tap muda state observável
/// - empty state renderiza texto
/// - loading/error states renderizam widgets corretos

class _FakeMissionRepo implements MissionRepository {
  final Map<MissionTabOrigin, List<MissionProgress>> byTab;
  _FakeMissionRepo({this.byTab = const {}});

  @override
  Future<List<MissionProgress>> findByTab(
          int playerId, MissionTabOrigin tab) async =>
      byTab[tab] ?? const [];

  @override
  Future<List<MissionProgress>> findHistorical(int playerId) async => const [];

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

PlayersTableData _fakePlayer({int id = 1}) {
  // Construção manual — PlayersTableData vem do drift generator.
  return PlayersTableData(
    id: id,
    email: 't@t',
    passwordHash: 'h',
    shadowName: 'Sombra',
    level: 5,
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
    guildRank: 'none',
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
    streakDays: 0,
    caelumDay: 0,
    createdAt: DateTime.now(),
  );
}

MissionProgress _mkMission(int id, MissionTabOrigin tab, MissionModality mod) {
  return MissionProgress(
    id: id,
    playerId: 1,
    missionKey: 'M$id',
    modality: mod,
    tabOrigin: tab,
    rank: GuildRank.e,
    targetValue: 10,
    currentValue: 0,
    reward: const RewardDeclared(),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: '{}',
  );
}

Widget _harness({
  required MissionRepository repo,
  required AppEventBus bus,
  required PlayersTableData player,
}) {
  return ProviderScope(
    overrides: [
      missionRepositoryProvider.overrideWithValue(repo),
      appEventBusProvider.overrideWithValue(bus),
      currentPlayerProvider.overrideWith((ref) => player),
    ],
    child: const MaterialApp(home: QuestsScreen()),
  );
}

void main() {
  testWidgets('renderiza 6 tab chips + 4 category chips', (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(),
      bus: bus,
      player: _fakePlayer(),
    ));
    await tester.pumpAndSettle();

    // 6 tabs
    expect(find.byKey(const ValueKey('quest-tab-daily')), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-tab-classTab')), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-tab-faction')), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-tab-extras')), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-tab-admission')), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-tab-history')), findsOneWidget);

    // 4 categorias
    for (final cat in MissionCategory.values) {
      expect(find.byKey(ValueKey('category-${cat.storage}')), findsOneWidget);
    }
  });

  testWidgets('tap em chip de tab muda activeTab (renderiza lista da tab)',
      (tester) async {
    final repo = _FakeMissionRepo(byTab: {
      MissionTabOrigin.daily: const [],
      MissionTabOrigin.classTab: [
        _mkMission(1, MissionTabOrigin.classTab, MissionModality.internal),
      ],
    });
    final bus = AppEventBus();
    addTearDown(bus.dispose);

    await tester.pumpWidget(_harness(
      repo: repo,
      bus: bus,
      player: _fakePlayer(),
    ));
    await tester.pumpAndSettle();

    // Estado inicial: daily (vazio)
    expect(find.text('Nenhuma missão nesta aba.'), findsOneWidget);

    // Tap em Classe → lista não-vazia com 1 missão
    await tester.tap(find.byKey(const ValueKey('quest-tab-classTab')));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma missão nesta aba.'), findsNothing);
    expect(find.text('M1'), findsOneWidget);
  });

  testWidgets('tap em category chip altera filtro (chip fica selected)',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(),
      bus: bus,
      player: _fakePlayer(),
    ));
    await tester.pumpAndSettle();

    final chip = find.byKey(const ValueKey('category-fisico'));
    expect(chip, findsOneWidget);

    // Antes do tap: FilterChip.selected=false. Após tap: true.
    FilterChip getChip() =>
        tester.widget<FilterChip>(chip);
    expect(getChip().selected, isFalse);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(getChip().selected, isTrue);
  });

  testWidgets('lista vazia renderiza empty state', (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(byTab: {MissionTabOrigin.daily: const []}),
      bus: bus,
      player: _fakePlayer(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma missão nesta aba.'), findsOneWidget);
  });

  testWidgets('lista com missão internal renderiza InternalMissionCard',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);
    final m =
        _mkMission(42, MissionTabOrigin.daily, MissionModality.internal);
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(byTab: {MissionTabOrigin.daily: [m]}),
      bus: bus,
      player: _fakePlayer(),
    ));
    await tester.pumpAndSettle();
    // Internal card tem LinearProgressIndicator (barra passiva).
    expect(find.text('M42'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });
}
