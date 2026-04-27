import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/daily_mission.dart';
import '../../../domain/models/daily_mission_status.dart';
import 'daily_mission_card.dart';
import 'daily_quests_header.dart';

/// Sprint 3.2 Etapa 1.3.A — sanfona "MISSÕES DIÁRIAS" no topo do
/// `/quests`. Default expandida.
///
/// Header tappable (chevron + contador). Conteúdo: lista de
/// [DailyMissionCard]. Cards mantêm `_expanded` próprio via
/// `ValueKey(mission.id)` — auto-refresh do notifier não perde estado
/// de expansão.
class DailySection extends StatefulWidget {
  final List<DailyMission> missions;

  /// Reward resolvido por missão (parent calcula a partir do rank do
  /// jogador). Map por `mission.id`.
  final Map<int, ({int xp, int gold})> rewardsByMissionId;

  /// Rank do jogador pra exibir no card (E/D/C/B/A/S).
  final String rankLabel;

  /// Streak de daily missions do jogador — propagado pro card pra alimentar
  /// o [AnimatedRewardLine] (bônus 1.5× quando ≥10).
  final int dailyMissionsStreak;

  /// Etapa 1.3.C — `GlobalKey` do counter Gold/XP no header. Propagado
  /// pros cards pra que o `MissionCompletionPopup` saiba o destino das
  /// partículas voadoras.
  final GlobalKey<HeaderCounterState>? counterKey;

  final void Function(int missionId, String subTaskKey, int delta)
      onSubTaskDelta;

  /// Hotfix Etapa 1.3.A — chamado quando o jogador clica ✓ no card.
  final Future<void> Function(int missionId) onConfirm;

  const DailySection({
    super.key,
    required this.missions,
    required this.rewardsByMissionId,
    required this.rankLabel,
    required this.dailyMissionsStreak,
    required this.onSubTaskDelta,
    required this.onConfirm,
    this.counterKey,
  });

  @override
  State<DailySection> createState() => _DailySectionState();
}

class _DailySectionState extends State<DailySection> {
  bool _expanded = true;

  /// Etapa 1.3.C — cache de `GlobalKey` por `mission.id`, usadas como
  /// origin do `MissionCompletionPopup`. Mantidas estáveis entre rebuilds.
  final Map<int, GlobalKey> _cardKeys = {};

  GlobalKey _keyFor(int missionId) =>
      _cardKeys.putIfAbsent(missionId, () => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.missions
        .where((m) => m.status == DailyMissionStatus.completed)
        .length;
    final total = widget.missions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            key: const ValueKey('daily-section-header'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    color: AppColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MISSÕES DIÁRIAS',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 13,
                      color: AppColors.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completedCount/$total concluídas',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(
                height: 1, thickness: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Column(
                children: [
                  if (widget.missions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhuma missão diária ainda.',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  else
                    for (final entry in widget.missions.asMap().entries)
                      DailyMissionCard(
                        key: ValueKey('daily-mission-${entry.value.id}'),
                        mission: entry.value,
                        rewardXp: widget
                                .rewardsByMissionId[entry.value.id]?.xp ??
                            0,
                        rewardGold: widget
                                .rewardsByMissionId[entry.value.id]?.gold ??
                            0,
                        rankLabel: widget.rankLabel,
                        dailyMissionsStreak: widget.dailyMissionsStreak,
                        cardKey: _keyFor(entry.value.id),
                        counterKey: widget.counterKey,
                        onSubTaskDelta: (subKey, delta) => widget
                            .onSubTaskDelta(entry.value.id, subKey, delta),
                        onConfirm: () => widget.onConfirm(entry.value.id),
                      )
                          .animate(delay: (entry.key * 80).ms)
                          .fadeIn(
                              duration: 500.ms, curve: Curves.easeOut)
                          .slideY(
                              begin: 0.05,
                              end: 0.0,
                              duration: 500.ms,
                              curve: Curves.easeOut),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
