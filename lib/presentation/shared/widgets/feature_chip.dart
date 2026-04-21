import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

// Sprint 2.3 fix — chip compacto de navegação pra feature com gate de nível.
// Se playerLevel < requiredLevel, retorna SizedBox.shrink (esconde completo).
// Estilo espelha o chip "FORJA" do header do Ferreiro de Aureum
// (shop_screen.dart, linha 244+).
class FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final int requiredLevel;
  final int playerLevel;
  final Color color;

  const FeatureChip({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    required this.requiredLevel,
    required this.playerLevel,
    this.color = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    if (playerLevel < requiredLevel) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 10, color: color, letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
