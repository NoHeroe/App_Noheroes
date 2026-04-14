import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/requirements_helper.dart';
import '../../../data/datasources/local/habit_local_ds.dart';

class HabitCard extends StatefulWidget {
  final HabitWithStatus habitWithStatus;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const HabitCard({
    super.key,
    required this.habitWithStatus,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  bool _expanded = false;

  HabitWithStatus get h => widget.habitWithStatus;

  Color get _catColor => switch (h.habit.category) {
    'physical'  => AppColors.hp,
    'mental'    => AppColors.mp,
    'spiritual' => AppColors.shadowStable,
    'order'     => AppColors.gold,
    'vitalism'  => AppColors.purple,
    'recovery'  => const Color(0xFF00897B),
    _           => AppColors.purple,
  };

  IconData get _catIcon => switch (h.habit.category) {
    'physical'  => Icons.fitness_center,
    'mental'    => Icons.psychology_outlined,
    'spiritual' => Icons.self_improvement,
    'order'     => Icons.checklist,
    'vitalism'  => Icons.bolt,
    'recovery'  => Icons.bedtime_outlined,
    _           => Icons.star_outline,
  };

  String get _statusLabel => switch (h.todayStatus) {
    'completed' => '✓ Concluído',
    'partial'   => '◑ Parcial',
    'niet'      => '— Niet',
    'failed'    => '✗ Falhou',
    _           => 'Pendente',
  };

  Color get _statusColor => switch (h.todayStatus) {
    'completed' => AppColors.shadowAscending,
    'partial'   => AppColors.mp,
    'niet'      => AppColors.gold,
    'failed'    => AppColors.shadowChaotic,
    _           => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final locked   = h.isLocked;
    final reqs     = RequirementsHelper.parse(h.habit.requirements);
    final hasReqs  = reqs.isNotEmpty;
    final completion = RequirementsHelper.calcCompletion(reqs);

    return GestureDetector(
      onTap: () {
        if (hasReqs || h.habit.description.isNotEmpty ||
            (h.habit.autoDescription != null)) {
          setState(() => _expanded = !_expanded);
        }
        if (!locked) widget.onTap();
      },
      onLongPress: locked ? null : widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: h.isDone
                ? _catColor.withValues(alpha: 0.5)
                : AppColors.border,
            width: h.isDone ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Linha principal
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Borda colorida lateral
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: locked
                          ? AppColors.border
                          : _catColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Ícone
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _catColor.withValues(alpha: locked ? 0.05 : 0.12),
                    ),
                    child: Icon(_catIcon,
                        color: locked
                            ? AppColors.textMuted
                            : _catColor,
                        size: 18),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                h.habit.title,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: locked
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Rank badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _catColor.withValues(alpha: 0.4)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('R${h.habit.rank.toUpperCase()}',
                                  style: GoogleFonts.roboto(
                                      fontSize: 9, color: _catColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('+${h.habit.xpReward} XP',
                                style: GoogleFonts.roboto(
                                    fontSize: 11, color: AppColors.xp)),
                            const SizedBox(width: 8),
                            Text('+${h.habit.goldReward} 🪙',
                                style: GoogleFonts.roboto(
                                    fontSize: 11, color: AppColors.gold)),
                            const Spacer(),
                            Text(_statusLabel,
                                style: GoogleFonts.roboto(
                                    fontSize: 11, color: _statusColor)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  // Seta expansão se tem conteúdo
                  if (hasReqs || h.habit.description.isNotEmpty)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted, size: 18,
                    ),
                ],
              ),
            ),

            // Barra de progresso dos requisitos
            if (hasReqs && h.isDone)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completion,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(_catColor),
                    minHeight: 4,
                  ),
                ),
              ),

            // Conteúdo expandido
            if (_expanded) ...[
              Divider(color: AppColors.border, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descrição automática
                    if (h.habit.autoDescription != null &&
                        h.habit.autoDescription!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.format_quote,
                              color: _catColor.withValues(alpha: 0.5),
                              size: 12),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(h.habit.autoDescription!,
                                style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Descrição manual
                    if (h.habit.description.isNotEmpty) ...[
                      Text(h.habit.description,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                      const SizedBox(height: 8),
                    ],

                    // Preview requisitos
                    if (hasReqs) ...[
                      Text('REQUISITOS',
                          style: GoogleFonts.roboto(
                              fontSize: 9,
                              color: AppColors.textMuted,
                              letterSpacing: 2)),
                      const SizedBox(height: 6),
                      ...reqs.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  r.isComplete
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: r.isComplete
                                      ? AppColors.shadowAscending
                                      : AppColors.textMuted,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      '${r.label} — ${r.target} ${r.unitLabel}',
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: r.isComplete
                                              ? AppColors.shadowAscending
                                              : AppColors.textSecondary)),
                                ),
                              ],
                            ),
                          )),
                    ],

                    if (!locked) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _catColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow,
                                  color: _catColor, size: 16),
                              const SizedBox(width: 6),
                              Text('Iniciar Missão',
                                  style: GoogleFonts.cinzelDecorative(
                                      fontSize: 11,
                                      color: _catColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
