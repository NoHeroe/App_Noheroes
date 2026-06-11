import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/guild/screens/guild_screen.dart';
import '../presentation/reputation/screens/reputation_screen.dart';
import '../presentation/library/screens/library_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/playstyle/playstyle_screen.dart';
import '../presentation/notifications/notifications_screen.dart';
import '../presentation/splash/screens/splash_screen.dart';
import '../presentation/auth/screens/login_screen.dart';
import '../presentation/auth/screens/register_screen.dart';
import '../presentation/onboarding/screens/awakening_screen.dart';
import '../presentation/sanctuary/screens/sanctuary_screen.dart';
// Sprint 3.1 Bloco 1 — telas legacy removidas (HabitsScreen, HistoryScreen,
// ShadowChamberScreen, AchievementsScreen). Placeholder `_UnderConstruction`
// cobre as rotas até os blocos de UI serem entregues (10, 12, 8).
import '../presentation/character/screens/character_screen.dart';
import '../presentation/regions/screens/regions_screen.dart';
import '../presentation/inventory/screens/inventory_screen.dart';
import '../presentation/shop/screens/shop_screen.dart';
import '../presentation/shop/screens/shops_list_screen.dart';
import '../presentation/class_selection/screens/class_selection_screen.dart';
import '../presentation/faction_selection/screens/faction_selection_screen.dart';
import '../presentation/faction/screens/faction_screen.dart';
import '../presentation/achievements/screens/achievements_screen.dart';
import '../presentation/history/screens/history_screen.dart';
import '../presentation/profile/screens/profile_screen.dart';
import '../presentation/quests/screens/quests_screen.dart';
import '../presentation/dev/dev_panel_screen.dart';
import '../presentation/battle/screens/battle_hub_screen.dart';
import '../presentation/card_game/screens/card_matchmaking_screen.dart';
import '../presentation/card_game/screens/card_match_screen.dart';
import '../presentation/card_game/screens/deck_builder_screen.dart';
import '../presentation/card_game/screens/packs_screen.dart';
import '../presentation/vitalism/screens/void_ritual_screen.dart';
import '../presentation/vitalism/screens/crystal_ceremony_screen.dart';
import '../presentation/vitalism/screens/vitalism_hub_screen.dart';
import '../presentation/vitalism/screens/vitalism_tree_screen.dart';
import '../presentation/vitalism/screens/life_tree_screen.dart';
import '../presentation/magic/screens/magic_hub_screen.dart';
import '../presentation/forge/screens/forge_screen.dart';
import '../presentation/enchant/screens/enchant_screen.dart';
import 'providers.dart';

