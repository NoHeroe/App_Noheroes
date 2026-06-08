import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Atmosfera da Biblioteca (Fatia 2 / ajuste) — mesma linguagem do
/// Santuário: radial roxo→preto + glow topo + névoa + **faíscas (embers)**
/// + **silhueta de estantes** (no lugar dos arcos góticos) + vignette +
/// grão. Painters animados em [RepaintBoundary]; estantes/grão estáticos.
class LibraryAtmosphere extends StatefulWidget {
  const LibraryAtmosphere({super.key});

  @override
  State<LibraryAtmosphere> createState() => _LibraryAtmosphereState();
}

class _LibraryAtmosphereState extends State<LibraryAtmosphere>
    with TickerProviderStateMixin {
  late final AnimationController _fog;
  late final AnimationController _embers;
  late final List<_Ember> _emberSpecs;

  @override
  void initState() {
    super.initState();
    _fog = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
    _embers = AnimationController(
        vsync: this, duration: const Duration(seconds: 13))
      ..repeat();
    final rnd = math.Random(11);
    _emberSpecs = List.generate(14, (_) {
      return _Ember(
        x: rnd.nextDouble(),
        size: 1.5 + rnd.nextDouble() * 1.5,
        phase: rnd.nextDouble(),
        speed: 0.55 + rnd.nextDouble() * 0.9,
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
        // Base radial
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -1.0),
              radius: 1.2,
              colors: [
                Color(0xFF1A1226),
                Color(0xFF0D0A14),
                AppColors.blackVeil,
              ],
              stops: [0.0, 0.42, 0.78],
            ),
          ),
        ),
        // Glow roxo no topo
        Align(
          alignment: const Alignment(0, -0.95),
          child: Container(
            width: 520,
            height: 520,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x3D8B3DFF),
                  Color(0x148B3DFF),
                  Color(0x008B3DFF),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Névoa sutil
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _fog,
            builder: (_, __) => CustomPaint(
                painter: _FogPainter(_fog.value), size: Size.infinite),
          ),
        ),
        // Silhueta de estantes (lugar dos arcos góticos do Santuário)
        const RepaintBoundary(
          child: CustomPaint(painter: _ShelvesPainter(), size: Size.infinite),
        ),
        // Faíscas (embers)
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _embers,
            builder: (_, __) => CustomPaint(
              painter: _EmbersPainter(_embers.value, _emberSpecs),
              size: Size.infinite,
            ),
          ),
        ),
        // Vignette
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
        // Grão procedural (estático)
        const RepaintBoundary(
          child: CustomPaint(painter: _GrainPainter(), size: Size.infinite),
        ),
      ],
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
    final aDx = -80 + math.sin(tau) * 16;
    final aDy = 140 + math.cos(tau) * 22;
    final aRect = Rect.fromLTWH(aDx, aDy, 360, 260);
    final aPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.purple.withValues(alpha: 0.4),
          AppColors.purple.withValues(alpha: 0.0),
        ],
      ).createShader(aRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
    canvas.drawOval(aRect, aPaint);
  }

  @override
  bool shouldRepaint(covariant _FogPainter old) => old.t != t;
}

/// Estantes de biblioteca: 3 prateleiras horizontais com lombadas de livros
/// (retângulos verticais variados), silhueta escura ancorada embaixo.
class _ShelvesPainter extends CustomPainter {
  const _ShelvesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = h * 0.42; // ~58% de baixo
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1D1630), Color(0xFF0A0710)],
      ).createShader(Rect.fromLTWH(0, top, w, h - top))
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5);

    const shelves = 3;
    final shelfH = (h - top) / shelves;
    final rnd = math.Random(23); // seedado — silhueta estável

    for (var s = 0; s < shelves; s++) {
      final shelfTop = top + s * shelfH;
      // Tábua da prateleira
      final plank = Rect.fromLTWH(0, shelfTop + shelfH - 6, w, 5);
      canvas.drawRect(plank, fill);

      // Lombadas de livros (retângulos verticais variados)
      var x = rnd.nextDouble() * 10;
      while (x < w - 6) {
        final bw = 8.0 + rnd.nextDouble() * 16; // largura da lombada
        final bh = shelfH * (0.5 + rnd.nextDouble() * 0.42); // altura
        final by = shelfTop + (shelfH - 6) - bh;
        final book = Rect.fromLTWH(x, by, bw, bh);
        canvas.drawRect(book, fill);
        x += bw + (1.5 + rnd.nextDouble() * 3); // gap entre livros
      }
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
      const rise = 680.0;
      final y = size.height - p * rise;
      if (y < -10 || y > size.height + 10) continue;
      final x =
          e.x * size.width + math.sin(p * math.pi * 2) * e.drift * size.width;
      final alpha = (math.sin(p * math.pi)).clamp(0.0, 1.0);
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
    final rnd = math.Random(99);
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
