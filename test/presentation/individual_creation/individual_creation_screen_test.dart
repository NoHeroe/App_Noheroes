import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/services/individual_creation_service.dart';
import 'package:noheroes_app/presentation/individual_creation/screens/individual_creation_screen.dart';

/// Fake creation service — registra chamadas, lança exceções sob comando.
class _FakeCreationService implements IndividualCreationService {
  int calls = 0;
  IndividualCreationParams? lastParams;
  bool throwLimit = false;

  @override
  Future<int> createIndividual(IndividualCreationParams params) async {
    calls++;
    lastParams = params;
    if (throwLimit) {
      throw IndividualLimitExceededException(
        playerId: params.playerId,
        limit: 5,
        current: 5,
      );
    }
    return 42;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

PlayersTableData _player({int level = 10}) {
  return PlayersTableData(
    id: 1,
    email: 't@t',
    passwordHash: 'h',
    shadowName: 'S',
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
  );
}

Widget _harness({
  required _FakeCreationService fake,
  PlayersTableData? player,
}) {
  return ProviderScope(
    overrides: [
      individualCreationServiceProvider.overrideWithValue(fake),
      currentPlayerProvider.overrideWith((_) => player ?? _player()),
    ],
    child: const MaterialApp(home: IndividualCreationScreen()),
  );
}

/// Tap seguro em tile dentro de SingleChildScrollView — scrolla até o
/// elemento ficar visível antes do tap.
Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Preenche os 3 steps iniciais pra chegar no review.
Future<void> _fillToReview(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const ValueKey('creation-name')), 'Flexões');
  await tester.enterText(
      find.byKey(const ValueKey('creation-description')), '20 reps');
  await tester.pumpAndSettle();
  await _tapKey(tester, const ValueKey('creation-next'));

  await _tapKey(tester, const ValueKey('creation-cat-fisico'));
  await _tapKey(tester, const ValueKey('creation-int-medium'));
  await _tapKey(tester, const ValueKey('creation-next'));

  await _tapKey(tester, const ValueKey('creation-freq-one_shot'));
  await tester.enterText(
      find.byKey(const ValueKey('creation-qty')), '20');
  await tester.pumpAndSettle();
  await _tapKey(tester, const ValueKey('creation-next'));
}

void main() {
  testWidgets('Step 1: nome/descrição vazios desabilitam Próximo',
      (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake: fake));
    await tester.pumpAndSettle();
    final btn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('creation-next')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('Step 1: nome + descrição habilitam Próximo', (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake: fake));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('creation-name')), 'Teste');
    await tester.enterText(
        find.byKey(const ValueKey('creation-description')), 'desc');
    await tester.pumpAndSettle();
    final btn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('creation-next')));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('Step 3: qty inválida (0) mostra erro', (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake: fake));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('creation-name')), 'N');
    await tester.enterText(
        find.byKey(const ValueKey('creation-description')), 'D');
    await tester.pumpAndSettle();
    await _tapKey(tester, const ValueKey('creation-next'));
    await _tapKey(tester, const ValueKey('creation-cat-fisico'));
    await _tapKey(tester, const ValueKey('creation-int-medium'));
    await _tapKey(tester, const ValueKey('creation-next'));
    await tester.enterText(
        find.byKey(const ValueKey('creation-qty')), '0');
    await tester.pumpAndSettle();
    expect(find.text('Entre 1 e 9999'), findsOneWidget);
  });

  testWidgets('Step 4: preview reward aparece + muda com repetível',
      (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake: fake));
    await tester.pumpAndSettle();
    await _fillToReview(tester);

    // Médio (2) × 30 × fisico (1.0) × 0.4 = 24 XP. Gold 2×20×1.0×0.35=14.
    expect(find.text('24 XP'), findsOneWidget);
    expect(find.text('14 ouro'), findsOneWidget);

    // Toggle repetível → reward vira 24×0.7=16.8→17; 14×0.7=9.8→10
    await tester.tap(find.byKey(const ValueKey('creation-repetivel')));
    await tester.pumpAndSettle();
    expect(find.text('17 XP'), findsOneWidget);
    expect(find.text('10 ouro'), findsOneWidget);
  });

  testWidgets('Submit feliz: chama service com params corretos',
      (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake: fake));
    await tester.pumpAndSettle();
    await _fillToReview(tester);
    // Step 4: clica Criar missão
    await tester.tap(find.byKey(const ValueKey('creation-next')));
    // Não faz pumpAndSettle aqui porque NpcDialogOverlay + go_router
    // disparam novos frames que não estabilizam trivialmente.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.calls, 1);
    expect(fake.lastParams!.name, 'Flexões');
    expect(fake.lastParams!.description, '20 reps');
    expect(fake.lastParams!.quantityTarget, 20);
    expect(fake.lastParams!.isRepetivel, isFalse);
  });

  testWidgets('Submit com limite atingido: SnackBar + mantém na tela',
      (tester) async {
    final fake = _FakeCreationService()..throwLimit = true;
    await tester.pumpWidget(_harness(fake: fake));
    await tester.pumpAndSettle();
    await _fillToReview(tester);
    await tester.tap(find.byKey(const ValueKey('creation-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.calls, 1);
    // SnackBar aparece
    expect(find.textContaining('Limite de 5 missões individuais ativas'),
        findsOneWidget);
    // Ainda na tela de criação (Step 4 review)
    expect(find.text('Revisa e confirma'), findsOneWidget);
  });
}
