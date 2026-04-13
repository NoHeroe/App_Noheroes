import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/requirements_helper.dart';
import '../../../data/datasources/local/habit_local_ds.dart';

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
  late List<RequirementItem> _requirements;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requirements = RequirementsHelper.parse(
      widget.habitWithStatus.habit.requirements,
    );
  }

  bool get _hasRequirements => _requirements.isNotEmpty;

  double get _completion => RequirementsHelper.calcCompletion(_requirements);

  String get _status => RequirementsHelper.calcStatus(_requirements);

  Color get _categoryColor => switch (widget.habitWithStatus.habit.category) {
    'physical'  => AppColors.hp,
    'mental'    => AppColors.mp,
    'spiritual' => AppColors.shadowStable,
    'order'     => AppColors.gold,
    _           => AppColors.purple,
  };

  Future<void> _confirm() async {
    if (_loading) return;

    // Se tem requisitos, valida
    if (_hasRequirements && _completion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Complete pelo menos parte dos requisitos.'),
        backgroundColor: AppColors.shadowChaotic,
      ));
      return;
    }

    setState(() => _loading = true);
    final status = _hasRequirements ? _status : 'completed';
    await widget.onComplete(status);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habitWithStatus.habit;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _categoryColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _categoryColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(_categoryIcon, color: _categoryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.title,
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 13, color: AppColors.textPrimary)),
                      Text('Rank ${habit.rank.toUpperCase()} · +${habit.xpReward} XP · +${habit.goldReward} 🪙',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: _categoryColor)),
                    ],
                  ),
                ),
              ],
            ),

            // Descrição
            if (habit.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(habit.description,
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5)),
              ),
            ],

            // Sub-requisitos
            if (_hasRequirements) ...[
              const SizedBox(height: 16),
              Text('REQUISITOS',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 10,
                      color: AppColors.gold,
                      letterSpacing: 2)),
              const SizedBox(height: 10),
              ..._requirements.asMap().entries.map((entry) {
                final i = entry.key;
                final req = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.label,
                              style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: req.isComplete
                                      ? AppColors.shadowAscending
                                      : AppColors.textPrimary)),
                          Text('${req.done}/${req.target}',
                              style: GoogleFonts.cinzelDecorative(
                                  fontSize: 12,
                                  color: req.isComplete
                                      ? AppColors.shadowAscending
                                      : _categoryColor)),
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
                                : _categoryColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Controles +/-
                      Row(
                        children: [
                          _counterBtn(Icons.remove, () {
                            if (req.done > 0) {
                              setState(() => _requirements[i].done--);
                            }
                          }),
                          const SizedBox(width: 8),
                          _counterBtn(Icons.add, () {
                            if (req.done < req.target) {
                              setState(() => _requirements[i].done++);
                            }
                          }),
                          const SizedBox(width: 12),
                          Text('${(req.progress * 100).round()}% concluído',
                              style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Barra de progresso geral
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _completion,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          _completion >= 1.0
                              ? AppColors.shadowAscending
                              : AppColors.gold,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${(_completion * 100).round()}%',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: _completion >= 1.0
                              ? AppColors.shadowAscending
                              : AppColors.gold)),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancelar',
                        style: GoogleFonts.roboto(
                            color: AppColors.textMuted, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasRequirements
                          ? (_completion >= 1.0
                              ? AppColors.shadowAscending
                              : _completion > 0
                                  ? AppColors.mp
                                  : AppColors.border)
                          : _categoryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _hasRequirements
                                ? (_completion >= 1.0
                                    ? 'Concluído! ✓'
                                    : _completion > 0
                                        ? 'Parcial (${(_completion * 100).round()}%)'
                                        : 'Registrar')
                                : 'Concluir Ritual',
                            style: GoogleFonts.cinzelDecorative(
                                color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _categoryColor.withValues(alpha: 0.12),
            border: Border.all(color: _categoryColor.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: _categoryColor, size: 16),
        ),
      );

  IconData get _categoryIcon => switch (widget.habitWithStatus.habit.category) {
    'physical'  => Icons.fitness_center,
    'mental'    => Icons.psychology_outlined,
    'spiritual' => Icons.self_improvement,
    'order'     => Icons.checklist,
    _           => Icons.star_outline,
  };
}