/// Transição global de FADE (mesma sensação da Biblioteca) — substitui o
/// slide padrão do `MaterialPage`. Só muda COMO a página é construída; a
/// lógica de navegação (paths, params, redirects) fica intacta.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (ctx, anim, sec, child) {
      final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      // Opcional (CEO testar no flutter run): leve scale 0.98→1.0 junto do
      // fade pra dar mais "vida". Descomentar pra ativar:
      // return FadeTransition(
      //   opacity: fade,
      //   child: ScaleTransition(
      //     scale: Tween<double>(begin: 0.98, end: 1.0).animate(fade),
      //     child: child,
      //   ),
      // );
      return FadeTransition(opacity: fade, child: child);
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/',             pageBuilder: (c, s) => _fadePage(s, const SplashScreen())),
      GoRoute(path: '/login',        pageBuilder: (c, s) => _fadePage(s, const LoginScreen())),
      GoRoute(path: '/register',     pageBuilder: (c, s) => _fadePage(s, const RegisterScreen())),
      GoRoute(path: '/awakening',    pageBuilder: (c, s) => _fadePage(s, const AwakeningScreen())),
      GoRoute(path: '/sanctuary',    pageBuilder: (c, s) => _fadePage(s, const SanctuaryScreen())),
      // Sprint 3.1 Bloco 14.5 — rota legacy /habits removida (schema 25
      // resetou tudo; nenhum deep link conhecido dependia dela).
      // Sprint 3.1 Bloco 10a.1 — /quests virou tela real (6 abas + chips).
      GoRoute(path: '/quests',       pageBuilder: (c, s) => _fadePage(s, const QuestsScreen())),
      // Sprint 3.1 Bloco 14.6b — criação de missão individual virou
      // BottomSheet embutido no `/quests` aba Extras. Rota antiga
      // removida; arquivo legacy fica em .bak.pre_14_6b como referência.
      GoRoute(path: '/character',    pageBuilder: (c, s) => _fadePage(s, const CharacterScreen())),
      GoRoute(path: '/regions',      pageBuilder: (c, s) => _fadePage(s, const RegionsScreen())),
      // /shadow será refeita no Bloco 12 (migração de stats da Câmara pro Histórico).
      GoRoute(path: '/shadow',       pageBuilder: (c, s) => _fadePage(s, const _UnderConstruction(feature: 'Câmara das Sombras', block: 'Bloco 12'))),
      GoRoute(path: '/inventory',    pageBuilder: (c, s) => _fadePage(s, const InventoryScreen())),
      GoRoute(
        path: '/playstyle',
        pageBuilder: (context, state) => _fadePage(state, const PlaystyleScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _fadePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/library',
        pageBuilder: (context, state) => _fadePage(state, const LibraryScreen()),
      ),
      GoRoute(
        path: '/reputation',
        pageBuilder: (context, state) => _fadePage(state, const ReputationScreen()),
      ),
      GoRoute(
        path: '/guild',
        pageBuilder: (context, state) => _fadePage(state, const GuildScreen()),
      ),
      GoRoute(path: '/shops',        pageBuilder: (c, s) => _fadePage(s, const ShopsListScreen())),
      GoRoute(path: '/forge',        pageBuilder: (c, s) => _fadePage(s, const ForgeScreen())),
      GoRoute(path: '/enchant',      pageBuilder: (c, s) => _fadePage(s, const EnchantScreen())),
      GoRoute(
        path: '/shop/:shopKey',
        pageBuilder: (c, s) =>
            _fadePage(s, ShopScreen(shopKey: s.pathParameters['shopKey']!)),
      ),
      // /shop (sem key) redireciona pra listagem — não quebrar navegação legada.
      GoRoute(path: '/shop', redirect: (_, __) => '/shops'),
      // Sprint 3.1 Bloco 14.6b — tela restaurada (JSON-driven via
      // AchievementsService.catalog + PlayerAchievementsRepository).
      GoRoute(path: '/achievements',       pageBuilder: (c, s) => _fadePage(s, const AchievementsScreen())),
      GoRoute(path: '/class-selection',    pageBuilder: (c, s) => _fadePage(s, const ClassSelectionScreen())),
      GoRoute(path: '/faction-selection',  pageBuilder: (c, s) => _fadePage(s, const FactionSelectionScreen())),
      // Sprint 3.4 Etapa E — ficha da facção atual do player. `id` é o
      // faction_type; a tela mostra a ficha de membro (ou fallback se o
      // player não é membro daquela facção).
      GoRoute(
        path: '/faction/:id',
        pageBuilder: (c, s) =>
            _fadePage(s, FactionScreen(factionId: s.pathParameters['id']!)),
      ),
      GoRoute(path: '/dev',                pageBuilder: (c, s) => _fadePage(s, const DevPanelScreen())),
      GoRoute(path: '/battle',             pageBuilder: (c, s) => _fadePage(s, const BattleHubScreen())),
      // Modo Cartas (ACDA) — fluxo de entrada funcional.
      GoRoute(
        path: '/card-game/matchmaking',
        pageBuilder: (c, s) => _fadePage(
          s,
          CardMatchmakingScreen(mode: s.uri.queryParameters['mode'] ?? 'pve'),
        ),
      ),
      GoRoute(
        path: '/card-game/match',
        pageBuilder: (c, s) => _fadePage(
          s,
          CardMatchScreen(mode: s.uri.queryParameters['mode'] ?? 'pve'),
        ),
      ),
      // Construtor de Deck (ACDA) — monta o deck ativo (9 criaturas + 9 relíquias).
      GoRoute(
        path: '/card-game/deck-builder',
        pageBuilder: (c, s) => _fadePage(s, const DeckBuilderScreen()),
      ),
      // Pacotes (ACDA) — obtenção de cartas (comprar/abrir/revelar).
      GoRoute(
        path: '/card-game/packs',
        pageBuilder: (c, s) => _fadePage(s, const PacksScreen()),
      ),
      // Sprint 3.1 Bloco 14.6c — /history vira rota dedicada (saiu
      // da aba chip de /quests no redesign).
      GoRoute(path: '/history',            pageBuilder: (c, s) => _fadePage(s, const HistoryScreen())),
      // Sprint 3.2 Etapa 1.0 — /perfil (identidade + dados físicos +
      // recomendações diárias). Acessível pelo SanctuaryDrawer.
      GoRoute(path: '/perfil',             pageBuilder: (c, s) => _fadePage(s, const ProfileScreen())),
      GoRoute(path: '/settings',           pageBuilder: (c, s) => _fadePage(s, const SettingsScreen())),
      GoRoute(
        path: '/vitalism/void-ritual',
        pageBuilder: (c, s) => _fadePage(s, const VoidRitualScreen()),
        redirect: (context, state) {
          final player = ref.read(currentPlayerProvider);
          if (player == null) return '/login';
          if (player.level < 25) return '/sanctuary';
          if (!player.isVitalist) return '/sanctuary';
          return null;
        },
      ),
      GoRoute(
        path: '/vitalism/crystal-ceremony',
        pageBuilder: (c, s) => _fadePage(s, const CrystalCeremonyScreen()),
        redirect: (context, state) {
          final player = ref.read(currentPlayerProvider);
          if (player == null) return '/login';
          if (player.level < 25) return '/sanctuary';
          if (!player.isVitalist) return '/sanctuary';
          // Guard "já tem afinidade" é async e fica na tela (_boot).
          return null;
        },
      ),
      GoRoute(
        path: '/vitalism',
        pageBuilder: (c, s) => _fadePage(s, const VitalismHubScreen()),
        redirect: (context, state) {
          final player = ref.read(currentPlayerProvider);
          if (player == null) return '/login';
          if (player.level < 25) return '/sanctuary';
          if (!player.isVitalist) return '/sanctuary';
          return null;
        },
      ),
      GoRoute(
        path: '/magic',
        pageBuilder: (c, s) => _fadePage(s, const MagicHubScreen()),
        redirect: (context, state) {
          final player = ref.read(currentPlayerProvider);
          if (player == null) return '/login';
          if (player.level < 25) return '/sanctuary';
          if (player.isVitalist) return '/sanctuary';
          return null;
        },
      ),
      GoRoute(
        path: '/vitalism/tree/:vitalismId',
        pageBuilder: (c, s) => _fadePage(
          s,
          VitalismTreeScreen(vitalismId: s.pathParameters['vitalismId']!),
        ),
        redirect: (context, state) {
          final player = ref.read(currentPlayerProvider);
          if (player == null) return '/login';
          if (player.level < 25) return '/sanctuary';
          if (!player.isVitalist) return '/sanctuary';
          // Catálogo + posse são validados dentro da tela (async).
          return null;
        },
      ),
      GoRoute(
        path: '/vitalism/life-tree',
        pageBuilder: (c, s) => _fadePage(s, const LifeTreeScreen()),
        redirect: (context, state) {
          final player = ref.read(currentPlayerProvider);
          if (player == null) return '/login';
          if (player.level < 25) return '/sanctuary';
          if (!player.isVitalist) return '/sanctuary';
          // Checagem isVitalistaDaVida fica na tela (async).
          return null;
        },
      ),
    ],
  );

  // Sprint 3.3 Etapa 2.1c-γ — listener de navegação pra
  // PlayerScreensVisitedService.
  //
  // NavigatorObserver não funciona porque GoRoute não define `name` nas
  // rotas do projeto → `route.settings.name` fica null. Usamos
  // `routerDelegate.addListener` que reage a mudanças em
  // `currentConfiguration.uri.path` (resolvido com path params).
  //
  // Cleanup explícito via `removeListener(callback)` no `ref.onDispose`
  // — sem isso, hot reload acumula listeners e gera leak.
  void onRouteChange() {
    try {
      final player = ref.read(currentPlayerProvider);
      if (player == null) return;
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if (path.isEmpty) return;
      final service = ref.read(playerScreensVisitedServiceProvider);
      // Fire-and-forget — listener não pode ser async. Erros internos
      // ficam logados pelo service.
      service.recordVisit(player.id, path);
    } catch (e) {
      // ignore: avoid_print
      print('[router-listener] recordVisit falhou: $e');
    }
  }

  router.routerDelegate.addListener(onRouteChange);
  ref.onDispose(() {
    router.routerDelegate.removeListener(onRouteChange);
  });

  return router;
});

/// Placeholder temporário pra rotas cujas telas foram dropadas no reset brutal
/// da Sprint 3.1 Bloco 1 e serão reentregues em blocos posteriores. Indica ao
/// jogador/QA qual bloco devolve a feature — serve como indicador visual
/// durante o ciclo da sprint.
class _UnderConstruction extends StatelessWidget {
  final String feature;
  final String block;
  const _UnderConstruction({required this.feature, required this.block});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(feature)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_circle_outlined, size: 64),
              const SizedBox(height: 16),
              Text(feature,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Em reforma na Sprint 3.1 — volta no $block.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go('/sanctuary'),
                child: const Text('Voltar ao Santuário'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
