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
import 'package:noheroes_app/domain/models/daily_mission.dart';
import 'package:noheroes_app/domain/models/extras_mission_spec.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/repositories/mission_repository.dart';
import 'package:noheroes_app/domain/services/daily_mission_generator_service.dart';
import 'package:noheroes_app/domain/services/daily_mission_rollover_service.dart';
import 'package:noheroes_app/presentation/quests/screens/quests_screen.dart';

/// Sprint 3.2 Etapa 1.3.A — smoke do `/quests` redesenhado.
///
/// Header novo (`MISSÕES` + barra geral + 🔥), seção "MISSÕES DIÁRIAS"
/// no topo (Etapa 1.2 — pode estar vazia em smoke), bottom nav fixa,
/// seção "RITUAIS DIÁRIOS" legacy **dropada da UI**.
///
/// Usa fakes `implements` pros services novos pra evitar dependência
/// de DB real + assets em widget test (causava segfault no shell em
/// Flutter 3.x — usar in-memory drift + rootBundle dentro de WidgetTester
/// é instável).

class _FakeMissionRepo implements MissionRepository {
  final Map<MissionTabOrigin, List<MissionProgress>> byTab;
  _FakeMissionRepo({this.byTab = const {}});

  @override
  Future<List<MissionProgress>> findByTab(int playerId, MissionTabOrigin tab)
      async => byTab[tab] ?? const [];

  @override
  Future<List<MissionProgress>> findHistorical(int playerId) async =>
      const [];

  @override
  Future<List<MissionProgress>> findCompletedInWindow(int playerId,
          {required DateTime from, required DateTime to}) async =>
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

class _FakeDailyGenerator implements DailyMissionGeneratorService {
  final List<DailyMission> missions;
  _FakeDailyGenerator({this.missions = const []});

  @override
  Future<List<DailyMission>> getTodayMissions(int playerId) async => missions;

  @override
  Future<List<DailyMission>> generateForToday(int playerId, {DateTime? date})
      async => missions;

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

PlayersTableData _fakePlayer({int dailyStreak = 0, String rank = 'E'}) {
  return PlayersTableData(
    id: 1,
    email: 't@t',
    passwordHash: 'h',
    shadowName: 'Tester',
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
    guildRank: rank,
    narrativeMode: 'longa',
    playStyle: 'none',
    totalQuestsCompleted: 0,
    maxHp: 100,
    hp: 100,
    maxMp: 50,
    mp: 50,
    onboardingDone: true,
    lastLoginAt: DateTime.now(),
    streakDays: 0,
    caelumDay: 0,
    createdAt: DateTime.now(),
    dailyMissionsStreak: dailyStreak,
  );
}

MissionProgress _mkMission({
  required int id,
  required MissionTabOrigin tab,
  MissionModality modality = MissionModality.real,
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
    rewardClaimed: false,
    metaJson: '{}',
  );
}

Widget _harness({
  required AppEventBus bus,
  PlayersTableData? player,
  MissionRepository? repo,
  List<ExtrasMissionSpec> extras = const [],
  List<DailyMission> dailyMissions = const [],
}) {
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWithValue(bus),
      missionRepositoryProvider
          .overrideWithValue(repo ?? _FakeMissionRepo()),
      extrasCatalogServiceProvider
          .overrideWithValue(_FakeExtrasCatalog(items: extras)),
      dailyMissionGeneratorServiceProvider.overrideWithValue(
          _FakeDailyGenerator(missions: dailyMissions)),
      dailyMissionRolloverServiceProvider
          .overrideWithValue(_FakeDailyRollover()),
      currentPlayerProvider.overrideWith((_) => player ?? _fakePlayer()),
    ],
    child: const MaterialApp(home: QuestsScreen()),
  );
}

void main() {
  testWidgets('Header "MISSÕES" + streak + bottom nav renderizam',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);

    await tester.pumpWidget(
        _harness(bus: bus, player: _fakePlayer(dailyStreak: 7)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MISSÕES'), findsOneWidget);
    expect(find.text('7 dias'), findsOneWidget);
    // Bottom nav presente
    expect(find.text('Santuário'), findsOneWidget);
    expect(find.text('Missões'), findsOneWidget);
  });

  testWidgets('Sem missões diárias: seção "MISSÕES DIÁRIAS" + placeholder',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);

    await tester.pumpWidget(_harness(bus: bus));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MISSÕES DIÁRIAS'), findsOneWidget);
    expect(find.text('Nenhuma missão diária ainda.'), findsOneWidget);
    // Contador 0/0
    expect(find.text('0/0 concluídas'), findsOneWidget);
  });

  testWidgets('Seção "RITUAIS DIÁRIOS" legacy não aparece mais',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);

    await tester.pumpWidget(_harness(
      bus: bus,
      repo: _FakeMissionRepo(byTab: {
        MissionTabOrigin.daily: [
          _mkMission(id: 1, tab: MissionTabOrigin.daily),
        ],
      }),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('RITUAIS DIÁRIOS'), findsNothing);
  });

  testWidgets('Outras seções legacy permanecem (Individuais sempre)',
      (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);

    await tester.pumpWidget(_harness(
      bus: bus,
      repo: _FakeMissionRepo(byTab: {
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
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MISSÕES DE CLASSE'), findsOneWidget);
    expect(find.text('ADMISSÃO DE FACÇÃO'), findsOneWidget);
    // Seção Individuais pode estar fora do viewport — testada em outro caso.
  });

  testWidgets('Botão inline Nova Missão Individual renderiza', (tester) async {
    final bus = AppEventBus();
    addTearDown(bus.dispose);

    await tester.pumpWidget(_harness(bus: bus));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('quests-create-individual-inline')),
        findsOneWidget);
    expect(find.text('Nova Missão Individual'), findsOneWidget);
  });
}
