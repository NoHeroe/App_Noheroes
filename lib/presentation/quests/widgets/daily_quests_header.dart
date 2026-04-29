import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/player_stats_counter.dart';
import 'animated_progress_bar.dart';

/// Sprint 3.2 Etapa 1.3.A — header rico no topo de `/quests`.
///
/// "MISSÕES" CinzelDecorative + counter Gold/XP/Gems (target do popup de
/// completion via [counterKey]) + 🔥 streak + barra geral animada.
/// Etapa 1.3.B trocou LinearProgressIndicator por [AnimatedProgressBar].
/// Etapa 1.3.C adicionou o counter como destino das partículas voadoras.
/// Sprint 3.3 Etapa 2.4 promoveu `HeaderCounter` pra
/// [PlayerStatsCounter] compartilhado e adicionou Gems ao display.
class DailyQuestsHeader extends StatelessWidget {
  /// Sub-tarefas concluídas hoje (cross-missions).
  final int subTasksDone;

  /// Total de sub-tarefas hoje (3 missões × 3 = 9 quando geração rola).
  final int subTasksTotal;

  /// Streak de dias consecutivos com 3/3 missões 100%.
  final int streak;

  /// Gold atual do jogador.
  final int gold;

  /// XP atual do jogador.
  final int xp;

  /// Gems atual do jogador.
  final int gems;

  /// Key do counter — passada pelo parent pra ser usada como destino do
  /// `MissionCompletionPopup` (partículas voam até essa coordenada e o
  /// counter pulsa quando chegam).
  final GlobalKey<PlayerStatsCounterState>? counterKey;

  const DailyQuestsHeader({
    super.key,
    required this.subTasksDone,
    required this.subTasksTotal,
    required this.streak,
    required this.gold,
    required this.xp,
    required this.gems,
    this.counterKey,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        subTasksTotal == 0 ? 0.0 : (subTasksDone / subTasksTotal);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'MISSÕES',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 22,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              PlayerStatsCounter(
                key: counterKey,
                gold: gold,
                xp: xp,
                gems: gems,
              ),
              const SizedBox(width: 8),
              _StreakBadge(streak: streak),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AnimatedProgressBar(
                  value: progress,
                  color: AppColors.purple,
                  height: 5,
                  showParticles: false,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$subTasksDone/$subTasksTotal',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.shadowObsessive.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.shadowObsessive.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$streak ${streak == 1 ? 'dia' : 'dias'}',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.shadowObsessive,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
