import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.2 Etapa 1.3.A — header rico no topo de `/quests`.
///
/// "MISSÕES" CinzelDecorative + 🔥 streak (`dailyMissionsStreak`) +
/// barra geral de progresso das diárias do dia. Estática nessa
/// sub-etapa (1.3.B anima a barra).
class DailyQuestsHeader extends StatelessWidget {
  /// Sub-tarefas concluídas hoje (cross-missions).
  final int subTasksDone;

  /// Total de sub-tarefas hoje (3 missões × 3 = 9 quando geração rola).
  final int subTasksTotal;

  /// Streak de dias consecutivos com 3/3 missões 100%.
  final int streak;

  const DailyQuestsHeader({
    super.key,
    required this.subTasksDone,
    required this.subTasksTotal,
    required this.streak,
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
              _StreakBadge(streak: streak),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.purple),
                  ),
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
