import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/app_snack.dart';

/// Substitui todos os SnackBars do app por um visual unificado dark/dourado.
/// Mensagens longas ficam mais tempo na tela.
class AppSnack {
  static void show(
    BuildContext context,
    String message, {
    Color borderColor = AppColors.gold,
    IconData? icon,
    Duration? duration,
  }) {
    final words = message.split(' ').length;
    final auto = duration ??
        Duration(milliseconds: words > 10 ? 4000 : 2500);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: borderColor, size: 16),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.roboto(
                    fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0E0E1A),
        duration: auto,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  static void error(BuildContext context, String message) =>
      show(context, message,
          borderColor: AppColors.hp, icon: Icons.error_outline);

  static void success(BuildContext context, String message) =>
      show(context, message,
          borderColor: AppColors.shadowAscending,
          icon: Icons.check_circle_outline);

  static void info(BuildContext context, String message) =>
      show(context, message,
          borderColor: AppColors.mp, icon: Icons.info_outline);

  static void warning(BuildContext context, String message) =>
      show(context, message,
          borderColor: AppColors.gold, icon: Icons.warning_amber_outlined);
}
