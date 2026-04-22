import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/requirements_helper.dart';
import '../../../data/datasources/local/habit_local_ds.dart';
import '../../shared/widgets/app_snack.dart';

class CompletionDialog extends StatefulWidget {
  final HabitWithStatus habitWithStatus;
  final Future<void> Function(String status) onComplete;

  const CompletionDialog({
    super.key,
    required this.habitWithStatus,
    required this.onComplete,
  });

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog> {
  late List<RequirementItem> _reqs;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _reqs = RequirementsHelper.parse(widget.habitWithStatus.habit.requirements);
  }

  bool   get _hasReqs    => _reqs.isNotEmpty;
  double get _completion => RequirementsHelper.calcCompletion(_reqs);
  String get _status     => RequirementsHelper.calcStatus(_reqs);

  Color get _catColor => switch (widget.habitWithStatus.habit.category) {
    'physical'  => AppColors.hp,
    'mental'    => AppColors.mp,
    'spiritual' => AppColors.shadowStable,
    'order'     => AppColors.gold,
    'vitalism'  => AppColors.purple,
    'recovery'  => const Color(0xFF00897B),
    _           => AppColors.purple,
  };

  IconData get _catIcon => switch (widget.habitWithStatus.habit.category) {
    'physical'  => Icons.fitness_center,
    'mental'    => Icons.psychology_outlined,
    'spiritual' => Icons.self_improvement,
    'order'     => Icons.checklist,
    'vitalism'  => Icons.bolt,
    'recovery'  => Icons.bedtime_outlined,
    _           => Icons.star_outline,
  };

  void _increment(int i, int amount) {
    setState(() {
      final req = _reqs[i];
      req.done = (req.done + amount).clamp(0, req.target);
    });
  }

  Future<void> _confirm() async {
    if (_loading) return;
    if (_hasReqs && _completion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Complete ao menos parte dos requisitos.'),
        backgroundColor: AppColors.shadowChaotic,
      ));
      return;
    }
    setState(() => _loading = true);
    final status = _hasReqs ? _status : 'completed';
    try {
      await widget.onComplete(status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao completar: ${e.toString()}'),
          backgroundColor: AppColors.hp,
        ));
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habitWithStatus.habit;
    final pct   = (_completion * 100).round();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _catColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _catColor.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header colorido
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _catColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: _catColor.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _catColor.withValues(alpha: 0.2),
                    ),
                    child: Icon(_catIcon, color: _catColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.title,
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 13, color: AppColors.textPrimary)),
                        Text('+${habit.xpReward} XP  +${habit.goldReward} 🪙  Rank ${habit.rank.toUpperCase()}',
                            style: GoogleFonts.roboto(
                                fontSize: 10, color: _catColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descrição automática
                    if (habit.autoDescription != null &&
                        habit.autoDescription!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _catColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.format_quote,
                                color: _catColor.withValues(alpha: 0.5),
                                size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(habit.autoDescription!,
                                  style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Descrição manual
                    if (habit.description.isNotEmpty) ...[
                      Text(habit.description,
                          style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                      const SizedBox(height: 14),
                    ],

                    // Sub-requisitos
                    if (_hasReqs) ...[
                      Row(
                        children: [
                          Text('REQUISITOS',
                              style: GoogleFonts.cinzelDecorative(
                                  fontSize: 9,
                                  color: AppColors.gold,
                                  letterSpacing: 2)),
                          const Spacer(),
                          Text('$pct% concluído',
                              style: GoogleFonts.roboto(
                                  fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ..._reqs.asMap().entries.map((e) {
                        final i   = e.key;
                        final req = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(req.label,
                                      style: GoogleFonts.roboto(
                                          fontSize: 13,
                                          color: req.isComplete
                                              ? AppColors.shadowAscending
                                              : AppColors.textPrimary,
                                          fontWeight: req.isComplete
                                              ? FontWeight.w600
                                              : FontWeight.normal)),
                                  Text(
                                    '${req.done}/${req.target} ${req.unitLabel}',
                                    style: GoogleFonts.cinzelDecorative(
                                        fontSize: 11,
                                        color: req.isComplete
                                            ? AppColors.shadowAscending
                                            : _catColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: req.progress,
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation(
                                    req.isComplete
                                        ? AppColors.shadowAscending
                                        : _catColor,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Controles +/- com incrementos múltiplos
                              Row(
                                children: [
                                  _incBtn('-25', () => _increment(i, -25)),
                                  const SizedBox(width: 4),
                                  _incBtn('-10', () => _increment(i, -10)),
                                  const SizedBox(width: 4),
                                  _incBtn('-1', () => _increment(i, -1)),
                                  const Spacer(),
                                  _incBtn('+1', () => _increment(i, 1),
                                      positive: true),
                                  const SizedBox(width: 4),
                                  _incBtn('+10', () => _increment(i, 10),
                                      positive: true),
                                  const SizedBox(width: 4),
                                  _incBtn('+25', () => _increment(i, 25),
                                      positive: true),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      // Barra geral
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _completion,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(
                            _completion >= 1.0
                                ? AppColors.shadowAscending
                                : AppColors.gold,
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ],

                    // Missão simples sem requisitos
                    if (!_hasReqs) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _catColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _catColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(_catIcon, color: _catColor, size: 20),
                            const SizedBox(width: 10),
                            Text('Marcar como concluída',
                                style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer com botão
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: Text('Cancelar',
                        style: GoogleFonts.roboto(
                            color: AppColors.textMuted, fontSize: 13)),
                  ),
                  const Spacer(),
                  // Botão ✓ principal
                  GestureDetector(
                    onTap: _loading ? null : _confirm,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _loading
                            ? AppColors.border
                            : (_hasReqs
                                ? (_completion >= 1.0
                                    ? AppColors.shadowAscending
                                    : _completion > 0
                                        ? AppColors.gold
                                        : AppColors.border)
                                : _catColor),
                        boxShadow: [
                          BoxShadow(
                            color: (_hasReqs
                                    ? (_completion >= 1.0
                                        ? AppColors.shadowAscending
                                        : AppColors.gold)
                                    : _catColor)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check,
                              color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incBtn(String label, VoidCallback onTap,
      {bool positive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: positive
              ? _catColor.withValues(alpha: 0.15)
              : AppColors.border.withValues(alpha: 0.5),
          border: Border.all(
            color: positive
                ? _catColor.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.roboto(
                fontSize: 11,
                color: positive ? _catColor : AppColors.textMuted,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
