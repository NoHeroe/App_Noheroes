import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.3 Etapa Final-B — header de stats da tela `/achievements`.
/// Mostra:
///   - "X / Y desbloqueadas" + barra de progresso
///   - "(N em breve)" badge se há shells (disabled=true)
///   - "M pendentes de coleta" linha destacada se M>0
class AchievementStatsHeader extends StatelessWidget {
  final int unlocked;
  final int total;
  final int shellCount;
  final int pendingClaims;

  const AchievementStatsHeader({
    super.key,
    required this.unlocked,
    required this.total,
    required this.shellCount,
    required this.pendingClaims,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (unlocked / total).clamp(0.0, 1.0);
    final pctLabel = (pct * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$unlocked / $total desbloqueadas',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      letterSpacing: 1)),
              const SizedBox(width: 8),
              Text('· $pctLabel% completo',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted)),
              if (shellCount > 0) ...[
                const SizedBox(width: 6),
                Text('($shellCount em breve)',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          if (pendingClaims > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.notifications_active,
                    color: AppColors.gold.withValues(alpha: 0.9), size: 14),
                const SizedBox(width: 6),
                Text('$pendingClaims pendentes de coleta',
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
