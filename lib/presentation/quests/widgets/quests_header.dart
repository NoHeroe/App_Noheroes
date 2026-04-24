import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.1 Bloco 14.6c — header fixo da `/quests` (port v0.28.2
/// `habits_screen.dart` linhas 63-132).
///
/// Renderiza:
///   - Título "MISSÕES" em CinzelDecorative dourado letterSpacing 2
///   - Badge de streak 🔥 (só se `streak > 0`)
///   - Contador `done/total` em roboto muted
///   - Progress bar horizontal roxa 4px altura (value = done/total)
///
/// `done` e `total` agregam TODAS as seções (rituais + classe + facção
/// + admissão + individuais + extras-mission se houver). Fórmula:
///   - `total` = `ativas + completadas` do período corrente
///   - `done` = subset com `completedAt != null`
class QuestsHeader extends StatelessWidget {
  final int done;
  final int total;
  final int streak;

  const QuestsHeader({
    super.key,
    required this.done,
    required this.total,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MISSÕES',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
              Row(
                children: [
                  if (streak > 0) ...[
                    _StreakBadge(streak: streak),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '$done/$total',
                    key: const ValueKey('quests-header-counter'),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.purple),
              minHeight: 4,
            ),
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
      key: const ValueKey('quests-header-streak'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$streak dias',
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
