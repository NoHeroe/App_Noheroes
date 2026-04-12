import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';

class DailyMissionsCard extends ConsumerWidget {
  const DailyMissionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RITUAIS DO DIA',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
            GestureDetector(
              onTap: () => context.go('/habits'),
              child: Text('Ver todos',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.purple)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        habitsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.purple)),
          error: (_, __) => const SizedBox(),
          data: (habits) {
            final today = habits.take(3).toList();
            if (today.isEmpty) {
              return GestureDetector(
                onTap: () => context.go('/habits'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Nenhum ritual ainda. Criar missões →',
                      style: GoogleFonts.roboto(
                          color: AppColors.textMuted, fontSize: 13)),
                ),
              );
            }
            return Column(
              children: today.map((h) {
                final color = switch (h.habit.category) {
                  'physical'  => AppColors.hp,
                  'mental'    => AppColors.mp,
                  'spiritual' => AppColors.shadowStable,
                  _ => AppColors.gold,
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: h.isDone
                          ? color.withOpacity(0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(width: 4, height: 36,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.habit.title,
                                style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: h.isDone
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                    decoration: h.isDone
                                        ? TextDecoration.lineThrough
                                        : null)),
                            Text(h.habit.isSystemHabit
                                ? 'Ritual Diário'
                                : 'Missão Individual',
                                style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Icon(
                        h.isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: h.isDone ? color : AppColors.border,
                        size: 22,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
