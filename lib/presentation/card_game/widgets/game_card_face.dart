import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_game.dart';

/// Face de carta COMPARTILHADA do Modo Cartas — mesma DNA visual do card da
/// coleção (`_CardTile` em `library/widgets/library_cards_section.dart`): raio
/// 10, gradiente escuro, borda por conceito, área de arte com radial do
/// conceito + ícone, losango de custo (top-left), gema de raridade + nome, e um
/// rodapé customizável (stats da mão ou PV/keywords no tabuleiro).
///
/// Mantém o formato consistente entre coleção, mão e tabuleiro. O [footer] é um
/// slot: a mão passa ATK/PV; o tabuleiro passa PV atual + barra + keywords.
class GameCardFace extends StatelessWidget {
  const GameCardFace({
    super.key,
    required this.name,
    required this.cost,
    required this.concepts,
    required this.rarity,
    required this.artIcon,
    required this.footer,
    this.width,
    this.dimmed = false,
    this.selected = false,
    this.borderOverride,
    this.glowColor,
    this.cornerBadge,
  });

  final String name;
  final int cost;
  final List<CardConcept> concepts;
  final Rarity rarity;
  final IconData artIcon;

  /// Rodapé (stats). Mão: ATK/PV base. Tabuleiro: PV atual/máx + barra + kw.
  final Widget footer;

  final double? width;

  /// Não-jogável (cristais insuficientes / sem alvo): esmaece.
  final bool dimmed;

  /// Selecionada no fluxo de 2 toques.
  final bool selected;

  /// Sobrescreve a cor da borda (destaque de lane/alvo no tabuleiro).
  final Color? borderOverride;

  /// Brilho externo (selecionada / destaque).
  final Color? glowColor;

  /// Selo opcional no canto superior direito da arte (ex.: FLASH, ícone de tipo).
  final Widget? cornerBadge;

  Color get _concept => conceptColor(concepts);
  Color get _rarity => rarityColor(rarity);

  @override
  Widget build(BuildContext context) {
    final border = borderOverride ??
        (selected ? AppColors.purpleLight : _concept.withValues(alpha: 0.35));
    final glow = glowColor ??
        (selected ? AppColors.purpleGlow : _concept.withValues(alpha: 0.12));

    final card = Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF211A2E), Color(0xFF0B0810)],
        ),
        border: Border.all(
            color: border, width: (selected || borderOverride != null) ? 1.6 : 1),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: selected ? 10 : 8, spreadRadius: 1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Área de arte (radial do conceito + ícone + fade), custo e selo.
            Expanded(
              flex: 56,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.2),
                              radius: 0.9,
                              colors: [
                                _concept.withValues(alpha: 0.45),
                                const Color(0xFF0B0810),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(artIcon,
                              size: 34,
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.center,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x000B0810), Color(0xCC0B0810)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (concepts.length > 1)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Row(
                        children: [
                          for (final extra in concepts.skip(1))
                            Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: conceptColor(<CardConcept>[extra]),
                                  border: Border.all(
                                      color: const Color(0xCC0B0810), width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (cornerBadge != null)
                    Positioned(bottom: 3, right: 3, child: cornerBadge!),
                ],
              ),
            ),
            const SizedBox(height: 5),
            // Gema de raridade + nome.
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _rarity,
                    boxShadow: [
                      BoxShadow(
                          color: _rarity.withValues(alpha: 0.6), blurRadius: 5),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            footer,
          ],
        ),
      ),
    );

    // Custo no TOPO-CENTRO da carta, "metade pra fora / metade pra dentro"
    // (cravando na borda superior). Precisa de Clip.none nos pais (o tabuleiro
    // e o leque já usam) — fica sobre a borda, centralizado.
    final framed = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        card,
        Positioned(
          top: -12, // metade dos 24px do diamante acima da borda
          left: 0,
          right: 0,
          child: Center(child: _CostDiamond(cost)),
        ),
      ],
    );

    return dimmed ? Opacity(opacity: 0.42, child: framed) : framed;
  }
}

/// Mapa de conceito → cor (espelha o helper privado da coleção).
Color conceptColor(List<CardConcept> concepts) {
  if (concepts.isEmpty) return AppColors.conceptNeutro;
  switch (concepts.first) {
    case CardConcept.vitalismo:
      return AppColors.conceptVita;
    case CardConcept.neutro:
      return AppColors.conceptNeutro;
    case CardConcept.chrysalis:
      return AppColors.conceptChrysalis;
    case CardConcept.celestial:
      return AppColors.conceptCelestial;
    case CardConcept.magico:
      return AppColors.conceptMagico;
    case CardConcept.corrompido:
      return AppColors.conceptCorrompido;
  }
}

Color rarityColor(Rarity r) {
  switch (r) {
    case Rarity.comum:
      return AppColors.cardComum;
    case Rarity.rara:
      return AppColors.cardRara;
    case Rarity.epica:
      return AppColors.cardEpica;
    case Rarity.lendaria:
      return AppColors.cardLendaria;
    case Rarity.elite:
      return AppColors.cardElite;
  }
}

/// Ícone de arte por tipo de dano (placeholder consistente da arte da carta).
IconData damageTypeIcon(DamageType t) {
  switch (t) {
    case DamageType.corpoACorpo:
      return Icons.sports_martial_arts;
    case DamageType.aDistancia:
      return Icons.gps_fixed;
    case DamageType.magico:
      return Icons.auto_fix_high;
    case DamageType.vitalismo:
      return Icons.flare;
    case DamageType.cura:
      return Icons.healing;
  }
}

/// Cor do tipo de dano — pra diferenciar de relance no card (CEO 2026-06-10:
/// "todas mostram espada, não dá pra distinguir mágico/arqueiro"). Aplicada no
/// ícone + número de ATK do rodapé.
Color damageTypeColor(DamageType t) {
  switch (t) {
    case DamageType.corpoACorpo:
      return AppColors.hp; // vermelho — golpe físico
    case DamageType.aDistancia:
      return AppColors.gold; // dourado — flecha
    case DamageType.magico:
      return AppColors.conceptMagico; // azul/ciano — magia
    case DamageType.vitalismo:
      return AppColors.purple; // roxo — vitalismo (verdadeiro)
    case DamageType.cura:
      return AppColors.conceptChrysalis; // verde — cura
  }
}

/// Losango de custo (top-left) — idêntico ao da coleção.
class _CostDiamond extends StatelessWidget {
  const _CostDiamond(this.cost);
  final int cost;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _DiamondClipper(),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A8CFF), Color(0xFF3A4FAE)],
          ),
        ),
        child: Text('$cost',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

class _DiamondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
