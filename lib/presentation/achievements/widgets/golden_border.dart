import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.3 Etapa Final-B — borda dourada com brilho intenso pra
/// conquistas LENDÁRIAS topo-absoluto (tier `lendaria_boost_10`).
///
/// 7 conquistas qualificam: VOL_MITO_DISCIPLINA, STREAK_SOL_NEGRO,
/// BEST_ECO_SOL_NEGRO, PERF_GEOMETRIA_SAGRADA, SUPERPERF_EXCEDENTE_ETERNO,
/// NOFAIL_PACTO_ETERNO, BEST_LEMBRANCA_FORNALHA (subset).
///
/// Diferença vs [RainbowBorder]: estática (sem animação). Pulso sutil
/// via leve glow externo. Reservada pra lendárias normais (não-secretas)
/// — secretas têm rainbow.
class GoldenBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadiusGeometry borderRadius;
  final Color surfaceColor;

  const GoldenBorder({
    super.key,
    required this.child,
    required this.surfaceColor,
    this.borderWidth = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold,
            Color(0xFFFFE680),
            AppColors.gold,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.all(
            Radius.circular(_innerRadius()),
          ),
        ),
        child: child,
      ),
    );
  }

  double _innerRadius() {
    final br = borderRadius;
    if (br is BorderRadius) {
      return (br.topLeft.x - borderWidth).clamp(0.0, double.infinity);
    }
    return 10.0;
  }
}
