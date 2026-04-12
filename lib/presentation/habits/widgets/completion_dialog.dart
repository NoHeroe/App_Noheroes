import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/habit_local_ds.dart';

class CompletionDialog extends StatelessWidget {
  final HabitWithStatus habitWithStatus;
  final Function(String status) onComplete;

  const CompletionDialog({
    super.key,
    required this.habitWithStatus,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final habit = habitWithStatus.habit;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(
        habit.title,
        style: GoogleFonts.cinzelDecorative(
            color: AppColors.textPrimary, fontSize: 15),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como foi este ritual?',
            style: GoogleFonts.roboto(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _option(context, 'Concluído', 'completed',
              'Meta cumprida completamente.', AppColors.shadowAscending,
              Icons.check_circle_outline),
          _option(context, 'Parcial', 'partial',
              'Fiz parte, mas não tudo.', AppColors.mp,
              Icons.remove_circle_outline),
          _option(context, 'Niet', 'niet',
              'Assumi que não fiz. Sem desculpas.', AppColors.gold,
              Icons.block_outlined),
          _option(context, 'Falha', 'failed',
              'Não fiz e nem assumo.', AppColors.hp,
              Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String label, String status,
      String desc, Color color, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onComplete(status);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.roboto(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(desc,
                      style: GoogleFonts.roboto(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
