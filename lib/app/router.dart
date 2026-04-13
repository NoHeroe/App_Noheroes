import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/splash/screens/splash_screen.dart';
import '../presentation/auth/screens/login_screen.dart';
import '../presentation/auth/screens/register_screen.dart';
import '../presentation/onboarding/screens/awakening_screen.dart';
import '../presentation/sanctuary/screens/sanctuary_screen.dart';
import '../presentation/habits/screens/habits_screen.dart';
import '../presentation/character/screens/character_screen.dart';
import '../presentation/regions/screens/regions_screen.dart';
import '../presentation/shadow_chamber/screens/shadow_chamber_screen.dart';
import '../presentation/inventory/screens/inventory_screen.dart';
import '../presentation/shop/screens/shop_screen.dart';
import '../presentation/achievements/screens/achievements_screen.dart';
import '../presentation/class_selection/screens/class_selection_screen.dart';
import '../presentation/faction_selection/screens/faction_selection_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/',             builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login',        builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register',     builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/awakening',    builder: (c, s) => const AwakeningScreen()),
      GoRoute(path: '/sanctuary',    builder: (c, s) => const SanctuaryScreen()),
      GoRoute(path: '/habits',       builder: (c, s) => const HabitsScreen()),
      GoRoute(path: '/character',    builder: (c, s) => const CharacterScreen()),
      GoRoute(path: '/regions',      builder: (c, s) => const RegionsScreen()),
      GoRoute(path: '/shadow',       builder: (c, s) => const ShadowChamberScreen()),
      GoRoute(path: '/inventory',    builder: (c, s) => const InventoryScreen()),
      GoRoute(path: '/shop',         builder: (c, s) => const ShopScreen()),
      GoRoute(path: '/achievements',       builder: (c, s) => const AchievementsScreen()),
      GoRoute(path: '/class-selection',    builder: (c, s) => const ClassSelectionScreen()),
      GoRoute(path: '/faction-selection',  builder: (c, s) => const FactionSelectionScreen()),
    ],
  );
});
