import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/daily_mission.dart';
import '../../../domain/models/daily_mission_status.dart';
import '../../../domain/services/daily_mission_progress_service.dart';
import 'animated_reward_line.dart';
import 'daily_pilar_visuals.dart';
import 'daily_quests_header.dart';
import 'daily_sub_task_row.dart';
import 'mission_completion_popup.dart';

/// Sprint 3.2 Etapa 1.3.A — card visual de uma missão diária.
///
/// **Hotfix:** conclusão é manual via clique no ✓ (não auto-fecha mais
/// ao bater 3/3). 3 modos closed (completed/partial/failed) com visual
/// próprio pelo helper [DailyPilarVisuals.closedVisualOf].
///
/// Modos:
/// - **Aberto**: cabeçalho + quote + 3 sub-tarefas + ✓ bottom-right
///   (sem botão Cancelar — colapsa tocando no header).
/// - **Fechado por status** (completed/partial/failed): borda colorida,
///   opacity reduzida, ícone+label do helper, sem expand.
/// - **Pending colapsado** (default): cabeçalho compacto interativo.
///
/// Tap no body alterna pending ↔ aberto. Tap em closed é noop.
/// `ValueKey(mission.id)` no parent preserva `_expanded` entre rebuilds.
class DailyMissionCard extends StatefulWidget {
  final DailyMission mission;

  /// Recompensa base (XP/gold do rank). Mostrada apenas em closed cards
  /// como referência. Card aberto usa [AnimatedRewardLine] que recalcula
  /// reward em tempo real conforme progresso.
  final int rewardXp;
  final int rewardGold;
  final String rankLabel;

  /// Streak de daily missions do jogador — usado pelo [AnimatedRewardLine]
  /// pra aplicar bônus 1.5× quando ≥10 e missão fecha como completed.
  final int dailyMissionsStreak;

  /// Etapa 1.3.C — `GlobalKey` do Container externo desse card.
  /// Usado pelo [MissionCompletionPopup] como ORIGEM das partículas
  /// voadoras quando o jogador confirma a missão.
  final GlobalKey cardKey;

  /// Etapa 1.3.C — `GlobalKey` do counter Gold/XP no header.
  /// Usado pelo [MissionCompletionPopup] como DESTINO das partículas.
  final GlobalKey<HeaderCounterState>? counterKey;

  final void Function(String subTaskKey, int delta) onSubTaskDelta;

  /// Hotfix Etapa 1.3.A — chamado quando o jogador clica ✓ pra confirmar
  /// a conclusão. Service decide o status final (completed/partial/failed).
  final Future<void> Function() onConfirm;

  const DailyMissionCard({
    super.key,
    required this.mission,
    required this.rewardXp,
    required this.rewardGold,
    required this.rankLabel,
    required this.dailyMissionsStreak,
    required this.cardKey,
    required this.counterKey,
    required this.onSubTaskDelta,
    required this.onConfirm,
  });

  @override
  State<DailyMissionCard> createState() => _DailyMissionCardState();
}

class _DailyMissionCardState extends State<DailyMissionCard> {
  bool _expanded = false;
  bool _confirming = false;

  ClosedVisual? get _closed =>
      DailyPilarVisuals.closedVisualOf(widget.mission.status);

  bool get _isClosed => _closed != null;

  @override
  Widget build(BuildContext context) {
    final pilarColor =
        DailyPilarVisuals.colorOf(widget.mission.modalidade);
    final closed = _closed;
    final borderColor = closed?.color ?? pilarColor;

    final card = Container(
      key: widget.cardKey,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: Border.all(
            color: borderColor.withValues(alpha: 0.7), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isClosed
            ? null
            : () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(pilarColor, closed),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: (_expanded && !_isClosed)
                        ? _buildExpandedContent(pilarColor)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (closed != null) return Opacity(opacity: closed.opacity, child: card);
    return card;
  }

  // ─── expanded content (1.3.B AnimatedSize/Switcher) ────────────────

  Widget _buildExpandedContent(Color pilarColor) {
    return Column(
      key: const ValueKey('daily-card-expanded'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildQuote(),
        const SizedBox(height: 16),
        _buildRequisitosHeader(),
        const SizedBox(height: 12),
        ...widget.mission.subTarefas.map(
          (sub) => DailySubTaskRow(
            sub: sub,
            cardColor: pilarColor,
            onDelta: (delta) =>
                widget.onSubTaskDelta(sub.subTaskKey, delta),
          ),
        ),
        const SizedBox(height: 4),
        _buildFooter(),
      ],
    );
  }

  // ─── header ─────────────────────────────────────────────────────────

  Widget _buildHeader(Color pilarColor, ClosedVisual? closed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeaderIcon(pilarColor, closed),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mission.tituloResolvido,
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              if (closed != null)
                Text(
                  closed.label,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: closed.color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                )
              else
                AnimatedRewardLine(
                  mission: widget.mission,
                  rank: widget.rankLabel,
                  rankLabel: widget.rankLabel,
                  dailyMissionsStreak: widget.dailyMissionsStreak,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (closed == null)
          Icon(
            _expanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: AppColors.textMuted,
            size: 22,
          ),
      ],
    );
  }

  Widget _buildHeaderIcon(Color pilarColor, ClosedVisual? closed) {
    if (closed != null) {
      return Icon(closed.icon, color: closed.color, size: 36);
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pilarColor.withValues(alpha: 0.12),
        border: Border.all(color: pilarColor.withValues(alpha: 0.6)),
      ),
      child: Icon(
        DailyPilarVisuals.iconOf(widget.mission.modalidade),
        size: 18,
        color: pilarColor,
      ),
    );
  }

