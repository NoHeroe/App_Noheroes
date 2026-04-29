import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.3 Etapa 2.4 — counter compartilhado Gold + XP + Gems.
///
/// Promovido a partir do `HeaderCounter` original de
/// `daily_quests_header.dart` (Sprint 3.2 Etapa 1.3.A) pra reuso em
/// /quests, /sanctuary, /profile, /shops, /shop, /inventory.
///
/// O `pulse()` em [PlayerStatsCounterState] é acionado pelo
/// `MissionCompletionPopup` quando partículas chegam — só /quests usa
/// (via [GlobalKey]). Outras telas passam `key: null`.
class PlayerStatsCounter extends StatefulWidget {
  final int gold;
  final int xp;
  final int gems;

  const PlayerStatsCounter({
    super.key,
    required this.gold,
    required this.xp,
    required this.gems,
  });

  @override
  State<PlayerStatsCounter> createState() => PlayerStatsCounterState();
}

class PlayerStatsCounterState extends State<PlayerStatsCounter>
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
  /// popup de completion quando as partículas chegam.
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
            const SizedBox(width: 8),
            const Icon(Icons.diamond_outlined,
                size: 12, color: AppColors.purple),
            const SizedBox(width: 3),
            Text(
              '${widget.gems}',
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
