import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.2 Etapa 1.3.B — barra de progresso animada estilo LoL.
///
/// 3 camadas (em ordem): background flat, fill com gradient horizontal
/// (darken → cor → lighten) animado em ~400ms ease-out cubic, e shimmer
/// loop infinito (~2.5s) cruzando da esquerda pra direita com fade nas
/// pontas.
///
/// Uso: substitui `LinearProgressIndicator` em `daily_sub_task_row.dart`
/// e `daily_quests_header.dart`. Cada instância mantém seu próprio
/// `AnimationController` pro shimmer (dispose automático).
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

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.cornerRadius = 4,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtl;

  @override
  void initState() {
    super.initState();
    _shimmerCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: target),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (_, fill, __) => AnimatedBuilder(
          animation: _shimmerCtl,
          builder: (_, __) => CustomPaint(
            painter: _ProgressPainter(
              fill: fill,
              shimmer: _shimmerCtl.value,
              color: widget.color,
            ),
            size: Size(double.infinity, widget.height),
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double fill;
  final double shimmer;
  final Color color;

  _ProgressPainter({
    required this.fill,
    required this.shimmer,
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
    final shimmerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x4DFFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.5, 1.0],
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
      old.fill != fill || old.shimmer != shimmer || old.color != color;
}
