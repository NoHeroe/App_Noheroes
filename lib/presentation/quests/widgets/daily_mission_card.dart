import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/daily_mission.dart';
import '../../../domain/models/daily_mission_status.dart';
import 'daily_pilar_visuals.dart';
import 'daily_sub_task_row.dart';

/// Sprint 3.2 Etapa 1.3.A — card visual de uma missão diária.
///
/// 3 modos:
/// - **Fechado** (default): linha compacta com ícone + título + reward.
/// - **Aberto**: cabeçalho + quote + 3 sub-tarefas com botões + Cancelar/✓.
/// - **Concluído** (`status == completed`): borda verde, opacity 70%,
///   forçado colapsado, sem expand.
///
/// Tap no body alterna fechado↔aberto. Tap em concluído é noop.
///
/// Estado interno: só `_expanded`. ListView do parent usa
/// `ValueKey(mission.id)` pra preservar `_expanded` entre rebuilds do
/// notifier (auto-refresh via eventos).
class DailyMissionCard extends StatefulWidget {
  final DailyMission mission;

  /// Recompensa resolvida (XP/gold). Vem do parent (notifier calcula uma
  /// vez a partir do rank do jogador) — evita o card precisar de provider.
  /// Pra missões já concluídas isso é a recompensa que foi creditada.
  final int rewardXp;
  final int rewardGold;
  final String rankLabel;

  /// Callback chamado a cada toque de botão de sub-tarefa.
  final void Function(String subTaskKey, int delta) onSubTaskDelta;

  const DailyMissionCard({
    super.key,
    required this.mission,
    required this.rewardXp,
    required this.rewardGold,
    required this.rankLabel,
    required this.onSubTaskDelta,
  });

  @override
  State<DailyMissionCard> createState() => _DailyMissionCardState();
}

class _DailyMissionCardState extends State<DailyMissionCard> {
  bool _expanded = false;

  bool get _isCompleted =>
      widget.mission.status == DailyMissionStatus.completed;

  @override
  Widget build(BuildContext context) {
    final color = DailyPilarVisuals.colorOf(widget.mission.modalidade);
    final borderColor =
        _isCompleted ? DailyPilarVisuals.completedColor : color;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: Border.all(color: borderColor.withValues(alpha: 0.7), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isCompleted
            ? null
            : () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(color),
              if (!_isCompleted && _expanded) ...[
                const SizedBox(height: 16),
                _buildQuote(),
                const SizedBox(height: 16),
                _buildRequisitosHeader(),
                const SizedBox(height: 12),
                ...widget.mission.subTarefas.map(
                  (sub) => DailySubTaskRow(
                    sub: sub,
                    cardColor: color,
                    onDelta: (delta) =>
                        widget.onSubTaskDelta(sub.subTaskKey, delta),
                  ),
                ),
                const SizedBox(height: 4),
                _buildFooter(color),
              ],
            ],
          ),
        ),
      ),
    );

    if (_isCompleted) {
      return Opacity(opacity: 0.7, child: card);
    }
    return card;
  }

  // ─── header ─────────────────────────────────────────────────────────

  Widget _buildHeader(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeaderIcon(color),
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
              if (_isCompleted)
                Text(
                  'CONCLUÍDA',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: DailyPilarVisuals.completedColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                )
              else
                Text(
                  '+${widget.rewardXp} XP  +${widget.rewardGold} gold  ·  Rank ${widget.rankLabel}',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (!_isCompleted)
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

  Widget _buildHeaderIcon(Color color) {
    if (_isCompleted) {
      return const Icon(
        Icons.check_circle,
        color: DailyPilarVisuals.completedColor,
        size: 36,
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Icon(
        DailyPilarVisuals.iconOf(widget.mission.modalidade),
        size: 18,
        color: color,
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
    final subs = widget.mission.subTarefas;
    if (subs.isEmpty) return 0;
    final done = subs.where((s) => s.completed).length;
    return ((done / subs.length) * 100).round();
  }

  // ─── footer ────────────────────────────────────────────────────────

  Widget _buildFooter(Color color) {
    return Row(
      children: [
        // Cancelar (colapsa, não muda dados).
        GestureDetector(
          onTap: () => setState(() => _expanded = false),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const Spacer(),
        // ✓ circular dourado. Habilitado só se 3/3 sub completas — o
        // service auto-fecha ao completar a 3ª, mas o botão fica como
        // "selo manual" pro usuário.
        _buildCheckButton(),
      ],
    );
  }

  Widget _buildCheckButton() {
    final allDone =
        widget.mission.subTarefas.every((s) => s.completed);
    final color =
        allDone ? AppColors.gold : AppColors.gold.withValues(alpha: 0.25);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
        color: allDone ? AppColors.gold.withValues(alpha: 0.15) : null,
      ),
      child: Icon(
        Icons.check,
        color: color,
        size: 20,
      ),
    );
  }
}
