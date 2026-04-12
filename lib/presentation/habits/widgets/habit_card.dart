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

  Color get _categoryColor {
    return switch (habitWithStatus.habit.category) {
      'physical'  => AppColors.hp,
      'mental'    => AppColors.mp,
      'spiritual' => AppColors.shadowStable,
      'order'     => AppColors.gold,
      _ => AppColors.purple,
    };
  }

  IconData get _categoryIcon {
    return switch (habitWithStatus.habit.category) {
      'physical'  => Icons.fitness_center,
      'mental'    => Icons.psychology_outlined,
      'spiritual' => Icons.self_improvement,
      'order'     => Icons.checklist,
      _ => Icons.star_outline,
    };
  }

  String get _statusLabel {
    return switch (habitWithStatus.todayStatus) {
      'completed' => 'Concluído',
      'partial'   => 'Parcial',
      'niet'      => 'Niet',
      'failed'    => 'Falhou',
      _ => 'Pendente',
    };
  }

  Color get _statusColor {
    return switch (habitWithStatus.todayStatus) {
      'completed' => AppColors.shadowAscending,
      'partial'   => AppColors.mp,
      'niet'      => AppColors.gold,
      'failed'    => AppColors.shadowChaotic,
      _ => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final done = habitWithStatus.isDone &&
        !habitWithStatus.habit.isRepeatable;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: habitWithStatus.isDone
                ? _categoryColor.withOpacity(0.4)
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
                color: _categoryColor.withOpacity(0.12),
              ),
              child: Icon(_categoryIcon,
                  color: _categoryColor, size: 18),
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
                      color: done
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _rankBadge(habitWithStatus.habit.rank),
                      const SizedBox(width: 8),
                      Text(
                        '+${habitWithStatus.habit.xpReward} XP',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: AppColors.xp),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${habitWithStatus.habit.goldReward} 🪙',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: AppColors.gold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _statusLabel,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: _statusColor,
                  ),
                ),
                if (habitWithStatus.habit.isRepeatable)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('repetível',
                        style: GoogleFonts.roboto(
                            fontSize: 9,
                            color: AppColors.textMuted)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rankBadge(String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.purple.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Rank ${rank.toUpperCase()}',
        style: GoogleFonts.roboto(
            fontSize: 9,
            color: AppColors.purple),
      ),
    );
  }
}
