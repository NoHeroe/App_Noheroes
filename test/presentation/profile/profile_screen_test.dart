import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/domain/services/body_metrics_service.dart';
import 'package:noheroes_app/presentation/profile/screens/profile_screen.dart';

PlayersTableData _player({int? weightKg, int? heightCm}) {
  return PlayersTableData(
    id: 1,
    email: 't@t',
    passwordHash: 'h',
    shadowName: 'Tester',
    level: 12,
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
    weightKg: weightKg,
    heightCm: heightCm,
  );
}

Widget _harness(PlayersTableData player) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final router = GoRouter(
    initialLocation: '/perfil',
    routes: [
      GoRoute(path: '/perfil', builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: '/sanctuary',
          builder: (_, __) => const Scaffold(body: Text('sanctuary'))),
    ],
  );
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      currentPlayerProvider.overrideWith((_) => player),
      bodyMetricsServiceProvider
          .overrideWithValue(BodyMetricsService(dao: PlayerDao(db))),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('Header "PERFIL" + botão voltar renderizam', (tester) async {
    await tester.pumpWidget(_harness(_player()));
    await tester.pump();
    expect(find.text('PERFIL'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-back')), findsOneWidget);
  });

  testWidgets('Identidade exibe nome, classe e level', (tester) async {
    await tester.pumpWidget(_harness(_player()));
    await tester.pump();
    expect(find.text('Tester'), findsOneWidget);
    expect(find.text('Guerreiro'), findsOneWidget);
    expect(find.text('Nível 12'), findsOneWidget);
  });

  testWidgets('Sem peso/altura: campos exibem "—" + recomendações null',
      (tester) async {
    await tester.pumpWidget(_harness(_player()));
    await tester.pump();
    // 5 placeholders: peso, altura, IMC, água, proteína (Faixa = "Incompleto").
    expect(find.text('—'), findsNWidgets(5));
    expect(find.text('Incompleto'), findsOneWidget);
    expect(
      find.text('Preenche peso pra calcular as recomendações.'),
      findsOneWidget,
    );
  });

  testWidgets('Com peso/altura: IMC calculado + recomendações renderizam',
      (tester) async {
    await tester.pumpWidget(_harness(_player(weightKg: 70, heightCm: 170)));
    await tester.pump();
    expect(find.text('70 kg'), findsOneWidget);
    expect(find.text('170 cm'), findsOneWidget);
    expect(find.text('24.2'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('2450 ml'), findsOneWidget);
    expect(find.text('112 g'), findsOneWidget);
  });

  testWidgets('Botões editar peso/altura presentes', (tester) async {
    await tester.pumpWidget(_harness(_player(weightKg: 70, heightCm: 170)));
    await tester.pump();
    // 2 ícones edit: peso + altura (IMC e Faixa não têm).
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
  });

  testWidgets('Tap em editar peso abre dialog com input', (tester) async {
    await tester.pumpWidget(_harness(_player(weightKg: 70, heightCm: 170)));
    await tester.pump();
    final editButtons = find.byIcon(Icons.edit_outlined);
    expect(editButtons, findsNWidgets(2));
    await tester.tap(editButtons.first);
    await tester.pump();
    expect(find.byKey(const ValueKey('profile-edit-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-edit-confirm')), findsOneWidget);
  });
}
