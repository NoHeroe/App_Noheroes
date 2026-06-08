import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/asset_loader.dart';

/// Restyle Santuário (mockup v3) — card da Sombra com sigil roxo
/// "respirando" (breathe). Estado + quote reais (`shadowState` +
/// `AssetLoader.getShadowPhrase`) preservados.
class ShadowStatusCard extends ConsumerStatefulWidget {
  const ShadowStatusCard({super.key});

  static String _labelFor(String state) => switch (state) {
        'unstable' => 'Instável',
        'chaotic' => 'Caótica',
        'abyssal' => 'Abissal',
        'ascending' => 'Ascendente',
        _ => 'Estável',
      };

  @override
  ConsumerState<ShadowStatusCard> createState() => _ShadowStatusCardState();
}

class _ShadowStatusCardState extends ConsumerState<ShadowStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);
    final state = player?.shadowState ?? 'stable';
    final label = ShadowStatusCard._labelFor(state);

    return FutureBuilder<String>(
      future: AssetLoader.getShadowPhrase(state),
      initialData: '...',
      builder: (context, snapshot) {
        final phrase = snapshot.data ?? '...';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x991E1430), Color(0xD90D0B14)],
            ),
            border:
                Border.all(color: AppColors.purple.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.purpleGlow45.withValues(alpha: 0.18),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _breathe,
                  builder: (_, __) => CustomPaint(
                    size: const Size(78, 78),
                    painter: _SigilPainter(_breathe.value),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUA SOMBRA',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        letterSpacing: 3,
                        color: AppColors.txtMut,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purpleLt,
                        shadows: const [
                          Shadow(
                            color: AppColors.purpleGlow45,
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phrase,
                      style: GoogleFonts.roboto(
                        fontSize: 15.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.txt2,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SigilPainter extends CustomPainter {
  final double t; // 0..1 breathe
  const _SigilPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rOuter = size.width / 2 - 2;

    // Halo radial roxo (pulsa com breathe)
    final haloAlpha = 0.10 + t * 0.16;
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.purple.withValues(alpha: haloAlpha),
          AppColors.purple.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: rOuter))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(c, rOuter, halo);

    // Anel externo tracejado
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.purple.withValues(alpha: 0.55);
    const dashes = 28;
    for (var i = 0; i < dashes; i++) {
      final a0 = (i / dashes) * 2 * math.pi;
      final a1 = a0 + (2 * math.pi / dashes) * 0.5;
      final p0 = c + Offset(math.cos(a0), math.sin(a0)) * rOuter;
      final p1 = c + Offset(math.cos(a1), math.sin(a1)) * rOuter;
      canvas.drawLine(p0, p1, dashPaint);
    }

    // Anel interno sólido
    final innerR = rOuter - 12;
    final solid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.purple.withValues(alpha: 0.7);
    canvas.drawCircle(c, innerR, solid);

    // Core 22px (radial) com glow pulsante
    const coreR = 11.0;
    final coreGlow = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + t * 6)
      ..color = AppColors.purpleLt.withValues(alpha: 0.5 + t * 0.3);
    canvas.drawCircle(c, coreR + 4, coreGlow);
    final core = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFCDB0FF), Color(0xFF6A23C9)],
      ).createShader(Rect.fromCircle(center: c, radius: coreR));
    canvas.drawCircle(c, coreR, core);
  }

  @override
  bool shouldRepaint(covariant _SigilPainter old) => old.t != t;
}
