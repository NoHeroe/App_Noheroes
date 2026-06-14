import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    this.itemIcon,
    this.showItemSlot = false,
    this.effects = const <EffectBadge>[],
    this.debuffs = const <CardGlyph>[],
    this.statusOverlay,
    this.minimal = false,
    this.showCost = true,
    this.glowByConcept = false,
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

  /// Ícone do ITEM equipado (mostrado no pentágono inferior). null = slot vazio.
  final IconData? itemIcon;

  /// Mostra o slot de item (pentágono) cravado na borda inferior.
  final bool showItemSlot;

  /// Brasões de EFEITO (keywords) — pequenos círculos ROXOS na borda esquerda
  /// que vazam ~40% pra fora, abaixo da bandeira de raridade. + habilidades =
  /// + brasões. Cada um carrega a MAGNITUDE (mostra o número se > 1).
  final List<EffectBadge> effects;

  /// DEBUFFS (status negativos) — bolinhas VERMELHAS no TOPO-DIREITA (ao lado do
  /// cristal de custo). + debuffs = + bolinhas (CEO 2026-06-13).
  final List<CardGlyph> debuffs;

  /// Camada de STATUS transitório (armadura/sangramento/veneno/doença/atordoar
  /// etc.) sobreposta no canto inferior-esquerdo da arte. null = sem status.
  final Widget? statusOverlay;

  /// MÍNIMO (preview da próxima carta): esconde custo, slot de item, brasões,
  /// bandeira de raridade e os pontos de conceito — só arte + nome, mais clean.
  final bool minimal;

  /// Exibe o cristal de custo no topo. false = cartas sem custo (ex.: heróis).
  final bool showCost;

  /// Glow na cor do CONCEITO (não da raridade) e bem SUAVE — usado nas cartas
  /// IN-GAME (tabuleiro/mão). Coleção/pacotes mantêm o brilho de raridade.
  final bool glowByConcept;

  Color get _concept => conceptColor(concepts);

  @override
  Widget build(BuildContext context) {
    // Destaque por RARIDADE (CEO 2026-06-12): épica/lendária/elite ganham borda
    // e brilho na cor da raridade (na exibição e na revelação).
    final rarCol = switch (rarity) {
      Rarity.comum => AppColors.cardComum,
      Rarity.rara => AppColors.cardRara,
      Rarity.epica => AppColors.cardEpica,
      Rarity.lendaria => AppColors.cardLendaria,
      Rarity.elite => AppColors.cardElite,
    };
    final isHigh = rarity == Rarity.epica ||
        rarity == Rarity.lendaria ||
        rarity == Rarity.elite;
    final border = borderOverride ??
        (selected
            ? AppColors.purpleLight
            : isHigh
                ? rarCol.withValues(alpha: 0.75)
                : _concept.withValues(alpha: 0.35));
    // IN-GAME (glowByConcept): glow SUAVE na cor do CONCEITO, ignorando a
    // raridade (CEO 2026-06-13: "o glow reflete o conceito e bem mais fraco").
    // Selecionada ainda pulsa roxo.
    final weakGlow = glowByConcept && !selected;
    final glow = glowColor ??
        (selected
            ? AppColors.purpleGlow
            : weakGlow
                ? _concept.withValues(alpha: 0.13)
                : isHigh
                    ? rarCol.withValues(alpha: 0.5)
                    : _concept.withValues(alpha: 0.12));

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
            color: border,
            width: (selected || borderOverride != null || isHigh) ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
              color: glow,
              blurRadius: (selected || isHigh) ? 12 : 8,
              spreadRadius: isHigh ? 1.5 : 1),
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
                  // Nome no TOPO da carta — SEM contorno/caixa, centralizado e
                  // completo (até 2 linhas, espaçamento apertado). Fica logo
                  // abaixo do alcance do cristal de custo (topo-centro). Sombra
                  // suave garante legibilidade sobre a arte. (Raridade =
                  // bandeira na borda esquerda.)
                  Positioned(
                    top: 13,
                    left: 14,
                    right: 14,
                    child: Text(
                      name,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 6.5,
                        height: 1.04,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        shadows: const [
                          Shadow(
                              color: Color(0xCC000000),
                              blurRadius: 3,
                              offset: Offset(0, 1)),
                          Shadow(color: Color(0x99000000), blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                  if (concepts.length > 1 && !minimal)
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
                  if (statusOverlay != null && !minimal)
                    Positioned(bottom: 3, left: 3, child: statusOverlay!),
                ],
              ),
            ),
            // Nome migrou pro TOPO da arte (overlay); aqui fica só o rodapé.
            const SizedBox(height: 6),
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
        // Bandeira de RARIDADE pendurada rente ao TOPO, na borda esquerda
        // (mini banner virado pra baixo, sem estourar). Lendária = RGB animado.
        // Mostrada também no preview (minimal) — faz parte da identidade da carta.
        Positioned(top: 0, left: 3, child: _RarityPennant(rarity: rarity)),
        // Brasões de EFEITO (keywords) na borda esquerda, abaixo da bandeira,
        // vazando ~40% pra fora. SEM teto (CEO 2026-06-13): mostra TODAS as
        // habilidades da carta — antes `take(4)` escondia a 5ª+ ("cartas não
        // mostravam todos os atributos"). Mesmo design nos 4 contextos.
        if (effects.isNotEmpty && !minimal)
          Positioned(
            top: 34,
            left: -7,
            child: Column(
              children: [
                for (final g in effects) _EffectCrest(badge: g),
              ],
            ),
          ),
        // Debuffs (bolinhas vermelhas) no topo-direita, ao lado do custo.
        if (debuffs.isNotEmpty && !minimal)
          Positioned(
            top: 2,
            right: -7,
            child: Column(
              children: [
                for (final g in debuffs) _DebuffCrest(glyph: g),
              ],
            ),
          ),
        if (!minimal && showCost)
          Positioned(
            top: -12, // metade dos 24px do diamante acima da borda
            left: 0,
            right: 0,
            child: Center(child: CrystalGem(value: cost)),
          ),
        // Slot de ITEM (pentágono) cravado na borda INFERIOR-centro.
        if (showItemSlot && !minimal)
          Positioned(
            bottom: -14,
            left: 0,
            right: 0,
            child: Center(child: _PentagonSlot(icon: itemIcon)),
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

/// Um glifo de carta que pode ser um ícone SVG profissional (game-icons.net,
/// monocromático e tingível) OU um [IconData] do Material como fallback.
/// [build] renderiza: SVG tingido via ColorFilter(srcIn), ou Icon colorido.
/// Toda keyword/tipo sem SVG mapeado degrada para o Material sem quebrar.
class CardGlyph {
  const CardGlyph({this.svg, required this.fallback});

  /// Caminho do asset SVG (game-icons.net) ou null → usa o [fallback].
  final String? svg;
  final IconData fallback;

  Widget build({required double size, required Color color}) {
    final s = svg;
    if (s != null) {
      return SvgPicture.asset(
        s,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(fallback, size: size, color: color);
  }
}

/// Brasão de EFEITO com MAGNITUDE: o glifo + a quantidade do buff (ex.: Espinhos
/// 3). O número só aparece quando `count > 1` — sinalização sutil (CEO 2026-06-13).
class EffectBadge {
  const EffectBadge(this.glyph, [this.count = 1]);
  final CardGlyph glyph;
  final int count;
}

/// Ícones RPG profissionais (game-icons.net, CC BY 3.0). Monocromáticos →
/// tingidos por cor em runtime. Crédito vai na tela de Créditos do app.
const String _kRpgBase = 'assets/icons/rpg';

/// Caminho do SVG RPG de cada tipo de dano.
String? damageTypeSvg(DamageType t) {
  switch (t) {
    case DamageType.corpoACorpo:
      return '$_kRpgBase/crossed-swords.svg';
    case DamageType.aDistancia:
      return '$_kRpgBase/high-shot.svg';
    case DamageType.magico:
      return '$_kRpgBase/magic-swirl.svg';
    case DamageType.vitalismo:
      return '$_kRpgBase/sun-radiations.svg';
    case DamageType.cura:
      return '$_kRpgBase/healing.svg';
  }
}

/// Glifo (SVG RPG + fallback Material) de um tipo de dano.
CardGlyph damageTypeGlyph(DamageType t) =>
    CardGlyph(svg: damageTypeSvg(t), fallback: damageTypeIcon(t));

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

/// Glifo do tipo de dano em BRANCO (físico = espada custom; demais = ícone
/// Material). Compartilhado entre a PARTIDA e a COLEÇÃO pra manter o mesmo
/// visual de carta.
Widget typeGlyph(DamageType type, {double size = 12}) {
  return damageTypeGlyph(type).build(size: size, color: Colors.white);
}

/// Ícone (brasão) de uma keyword de habilidade.
IconData keywordIcon(AbilityKeyword k) {
  switch (k) {
    case AbilityKeyword.provocar:
      return Icons.campaign;
    case AbilityKeyword.escudo:
      return Icons.shield;
    case AbilityKeyword.voo:
      return Icons.flight;
    case AbilityKeyword.ataqueDuplo:
      return Icons.fast_forward;
    case AbilityKeyword.alcance:
      return Icons.open_in_full;
    case AbilityKeyword.inspirar:
      return Icons.upgrade;
    case AbilityKeyword.pisotear:
      return Icons.south;
    case AbilityKeyword.silencio:
      return Icons.volume_off;
    case AbilityKeyword.furtividade:
      return Icons.visibility_off;
    case AbilityKeyword.cristalDeDrenagem:
      return Icons.diamond;
    case AbilityKeyword.rouboDePv:
      return Icons.bloodtype;
    case AbilityKeyword.investida:
      return Icons.bolt;
    // Lote 2 (defensivas).
    case AbilityKeyword.espinhos:
      return Icons.grass;
    case AbilityKeyword.escudoEspelhado:
      return Icons.flip;
    case AbilityKeyword.escudoSagrado:
      return Icons.health_and_safety;
    case AbilityKeyword.contraAtaque:
      return Icons.replay;
    case AbilityKeyword.reflexoMagico:
      return Icons.flare;
    case AbilityKeyword.inabalavel:
      return Icons.anchor;
    // Lote 3a (status / DoT).
    case AbilityKeyword.sangramento:
      return Icons.water_drop;
    case AbilityKeyword.veneno:
      return Icons.science;
    case AbilityKeyword.atordoar:
      return Icons.stars;
    case AbilityKeyword.enredar:
      return Icons.hub;
    // Lote 3b (auras / combo).
    case AbilityKeyword.desmoralizar:
      return Icons.trending_down;
    case AbilityKeyword.suprimirMagia:
      return Icons.auto_fix_off;
    case AbilityKeyword.doenca:
      return Icons.coronavirus;
    case AbilityKeyword.surto:
      return Icons.whatshot;
    // Lote 5 (exóticas).
    case AbilityKeyword.andorinha:
      return Icons.flutter_dash;
    case AbilityKeyword.crescimento:
      return Icons.trending_up;
    case AbilityKeyword.mimico:
      return Icons.content_copy;
    case AbilityKeyword.zumbi:
      return Icons.sentiment_very_dissatisfied;
    case AbilityKeyword.ressurreicao:
      return Icons.autorenew;
    case AbilityKeyword.transformar:
      return Icons.change_circle;
    // Lote 6 (imunidades / utilidades).
    case AbilityKeyword.imunidade:
      return Icons.verified_user;
    case AbilityKeyword.perseveranca:
      return Icons.fitness_center;
    case AbilityKeyword.vigilante:
      return Icons.remove_red_eye;
    case AbilityKeyword.furia:
      return Icons.local_fire_department;
    case AbilityKeyword.encantarArmadura:
      return Icons.add_moderator;
    case AbilityKeyword.cristalAdicional:
      return Icons.diamond_outlined;
    // Lote 7.
    case AbilityKeyword.espinhoDeEscudo:
      return Icons.shield_outlined;
    case AbilityKeyword.nevoa:
      return Icons.cloud;
    case AbilityKeyword.antiAereo:
      return Icons.airline_stops;
    case AbilityKeyword.quebraArmadura:
      return Icons.heart_broken;
    case AbilityKeyword.explosaoMagica:
      return Icons.bubble_chart;
    case AbilityKeyword.nevoaToxica:
      return Icons.cloud_queue;
    case AbilityKeyword.esquiva:
      return Icons.directions_run;
    // Skills novas (docx 2026-06-12).
    case AbilityKeyword.recuo:
      return Icons.keyboard_return;
    case AbilityKeyword.percepcao:
      return Icons.visibility;
    case AbilityKeyword.executor:
      return Icons.dangerous;
    case AbilityKeyword.cura:
      return Icons.healing;
  }
}

/// Caminho do SVG RPG (game-icons.net) de cada keyword. Exaustivo: keyword nova
/// quebra a compilação até ter um ícone (ou degrada se eu retornar null aqui).
String? keywordSvg(AbilityKeyword k) {
  String p(String n) => '$_kRpgBase/$n.svg';
  switch (k) {
    case AbilityKeyword.provocar:
      return p('shouting');
    case AbilityKeyword.escudo:
      return p('checked-shield');
    case AbilityKeyword.voo:
      return p('feathered-wing');
    case AbilityKeyword.ataqueDuplo:
      return p('sword-array');
    case AbilityKeyword.alcance:
      return p('spear-hook');
    case AbilityKeyword.inspirar:
      return p('rally-the-troops');
    case AbilityKeyword.pisotear:
      return p('boot-stomp');
    case AbilityKeyword.silencio:
      return p('silence');
    case AbilityKeyword.furtividade:
      return p('hooded-figure');
    case AbilityKeyword.cristalDeDrenagem:
      return p('crystal-cluster');
    case AbilityKeyword.rouboDePv:
      return p('vampire-dracula');
    case AbilityKeyword.investida:
      return p('charging-bull');
    case AbilityKeyword.espinhos:
      return p('thorn-helix');
    case AbilityKeyword.escudoEspelhado:
      return p('shield-reflect');
    case AbilityKeyword.escudoSagrado:
      return p('healing-shield');
    case AbilityKeyword.contraAtaque:
      return p('sword-clash');
    case AbilityKeyword.reflexoMagico:
      return p('mirror-mirror');
    case AbilityKeyword.inabalavel:
      return p('stone-tower');
    case AbilityKeyword.sangramento:
      return p('bleeding-wound');
    case AbilityKeyword.veneno:
      return p('poison-bottle');
    case AbilityKeyword.atordoar:
      return p('knockout');
    case AbilityKeyword.enredar:
      return p('curling-vines');
    case AbilityKeyword.desmoralizar:
      return p('despair');
    case AbilityKeyword.suprimirMagia:
      return p('cancel');
    case AbilityKeyword.doenca:
      return p('virus');
    case AbilityKeyword.surto:
      return p('biohazard');
    case AbilityKeyword.andorinha:
      return p('swallow');
    case AbilityKeyword.crescimento:
      return p('growth');
    case AbilityKeyword.mimico:
      return p('mimic-chest');
    case AbilityKeyword.zumbi:
      return p('shambling-zombie');
    case AbilityKeyword.ressurreicao:
      return p('angel-wings');
    case AbilityKeyword.transformar:
      return p('transform');
    case AbilityKeyword.imunidade:
      return p('spiked-halo');
    case AbilityKeyword.perseveranca:
      return p('muscle-up');
    case AbilityKeyword.vigilante:
      return p('eye-target');
    case AbilityKeyword.furia:
      return p('enrage');
    case AbilityKeyword.encantarArmadura:
      return p('armor-upgrade');
    case AbilityKeyword.cristalAdicional:
      return p('cut-diamond');
    case AbilityKeyword.espinhoDeEscudo:
      return p('spiked-shield');
    case AbilityKeyword.nevoa:
      return p('fog');
    case AbilityKeyword.antiAereo:
      return p('missile-swarm');
    case AbilityKeyword.quebraArmadura:
      return p('broken-shield');
    case AbilityKeyword.explosaoMagica:
      return p('sparkles');
    case AbilityKeyword.nevoaToxica:
      return p('poison-cloud');
    case AbilityKeyword.esquiva:
      return p('dodging');
    case AbilityKeyword.recuo:
      return p('return-arrow');
    case AbilityKeyword.percepcao:
      return p('all-seeing-eye');
    case AbilityKeyword.executor:
      return p('guillotine');
    case AbilityKeyword.cura:
      return p('healing');
  }
}

/// Glifo (SVG RPG + fallback Material) de uma keyword.
CardGlyph keywordGlyph(AbilityKeyword k) =>
    CardGlyph(svg: keywordSvg(k), fallback: keywordIcon(k));

/// Descrição curta (1 linha) de cada keyword — usada na LEGENDA da partida
/// (glossário). Exaustivo: keyword nova quebra a compilação até descrever.
String keywordDescription(AbilityKeyword k) {
  switch (k) {
    case AbilityKeyword.provocar:
      return 'Atrai os ataques à distância/mágicos inimigos para si.';
    case AbilityKeyword.escudo:
      return 'Armadura inata: pool que absorve o dano físico (desgasta).';
    case AbilityKeyword.voo:
      return 'Evade ataques (50% melee / 25% à distância) de quem não voa.';
    case AbilityKeyword.ataqueDuplo:
      return 'Acerto melee da frente dá dano verdadeiro extra na retaguarda.';
    case AbilityKeyword.alcance:
      return 'Pode atacar corpo a corpo mesmo da retaguarda.';
    case AbilityKeyword.inspirar:
      return 'No início do turno, aliados ganham +ataque corpo a corpo.';
    case AbilityKeyword.pisotear:
      return 'Dano físico excedente transborda para a próxima criatura.';
    case AbilityKeyword.silencio:
      return 'Enquanto viva, inimigos não usam ataque mágico nem cura.';
    case AbilityKeyword.furtividade:
      return 'Na retaguarda, não pode ser alvo de à distância/mágico.';
    case AbilityKeyword.cristalDeDrenagem:
      return 'Ao destruir uma criatura, +1 cristal no próximo turno.';
    case AbilityKeyword.rouboDePv:
      return 'Ao acertar um ataque, ganha +PV atual e máximo.';
    case AbilityKeyword.investida:
      return 'No início do turno, +ataque melee até a rodada do oponente.';
    case AbilityKeyword.espinhos:
      return 'Ao ser atingida por melee, causa dano verdadeiro ao atacante.';
    case AbilityKeyword.escudoEspelhado:
      return 'Reduz o dano mágico recebido (armadura mágica).';
    case AbilityKeyword.escudoSagrado:
      return 'Absorve dano físico (pool de armadura) e reduz o mágico.';
    case AbilityKeyword.contraAtaque:
      return 'Ao ser atingida por melee, 50% de revidar com seu ataque.';
    case AbilityKeyword.reflexoMagico:
      return 'Ignora o dano mágico e o devolve ao atacante (loop se ambos têm).';
    case AbilityKeyword.inabalavel:
      return 'Se fosse destruída, ressuscita com vida cheia (1×/partida).';
    case AbilityKeyword.sangramento:
      return 'Acerto físico aplica dano/turno acumulável (decai sozinho).';
    case AbilityKeyword.veneno:
      return 'Ao acertar, 1 de dano/turno permanente (cura remove).';
    case AbilityKeyword.atordoar:
      return 'Acerto melee faz o alvo pular o próximo ataque (tem cooldown).';
    case AbilityKeyword.enredar:
      return 'Ao acertar alvo com Voo, tira o Voo e o prende por 1 turno.';
    case AbilityKeyword.desmoralizar:
      return 'No início do turno, reduz o ataque melee dos inimigos.';
    case AbilityKeyword.suprimirMagia:
      return 'No início do turno, reduz o ataque mágico dos inimigos.';
    case AbilityKeyword.doenca:
      return 'Ao acertar, adoece o alvo (perde Inspirar/Desmoralizar).';
    case AbilityKeyword.surto:
      return 'Ao acertar alvo doente, remove a doença e reduz o PV máximo.';
    case AbilityKeyword.andorinha:
      return 'Ao destruir uma criatura, +ataque e +PV máximo permanentes.';
    case AbilityKeyword.crescimento:
      return 'Após ser curada, +ataque e +PV máximo permanentes.';
    case AbilityKeyword.mimico:
      return 'Ao entrar em jogo, copia stats e habilidades de outra criatura.';
    case AbilityKeyword.zumbi:
      return 'Ao morrer, volta enfraquecida para a mão (1×).';
    case AbilityKeyword.ressurreicao:
      return 'Se fosse destruída, ressuscita com PV reduzido (1×/partida).';
    case AbilityKeyword.transformar:
      return 'Com o PV baixo, ativa a 2ª forma (cura + bônus de ataque/PV).';
    case AbilityKeyword.imunidade:
      return 'Imune a Desmoralizar, Suprimir Magia e Silêncio.';
    case AbilityKeyword.perseveranca:
      return 'Imune a Doença, Enredar, Silêncio, Desmoralizar e Suprimir Magia.';
    case AbilityKeyword.vigilante:
      return 'Imune a Contra-Ataque, Espinhos e Enredar.';
    case AbilityKeyword.furia:
      return '+ataque melee igual ao PV que falta (PV máximo − atual).';
    case AbilityKeyword.encantarArmadura:
      return 'Se já tem armadura, ganha +1 de armadura.';
    case AbilityKeyword.cristalAdicional:
      return 'Ao ser sacrificada, gera +1 cristal.';
    case AbilityKeyword.espinhoDeEscudo:
      return 'Ao sofrer qualquer dano, devolve dano à fonte.';
    case AbilityKeyword.nevoa:
      return 'Após sofrer dano, o próximo golpe é prevenido.';
    case AbilityKeyword.antiAereo:
      return 'Ignora o Voo do alvo e causa dano extra a quem voa.';
    case AbilityKeyword.quebraArmadura:
      return 'Causa dano extra a alvos com armadura.';
    case AbilityKeyword.explosaoMagica:
      return 'Dano mágico excedente transborda na próxima criatura.';
    case AbilityKeyword.nevoaToxica:
      return 'No início do turno, adoece todos os inimigos.';
    case AbilityKeyword.esquiva:
      return 'Evade qualquer tipo de ataque (chance).';
    case AbilityKeyword.recuo:
      return 'Volta uma criatura aliada da retaguarda para a mão.';
    case AbilityKeyword.percepcao:
      return 'Revela e mira criaturas Furtivas (ignora a Furtividade).';
    case AbilityKeyword.executor:
      return 'Ao acertar, destrói o alvo se ele ficar com PV muito baixo.';
    case AbilityKeyword.cura:
      return 'Faz uma ação de cura no aliado mais ferido (ou em si).';
  }
}

/// Brasões de efeito (glifo + magnitude) a partir das strings de habilidade da
/// carta. A magnitude vem do número na string (ex.: "espinhos_3" → 3); sem
/// número = 1 (não mostra contador). CEO 2026-06-13.
List<EffectBadge> effectGlyphsFromAbilities(List<String> abilities) {
  final out = <EffectBadge>[];
  for (final a in abilities) {
    final k = abilityKeywordFromString(a);
    if (k == null) continue;
    out.add(EffectBadge(keywordGlyph(k), abilityMagnitude(a) ?? 1));
  }
  return out;
}

/// Brasões de efeito de uma criatura EM JOGO: usa a magnitude EFETIVA (carta +
/// relíquias) via `keywordValue`. CEO 2026-06-13.
List<EffectBadge> effectBadgesForCreature(CreatureInPlay c) => c.keywords
    .map((k) => EffectBadge(keywordGlyph(k), c.keywordValue(k, 1)))
    .toList();

/// Camada de STATUS transitório de uma criatura no tabuleiro: armadura (física
/// e mágica), DoT (sangramento/veneno), doença, atordoamento/enredamento e
/// debuffs de aura (Desmoralizar/Suprimir). Retorna null se não há nada ativo —
/// aí a carta fica limpa. Empilha chips pequenos no canto inferior-esquerdo.
Widget? buildCardStatusOverlay(CreatureInPlay c) {
  final chips = <Widget>[];
  if (c.armor > 0) {
    chips.add(_StatusChip(Icons.shield, const Color(0xFF9FB4D8), '${c.armor}'));
  }
  if (c.magicArmor > 0) {
    chips.add(_StatusChip(
        Icons.auto_awesome, AppColors.conceptMagico, '${c.magicArmor}'));
  }
  if (c.bleedStacks > 0) {
    chips.add(_StatusChip(Icons.water_drop, AppColors.hp, '${c.bleedStacks}'));
  }
  if (c.poisoned) {
    chips.add(const _StatusChip(Icons.science, AppColors.conceptChrysalis));
  }
  if (c.diseaseStacks > 0) {
    chips.add(_StatusChip(
        Icons.coronavirus, AppColors.purpleLight, '${c.diseaseStacks}'));
  }
  if (c.stunned) chips.add(const _StatusChip(Icons.stars, AppColors.gold));
  if (c.entangled) {
    chips.add(const _StatusChip(Icons.hub, AppColors.conceptVita));
  }
  if (c.desmoralizadoMelee > 0 || c.suprimidoMagico > 0) {
    chips.add(const _StatusChip(Icons.trending_down, Color(0xFFE08A4A)));
  }
  if (chips.isEmpty) return null;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: chips,
  );
}

/// Chip minúsculo de status: ícone colorido + número opcional, sobre fundo
/// escuro translúcido. Usado por [buildCardStatusOverlay].
class _StatusChip extends StatelessWidget {
  const _StatusChip(this.icon, this.color, [this.text]);
  final IconData icon;
  final Color color;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          if (text != null) ...[
            const SizedBox(width: 1),
            Text(text!,
                style: GoogleFonts.robotoMono(
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ],
      ),
    );
  }
}


/// Cristal facetado com um número (custo da carta OU contador de cristais do
/// HUD). `size` escala tudo. Mesma DNA visual nos dois usos (pedido do CEO).
class CrystalGem extends StatelessWidget {
  const CrystalGem({super.key, required this.value, this.size = 24});
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: _DiamondClipper(),
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                // Gradiente com profundidade (claro→médio→escuro).
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9DB6FF),
                    Color(0xFF5E80F0),
                    Color(0xFF2E3F92)
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(
                      child: CustomPaint(painter: _CrystalFacets())),
                  Text('$value',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: size * 0.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Color(0xAA1A2050), blurRadius: 2)
                          ])),
                ],
              ),
            ),
          ),
          // Borda do cristal (contorno do losango).
          const Positioned.fill(
              child: CustomPaint(painter: _DiamondBorder())),
        ],
      ),
    );
  }
}

