import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/daily_mission.dart';
import '../../../domain/models/daily_mission_status.dart';
import '../../../domain/services/daily_mission_progress_service.dart';
import 'daily_pilar_visuals.dart';

/// Sprint 3.2 Etapa 1.3.B — linha de reward dinâmico no header do card.
///
/// Substitui a linha estática "+X XP +Y gold · Rank N". Recalcula reward
/// a cada rebuild via [DailyMissionProgressService.computeReward] e anima
/// XP/gold rolando + cor da linha conforme preview status + factor.
///
/// Casos visuais (espelha tabela CEO):
/// - factor==0 (estado inicial): base muted "+28 XP +20 gold · Rank C".
/// - failed (todas <25%): vermelho "+0 XP +0 gold · FALHA".
/// - partial: amarelo "· PARCIAL" (com ✨ se factor>1.0).
/// - completed exato: verde "· COMPLETA".
/// - completed excedência: verde "✨" (factor>1.0) ou verde dourado
///   "✨ MAX" (factor==3.0).
class AnimatedRewardLine extends StatefulWidget {
  final DailyMission mission;
  final String rank;
  final String rankLabel;
  final int dailyMissionsStreak;

  const AnimatedRewardLine({
    super.key,
    required this.mission,
    required this.rank,
    required this.rankLabel,
    required this.dailyMissionsStreak,
  });

  @override
  State<AnimatedRewardLine> createState() => _AnimatedRewardLineState();
}

class _AnimatedRewardLineState extends State<AnimatedRewardLine> {
  // Valores anteriores armazenados pra que o tween parta do display
  // atual quando o jogador clica em rajada.
  int _lastXp = 0;
  int _lastGold = 0;
  Color _lastColor = AppColors.textMuted;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final display = _resolveDisplay();
    if (!_initialized) {
      _lastXp = display.xp;
      _lastGold = display.gold;
      _lastColor = display.color;
      _initialized = true;
    }

    final fromXp = _lastXp;
    final fromGold = _lastGold;
    final fromColor = _lastColor;

    // Atualiza "last" pro próximo build.
    _lastXp = display.xp;
    _lastGold = display.gold;
    _lastColor = display.color;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      key: ValueKey('reward-${display.xp}-${display.gold}-${display.suffix}'),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, t, __) {
        final xp = (fromXp + (display.xp - fromXp) * t).round();
        final gold = (fromGold + (display.gold - fromGold) * t).round();
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: fromColor, end: display.color),
          duration: const Duration(milliseconds: 450),
          builder: (_, color, __) => Text(
            '+$xp XP  +$gold gold  ${display.suffix}',
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: color ?? display.color,
              fontWeight: display.color == AppColors.textMuted
                  ? FontWeight.w400
                  : FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  _RewardDisplay _resolveDisplay() {
    final factor =
        DailyMissionProgressService.missionFactor(widget.mission);
    final base =
        DailyMissionProgressService.rewardByRank[widget.rank] ??
            DailyMissionProgressService.rewardByRank['E']!;

    if (factor == 0.0) {
      return _RewardDisplay(
        xp: base.xp,
        gold: base.gold,
        color: AppColors.textMuted,
        suffix: '· Rank ${widget.rankLabel}',
      );
    }

    final preview =
        DailyMissionProgressService.previewStatus(widget.mission);
    final reward = DailyMissionProgressService.computeReward(
      rank: widget.rank,
      mission: widget.mission,
      status: preview,
      dailyMissionsStreak: widget.dailyMissionsStreak,
    );

    switch (preview) {
      case DailyMissionStatus.failed:
        return _RewardDisplay(
          xp: reward.xp,
          gold: reward.gold,
          color: DailyPilarVisuals.failedColor,
          suffix: '· FALHA',
        );
      case DailyMissionStatus.partial:
        final sparkle = factor > 1.0;
        return _RewardDisplay(
          xp: reward.xp,
          gold: reward.gold,
          color: DailyPilarVisuals.partialColor,
          suffix: sparkle ? '✨ PARCIAL' : '· PARCIAL',
        );
      case DailyMissionStatus.completed:
        final maxed = factor >= 3.0;
        final sparkle = factor > 1.0;
        final color = maxed
            ? Color.lerp(DailyPilarVisuals.completedColor,
                AppColors.gold, 0.5)!
            : DailyPilarVisuals.completedColor;
        final suffix = maxed
            ? '✨ MAX'
            : (sparkle ? '✨ COMPLETA' : '· COMPLETA');
        return _RewardDisplay(
          xp: reward.xp,
          gold: reward.gold,
          color: color,
          suffix: suffix,
        );
      case DailyMissionStatus.pending:
        // _resolveStatus nunca retorna pending; defesa.
        return _RewardDisplay(
          xp: base.xp,
          gold: base.gold,
          color: AppColors.textMuted,
          suffix: '· Rank ${widget.rankLabel}',
        );
    }
  }
}

class _RewardDisplay {
  final int xp;
  final int gold;
  final Color color;
  final String suffix;
  const _RewardDisplay({
    required this.xp,
    required this.gold,
    required this.color,
    required this.suffix,
  });
}
