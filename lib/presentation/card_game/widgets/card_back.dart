import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Costa (verso) de uma carta — proporção TRAVADA em 142:206 (a mesma da face),
/// então a arte do CEO (`assets/images/card_game/card_back.png`) aparece SEMPRE
/// inteira, sem corte nem distorção, em qualquer tamanho/tela. Enquanto a imagem
/// não existir, mostra um placeholder estilo NoHeroes (gradiente escuro + emblema).
///
/// Usada na mão do OPONENTE (mostra a contagem sem revelar as cartas) e em
/// qualquer lugar que precise de uma carta virada.
class CardBack extends StatelessWidget {
  const CardBack({super.key, this.width, this.height, this.radius = 10});

  /// Proporção nativa da carta (largura:altura).
  static const double kAspect = 142 / 206;

  static const String _asset = 'assets/images/card_game/card_back.png';

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        _asset,
        fit: BoxFit.cover,
        // Sem a arte ainda: placeholder. Quando o CEO soltar card_back.png na
        // pasta, ele aparece automaticamente (mesma proporção → sem corte).
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );

    if (height != null) {
      return SizedBox(height: height, width: height! * kAspect, child: card);
    }
    if (width != null) {
      return SizedBox(width: width, height: width! / kAspect, child: card);
    }
    return AspectRatio(aspectRatio: kAspect, child: card);
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderViolet, width: 1.2),
        gradient: const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.95,
          colors: [Color(0xFF2A1B40), Color(0xFF160C22), Color(0xFF0A0610)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.62,
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.purpleLight.withValues(alpha: 0.5),
                    width: 1.4),
                gradient: RadialGradient(colors: [
                  AppColors.purple.withValues(alpha: 0.30),
                  Colors.transparent,
                ]),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'NH',
                    style: GoogleFonts.cinzelDecorative(
                      color: AppColors.purpleLight.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
