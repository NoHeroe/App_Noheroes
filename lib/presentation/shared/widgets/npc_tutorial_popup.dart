import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class NpcTutorialPopup extends StatelessWidget {
  final String npcName;
  final String npcTitle;
  final String message;
  final String buttonLabel;
  final VoidCallback? onConfirm;

  const NpcTutorialPopup({
    super.key,
    required this.npcName,
    required this.npcTitle,
    required this.message,
    this.buttonLabel = 'Entendido',
    this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String npcName,
    required String npcTitle,
    required String message,
    String buttonLabel = 'Entendido',
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => NpcTutorialPopup(
        npcName: npcName,
        npcTitle: npcTitle,
        message: message,
        buttonLabel: buttonLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.1),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emblema NPC
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.person_outline,
                  color: AppColors.gold, size: 28),
            ),
            const SizedBox(height: 12),

            // Nome do NPC
            Text(
              npcName,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: AppColors.gold,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 2),
            Text(
              npcTitle,
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
                height: 1,
                color: AppColors.gold.withValues(alpha: 0.2)),
            const SizedBox(height: 20),

            // Mensagem
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6),
            ),
            const SizedBox(height: 24),

            // Botão
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm?.call();
                },
                style: TextButton.styleFrom(
                  backgroundColor:
                      AppColors.gold.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 12, color: AppColors.gold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
