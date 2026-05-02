import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/achievement_definition.dart';
import '../utils/reward_display_helper.dart';
import 'achievement_card.dart';
import 'golden_border.dart';
import 'rainbow_border.dart';

/// Sprint 3.3 Etapa Final-B — toast visual exibido pelo
/// `AchievementToastListener` quando uma conquista é desbloqueada.
///
/// Slide-in do topo + auto-dismiss ~4s (controlado pelo caller).
/// Tap → dismiss imediato.
///
/// Visual diferenciado:
///   - Secret: `RainbowBorder` arco-íris animada
///   - Lendária topo (boost10): `GoldenBorder` brilho dourado
///   - Default: borda dourada simples
class AchievementUnlockedToast extends StatefulWidget {
  final AchievementDefinition def;
  final VoidCallback onDismiss;

  const AchievementUnlockedToast({
    super.key,
    required this.def,
    required this.onDismiss,
  });

  @override
  State<AchievementUnlockedToast> createState() =>
      _AchievementUnlockedToastState();
}

class _AchievementUnlockedToastState extends State<AchievementUnlockedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideCtrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    await _slideCtrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.def.reward == null
        ? null
        : RewardDisplay.fromDeclared(widget.def.reward!);
    final isSecret = widget.def.isSecret;
    final isLegendaryTop =
        kLegendaryTopAchievementKeys.contains(widget.def.key);

    Widget body = _ToastBody(def: widget.def, reward: reward);

    if (isSecret) {
      body = RepaintBoundary(
        child: RainbowBorder(
          surfaceColor: AppColors.surface,
          borderWidth: 2.5,
          child: body,
        ),
      );
    } else if (isLegendaryTop) {
      body = GoldenBorder(
        surfaceColor: AppColors.surface,
        borderWidth: 2.5,
        child: body,
      );
    } else {
      body = Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.18),
              blurRadius: 8,
            ),
          ],
        ),
        child: body,
      );
    }

    return Semantics(
      liveRegion: true,
      label: 'Conquista desbloqueada: ${widget.def.name}',
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: _handleTap,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastBody extends StatelessWidget {
  final AchievementDefinition def;
  final RewardDisplay? reward;

  const _ToastBody({required this.def, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.18),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.7)),
            ),
            child: Icon(
              def.isSecret
                  ? Icons.auto_awesome
                  : (kLegendaryTopAchievementKeys.contains(def.key)
                      ? Icons.workspace_premium
                      : Icons.emoji_events),
              color: AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conquista desbloqueada!',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 10,
                        color: AppColors.gold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(def.name,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold)),
                if (reward != null && !reward!.isEmpty) ...[
                  const SizedBox(height: 6),
                  _buildRewardLine(reward!),
                ],
                const SizedBox(height: 4),
                Text('Toque pra dispensar · coletar em /achievements',
                    style: GoogleFonts.roboto(
                        fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardLine(RewardDisplay reward) {
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        if (reward.xp > 0)
          Text('+${reward.xp} XP',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.xp)),
        if (reward.gold > 0)
          Text('+${reward.gold} ouro',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.gold)),
        if (reward.gems > 0)
          Text('+${reward.gems} 💎',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.mp)),
      ],
    );
  }
}
