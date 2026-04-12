import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/onboarding/screens/awakening_screen.dart';
import '../presentation/sanctuary/screens/sanctuary_screen.dart';
import '../presentation/habits/screens/habits_screen.dart';
import '../presentation/character/screens/character_screen.dart';
import '../presentation/shadow_chamber/screens/shadow_chamber_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AwakeningScreen(),
      ),
      GoRoute(
        path: '/sanctuary',
        builder: (context, state) => const SanctuaryScreen(),
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        path: '/character',
        builder: (context, state) => const CharacterScreen(),
      ),
      GoRoute(
        path: '/shadow',
        builder: (context, state) => const ShadowChamberScreen(),
      ),
    ],
  );
});
