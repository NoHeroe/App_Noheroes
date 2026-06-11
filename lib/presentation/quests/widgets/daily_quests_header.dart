import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../sanctuary/widgets/sanctuary_header_widgets.dart';
import 'animated_progress_bar.dart';

/// Header de `/quests` — padronizado com o Santuário: mini-perfil (avatar +
/// nome + barra de XP) à esquerda + carteira (ouro/gemas) à direita, depois o
/// streak redesenhado + a barra de progresso geral das diárias.
///
/// Sprint 3.2 Etapa 1.3.A criou o header rico; aqui (sweep de UI 2026-06-11)
/// trocamos o `PlayerStatsCounter` pelo padrão `SanctuaryMiniProfile` +
/// `SanctuaryWalletPills`. O alvo de partículas do `MissionCompletionPopup`
/// (antigo `counterKey`) degrada graciosamente (popup ainda aparece).
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
          // Mini-perfil (avatar + nome + XP) + carteira — padrão Santuário.
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: SanctuaryMiniProfile()),
              SizedBox(width: 10),
              SanctuaryWalletPills(),
            ],
          ),
          const SizedBox(height: 12),
          // Streak + progresso geral das diárias.
          Row(
            children: [
              _StreakBadge(streak: streak),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedProgressBar(
                  value: progress,
                  color: AppColors.gold,
                  height: 6,
                  showParticles: false,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$subTasksDone/$subTasksTotal',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: AppColors.txtMut),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Streak redesenhado — pílula escura coerente com o app + chama âmbar e
/// número em dourado (no lugar do emoji 🔥 + pílula laranja antiga).
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF221A2E), Color(0xFF0B0910)],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        boxShadow: streak > 0
            ? [
                BoxShadow(
                    color: const Color(0xFFFF8A3D).withValues(alpha: 0.18),
                    blurRadius: 8),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              size: 15,
              color: streak > 0
                  ? const Color(0xFFFF8A3D)
                  : AppColors.txtMut),
          const SizedBox(width: 5),
          Text('$streak',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldLt)),
          const SizedBox(width: 3),
          Text(streak == 1 ? 'dia' : 'dias',
              style: GoogleFonts.roboto(
                  fontSize: 9, color: AppColors.txtMut, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
