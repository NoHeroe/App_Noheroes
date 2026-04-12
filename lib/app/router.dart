import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routing/app_routes.dart';
import '../presentation/onboarding/screens/awakening_screen.dart';
import '../presentation/sanctuary/screens/sanctuary_screen.dart';
import '../presentation/habits/screens/habits_screen.dart';
import '../presentation/character/screens/character_screen.dart';
import '../presentation/shadow_chamber/screens/shadow_chamber_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
      initialLocation: AppRoutes.awakening,
          routes: [
                GoRoute(
                        path: AppRoutes.awakening,
                                builder: (context, state) => const AwakeningScreen(),
                                      ),
                                            GoRoute(
                                                    path: AppRoutes.sanctuary,
                                                            builder: (context, state) => const SanctuaryScreen(),
                                                                  ),
                                                                        GoRoute(
                                                                                path: AppRoutes.habits,
                                                                                        builder: (context, state) => const HabitsScreen(),
                                                                                              ),
                                                                                                    GoRoute(
                                                                                                            path: AppRoutes.character,
                                                                                                                    builder: (context, state) => const CharacterScreen(),
                                                                                                                          ),
                                                                                                                                GoRoute(
                                                                                                                                        path: AppRoutes.shadowChamber,
                                                                                                                                                builder: (context, state) => const ShadowChamberScreen(),
                                                                                                                                                      ),
                                                                                                                                                          ],
                                                                                                                                                            );
                                                                                                                                                            });