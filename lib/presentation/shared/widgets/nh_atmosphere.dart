import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Atmosfera de fundo REUTILIZÁVEL (procedural) — base radial + glow no topo +
/// névoa em drift + faíscas douradas + vignette + grão. Sem silhueta (genérica),
/// tintável por [glow]/[base] pra cada tela. Mesma linguagem do
/// Santuário/Biblioteca/Mercado. Faíscas com speed inteiro (sem flick no loop).
class NhAtmosphere extends StatefulWidget {
  /// Cor do glow do topo + névoa (com alpha aplicado internamente).
  final Color glow;

  /// 3 cores da base radial (topo → meio → fundo).
  final List<Color> base;

  const NhAtmosphere({
    super.key,
    this.glow = AppColors.purple,
    this.base = const [Color(0xFF1A1226), Color(0xFF0D0A14), Color(0xFF070510)],
  });

  @override
  State<NhAtmosphere> createState() => _NhAtmosphereState();
}

class _NhAtmosphereState extends State<NhAtmosphere>
    with TickerProviderStateMixin {
  late final AnimationController _fog;
  late final AnimationController _embers;
  late final List<_Ember> _emberSpecs;

  @override
  void initState() {
    super.initState();
    _fog = AnimationController(
        vsync: this, duration: const Duration(seconds: 29))
      ..repeat();
    _embers = AnimationController(
        vsync: this, duration: const Duration(seconds: 13))
      ..repeat();
    final rnd = math.Random(13);
    _emberSpecs = List.generate(12, (_) {
      return _Ember(
        x: rnd.nextDouble(),
        size: 1.4 + rnd.nextDouble() * 1.4,
        phase: rnd.nextDouble(),
        speed: (rnd.nextInt(2) + 1).toDouble(),
        drift: (rnd.nextDouble() - 0.5) * 0.06,
      );
    });
  }

  @override
  void dispose() {
    _fog.dispose();
    _embers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.0),
              radius: 1.2,
              colors: widget.base,
              stops: const [0.0, 0.42, 0.82],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.95),
          child: Container(
            width: 520,
            height: 520,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.glow.withValues(alpha: 0.28),
                  widget.glow.withValues(alpha: 0.10),
                  widget.glow.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _fog,
            builder: (_, __) => CustomPaint(
                painter: _FogPainter(_fog.value, widget.glow),
                size: Size.infinite),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _embers,
            builder: (_, __) => CustomPaint(
              painter: _EmbersPainter(_embers.value, _emberSpecs),
              size: Size.infinite,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [Color(0x00000000), Color(0x8C000000)],
              stops: [0.55, 1.0],
            ),
          ),
        ),
        const RepaintBoundary(
          child: CustomPaint(painter: _GrainPainter(), size: Size.infinite),
        ),
      ],
    );
  }
}

class _Ember {
  final double x, size, phase, speed, drift;
  const _Ember({
    required this.x,
    required this.size,
    required this.phase,
    required this.speed,
    required this.drift,
  });
}

class _FogPainter extends CustomPainter {
  final double t;
  final Color color;
  const _FogPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final tau = t * 2 * math.pi;
    final dx = -70 + math.sin(tau) * 18;
    final dy = 150 + math.cos(tau) * 22;
    final rect = Rect.fromLTWH(dx, dy, 360, 260);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0.0)],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _FogPainter old) => old.t != t;
}

class _EmbersPainter extends CustomPainter {
  final double t;
  final List<_Ember> embers;
  const _EmbersPainter(this.t, this.embers);

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final e in embers) {
      final p = (t * e.speed + e.phase) % 1.0;
      const rise = 680.0;
      final y = size.height - p * rise;
      if (y < -10 || y > size.height + 10) continue;
      final x =
          e.x * size.width + math.sin(p * math.pi * 2) * e.drift * size.width;
      final alpha = math.sin(p * math.pi).clamp(0.0, 1.0);
      glow.color = AppColors.goldLt.withValues(alpha: 0.7 * alpha);
      canvas.drawCircle(Offset(x, y), e.size + 1.5, glow);
      final core = Paint()..color = AppColors.goldLt.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), e.size, core);
    }
  }

  @override
  bool shouldRepaint(covariant _EmbersPainter old) => old.t != t;
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(91);
    final paint = Paint()..blendMode = BlendMode.overlay;
    final count = (size.width * size.height / 1100).clamp(0, 1800).toInt();
    for (var i = 0; i < count; i++) {
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.05);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
