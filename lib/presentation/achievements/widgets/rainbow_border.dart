import 'package:flutter/material.dart';

/// Sprint 3.3 Etapa Final-B — borda animada com gradient arco-íris em
/// movimento (estilo LED running light). Reservada pra:
///   - Conquistas SECRETAS desbloqueadas (Estado E na tela
///     `/achievements`) — borda permanente mesmo após coleta
///   - Popup de unlock de conquistas secretas
///
/// Implementação: `LinearGradient` cujo `transform: GradientRotation`
/// roda em loop infinito (~3s período). Container envoltório com fundo
/// gradient + child interno com `surfaceColor` cria efeito de borda
/// gradiente. Performance: `RepaintBoundary` no caller pra isolar
/// repaint do widget animado em listas longas.
class RainbowBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadiusGeometry borderRadius;
  final Color surfaceColor;
  final Duration period;

  const RainbowBorder({
    super.key,
    required this.child,
    required this.surfaceColor,
    this.borderWidth = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.period = const Duration(seconds: 3),
  });

  @override
  State<RainbowBorder> createState() => _RainbowBorderState();
}

class _RainbowBorderState extends State<RainbowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _colors = <Color>[
    Color(0xFFFF3B30), // red
    Color(0xFFFF9500), // orange
    Color(0xFFFFCC00), // yellow
    Color(0xFF34C759), // green
    Color(0xFF00C7BE), // teal
    Color(0xFF007AFF), // blue
    Color(0xFFAF52DE), // purple
    Color(0xFFFF3B30), // red (loop close)
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Rotação de gradient ao longo do controller (0..1 → 0..2π).
        final angle = _ctrl.value * 6.28318530718; // 2*pi
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: _colors,
              transform: GradientRotation(angle),
            ),
          ),
          padding: EdgeInsets.all(widget.borderWidth),
          child: Container(
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: BorderRadius.all(
                Radius.circular(_innerRadius()),
              ),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }

  double _innerRadius() {
    final br = widget.borderRadius;
    if (br is BorderRadius) {
      return (br.topLeft.x - widget.borderWidth)
          .clamp(0.0, double.infinity);
    }
    return 10.0;
  }
}
