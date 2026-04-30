import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/guild/screens/guild_screen.dart';
import '../presentation/reputation/screens/reputation_screen.dart';
import '../presentation/library/screens/library_screen.dart';
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
import '../presentation/achievements/screens/achievements_screen.dart';
import '../presentation/history/screens/history_screen.dart';
import '../presentation/profile/screens/profile_screen.dart';
import '../presentation/mission_calibration/screens/mission_calibration_screen.dart';
import '../presentation/quests/screens/quests_screen.dart';
import '../presentation/dev/dev_panel_screen.dart';
import '../presentation/battle/screens/battle_hub_screen.dart';
import '../presentation/vitalism/screens/void_ritual_screen.dart';
import '../presentation/vitalism/screens/crystal_ceremony_screen.dart';
import '../presentation/vitalism/screens/vitalism_hub_screen.dart';
import '../presentation/vitalism/screens/vitalism_tree_screen.dart';
import '../presentation/vitalism/screens/life_tree_screen.dart';
import '../presentation/magic/screens/magic_hub_screen.dart';
import '../presentation/forge/screens/forge_screen.dart';
import '../presentation/enchant/screens/enchant_screen.dart';
import '../data/database/tables/players_table_ext.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/',             builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login',        builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register',     builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/awakening',    builder: (c, s) => const AwakeningScreen()),
      GoRoute(path: '/sanctuary',    builder: (c, s) => const SanctuaryScreen()),
      // Sprint 3.1 Bloco 14.5 — rota legacy /habits removida (schema 25
      // resetou tudo; nenhum deep link conhecido dependia dela).
      // Sprint 3.1 Bloco 10a.1 — /quests virou tela real (6 abas + chips).
      GoRoute(path: '/quests',       builder: (c, s) => const QuestsScreen()),
      // Sprint 3.1 Bloco 14.6b — criação de missão individual virou
      // BottomSheet embutido no `/quests` aba Extras. Rota antiga
      // removida; arquivo legacy fica em .bak.pre_14_6b como referência.
      GoRoute(path: '/character',    builder: (c, s) => const CharacterScreen()),
      GoRoute(path: '/regions',      builder: (c, s) => const RegionsScreen()),
      // /shadow será refeita no Bloco 12 (migração de stats da Câmara pro Histórico).
      GoRoute(path: '/shadow',       builder: (c, s) => const _UnderConstruction(feature: 'Câmara das Sombras', block: 'Bloco 12')),
      GoRoute(path: '/inventory',    builder: (c, s) => const InventoryScreen()),
      GoRoute(
        path: '/playstyle',
        builder: (context, state) => const PlaystyleScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/reputation',
        builder: (context, state) => const ReputationScreen(),
      ),
      GoRoute(
        path: '/guild',
        builder: (context, state) => const GuildScreen(),
      ),
      GoRoute(path: '/shops',        builder: (c, s) => const ShopsListScreen()),
      GoRoute(path: '/forge',        builder: (c, s) => const ForgeScreen()),
      GoRoute(path: '/enchant',      builder: (c, s) => const EnchantScreen()),
      GoRoute(
        path: '/shop/:shopKey',
        builder: (c, s) => ShopScreen(shopKey: s.pathParameters['shopKey']!),
      ),
      // /shop (sem key) redireciona pra listagem — não quebrar navegação legada.
      GoRoute(path: '/shop', redirect: (_, __) => '/shops'),
      // Sprint 3.1 Bloco 14.6b — tela restaurada (JSON-driven via
      // AchievementsService.catalog + PlayerAchievementsRepository).
      GoRoute(path: '/achievements',       builder: (c, s) => const AchievementsScreen()),
      GoRoute(path: '/class-selection',    builder: (c, s) => const ClassSelectionScreen()),
      GoRoute(path: '/faction-selection',  builder: (c, s) => const FactionSelectionScreen()),
      // Sprint 3.1 Bloco 9 — Quiz de calibração inicial.
      // Sprint 3.1 Bloco 10b — também aceita `?recalibrate=true` (modo
      // refazer, acessado via SanctuaryDrawer item Refazer Calibração).
      GoRoute(
        path: '/mission_calibration',
        builder: (c, s) => MissionCalibrationScreen(
          isRecalibrate:
              s.uri.queryParameters['recalibrate'] == 'true',
        ),
        redirect: (context, state) {
          final player = ref.read(currentPlayerProvider);
          if (player == null) return '/login';
          if (player.level < 5) return '/sanctuary';
          final cls = player.classType;
          if (cls == null || cls.isEmpty) return '/class-selection';
          return null;
        },
      ),
      GoRoute(path: '/dev',                builder: (c, s) => const DevPanelScreen()),
      GoRoute(path: '/battle',             builder: (c, s) => const BattleHubScreen()),
      // Sprint 3.1 Bloco 14.6c — /history vira rota dedicada (saiu
      // da aba chip de /quests no redesign).
      GoRoute(path: '/history',            builder: (c, s) => const HistoryScreen()),
      // Sprint 3.2 Etapa 1.0 — /perfil (identidade + dados físicos +
      // recomendações diárias). Acessível pelo SanctuaryDrawer.
      GoRoute(path: '/perfil',             builder: (c, s) => const ProfileScreen()),
      GoRoute(
        path: '/vitalism/void-ritual',
        builder: (c, s) => const VoidRitualScreen(),
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
        builder: (c, s) => const CrystalCeremonyScreen(),
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
        builder: (c, s) => const VitalismHubScreen(),
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
        builder: (c, s) => const MagicHubScreen(),
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
        builder: (c, s) => VitalismTreeScreen(
          vitalismId: s.pathParameters['vitalismId']!,
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
        builder: (c, s) => const LifeTreeScreen(),
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
