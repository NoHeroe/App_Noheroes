import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Atmosfera do Mercado — mesma linguagem do Santuário/Biblioteca, mas com
/// paleta QUENTE de bazar à luz de lanterna: radial âmbar→preto + dois glows
/// de lanterna que tremulam (esq/dir) + névoa quente + silhueta de barracas
/// (toldos + caixotes) + faíscas douradas + vignette + grão. Painters animados
/// em [RepaintBoundary]; silhueta/grão estáticos.
class MarketAtmosphere extends StatefulWidget {
  const MarketAtmosphere({super.key});

  @override
  State<MarketAtmosphere> createState() => _MarketAtmosphereState();
}

class _MarketAtmosphereState extends State<MarketAtmosphere>
    with TickerProviderStateMixin {
  late final AnimationController _fog;
  late final AnimationController _embers;
  late final AnimationController _flicker;
  late final List<_Ember> _emberSpecs;

  @override
  void initState() {
    super.initState();
    _fog = AnimationController(
        vsync: this, duration: const Duration(seconds: 28))
      ..repeat();
    _embers = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _flicker = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    final rnd = math.Random(7);
    _emberSpecs = List.generate(16, (_) {
      return _Ember(
        x: rnd.nextDouble(),
        size: 1.4 + rnd.nextDouble() * 1.6,
        phase: rnd.nextDouble(),
        speed: 0.5 + rnd.nextDouble() * 0.9,
        drift: (rnd.nextDouble() - 0.5) * 0.07,
      );
    });
  }

  @override
  void dispose() {
    _fog.dispose();
    _embers.dispose();
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base radial quente (âmbar profundo → marrom → quase preto).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.9),
              radius: 1.25,
              colors: [
                Color(0xFF2A1B12),
                Color(0xFF1A1008),
                Color(0xFF0A0705),
              ],
              stops: [0.0, 0.45, 0.82],
            ),
          ),
        ),
        // Dois glows de LANTERNA que tremulam (cantos superiores).
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _flicker,
            builder: (_, __) {
              final f = 0.82 + _flicker.value * 0.18;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _lanternGlow(const Alignment(-0.78, -0.82), 300, f),
                  _lanternGlow(const Alignment(0.82, -0.66), 260, 1.62 - f),
                ],
              );
            },
          ),
        ),
        // Névoa quente sutil.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _fog,
            builder: (_, __) => CustomPaint(
                painter: _FogPainter(_fog.value), size: Size.infinite),
          ),
        ),
        // Silhueta de barracas de mercado (toldos + caixotes).
        const RepaintBoundary(
          child: CustomPaint(painter: _StallsPainter(), size: Size.infinite),
        ),
        // Faíscas (embers) douradas subindo.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _embers,
            builder: (_, __) => CustomPaint(
              painter: _EmbersPainter(_embers.value, _emberSpecs),
              size: Size.infinite,
            ),
          ),
        ),
        // Vignette.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [Color(0x00000000), Color(0x99000000)],
              stops: [0.52, 1.0],
            ),
          ),
        ),
        // Grão procedural (estático).
        const RepaintBoundary(
          child: CustomPaint(painter: _GrainPainter(), size: Size.infinite),
        ),
      ],
    );
  }

  Widget _lanternGlow(Alignment align, double diameter, double intensity) {
    final a = intensity.clamp(0.0, 1.0);
    return Align(
      alignment: align,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFFFB347).withValues(alpha: 0.30 * a),
              const Color(0xFFFF8A3D).withValues(alpha: 0.10 * a),
              const Color(0x00FF8A3D),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _Ember {
  final double x;
  final double size;
  final double phase;
  final double speed;
  final double drift;
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
  const _FogPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final tau = t * 2 * math.pi;
    final aDx = -60 + math.sin(tau) * 18;
    final aDy = 160 + math.cos(tau) * 24;
    final aRect = Rect.fromLTWH(aDx, aDy, 380, 280);
    final aPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD9883A).withValues(alpha: 0.30),
          const Color(0x00D9883A),
        ],
      ).createShader(aRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawOval(aRect, aPaint);
  }

  @override
  bool shouldRepaint(covariant _FogPainter old) => old.t != t;
}

/// Barracas de mercado: fileira de toldos triangulares + caixotes, silhueta
/// escura ancorada embaixo (lugar das estantes da Biblioteca).
class _StallsPainter extends CustomPainter {
  const _StallsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = h * 0.80; // linha do chão das barracas
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF241710), Color(0xFF0A0705)],
      ).createShader(Rect.fromLTWH(0, base - 90, w, h - (base - 90)));

    final rnd = math.Random(31); // seedado — silhueta estável
    var x = -20.0;
    while (x < w + 20) {
      final stallW = 70.0 + rnd.nextDouble() * 50;
      final awningH = 26.0 + rnd.nextDouble() * 14;
      final postH = 54.0 + rnd.nextDouble() * 26;
      final top = base - postH - awningH;

      // Postes
      canvas.drawRect(
          Rect.fromLTWH(x + 3, base - postH, 4, postH), fill);
      canvas.drawRect(
          Rect.fromLTWH(x + stallW - 7, base - postH, 4, postH), fill);
      // Tábua/balcão
      canvas.drawRect(
          Rect.fromLTWH(x, base - 14, stallW, 6), fill);

      // Toldo triangular (zigue-zague nas pontas pra dar cara de tecido)
      final awning = Path()
        ..moveTo(x - 6, top + awningH)
        ..lineTo(x + stallW * 0.5, top)
        ..lineTo(x + stallW + 6, top + awningH);
      // bainha serrilhada
      final teeth = ((stallW + 12) / 12).floor();
      for (var i = teeth; i >= 0; i--) {
        final tx = (x - 6) + (i / teeth) * (stallW + 12);
        awning.lineTo(tx, top + awningH + (i.isEven ? 7 : 0));
      }
      awning.close();
      canvas.drawPath(awning, fill);

      x += stallW + (6 + rnd.nextDouble() * 18);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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
      const rise = 700.0;
      final y = size.height - p * rise;
      if (y < -10 || y > size.height + 10) continue;
      final x =
          e.x * size.width + math.sin(p * math.pi * 2) * e.drift * size.width;
      final alpha = (math.sin(p * math.pi)).clamp(0.0, 1.0);
      const amber = Color(0xFFFFB347);
      glow.color = amber.withValues(alpha: 0.7 * alpha);
      canvas.drawCircle(Offset(x, y), e.size + 1.5, glow);
      final core = Paint()..color = amber.withValues(alpha: alpha);
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
    final rnd = math.Random(57);
    final paint = Paint()..blendMode = BlendMode.overlay;
    final count = (size.width * size.height / 900).clamp(0, 2200).toInt();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.05);
      canvas.drawCircle(Offset(x, y), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
