import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../settings/settings_provider.dart';

/// Bloco 1 do restyle do Santuário (mockup v3).
///
/// Camadas atmosféricas empilhadas. Os painters animados (névoa, faíscas)
/// ficam em [RepaintBoundary] pra isolar repaint. Grão e colunas são
/// estáticos (seedados — nunca regeram por frame).
///
/// Respeita o toggle global `backgroundAnimationsProvider` (Configurações):
/// OFF = controllers parados + camadas animadas não montadas (só estáticas).
class SanctuaryAtmosphere extends ConsumerStatefulWidget {
  const SanctuaryAtmosphere({super.key});

  @override
  ConsumerState<SanctuaryAtmosphere> createState() =>
      _SanctuaryAtmosphereState();
}

class _SanctuaryAtmosphereState extends ConsumerState<SanctuaryAtmosphere>
    with TickerProviderStateMixin {
  late final AnimationController _fog;
  late final AnimationController _embers;

  // Faíscas seedadas uma vez (não regerar por frame).
  late final List<_Ember> _emberSpecs;

  @override
  void initState() {
    super.initState();
    _fog = AnimationController(
        vsync: this, duration: const Duration(seconds: 28))
      ..repeat();
    _embers = AnimationController(
        vsync: this, duration: const Duration(seconds: 13))
      ..repeat();
    final rnd = math.Random(7);
    _emberSpecs = List.generate(14, (_) {
      return _Ember(
        x: rnd.nextDouble(),
        size: 1.5 + rnd.nextDouble() * 1.5,
        phase: rnd.nextDouble(),
        // Inteiro (1 ou 2 subidas por ciclo) — sem flick no reinício do loop.
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
    // Toggle global (Configurações). OFF = só camadas estáticas + controllers
    // parados (alívio de performance).
    final animate = ref.watch(backgroundAnimationsProvider);
    if (animate) {
      if (!_fog.isAnimating) _fog.repeat();
      if (!_embers.isAnimating) _embers.repeat();
    } else {
      _fog.stop();
      _embers.stop();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base radial
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

        // 2. Glow roxo no topo
        Align(
          alignment: const Alignment(0, -0.95),
          child: Container(
            width: 560,
            height: 560,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x4D8B3DFF), // .30
                  Color(0x1F8B3DFF), // .12
                  Color(0x008B3DFF), // transparent
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // 3. Névoa (A roxa + B vermelha) — drift lento (animada → gated)
        if (animate)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _fog,
              builder: (_, __) => CustomPaint(
                  painter: _FogPainter(_fog.value), size: Size.infinite),
            ),
          ),

        // 4. Colunas góticas (estático)
        const RepaintBoundary(
          child: CustomPaint(painter: _ColumnsPainter(), size: Size.infinite),
        ),

        // 5. Faíscas (embers) — animada → gated
        if (animate)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _embers,
              builder: (_, __) => CustomPaint(
                painter: _EmbersPainter(_embers.value, _emberSpecs),
                size: Size.infinite,
              ),
            ),
          ),

        // 6. Vignette
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

        // 7. Grão procedural (estático, BlendMode.overlay)
        const RepaintBoundary(
          child: CustomPaint(painter: _GrainPainter(), size: Size.infinite),
        ),
      ],
    );
  }
}

class _Ember {
  final double x; // 0..1 horizontal
  final double size;
  final double phase; // offset 0..1 no ciclo
  final double speed; // fração extra
  final double drift; // deslize horizontal
  const _Ember({
    required this.x,
    required this.size,
    required this.phase,
    required this.speed,
    required this.drift,
  });
}

class _FogPainter extends CustomPainter {
  final double t; // 0..1
  const _FogPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final tau = t * 2 * math.pi;

    // Fog A — roxa, drift descendente lento
    final aDx = -90 + math.sin(tau) * 18;
    final aDy = 120 + math.cos(tau) * 24;
    final aRect = Rect.fromLTWH(aDx, aDy, 380, 280);
    final aPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.purple.withValues(alpha: 0.5),
          AppColors.purple.withValues(alpha: 0.0),
        ],
      ).createShader(aRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48)
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5);
    canvas.drawOval(aRect, aPaint);

    // Fog B — vermelha, drift reverso
    final bDx = size.width - 100 + math.sin(-tau + 1.2) * 20;
    final bDy = 340 + math.cos(-tau + 1.2) * 26;
    final bRect = Rect.fromLTWH(bDx - 340, bDy, 340, 260);
    final bPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x529D1F29), // rgba(157,31,41,.32)
          Color(0x009D1F29),
        ],
      ).createShader(bRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
    canvas.drawOval(bRect, bPaint);
  }

  @override
  bool shouldRepaint(covariant _FogPainter old) => old.t != t;
}

class _ColumnsPainter extends CustomPainter {
  const _ColumnsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final top = h * 0.38; // colunas ocupam ~62% de baixo
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1D1630), Color(0xFF0A0710)],
      ).createShader(Rect.fromLTWH(0, top, w, h - top))
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5);

    // 3 colunas com arco gótico de cada lado, silhueta ancorada embaixo.
    const colW = 46.0;
    final xs = [w * 0.10, w * 0.5 - colW / 2, w * 0.90 - colW];
    for (final x in xs) {
      final path = Path()
        ..moveTo(x, h)
        ..lineTo(x, top + 40)
        // capitel em arco apontado
        ..quadraticBezierTo(x + colW / 2, top - 18, x + colW, top + 40)
        ..lineTo(x + colW, h)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Arco central ligando (silhueta de santuário)
    final arch = Path()
      ..moveTo(w * 0.10 + colW, top + 50)
      ..quadraticBezierTo(w * 0.5, top - 40, w * 0.90 - colW + colW, top + 50);
    final archPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = const Color(0xFF1D1630).withValues(alpha: 0.5);
    canvas.drawPath(arch, archPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _EmbersPainter extends CustomPainter {
  final double t; // 0..1
  final List<_Ember> embers;
  const _EmbersPainter(this.t, this.embers);

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final e in embers) {
      // progresso individual com fase + velocidade, sobe ~680px
      var p = (t * e.speed + e.phase) % 1.0;
      const rise = 680.0;
      final y = size.height - p * rise;
      if (y < -10 || y > size.height + 10) continue;
      final x = e.x * size.width + math.sin(p * math.pi * 2) * e.drift * size.width;
      // fade nas pontas
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
