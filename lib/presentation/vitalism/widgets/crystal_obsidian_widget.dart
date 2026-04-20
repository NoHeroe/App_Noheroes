import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

// Monolito de obsidiana envolto por dragão — altar permanente do vitalismo.
// Ver [[vitalismos_unicos#O Cristal de Obsidiana do Dragão]].
//
// Escopo desta sprint (1.2): widget visual + tap callback.
// O dragão é placeholder textual/iconográfico — refinamento visual fica pra
// Fase 5 (Polimento) quando houver asset (lottie ou custom painter avançado).
class CrystalObsidianWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final double height;
  final bool pulsing;

  const CrystalObsidianWidget({
    super.key,
    this.onTap,
    this.height = 220,
    this.pulsing = true,
  });

  @override
  Widget build(BuildContext context) {
    final crystal = SizedBox(
      width: height * 0.55,
      height: height,
      child: CustomPaint(
        painter: _CrystalPainter(),
        child: Center(
          child: Icon(
            Icons.pets, // placeholder: dragão enroscado (TODO asset)
            color: AppColors.purpleLight.withValues(alpha: 0.85),
            size: height * 0.28,
          ),
        ),
      ),
    );

    final wrapped = pulsing
        ? (crystal
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.97, 0.97),
              end: const Offset(1.03, 1.03),
              duration: 2200.ms,
              curve: Curves.easeInOut,
            )
            .shimmer(
              duration: 2400.ms,
              color: AppColors.purpleGlow,
            ))
        : crystal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(onTap: onTap, child: wrapped),
        const SizedBox(height: 12),
        Text(
          'CRISTAL DE OBSIDIANA',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 10,
            color: AppColors.purpleLight,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'do Dragão',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 10,
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _CrystalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Losango elongado (monolito vertical)
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h * 0.30)
      ..lineTo(w, h * 0.72)
      ..lineTo(w / 2, h)
      ..lineTo(0, h * 0.72)
      ..lineTo(0, h * 0.30)
      ..close();

    // Fill obsidiana com gradiente vertical
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0B0A14),
          AppColors.shadowVoid,
          Color(0xFF050509),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fill);

    // Borda roxa brilhante
    final border = Paint()
      ..color = AppColors.purpleLight.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, border);

    // Glow interno
    final glow = Paint()
      ..color = AppColors.purpleGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
    canvas.drawPath(path, glow);

    // Faceta central (linhas verticais sutis)
    final facet = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), facet);
    canvas.drawLine(Offset(w * 0.25, h * 0.15), Offset(w * 0.25, h * 0.85), facet);
    canvas.drawLine(Offset(w * 0.75, h * 0.15), Offset(w * 0.75, h * 0.85), facet);
  }

  @override
  bool shouldRepaint(_) => false;
}
