import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/services/individual_creation_service.dart';
import 'package:noheroes_app/presentation/individual_creation/widgets/create_individual_mission_sheet.dart';

/// Fake creation service — registra chamadas e permite simular limite.
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

PlayersTableData _player() {
  return PlayersTableData(
    id: 1,
    email: 't@t',
    passwordHash: 'h',
    shadowName: 'S',
    level: 10,
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
  );
}

Widget _harness(_FakeCreationService fake) {
  return ProviderScope(
    overrides: [
      individualCreationServiceProvider.overrideWithValue(fake),
      currentPlayerProvider.overrideWith((_) => _player()),
    ],
    child: const MaterialApp(
      home: Scaffold(body: CreateIndividualMissionSheet()),
    ),
  );
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Submit desabilitado sem nome e sem requirements; habilita com ambos',
      (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();

    // 1º frame: botão Submit desabilitado (sem nome, sem requirements).
    var btn = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('sheet-submit')));
    expect(btn.onPressed, isNull);

    // Nome sozinho ainda não habilita (requirements vazios).
    await tester.enterText(
        find.byKey(const ValueKey('sheet-name')), 'Forja');
    await tester.pumpAndSettle();
    btn = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('sheet-submit')));
    expect(btn.onPressed, isNull);

    // Adiciona 1 template físico (Flexões) → habilita.
    await _tapKey(tester, const ValueKey('sheet-tpl-Flexões'));
    btn = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('sheet-submit')));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets(
      'Trocar categoria limpa requirements e auto-description',
      (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('sheet-name')), 'Forja');
    await tester.pumpAndSettle();

    // Adiciona template de físico.
    await _tapKey(tester, const ValueKey('sheet-tpl-Flexões'));
    expect(find.text('ADICIONADOS'), findsOneWidget);

    // Troca pra mental → requirements somem.
    await _tapKey(tester, const ValueKey('sheet-cat-mental'));
    expect(find.text('ADICIONADOS'), findsNothing);
  });

  testWidgets(
      'Reward preview aparece após adicionar requirement e muda com repetível',
      (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('sheet-name')), 'Forja');
    await tester.pumpAndSettle();
    await _tapKey(tester, const ValueKey('sheet-tpl-Flexões'));

    // Médio × 30 × físico(1.0) × soulslike xp(0.4) = 24 XP.
    expect(find.text('24 XP'), findsOneWidget);
    expect(find.text('14 ouro'), findsOneWidget);

    // Toggle repetível aplica penalty 0.7 → XP 17, ouro 10.
    await _tapKey(tester, const ValueKey('sheet-repetivel'));
    expect(find.text('17 XP'), findsOneWidget);
    expect(find.text('10 ouro'), findsOneWidget);
  });

  testWidgets('Submit feliz: chama service com requirements + params',
      (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('sheet-name')), 'Forja Matinal');
    await tester.pumpAndSettle();
    await _tapKey(tester, const ValueKey('sheet-tpl-Flexões'));
    await _tapKey(tester, const ValueKey('sheet-tpl-Agachamentos'));

    // Submit fica abaixo do viewport após 2 templates + toggle + reward
    // preview: scrolla antes de tapar.
    final submit = find.byKey(const ValueKey('sheet-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    // NpcDialogOverlay + Navigator.pop disparam frames — não esperamos
    // settle trivial.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.calls, 1);
    expect(fake.lastParams!.name, 'Forja Matinal');
    expect(fake.lastParams!.requirements, hasLength(2));
    expect(fake.lastParams!.requirements.map((r) => r.label),
        containsAll(['Flexões', 'Agachamentos']));
    expect(fake.lastParams!.isRepetivel, isFalse);
  });

  testWidgets('Limite exceeded: SnackBar + mantém sheet aberta',
      (tester) async {
    final fake = _FakeCreationService()..throwLimit = true;
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('sheet-name')), 'Forja');
    await tester.pumpAndSettle();
    await _tapKey(tester, const ValueKey('sheet-tpl-Flexões'));

    final submit = find.byKey(const ValueKey('sheet-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.calls, 1);
    expect(find.textContaining('Limite de 5 missões individuais ativas'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-submit')), findsOneWidget);
  });

  testWidgets('Remover requirement via botão X limpa da lista',
      (tester) async {
    final fake = _FakeCreationService();
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('sheet-name')), 'Forja');
    await tester.pumpAndSettle();
    await _tapKey(tester, const ValueKey('sheet-tpl-Flexões'));
    expect(find.text('ADICIONADOS'), findsOneWidget);

    await _tapKey(tester, const ValueKey('sheet-req-remove-0'));
    expect(find.text('ADICIONADOS'), findsNothing);
    // Submit volta a ficar desabilitado (sem requirements).
    final btn = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('sheet-submit')));
    expect(btn.onPressed, isNull);
  });
}

