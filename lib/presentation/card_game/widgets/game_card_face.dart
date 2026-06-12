import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    this.effects = const <IconData>[],
    this.statusOverlay,
    this.minimal = false,
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

  /// Brasões de EFEITO (keywords) — pequenos círculos na borda esquerda que
  /// vazam ~40% pra fora, abaixo da bandeira de raridade.
  final List<IconData> effects;

  /// Camada de STATUS transitório (armadura/sangramento/veneno/doença/atordoar
  /// etc.) sobreposta no canto inferior-esquerdo da arte. null = sem status.
  final Widget? statusOverlay;

  /// MÍNIMO (preview da próxima carta): esconde custo, slot de item, brasões,
  /// bandeira de raridade e os pontos de conceito — só arte + nome, mais clean.
  final bool minimal;

  Color get _concept => conceptColor(concepts);

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
        // vazando ~40% pra fora.
        if (effects.isNotEmpty && !minimal)
          Positioned(
            top: 34,
            left: -7,
            child: Column(
              children: [
                for (final ic in effects.take(4)) _EffectCrest(icon: ic),
              ],
            ),
          ),
        if (!minimal)
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
  if (type == DamageType.corpoACorpo) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _SwordGlyph(Colors.white)),
    );
  }
  return Icon(damageTypeIcon(type), size: size, color: Colors.white);
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
  }
}

/// Descrição curta (1 linha) de cada keyword — usada na LEGENDA da partida
/// (glossário). Exaustivo: keyword nova quebra a compilação até descrever.
String keywordDescription(AbilityKeyword k) {
  switch (k) {
    case AbilityKeyword.provocar:
      return 'Atrai os ataques à distância/mágicos inimigos para si.';
    case AbilityKeyword.escudo:
      return 'Armadura inata: reduz o dano físico recebido.';
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
      return 'Reduz o dano físico E mágico recebido.';
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
  }
}

/// Brasões de efeito a partir das strings de habilidade de uma carta.
List<IconData> effectIconsFromAbilities(List<String> abilities) => abilities
    .map(abilityKeywordFromString)
    .whereType<AbilityKeyword>()
    .map(keywordIcon)
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
    chips.add(_StatusChip(Icons.science, AppColors.conceptChrysalis));
  }
  if (c.diseaseStacks > 0) {
    chips.add(_StatusChip(
        Icons.coronavirus, AppColors.purpleLight, '${c.diseaseStacks}'));
  }
  if (c.stunned) chips.add(_StatusChip(Icons.stars, AppColors.gold));
  if (c.entangled) chips.add(_StatusChip(Icons.hub, AppColors.conceptVita));
  if (c.desmoralizadoMelee > 0 || c.suprimidoMagico > 0) {
    chips.add(_StatusChip(Icons.trending_down, const Color(0xFFE08A4A)));
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

/// Glifo de ESPADA única (vertical, ponta pra cima) — ícone do ATK físico.
class _SwordGlyph extends CustomPainter {
  const _SwordGlyph(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = color
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round;
    final blade = Path()
      ..moveTo(cx, h * 0.04)
      ..lineTo(cx - w * 0.11, h * 0.20)
      ..lineTo(cx - w * 0.11, h * 0.60)
      ..lineTo(cx + w * 0.11, h * 0.60)
      ..lineTo(cx + w * 0.11, h * 0.20)
      ..close();
    canvas.drawPath(blade, fill);
    canvas.drawLine(Offset(w * 0.16, h * 0.63), Offset(w * 0.84, h * 0.63), line);
    canvas.drawLine(Offset(cx, h * 0.63), Offset(cx, h * 0.88), line);
    canvas.drawCircle(Offset(cx, h * 0.92), w * 0.09, fill);
  }

  @override
  bool shouldRepaint(covariant _SwordGlyph old) => old.color != color;
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
class _EffectCrest extends StatelessWidget {
  const _EffectCrest({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(bottom: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8C66A), Color(0xFF8A6A2A)],
        ),
        border: Border.all(color: const Color(0xFF1A140A), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 3)],
      ),
      child: Icon(icon, size: 10, color: Colors.white),
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
