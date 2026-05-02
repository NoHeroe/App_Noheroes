import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/models/achievement_definition.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/presentation/achievements/utils/achievement_progress.dart';
import 'package:noheroes_app/presentation/achievements/utils/reward_display_helper.dart';
import 'package:noheroes_app/presentation/achievements/widgets/achievement_card.dart';
import 'package:noheroes_app/presentation/achievements/widgets/golden_border.dart';
import 'package:noheroes_app/presentation/achievements/widgets/rainbow_border.dart';

AchievementDefinition _def({
  String key = 'K',
  bool secret = false,
  bool disabled = false,
  RewardDeclared? reward = const RewardDeclared(xp: 60, gold: 75, gems: 1),
}) =>
    AchievementDefinition(
      key: key,
      name: 'Brasa Acesa',
      description: 'descrição',
      category: 'streak',
      trigger: const MetaTrigger(targetCount: 1),
      reward: reward,
      isSecret: secret,
      disabled: disabled,
    );

Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  testWidgets('Estado A (locked) — mostra título, categoria, recompensa cinza, '
      'sem botão claim', (tester) async {
    final def = _def();
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.locked,
        progress: const AchievementProgress(current: 2, target: 5),
        reward: RewardDisplay.fromDeclared(def.reward!),
      ),
    ));
    expect(find.text('Brasa Acesa'), findsOneWidget);
    expect(find.textContaining('streak'), findsOneWidget);
    expect(find.text('+24 XP'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('RECEBER RECOMPENSA'), findsNothing);
  });

  testWidgets('Estado A — sem progress, oculta barra (binário)',
      (tester) async {
    final def = _def();
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.locked,
        progress: null,
        reward: RewardDisplay.fromDeclared(def.reward!),
      ),
    ));
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('Estado B (pending) — mostra badge NOVO + botão RECEBER',
      (tester) async {
    final def = _def();
    var clicked = false;
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.pending,
        reward: RewardDisplay.fromDeclared(def.reward!),
        onClaim: () async {
          clicked = true;
        },
      ),
    ));
    expect(find.text('NOVO'), findsOneWidget);
    expect(find.text('RECEBER RECOMPENSA'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('achievement-claim-K')));
    await tester.pump();
    expect(clicked, isTrue);
  });

  testWidgets('Estado C (claimed) — badge ✓ COLETADA + opacidade reduzida',
      (tester) async {
    final def = _def();
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.claimed,
        reward: RewardDisplay.fromDeclared(def.reward!),
      ),
    ));
    expect(find.text('✓ COLETADA'), findsOneWidget);
    expect(find.text('RECEBER RECOMPENSA'), findsNothing);

    final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, lessThan(1.0));
  });

  testWidgets('Estado E (secret unlocked) — RainbowBorder presente',
      (tester) async {
    final def = _def(secret: true);
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.secretUnlocked,
        reward: RewardDisplay.fromDeclared(def.reward!),
        onClaim: () async {},
      ),
    ));
    expect(find.byType(RainbowBorder), findsOneWidget);
  });

  testWidgets(
      'Lendária topo10 desbloqueada — GoldenBorder presente (não-secret)',
      (tester) async {
    final def = _def(key: 'VOL_MITO_DISCIPLINA');
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.pending,
        reward: RewardDisplay.fromDeclared(def.reward!),
        onClaim: () async {},
      ),
    ));
    expect(find.byType(GoldenBorder), findsOneWidget);
    expect(find.byType(RainbowBorder), findsNothing);
  });

  testWidgets('Lendária topo10 BLOQUEADA — sem GoldenBorder ainda',
      (tester) async {
    final def = _def(key: 'VOL_MITO_DISCIPLINA');
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.locked,
        progress: const AchievementProgress(current: 100, target: 5000),
        reward: RewardDisplay.fromDeclared(def.reward!),
      ),
    ));
    expect(find.byType(GoldenBorder), findsNothing);
  });

  testWidgets('Disabled (shell) achievement — badge EM BREVE',
      (tester) async {
    final def = _def(disabled: true);
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.locked,
        reward: RewardDisplay.fromDeclared(def.reward!),
      ),
    ));
    expect(find.text('EM BREVE'), findsOneWidget);
  });

  testWidgets('Tap em card expande description', (tester) async {
    final def = _def();
    await tester.pumpWidget(_harness(
      AchievementCard(
        def: def,
        state: AchievementCardState.locked,
        reward: RewardDisplay.fromDeclared(def.reward!),
      ),
    ));
    expect(find.text('descrição'), findsNothing);
    await tester.tap(find.text('Brasa Acesa'));
    await tester.pump();
    expect(find.text('descrição'), findsOneWidget);
  });
}
