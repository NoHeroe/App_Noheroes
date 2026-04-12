import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class ShadowStatusCard extends StatelessWidget {
  const ShadowStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shadowStable.withOpacity(0.4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.shadowStable.withOpacity(0.08),
            AppColors.surface,
          ],
        ),
      ),
      child: Row(
        children: [
          // Orbe da sombra
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.shadowStable.withOpacity(0.6),
                width: 1.5,
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.shadowStable.withOpacity(0.4),
                  AppColors.shadowVoid,
                ],
              ),
            ),
            child: const Icon(
              Icons.blur_circular,
              color: AppColors.shadowStable,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUA SOMBRA',
                  style: GoogleFonts.roboto(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estável',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    color: AppColors.shadowStable,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sua sombra observa em silêncio.',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
