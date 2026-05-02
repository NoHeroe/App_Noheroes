import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/presentation/achievements/screens/achievements_screen.dart';

/// Sprint 3.3 Etapa Final-B — tela `/achievements` foi reescrita com 5
/// estados de card + filtros + stats header + coleta manual. Os
/// comportamentos específicos de renderização ficam cobertos pelos
/// tests dos widgets (`achievement_card_test`, `achievement_toast_*`,
/// helpers em `utils/`). Este arquivo cobre apenas o caminho degradado
/// (sem player) que renderiza empty state — testar a tela completa
/// requer DB Drift in-memory + DAOs reais; out-of-scope desta sub-etapa.
void main() {
  testWidgets(
      'currentPlayer=null → empty state com mensagem de catálogo vazio',
      (tester) async {
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPlayerProvider.overrideWith((_) => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Sem player → catálogo vazio carregado → empty state.
    expect(find.byKey(const ValueKey('achievements-empty')), findsOneWidget);
    expect(find.text('Nenhuma conquista no catálogo.'), findsOneWidget);
    // Header CONQUISTAS visível mesmo no degradado.
    expect(find.text('CONQUISTAS'), findsOneWidget);
  });
}
