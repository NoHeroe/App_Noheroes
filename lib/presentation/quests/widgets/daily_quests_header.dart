import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'animated_progress_bar.dart';

/// Sprint 3.2 Etapa 1.3.A — header rico no topo de `/quests`.
///
/// "MISSÕES" CinzelDecorative + counter Gold/XP (target do popup de
/// completion via [counterKey]) + 🔥 streak + barra geral animada.
/// Etapa 1.3.B trocou LinearProgressIndicator por [AnimatedProgressBar].
/// Etapa 1.3.C adicionou o counter como destino das partículas voadoras.
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

  /// Key do counter — passada pelo parent pra ser usada como destino do
  /// `MissionCompletionPopup` (partículas voam até essa coordenada e o
  /// counter pulsa quando chegam).
  final GlobalKey<HeaderCounterState>? counterKey;

  const DailyQuestsHeader({
    super.key,
    required this.subTasksDone,
    required this.subTasksTotal,
    required this.streak,
    required this.gold,
    required this.xp,
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
              HeaderCounter(
                key: counterKey,
                gold: gold,
                xp: xp,
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

/// Counter Gold + XP no header. Tem método público [pulse] disparado pelo
/// `MissionCompletionPopup` quando as partículas chegam.
class HeaderCounter extends StatefulWidget {
  final int gold;
  final int xp;

  const HeaderCounter({
    super.key,
    required this.gold,
    required this.xp,
  });

  @override
  State<HeaderCounter> createState() => HeaderCounterState();
}

class HeaderCounterState extends State<HeaderCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtl;

  @override
  void initState() {
    super.initState();
    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _pulseCtl.dispose();
    super.dispose();
  }

  /// Aciona pulse de scale 1.0 → 1.15 → 1.0 (200ms total). Chamado pelo
  /// popup quando as partículas chegam.
  void pulse() {
    if (!mounted) return;
    _pulseCtl.forward(from: 0).then((_) {
      if (mounted) _pulseCtl.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtl,
      builder: (_, child) {
        final scale = 1.0 + (_pulseCtl.value * 0.15);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on,
                size: 12, color: AppColors.gold),
            const SizedBox(width: 3),
            Text(
              '${widget.gold}',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.auto_awesome,
                size: 12, color: AppColors.purple),
            const SizedBox(width: 3),
            Text(
              '${widget.xp}',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: AppColors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
