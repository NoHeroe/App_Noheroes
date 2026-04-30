import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/models/achievement_definition.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/repositories/player_achievements_repository.dart';
import 'package:noheroes_app/domain/services/achievements_service.dart';
import 'package:noheroes_app/presentation/achievements/screens/achievements_screen.dart';

class _FakeAchievementsService implements AchievementsService {
  final Map<String, AchievementDefinition> _catalog;
  _FakeAchievementsService(this._catalog);

  @override
  Future<void> ensureLoaded() async {}

  @override
  Map<String, AchievementDefinition> get catalog =>
      Map.unmodifiable(_catalog);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeAchievementsRepo implements PlayerAchievementsRepository {
  final Set<String> completed;
  _FakeAchievementsRepo(this.completed);

  @override
  Future<List<String>> listCompletedKeys(int playerId) async =>
      completed.toList();

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

AchievementDefinition _def({
  required String key,
  String name = 'Nome',
  String description = 'Descrição',
  String category = 'progression',
  bool isSecret = false,
  RewardDeclared? reward,
}) {
  return AchievementDefinition(
    key: key,
    name: name,
    description: description,
    category: category,
    trigger: const EventCountTrigger(eventName: 'MissionCompleted', count: 1),
    reward: reward,
    isSecret: isSecret,
  );
}

PlayersTableData _player() {
  return PlayersTableData(
    id: 1,
    email: 't@t',
    passwordHash: 'h',
    shadowName: 'S',
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
    classType: 'warrior',
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
    streakDays: 0,
    caelumDay: 0,
    createdAt: DateTime.now(),
    dailyMissionsStreak: 0,
    totalGemsSpent: 0,
    peakLevel: 1,
    totalAttributePointsSpent: 0,
  );
}

Widget _harness({
  required Map<String, AchievementDefinition> catalog,
  required Set<String> unlocked,
}) {
  final router = GoRouter(
    initialLocation: '/achievements',
    routes: [
      GoRoute(
          path: '/achievements',
          builder: (_, __) => const AchievementsScreen()),
      GoRoute(
          path: '/sanctuary',
          builder: (_, __) => const Scaffold(body: Text('sanctuary'))),
    ],
  );
  return ProviderScope(
    overrides: [
      achievementsServiceProvider
          .overrideWithValue(_FakeAchievementsService(catalog)),
      playerAchievementsRepositoryProvider
          .overrideWithValue(_FakeAchievementsRepo(unlocked)),
      currentPlayerProvider.overrideWith((_) => _player()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('Catálogo vazio → empty state', (tester) async {
    await tester.pumpWidget(_harness(catalog: const {}, unlocked: const {}));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('achievements-empty')), findsOneWidget);
    expect(find.text('Nenhuma conquista no catálogo.'), findsOneWidget);
  });

  testWidgets('3 definições + 1 unlocked → 1 colorido, 2 locked', (tester) async {
    final catalog = {
      'ACH_A': _def(
        key: 'ACH_A',
        name: 'Primeira',
        reward: const RewardDeclared(xp: 100, gold: 50),
      ),
      'ACH_B': _def(key: 'ACH_B', name: 'Segunda'),
      'ACH_C': _def(key: 'ACH_C', name: 'Terceira'),
    };
    await tester.pumpWidget(_harness(
      catalog: catalog,
      unlocked: const {'ACH_A'},
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('achievements-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('achievement-card-ACH_A')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('achievement-card-ACH_B')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('achievement-card-ACH_C')),
        findsOneWidget);

    // DESBLOQUEADO aparece só no card ACH_A.
    expect(find.text('DESBLOQUEADO'), findsOneWidget);
    // XP/gold badges aparecem no unlocked.
    expect(find.text('+100 XP'), findsOneWidget);
    expect(find.text('+50 ouro'), findsOneWidget);
  });

  testWidgets('Secret + locked → renderiza _SecretCard sem expor nome',
      (tester) async {
    final catalog = {
      'ACH_SECRET': _def(
          key: 'ACH_SECRET',
          name: 'Nome Escondido',
          description: 'Texto real',
          isSecret: true),
      'ACH_NORMAL': _def(key: 'ACH_NORMAL', name: 'Visível'),
    };
    await tester.pumpWidget(_harness(
      catalog: catalog,
      unlocked: const {},
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('achievement-card-secret')),
        findsOneWidget);
    expect(find.text('Conquista Secreta'), findsOneWidget);
    // Nome real do secret não vaza.
    expect(find.text('Nome Escondido'), findsNothing);
    expect(find.text('Texto real'), findsNothing);
    // Visível renderiza normalmente.
    expect(find.text('Visível'), findsOneWidget);
  });

  testWidgets('Contador "X/Y" no header reflete catálogo + unlocked',
      (tester) async {
    final catalog = {
      'ACH_A': _def(key: 'ACH_A'),
      'ACH_B': _def(key: 'ACH_B'),
      'ACH_C': _def(key: 'ACH_C'),
    };
    await tester.pumpWidget(_harness(
      catalog: catalog,
      unlocked: const {'ACH_A', 'ACH_B'},
    ));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
  });
}