/// Contorno (borda) do losango do cristal — claro, fica metade visível sobre a
/// borda do clip.
class _DiamondBorder extends CustomPainter {
  const _DiamondBorder();
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = s.width * 0.06
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _DiamondBorder old) => false;
}

/// Facetas internas do cristal de custo: arestas do centro aos 4 vértices +
/// uma faceta superior mais clara (brilho). Dá "cara de cristal lapidado" sem
/// mudar a forma/tamanho do diamante.
class _CrystalFacets extends CustomPainter {
  const _CrystalFacets();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final c = Offset(w / 2, h / 2);
    final top = Offset(w / 2, 0);
    final right = Offset(w, h / 2);
    final bottom = Offset(w / 2, h);
    final left = Offset(0, h / 2);

    // Faceta superior-esquerda mais clara (brilho do topo).
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.20);
    canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(c.dx, c.dy)
          ..close(),
        shine);
    // Faceta inferior-direita mais escura (sombra).
    final shade = Paint()..color = const Color(0x33000022);
    canvas.drawPath(
        Path()
          ..moveTo(bottom.dx, bottom.dy)
          ..lineTo(right.dx, right.dy)
          ..lineTo(c.dx, c.dy)
          ..close(),
        shade);

    // Arestas das facetas (centro → vértices).
    final edge = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(c, top, edge);
    canvas.drawLine(c, right, edge);
    canvas.drawLine(c, bottom, edge);
    canvas.drawLine(c, left, edge);
  }

  @override
  bool shouldRepaint(covariant _CrystalFacets old) => false;
}

