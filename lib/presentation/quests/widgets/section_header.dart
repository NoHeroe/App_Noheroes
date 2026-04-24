import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.1 Bloco 14.6c — header de seção (port direto v0.28.2
/// `habits_screen.dart` linhas 305-316).
///
/// Usado dentro de `SectionAccordion` como trigger clicável. Quando
/// [expanded] muda, o chevron anima rotação 180°.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final bool expanded;
  final VoidCallback onToggle;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.gold;
    return InkWell(
      key: ValueKey('section-header-${title.toLowerCase().replaceAll(' ', '-')}'),
      onTap: onToggle,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: c, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 11,
                      color: c,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: c.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  subtitle!,
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
