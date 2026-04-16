import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';

class ClassQuestCard extends StatelessWidget {
  final ClassQuestsTableData quest;

  const ClassQuestCard({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    final progress = quest.progress;
    final target = quest.progressTarget;
    final pct = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final done = quest.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? AppColors.shadowAscending.withValues(alpha: 0.4)
              : AppColors.purple.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(quest.title,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color: done
                            ? AppColors.textMuted
                            : AppColors.textPrimary)),
              ),
              if (done)
                const Icon(Icons.check_circle_outline,
                    color: AppColors.shadowAscending, size: 16)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.4)),
                  ),
                  child: Text('AUTO',
                      style: GoogleFonts.roboto(
                          fontSize: 8,
                          color: AppColors.purple,
                          letterSpacing: 1)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(quest.description,
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                  done ? AppColors.shadowAscending : AppColors.purple),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$progress / $target',
                  style: GoogleFonts.roboto(
                      fontSize: 10, color: AppColors.textMuted)),
              Row(children: [
                Icon(Icons.auto_awesome, color: AppColors.xp, size: 11),
                const SizedBox(width: 3),
                Text('+${quest.xpReward} XP',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.xp)),
                if (quest.goldReward > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.monetization_on_outlined,
                      color: AppColors.gold, size: 11),
                  const SizedBox(width: 3),
                  Text('+${quest.goldReward}',
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.gold)),
                ],
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