/// Brasão redondo de EFEITO (keyword) — pequeno, dourado, ícone branco.
/// Brasão de HABILIDADE (esquerda) — círculo ROXO com ícone branco (CEO
/// 2026-06-13: era dourado).
class _EffectCrest extends StatelessWidget {
  const _EffectCrest({required this.badge});
  final EffectBadge badge;

  @override
  Widget build(BuildContext context) {
    Widget crest = Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB07BE8), Color(0xFF5A2E8A)],
        ),
        border: Border.all(color: const Color(0xFF120A1E), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 3)],
      ),
      child: badge.glyph.build(size: 10, color: Colors.white),
    );
    // MAGNITUDE > 1 (CEO 2026-06-13): pílula pequena com o número no canto inf-dir
    // — sinalização sutil de "quantos" daquele buff (ex.: Espinhos 3).
    if (badge.count > 1) {
      crest = Stack(
        clipBehavior: Clip.none,
        children: [
          crest,
          Positioned(
            right: -3,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0F2B),
                borderRadius: BorderRadius.circular(5),
                border:
                    Border.all(color: const Color(0xFFB07BE8), width: 0.6),
              ),
              child: Text(
                '${badge.count}',
                style: const TextStyle(
                  fontSize: 7,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEBDBFF),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 3), child: crest);
  }
}

