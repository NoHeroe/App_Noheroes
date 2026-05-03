import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../presentation/achievements/widgets/achievement_toast_listener.dart';
import 'app_listeners.dart';
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
    // Sprint 3.3 Etapa 2.1c-α — agregador de moedas gastas. Single
    // writer de players.total_gems_spent. Sem este watch, GemsSpent
    // não atualizaria o contador até alguém ler o provider.
    ref.watch(playerCurrencyStatsServiceProvider);
    // Sprint 3.4 Etapa A hotfix — listener global de LevelUp que
    // sincroniza `currentPlayerProvider` (StateProvider manual) com o
    // DB sempre que `addXp` causa level up. Sem este watch, paths que
    // não atualizam o provider explicitamente (RewardGrantService,
    // applyAutoCompleted no rollover, etc.) deixavam UI stale —
    // visual mostrava XP resetando mas level antigo persistente.
    // Pattern espelha AchievementToastListener (Sprint 3.3 Final-B).
    ref.watch(playerStateSyncServiceProvider);
    return MaterialApp.router(
      title: 'NoHeroes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      // Sprint 3.3 Etapa Final-B — wrapper global que escuta
      // AchievementUnlocked no bus e exibe toast em qualquer rota.
      // Mount via builder mantém listener vivo enquanto app vivo.
      builder: (context, child) =>
          AchievementToastListener(child: child ?? const SizedBox()),
    );
  }
}