  // ─── quote ──────────────────────────────────────────────────────────

  Widget _buildQuote() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.shadowVoid.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❝',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 22,
              color: AppColors.gold.withValues(alpha: 0.7),
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.mission.quoteResolvida,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '❞',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 22,
              color: AppColors.gold.withValues(alpha: 0.7),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── requisitos header ─────────────────────────────────────────────

  Widget _buildRequisitosHeader() {
    final percent = _percentDone();
    return Row(
      children: [
        Text(
          'REQUISITOS',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 11,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Text(
          '$percent% concluído',
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  int _percentDone() {
    final factor =
        DailyMissionProgressService.partialFactor(widget.mission);
    return (factor * 100).round();
  }

  // ─── footer (só ✓, sem Cancelar) ───────────────────────────────────

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildCheckButton(),
      ],
    );
  }

  Widget _buildCheckButton() {
    final preview = DailyMissionProgressService.previewStatus(widget.mission);
    final allDone = preview == DailyMissionStatus.completed;
    final color = allDone ? AppColors.gold : AppColors.gold.withValues(alpha: 0.6);

    return GestureDetector(
      key: const ValueKey('daily-mission-confirm'),
      onTap: _confirming ? null : () => _onCheckTap(preview),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
          color: allDone
              ? AppColors.gold.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: _confirming
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.check, color: color, size: 22),
      ),
    );
  }

  Future<void> _onCheckTap(DailyMissionStatus preview) async {
    if (preview == DailyMissionStatus.completed) {
      // 3/3 ≥ 100% → confirma direto, sem dialog.
      await _runConfirm();
      return;
    }

    final isFailed = preview == DailyMissionStatus.failed;
    final message = isFailed
        ? 'Vai FALHAR a missão. Sem reward.'
        : 'Vai concluir como PARCIAL. Reward reduzida proporcionalmente.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Concluir missão?',
          style: GoogleFonts.cinzelDecorative(
              fontSize: 14, color: AppColors.gold, letterSpacing: 2),
        ),
        content: Text(
          message,
          style: GoogleFonts.roboto(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            key: const ValueKey('daily-mission-confirm-dialog-ok'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Confirmar',
              style: GoogleFonts.roboto(
                  color: isFailed
                      ? DailyPilarVisuals.failedColor
                      : DailyPilarVisuals.partialColor,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _runConfirm();
  }

  Future<void> _runConfirm() async {
    if (!mounted) return;

    // Etapa 1.3.C — pre-computa preview ANTES da confirmação. Status e
    // reward são determinísticos sobre as sub-tarefas in-memory; o que
    // o service vai gravar bate com isso. Usado pra mostrar o popup
    // imediatamente após o confirm com os valores corretos.
    final previewStatus =
        DailyMissionProgressService.previewStatus(widget.mission);
    final previewReward = DailyMissionProgressService.computeReward(
      rank: widget.rankLabel,
      mission: widget.mission,
      status: previewStatus,
      dailyMissionsStreak: widget.dailyMissionsStreak,
    );

    setState(() => _confirming = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      MissionCompletionPopup.show(
        context,
        status: previewStatus,
        rewardXp: previewReward.xp,
        rewardGold: previewReward.gold,
        originKey: widget.cardKey,
        targetKey: widget.counterKey,
      );
    } on RewardAlreadyGrantedException {
      // Silencia — UI já tá no estado correto.
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }
}
