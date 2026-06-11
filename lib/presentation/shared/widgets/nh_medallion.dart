import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Medalhão circular dourado disperso — linguagem visual do Santuário
/// (Fatia 1). Extraído como widget compartilhado na Fatia 2 (Biblioteca o
/// adota agora; o Santuário pode migrar do `SanctuaryMedallion` inline pra
/// cá quando não estiver em iteração — visual idêntico).
class NhMedallion extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool locked;

  /// Selo opcional (ex.: "EM BREVE"). Quando presente, o medalhão segue
  /// tappable mas exibe o selo sobre o círculo.
  final String? badge;

  /// Diâmetro do círculo. Default 64 (Santuário); Biblioteca usa maior.
  final double size;

  const NhMedallion({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.locked = false,
    this.badge,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final medColor = locked ? AppColors.txtMut : AppColors.goldLt;
    final ringColor = locked ? AppColors.borderViolet : AppColors.goldDk;
    return Opacity(
      opacity: locked ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF221A2E), Color(0xFF0B0910)],
                    ),
                    border: Border.all(color: ringColor),
                    boxShadow: locked
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              blurRadius: 12,
                            ),
                          ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2)),
                    ),
                    child: Icon(icon, color: medColor, size: size * 0.4),
                  ),
                ),
                // Cadeado: pequeno selo no canto inferior-direito quando bloqueado.
                if (locked)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: size * 0.34,
                      height: size * 0.34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0B0910),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Icon(Icons.lock,
                          color: AppColors.goldLt, size: size * 0.18),
                    ),
                  ),
                if (badge != null)
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFF0B0910),
                        border:
                            Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.roboto(
                          fontSize: 8,
                          letterSpacing: 1,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: badge != null ? 14 : 8),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.roboto(
                fontSize: 11,
                letterSpacing: 1.5,
                color: locked ? AppColors.txtMut : AppColors.txt2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
