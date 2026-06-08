import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Bloco 2 — botão hexagonal "COMBATE" (substitui o _PlayButton vermelho).
///
/// Hexágono apontado nas laterais. O contorno dourado é desenhado por um
/// [CustomPainter] usando o MESMO [Path] do recorte ([ClipPath]) — assim a
/// espessura fica uniforme nos 6 lados e nas 2 pontas (um `Border` de
/// container não acompanharia o clip).
class SanctuaryCombatHex extends StatelessWidget {
  final VoidCallback onTap;
  const SanctuaryCombatHex({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Fill clipado no hexágono
                ClipPath(
                  clipper: _HexClipper(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 13),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2A2139), Color(0xFF0D0A13)],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sports_martial_arts,
                            color: AppColors.goldLt, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'COMBATE',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: AppColors.goldLt,
                            shadows: [
                              Shadow(
                                color: AppColors.gold.withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Contorno uniforme: mesmo Path em stroke, por cima do fill.
                Positioned.fill(
                  child: CustomPaint(painter: _HexBorderPainter()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Path canônico do hexágono apontado nas laterais: pontas em 0%/100% no
/// eixo X (meio vertical) e recuo de 4% nas quinas de topo/base.
Path _hexPath(Size size) {
  final w = size.width;
  final h = size.height;
  const inset = 0.04; // 4%
  return Path()
    ..moveTo(w * inset, 0)
    ..lineTo(w * (1 - inset), 0)
    ..lineTo(w, h / 2)
    ..lineTo(w * (1 - inset), h)
    ..lineTo(w * inset, h)
    ..lineTo(0, h / 2)
    ..close();
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _hexPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.miter
      ..color = AppColors.goldLt.withValues(alpha: 0.85);
    canvas.drawPath(_hexPath(size), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
