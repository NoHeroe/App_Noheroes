import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/presentation/dev/dev_panel_screen.dart';

/// Sprint 3.3 hotfix dev panel — smoke test renderiza sem crash e
/// confirma que as 7 seções esperadas estão presentes (sem regressão
/// no corte de seções legacy).
void main() {
  Widget harness(AppEventBus bus) {
    final router = GoRouter(
      initialLocation: '/dev',
      routes: [
        GoRoute(path: '/dev', builder: (_, __) => const DevPanelScreen()),
        GoRoute(
            path: '/sanctuary',
            builder: (_, __) => const Scaffold(body: Text('sanctuary'))),
        GoRoute(
            path: '/class-selection',
            builder: (_, __) => const Scaffold(body: Text('class'))),
        GoRoute(
            path: '/faction-selection',
            builder: (_, __) => const Scaffold(body: Text('faction'))),
      ],
    );
    return ProviderScope(
      overrides: [
        // Player null = renderiza com placeholders, sem disparar mutations.
        currentPlayerProvider.overrideWith((_) => null),
        appEventBusProvider.overrideWithValue(bus),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('renderiza sem crash com player=null', (tester) async {
    final bus = AppEventBus();
    await tester.pumpWidget(harness(bus));
    await tester.pumpAndSettle();

    // AppBar.
    expect(find.text('DEV PANEL'), findsOneWidget);
    expect(find.text('APENAS DEV'), findsOneWidget);

    await bus.dispose();
  });

  testWidgets('7 seções visíveis após scroll completo', (tester) async {
    final bus = AppEventBus();
    await tester.pumpWidget(harness(bus));
    await tester.pumpAndSettle();

    // Seções devem aparecer enquanto rola — usar dragUntilVisible
    // garante chegar lá mesmo se a 1ª render só mostrou parte.
    final scrollable = find.byType(Scrollable).first;

    final expectedSections = [
      'STATUS',
      'AJUSTAR VALORES',
      'NAVEGAÇÃO',
      'MISSÕES DIÁRIAS',
      'CONQUISTAS',
      'REPUTAÇÃO FACÇÕES',
    ];
    for (final s in expectedSections) {
      await tester.dragUntilVisible(
        find.text(s),
        scrollable,
        const Offset(0, -50),
      );
      expect(find.text(s), findsOneWidget,
          reason: 'seção "$s" deveria estar visível');
    }

    // EVENTS prefix (com contador no label final).
    await tester.dragUntilVisible(
      find.textContaining('EVENTS'),
      scrollable,
      const Offset(0, -50),
    );
    expect(find.textContaining('EVENTS'), findsOneWidget);

    await bus.dispose();
  });

  testWidgets('seções legacy removidas NÃO aparecem', (tester) async {
    final bus = AppEventBus();
    await tester.pumpWidget(harness(bus));
    await tester.pumpAndSettle();

    // Sanity: nenhuma das seções cortadas deve estar presente.
    final removed = [
      'AÇÕES RÁPIDAS',
      'RANK + INVENTÁRIO',
      'QUESTS',
      'CALIBRAÇÃO',
      'CURRENCY',
      'RANK shortcuts',
      'INDIVIDUAIS',
    ];
    for (final s in removed) {
      expect(find.text(s), findsNothing,
          reason: 'seção legacy "$s" não deveria existir');
    }
    // Botão específico cortado (encantamento) não deve aparecer.
    expect(find.textContaining('Encantamento'), findsNothing);

    await bus.dispose();
  });

  testWidgets('botões críticos das seções mantidas estão presentes',
      (tester) async {
    final bus = AppEventBus();
    await tester.pumpWidget(harness(bus));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;

    final buttonsExpected = [
      'Resetar classe e facção',
      'Resetar missões diárias de hoje',
      'Pular pra amanhã (simular dia)',
      'Reset daily now (bypass 24h)',
      'Forçar complete 1ª missão ativa',
      'Forçar fail 1ª missão ativa',
      'Resetar TODAS as conquistas',
      'Listar conquistas atuais',
    ];

    for (final label in buttonsExpected) {
      await tester.dragUntilVisible(
        find.text(label),
        scrollable,
        const Offset(0, -50),
      );
      expect(find.text(label), findsOneWidget,
          reason: 'botão "$label" não encontrado');
    }

    await bus.dispose();
  });
}
