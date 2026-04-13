import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/habit_local_ds.dart';

class HabitCard extends StatelessWidget {
  final HabitWithStatus habitWithStatus;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const HabitCard({
    super.key,
    required this.habitWithStatus,
    required this.onTap,
    this.onLongPress,
  });

  Color get _categoryColor => switch (habitWithStatus.habit.category) {
    'physical'  => AppColors.hp,
    'mental'    => AppColors.mp,
    'spiritual' => AppColors.shadowStable,
    'order'     => AppColors.gold,
    _           => AppColors.purple,
  };

  IconData get _categoryIcon => switch (habitWithStatus.habit.category) {
    'physical'  => Icons.fitness_center,
    'mental'    => Icons.psychology_outlined,
    'spiritual' => Icons.self_improvement,
    'order'     => Icons.checklist,
    _           => Icons.star_outline,
  };

  String get _statusLabel => switch (habitWithStatus.todayStatus) {
    'completed' => 'Concluído',
    'partial'   => 'Parcial',
    'niet'      => 'Niet',
    'failed'    => 'Falhou',
    _           => 'Pendente',
  };

  Color get _statusColor => switch (habitWithStatus.todayStatus) {
    'completed' => AppColors.shadowAscending,
    'partial'   => AppColors.mp,
    'niet'      => AppColors.gold,
    'failed'    => AppColors.shadowChaotic,
    _           => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    // Trancado = qualquer hábito já registrado hoje (repetível ou não)
    final locked = habitWithStatus.isLocked;

    return GestureDetector(
      onTap: locked ? null : onTap,
      onLongPress: locked ? null : onLongPress,
      child: Opacity(
        opacity: locked ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: habitWithStatus.isDone
                  ? _categoryColor.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Ícone categoria
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _categoryColor.withValues(alpha: 0.12),
                ),
                child: Icon(_categoryIcon, color: _categoryColor, size: 18),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habitWithStatus.habit.title,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: locked
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration:
                            locked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _rankBadge(habitWithStatus.habit.rank),
                        const SizedBox(width: 8),
                        Text('+${habitWithStatus.habit.xpReward} XP',
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: AppColors.xp)),
                        const SizedBox(width: 8),
                        Text('+${habitWithStatus.habit.goldReward} 🪙',
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: AppColors.gold)),
                      ],
                    ),
                  ],
                ),
              ),

              // Status + ícones
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _statusLabel,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: _statusColor),
                  ),
                  const SizedBox(height: 2),
                  if (locked)
                    const Icon(Icons.lock_outline,
                        size: 13, color: AppColors.textMuted)
                  else if (habitWithStatus.habit.isRepeatable)
                    Text('repetível',
                        style: GoogleFonts.roboto(
                            fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rankBadge(String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Rank ${rank.toUpperCase()}',
        style: GoogleFonts.roboto(fontSize: 9, color: AppColors.purple),
      ),
    );
  }
}
