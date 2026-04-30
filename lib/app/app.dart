import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

class NoHeroesApp extends ConsumerWidget {
  const NoHeroesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Sprint 3.3 Etapa 2.1a — bootstrap eager do stats service. O provider
    // registra listeners no AppEventBus em `start()`; sem este watch ele
    // só inicializaria quando algo o lesse explicitamente.
    ref.watch(dailyMissionStatsServiceProvider);
    // Sprint 3.3 Etapa 2.1b — bootstrap eager do achievements service.
    // Hoje só `/achievements` lia o provider, atrasando o registro do
    // listener de DailyStatsUpdated. Eager garante que conquistas
    // disparadas por daily missions unlockem desde o primeiro evento.
    ref.watch(achievementsServiceProvider);
    return MaterialApp.router(
      title: 'NoHeroes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
