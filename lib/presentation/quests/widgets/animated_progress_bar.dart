import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'progress_particles.dart';

/// Sprint 3.2 Etapa 1.3.B + 1.3.C — barra de progresso animada estilo LoL.
///
/// 4 camadas (em ordem):
/// 1. Background flat (`AppColors.surfaceAlt`).
/// 2. Fill com gradient horizontal `[darken15(color), color, lighten10(color)]`
///    animado em ~600ms `easeOutCubic`.
/// 3. Shimmer band branca translúcida cruzando da esquerda pra direita em
///    loop ~4s `easeInOutSine`, com alpha pulsando entre 40% e 55% num
///    ciclo independente de 3s `repeat reverse`.
/// 4. Partículas (opcional) saindo da extremidade da barra preenchida.
///
/// Modo glow (`showGlow: true`) adiciona boxShadow externo pulsando 30%↔50%
/// no mesmo ciclo do pulse — sinaliza visualmente sub-tarefa que atingiu
/// alvo enquanto missão segue pending.
class AnimatedProgressBar extends StatefulWidget {
  /// Valor de preenchimento. Aceita > 1.0 (excedência) — display é
  /// clampado pra 0..1.
  final double value;

  /// Cor base do preenchimento. Gradient é derivado dela.
  final Color color;

  /// Altura da barra (ex: 6 sub, 5 header).
  final double height;

  /// Raio dos cantos. Default 4.
  final double cornerRadius;

  /// Mostra glow externo pulsando — usado quando sub completa pending.
  final bool showGlow;

  /// Habilita as partículas saindo da ponta. Default true.
  final bool showParticles;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.cornerRadius = 4,
    this.showGlow = false,
    this.showParticles = true,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerCtl;
  late final AnimationController _pulseCtl;
  final ValueNotifier<int> _burstSignal = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _shimmerCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    // Burst de partículas quando o valor muda (jogador clicou +1/+10).
    if (old.value != widget.value && widget.showParticles) {
      _burstSignal.value++;
    }
  }

  @override
  void dispose() {
    _shimmerCtl.dispose();
    _pulseCtl.dispose();
    _burstSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0);
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: target),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, fill, __) => AnimatedBuilder(
          animation: Listenable.merge([_shimmerCtl, _pulseCtl]),
          builder: (_, __) => CustomPaint(
            painter: _ProgressPainter(
              fill: fill,
              shimmer: Curves.easeInOutSine.transform(_shimmerCtl.value),
              shimmerAlpha:
                  Tween<double>(begin: 0.40, end: 0.55).evaluate(_pulseCtl),
              color: widget.color,
            ),
            size: Size(double.infinity, widget.height),
          ),
        ),
      ),
    );

    final particles = widget.showParticles
        ? ProgressParticles(
            value: target,
            color: widget.color,
            burstSignal: _burstSignal,
          )
        : null;

    final stacked = particles == null
        ? bar
        : Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [bar, particles],
          );

    if (!widget.showGlow) return stacked;

    return AnimatedBuilder(
      animation: _pulseCtl,
      builder: (_, __) {
        final glowAlpha =
            Tween<double>(begin: 0.30, end: 0.50).evaluate(_pulseCtl);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.cornerRadius),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: glowAlpha),
                blurRadius: 8,
              ),
            ],
          ),
          child: stacked,
        );
      },
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double fill;
  final double shimmer;
  final double shimmerAlpha;
  final Color color;

  _ProgressPainter({
    required this.fill,
    required this.shimmer,
    required this.shimmerAlpha,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1) Background.
    final bgPaint = Paint()..color = AppColors.surfaceAlt;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    if (fill <= 0) return;

    final fillW = w * fill;
    final fillRect = Rect.fromLTWH(0, 0, fillW, h);

    // 2) Fill com gradient (darken → cor → lighten).
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _adjustLightness(color, -0.15),
          color,
          _adjustLightness(color, 0.10),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(fillRect);
    canvas.drawRect(fillRect, fillPaint);

    // 3) Shimmer band — banda branca translúcida cruzando.
    canvas.save();
    canvas.clipRect(fillRect);
    final bandWidth = w * 0.4;
    final bandX = (shimmer * (w + bandWidth)) - bandWidth;
    final bandRect = Rect.fromLTWH(bandX, 0, bandWidth, h);
    final centerAlphaByte =
        (shimmerAlpha.clamp(0.0, 1.0) * 255).round();
    final centerColor =
        Color.fromARGB(centerAlphaByte, 0xFF, 0xFF, 0xFF);
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0x00FFFFFF),
          centerColor,
          const Color(0x00FFFFFF),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bandRect);
    canvas.drawRect(bandRect, shimmerPaint);
    canvas.restore();
  }

  Color _adjustLightness(Color c, double delta) {
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.fill != fill ||
      old.shimmer != shimmer ||
      old.shimmerAlpha != shimmerAlpha ||
      old.color != color;
}
