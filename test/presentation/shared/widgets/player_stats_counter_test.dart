import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/presentation/shared/widgets/player_stats_counter.dart';

/// Sprint 3.3 Etapa 2.4 — widget test do counter compartilhado
/// Gold + XP + Gems. Cobre renderização das 3 chips com valores e ícones
/// corretos. `pulse()` em si só dispara animação interna; a integração
/// com `MissionCompletionPopup` segue coberta pelos testes de /quests.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('PlayerStatsCounter renderiza gold/xp/gems com 3 ícones',
      (tester) async {
    await tester.pumpWidget(
      wrap(const PlayerStatsCounter(gold: 1234, xp: 567, gems: 42)),
    );

    expect(find.text('1234'), findsOneWidget);
    expect(find.text('567'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);

    expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(find.byIcon(Icons.diamond_outlined), findsOneWidget);
  });

  testWidgets('PlayerStatsCounterState.pulse() não lança quando montado',
      (tester) async {
    final key = GlobalKey<PlayerStatsCounterState>();
    await tester.pumpWidget(
      wrap(PlayerStatsCounter(key: key, gold: 0, xp: 0, gems: 0)),
    );

    expect(() => key.currentState!.pulse(), returnsNormally);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
