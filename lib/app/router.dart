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
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/',             builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login',        builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register',     builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/awakening',    builder: (c, s) => const AwakeningScreen()),
      GoRoute(path: '/sanctuary',    builder: (c, s) => const SanctuaryScreen()),
      // /habits mantém placeholder (rota legada) até usuários antigos pararem
      // de usá-la; telas reais viverão em /quests.
      GoRoute(path: '/habits',       builder: (c, s) => const _UnderConstruction(feature: 'Missões (/quests)', block: 'Bloco 10')),
      // Sprint 3.1 Bloco 10a.1 — /quests virou tela real (6 abas + chips).
      GoRoute(path: '/quests',       builder: (c, s) => const QuestsScreen()),
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
      // /achievements será refeita no Bloco 8 (conquistas JSON-driven com items).
      GoRoute(path: '/achievements',       builder: (c, s) => const _UnderConstruction(feature: 'Conquistas', block: 'Bloco 8')),
      GoRoute(path: '/class-selection',    builder: (c, s) => const ClassSelectionScreen()),
      GoRoute(path: '/faction-selection',  builder: (c, s) => const FactionSelectionScreen()),
      // Sprint 3.1 Bloco 9 — Quiz de calibração.
      GoRoute(
        path: '/mission_calibration',
        builder: (c, s) => const MissionCalibrationScreen(),
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
      // /history será refeita no Bloco 12.
      GoRoute(path: '/history',            builder: (c, s) => const _UnderConstruction(feature: 'Histórico', block: 'Bloco 12')),
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
