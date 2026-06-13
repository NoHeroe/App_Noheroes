import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Camada de POEIRA MÁGICA dourada (ADR-0028 / CEO 2026-06-12): partículas bem
/// finas e sutis, vindas de todos os lados de forma equilibrada, pra dar um
/// leve movimento "mágico" ao tabuleiro. Loop SEM emenda (deriva em nº inteiro
/// de telas por ciclo → posição igual no início e no fim). Não intercepta toques.
class MagicDustOverlay extends StatefulWidget {
  const MagicDustOverlay({
    super.key,
    this.count = 14,
    this.color = const Color(0xFFE7C766),
    this.active = true,
  });

  final int count;
  final Color color;

  /// Quando `false`, o controller PARA (não tica 60fps) e o overlay some — pra
  /// não gastar frame no replay de combate, quando os VFX pesam (CEO 2026-06-13).
  final bool active;

  @override
  State<MagicDustOverlay> createState() => _MagicDustOverlayState();
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.nx,
    required this.ny,
    required this.size,
    required this.opacity,
    required this.phase,
    required this.twinkle,
  });

  final double x; // posição base 0..1
  final double y;
  final double nx; // nº inteiro de telas/ciclo (direção+velocidade)
  final double ny;
  final double size; // raio px (fino)
  final double opacity; // opacidade base (sutil)
  final double phase; // fase do cintilar
  final double twinkle; // ciclos de cintilar por loop (inteiro)
}

class _MagicDustOverlayState extends State<MagicDustOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _ps;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    _ps = List.generate(widget.count, (_) {
      var nx = r.nextInt(3) - 1; // -1, 0, 1
      var ny = r.nextInt(3) - 1;
      if (nx == 0 && ny == 0) nx = 1; // garante movimento
      // alguns mais rápidos (2 telas/ciclo) pra variar
      if (r.nextDouble() < 0.25) nx *= 2;
      if (r.nextDouble() < 0.25) ny *= 2;
      return _Particle(
        x: r.nextDouble(),
        y: r.nextDouble(),
        nx: nx.toDouble(),
        ny: ny.toDouble(),
        size: 0.6 + r.nextDouble() * 1.5,
        opacity: 0.08 + r.nextDouble() * 0.22,
        phase: r.nextDouble() * math.pi * 2,
        twinkle: (2 + r.nextInt(4)).toDouble(),
      );
    });
    // Ciclo longo = deriva lenta. Só roda quando ATIVO (fora do combate).
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 70));
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(MagicDustOverlay old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _DustPainter(_ps, _c.value, widget.color),
          ),
        ),
      ),
    );
  }
}

class _DustPainter extends CustomPainter {
  _DustPainter(this.ps, this.t, this.color);

  final List<_Particle> ps;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // SEM MaskFilter.blur (CEO 2026-06-13): o blur por partícula POR FRAME era o
    // maior custo de GPU da tela (40 passes de blur/frame). Pontos finos crisp +
    // contagem reduzida (14) dão o mesmo clima por uma fração do custo.
    final paint = Paint();
    for (final p in ps) {
      final px = ((p.x + p.nx * t) % 1.0) * size.width;
      final py = ((p.y + p.ny * t) % 1.0) * size.height;
      final tw =
          0.4 + 0.6 * (0.5 + 0.5 * math.sin(p.phase + t * 2 * math.pi * p.twinkle));
      paint.color = color.withValues(alpha: (p.opacity * tw).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter old) => old.t != t;
}