/// Bolinha de DEBUFF (direita, topo) — círculo VERMELHO com ícone branco.
class _DebuffCrest extends StatelessWidget {
  const _DebuffCrest({required this.glyph});
  final CardGlyph glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(bottom: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE86A6A), Color(0xFF8A2424)],
        ),
        border: Border.all(color: const Color(0xFF1E0A0A), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 3)],
      ),
      child: glyph.build(size: 9, color: Colors.white),
    );
  }
}

/// Slot de ITEM em PENTÁGONO (apontando pra baixo) com borda DUPLA. Mostra o
/// ícone do item equipado no meio (ou vazio).
class _PentagonSlot extends StatelessWidget {
  const _PentagonSlot({this.icon});
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PentagonPainter(filled: icon != null),
        child: Center(
          child: icon == null
              ? null
              : Icon(icon, size: 13, color: Colors.white),
        ),
      ),
    );
  }
}

class _PentagonPainter extends CustomPainter {
  _PentagonPainter({required this.filled});
  final bool filled;

  /// Pentágono apontando pra baixo; [inset] lerpa os vértices rumo ao centro
  /// (0 = externo, 0.28 = borda interna), sem Matrix4.
  Path _path(Size s, [double inset = 0]) {
    final w = s.width, h = s.height;
    final c = Offset(w / 2, h / 2);
    Offset v(double x, double y) => Offset.lerp(Offset(x, y), c, inset)!;
    final a = v(0, 0),
        b = v(w, 0),
        d = v(w, h * 0.58),
        e = v(w / 2, h),
        f = v(0, h * 0.58);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(d.dx, d.dy)
      ..lineTo(e.dx, e.dy)
      ..lineTo(f.dx, f.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size s) {
    final path = _path(s);
    canvas.drawPath(
        path,
        Paint()
          ..color = filled ? const Color(0xEE2A2140) : const Color(0xCC15101E)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFE8C66A)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke);
    // Borda interna (dupla).
    canvas.drawPath(
        _path(s, 0.28),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _PentagonPainter old) => old.filled != filled;
}

/// Bandeira de raridade pendurada na borda esquerda (mini banner virado pra
/// baixo). Lendária = RGB animado (hue cíclico).
class _RarityPennant extends StatelessWidget {
  const _RarityPennant({required this.rarity});
  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    if (rarity == Rarity.lendaria) {
      return const SizedBox(width: 12, height: 28)
          .animate(onPlay: (c) => c.repeat())
          .custom(
            duration: 2600.ms,
            builder: (context, value, _) => _banner(
                HSVColor.fromAHSV(1, (value * 360) % 360, 0.85, 1).toColor()),
          );
    }
    return _banner(rarityColor(rarity));
  }

  Widget _banner(Color color) {
    return ClipPath(
      clipper: _PennantClipper(),
      child: Container(
        width: 12,
        height: 28,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.white, 0.35)!,
              color,
              Color.lerp(color, Colors.black, 0.25)!,
            ],
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
          ],
        ),
      ),
    );
  }
}

class _PennantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    const notch = 6.0, tlr = 6.0;
    // Base PONTUDA (notch central em V, cantos inferiores afiados) + canto
    // SUPERIOR-ESQUERDO arredondado (segue a curvatura da carta).
    return Path()
      ..moveTo(tlr, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - notch)
      ..lineTo(0, h)
      ..lineTo(0, tlr)
      ..quadraticBezierTo(0, 0, tlr, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
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
