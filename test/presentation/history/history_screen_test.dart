import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/repositories/mission_repository.dart';
import 'package:noheroes_app/presentation/history/screens/history_screen.dart';

class _FakeMissionRepo implements MissionRepository {
  final List<MissionProgress> historical;
  _FakeMissionRepo({this.historical = const []});

  @override
  Future<List<MissionProgress>> findHistorical(int playerId) async =>
      historical;

  @override
  Future<List<MissionProgress>> findCompletedInWindow(
    int playerId, {
    required DateTime from,
    required DateTime to,
  }) async =>
      const [];

  @override
  Future<List<MissionProgress>> findByTab(int playerId, MissionTabOrigin tab)
      async =>
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

PlayersTableData _fakePlayer({int totalQuests = 0}) {
  return PlayersTableData(
    id: 1,
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
    guildRank: 'e',
    narrativeMode: 'standard',
    playStyle: 'none',
    totalQuestsCompleted: totalQuests,
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

MissionProgress _mkMission({
  required int id,
  DateTime? completedAt,
  DateTime? failedAt,
}) {
  return MissionProgress(
    id: id,
    playerId: 1,
    missionKey: 'M$id',
    modality: MissionModality.real,
    tabOrigin: MissionTabOrigin.daily,
    rank: GuildRank.e,
    targetValue: 10,
    currentValue: completedAt != null ? 10 : 0,
    reward: const RewardDeclared(),
    startedAt: DateTime.now().subtract(const Duration(days: 1)),
    completedAt: completedAt,
    failedAt: failedAt,
    rewardClaimed: completedAt != null,
    metaJson: '{}',
  );
}

Widget _harness({
  required MissionRepository repo,
  PlayersTableData? player,
}) {
  final router = GoRouter(
    initialLocation: '/history',
    routes: [
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(
          path: '/sanctuary',
          builder: (_, __) => const Scaffold(body: Text('sanctuary'))),
    ],
  );
  final bus = AppEventBus();
  return ProviderScope(
    overrides: [
      missionRepositoryProvider.overrideWithValue(repo),
      appEventBusProvider.overrideWithValue(bus),
      currentPlayerProvider.overrideWith((_) => player ?? _fakePlayer()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('Header renderiza "HISTÓRICO" + botão voltar', (tester) async {
    await tester.pumpWidget(_harness(repo: _FakeMissionRepo()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('HISTÓRICO'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-back')), findsOneWidget);
  });

  testWidgets('Lista vazia renderiza copy "Nada no histórico ainda."',
      (tester) async {
    await tester.pumpWidget(_harness(repo: _FakeMissionRepo()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Nada no histórico ainda.'), findsOneWidget);
  });

  testWidgets('Missão de hoje → label HOJE', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(historical: [
        _mkMission(id: 1, completedAt: now),
      ]),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('HOJE'), findsOneWidget);
  });

  testWidgets('Missão de ontem → label ONTEM', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(historical: [
        _mkMission(id: 1, completedAt: yesterday),
      ]),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ONTEM'), findsOneWidget);
  });

  testWidgets('Filtro "Falhadas" esconde concluídas', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(_harness(
      repo: _FakeMissionRepo(historical: [
        _mkMission(id: 1, completedAt: now),
        _mkMission(id: 2, failedAt: now),
      ]),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Todas visíveis por default
    expect(find.byKey(const ValueKey('history-list')), findsOneWidget);

    // Tap em Falhadas
    await tester.tap(find.byKey(const ValueKey('history-filter-falhadas')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Missão 1 (completed) some, missão 2 (failed) continua
    expect(find.byKey(const ValueKey('history-card-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('history-card-1')), findsNothing);
  });
}
