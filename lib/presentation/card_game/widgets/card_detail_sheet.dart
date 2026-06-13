import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_models.dart';
import '../../../domain/card_game/hero.dart';
import 'card_economy_actions.dart';

/// Detalhe de carta (bottom sheet) COMPARTILHADO entre a Coleção e o Deck
/// Builder — garante que a inspeção é idêntica nas duas telas. A diferença é só
/// o rodapé: a Coleção mostra a economia (criar/aprimorar/desencantar); o Deck
/// Builder passa um botão "Selecionar".

enum CardVMKind { creature, relic, hero }

class ConceptStyle {
  final String label;
  final Color color;
  const ConceptStyle(this.label, this.color);
}

const Map<CardConcept, ConceptStyle> kConceptStyles = {
  CardConcept.vitalismo: ConceptStyle('Vita', AppColors.conceptVita),
  CardConcept.neutro: ConceptStyle('Neutro', AppColors.conceptNeutro),
  CardConcept.chrysalis: ConceptStyle('Chrysalis', AppColors.conceptChrysalis),
  CardConcept.celestial: ConceptStyle('Celestial', AppColors.conceptCelestial),
  CardConcept.magico: ConceptStyle('Mágico', AppColors.conceptMagico),
  CardConcept.corrompido: ConceptStyle('Corrompido', AppColors.conceptCorrompido),
};

ConceptStyle conceptStyleOf(CardConcept c) =>
    kConceptStyles[c] ?? const ConceptStyle('?', AppColors.conceptNeutro);

Color conceptColorOf(List<CardConcept> concepts) => concepts.isEmpty
    ? AppColors.conceptNeutro
    : conceptStyleOf(concepts.first).color;

Color rarityColorOf(Rarity r) {
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

String rarityLabelOf(Rarity r) {
  switch (r) {
    case Rarity.comum:
      return 'Comum';
    case Rarity.rara:
      return 'Rara';
    case Rarity.epica:
      return 'Épica';
    case Rarity.lendaria:
      return 'Lendária';
    case Rarity.elite:
      return 'Elite';
  }
}

IconData damageIconOf(DamageType t) {
  switch (t) {
    case DamageType.corpoACorpo:
      return Icons.sports_martial_arts;
    case DamageType.aDistancia:
      return Icons.gps_fixed;
    case DamageType.magico:
      return Icons.auto_fix_high;
    case DamageType.vitalismo:
      return Icons.bloodtype;
    case DamageType.cura:
      return Icons.healing;
  }
}

String damageLabelOf(DamageType t) {
  switch (t) {
    case DamageType.corpoACorpo:
      return 'Corpo a corpo';
    case DamageType.aDistancia:
      return 'À distância';
    case DamageType.magico:
      return 'Mágico';
    case DamageType.vitalismo:
      return 'Vitalismo (dano verdadeiro)';
    case DamageType.cura:
      return 'Cura';
  }
}

/// View-model unificado: adapta `CreatureCard`/`RelicCard`/`HeroId` para a casca
/// de carta (face + detalhe).
class CardVM {
  final String id;
  final String name;
  final CardVMKind kind;
  final List<CardConcept> concepts;
  final Rarity rarity;
  final int cost;
  final IconData icon;
  // Criatura
  final int atk;
  final int pv;
  final DamageType? damageType;
  final int relicSlots;
  final List<String> abilities;
  // Relíquia
  final String relicTag; // "Equipamento" | "Flash"
  final RelicGrants? grants;
  final bool isUniversal;
  // Herói
  final String passive;
  final String active;

  const CardVM({
    required this.id,
    required this.name,
    required this.kind,
    required this.concepts,
    required this.rarity,
    required this.cost,
    required this.icon,
    this.atk = 0,
    this.pv = 0,
    this.damageType,
    this.relicSlots = 0,
    this.abilities = const [],
    this.relicTag = '',
    this.grants,
    this.isUniversal = false,
    this.passive = '',
    this.active = '',
  });

  bool get isHero => kind == CardVMKind.hero;
  bool get isCreature => kind == CardVMKind.creature;
  Color get conceptColor => conceptColorOf(concepts);
  Color get rarityColor => rarityColorOf(rarity);

  /// Conceito primário NÃO-neutro (string) pra Essência de Facção; null se só neutro.
  String? get primaryConceptName {
    for (final c in concepts) {
      if (c != CardConcept.neutro) return cardConceptToString(c);
    }
    return null;
  }

  factory CardVM.fromCreature(CreatureCard c) => CardVM(
        id: c.id,
        name: c.nome,
        kind: CardVMKind.creature,
        concepts: c.concepts,
        rarity: c.rarity,
        cost: c.cost,
        icon: damageIconOf(c.damageType),
        atk: c.atk,
        pv: c.hp,
        damageType: c.damageType,
        relicSlots: c.relicSlots,
        abilities: c.abilities,
      );

  factory CardVM.fromRelic(RelicCard r) => CardVM(
        id: r.id,
        name: r.nome,
        kind: CardVMKind.relic,
        concepts: r.concepts,
        rarity: r.rarity,
        cost: r.cost,
        icon: r.isFlash ? Icons.bolt : Icons.shield_outlined,
        relicTag: r.isFlash ? 'Flash' : 'Equipamento',
        grants: r.grants,
        isUniversal: r.isUniversal,
      );

  factory CardVM.fromHero(HeroId h) => CardVM(
        id: heroIdToString(h),
        name: heroLabel(h),
        kind: CardVMKind.hero,
        concepts: [heroConcept(h)],
        rarity: heroRarity(h),
        cost: 0,
        icon: heroIconOf(h),
        passive: heroPassive(h),
        active: heroActive(h),
      );
}

/// Ícone de arte do herói (compartilhado por carta, detalhe e mini-slots).
IconData heroIconOf(HeroId h) {
  switch (h) {
    case HeroId.trapaceiro:
      return Icons.casino;
    case HeroId.cartomante:
      return Icons.style;
    case HeroId.oraculo:
      return Icons.visibility;
    case HeroId.coringa:
      return Icons.auto_awesome;
    case HeroId.assassino:
      return Icons.gps_fixed;
  }
}

/// Abre o detalhe da carta como bottom sheet. [showEconomy] = bloco de economia
/// (Coleção). [bottomAction] = botão extra no rodapé (ex.: Selecionar do Deck
/// Builder). Retorna o valor que o [bottomAction] passar no `Navigator.pop`.
Future<T?> showCardDetail<T>(
  BuildContext context, {
  required CardVM card,
  bool unlocked = true,
  bool showEconomy = true,
  Widget? bottomAction,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CardDetailSheet(
      card: card,
      unlocked: unlocked,
      showEconomy: showEconomy,
      bottomAction: bottomAction,
    ),
  );
}

class CardDetailSheet extends StatelessWidget {
  final CardVM card;
  final bool unlocked;
  final bool showEconomy;
  final Widget? bottomAction;
  const CardDetailSheet({
    super.key,
    required this.card,
    this.unlocked = true,
    this.showEconomy = true,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = card.conceptColor;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF181221), Color(0xFF0A0810)],
        ),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: AppColors.borderViolet,
                  ),
                ),
              ),
              // Cabeçalho: ícone + nome + raridade
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: RadialGradient(
                        colors: [c.withValues(alpha: 0.5), const Color(0xFF0B0810)],
                      ),
                      border: Border.all(color: c.withValues(alpha: 0.5)),
                    ),
                    child: Icon(card.icon,
                        size: 28, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldLt,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: card.rarityColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${rarityLabelOf(card.rarity)} · ${_kindLabel(card.kind)}',
                              style: GoogleFonts.roboto(
                                  fontSize: 12, color: AppColors.txt2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (!unlocked)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0x33D8323F),
                    border: Border.all(
                        color: AppColors.conceptCorrompido
                            .withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock,
                          size: 16, color: AppColors.conceptCorrompido),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bloqueada — não pode ser usada no deck',
                          style: GoogleFonts.roboto(
                              fontSize: 12.5,
                              color: AppColors.txt,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Conceitos
              Text('CONCEITOS',
                  style: GoogleFonts.roboto(
                      fontSize: 10, letterSpacing: 1.5, color: AppColors.txtMut)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final concept in card.concepts)
                    _conceptPill(conceptStyleOf(concept)),
                  if (card.kind == CardVMKind.relic && card.isUniversal)
                    _tagPill('Universal', AppColors.conceptNeutro),
                ],
              ),
              const SizedBox(height: 16),

              ..._buildStatRows(),

              if (showEconomy) ...[
                const SizedBox(height: 16),
                Divider(color: AppColors.borderViolet.withValues(alpha: 0.5)),
                CardEconomyActions(
                  cardId: card.id,
                  baseAtk: card.atk,
                  baseHp: card.pv,
                  isCreature: card.kind == CardVMKind.creature,
                  isHero: card.isHero,
                  concept: card.primaryConceptName,
                ),
              ],

              if (bottomAction != null) ...[
                const SizedBox(height: 16),
                bottomAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _kindLabel(CardVMKind k) => switch (k) {
        CardVMKind.creature => 'Criatura',
        CardVMKind.hero => 'Herói',
        CardVMKind.relic => 'Relíquia',
      };

  List<Widget> _buildStatRows() {
    final rows = <Widget>[];

    if (card.kind == CardVMKind.hero) {
      rows.add(_effectBlock(card.passive, title: 'PASSIVA'));
      rows.add(const SizedBox(height: 10));
      rows.add(_effectBlock(card.active, title: 'ATIVA'));
      return rows;
    }

    if (card.kind == CardVMKind.creature) {
      rows.add(_statRow('Custo', '${card.cost}', Icons.local_fire_department));
      rows.add(_statRow('Ataque', '${card.atk}', Icons.colorize));
      rows.add(_statRow('PV', '${card.pv}', Icons.favorite));
      if (card.damageType != null) {
        rows.add(_statRow('Tipo de dano', damageLabelOf(card.damageType!),
            damageIconOf(card.damageType!)));
      }
      rows.add(_statRow(
          'Slots de relíquia', '${card.relicSlots}', Icons.add_box_outlined));
      if (card.abilities.isNotEmpty) {
        rows.add(_statRow(
            'Habilidades', card.abilities.join(', '), Icons.auto_awesome));
      }
    } else {
      rows.add(_statRow('Custo', '${card.cost}', Icons.local_fire_department));
      rows.add(_statRow('Tipo', card.relicTag,
          card.relicTag == 'Flash' ? Icons.bolt : Icons.shield_outlined));
      final g = card.grants;
      if (g != null) {
        if (g.atkBonus != null) {
          rows.add(
              _statRow('Bônus de ataque', '+${g.atkBonus}', Icons.colorize));
        }
        if (g.hpBonus != null) {
          rows.add(_statRow('Bônus de PV', '+${g.hpBonus}', Icons.favorite));
        }
        if (g.armor != null) {
          rows.add(_statRow('Armadura', '${g.armor}', Icons.security));
        }
        if (g.heal != null) {
          rows.add(_statRow('Cura', '${g.heal}', Icons.healing));
        }
        if (g.attackType != null) {
          rows.add(_statRow('Tipo de ataque concedido',
              damageLabelOf(g.attackType!), damageIconOf(g.attackType!)));
        }
        if (g.abilities.isNotEmpty) {
          rows.add(_statRow(
              'Habilidades', g.abilities.join(', '), Icons.auto_awesome));
        }
        if (g.rawEffect.isNotEmpty) {
          rows.add(const SizedBox(height: 6));
          rows.add(_effectBlock(g.rawEffect));
        }
      }
    }

    return rows;
  }

  Widget _statRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.txtMut),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                    GoogleFonts.roboto(fontSize: 12.5, color: AppColors.txt2)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  color: AppColors.txt,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _effectBlock(String text, {String title = 'EFEITO'}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x33100C15),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.roboto(
                  fontSize: 10, letterSpacing: 1.5, color: AppColors.txtMut)),
          const SizedBox(height: 6),
          Text(text,
              style: GoogleFonts.roboto(
                  fontSize: 13, height: 1.4, color: AppColors.txt)),
        ],
      ),
    );
  }

  Widget _conceptPill(ConceptStyle s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: s.color.withValues(alpha: 0.16),
        border: Border.all(color: s.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: s.color),
          ),
          const SizedBox(width: 6),
          Text(s.label,
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.txt,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _tagPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: GoogleFonts.roboto(
              fontSize: 12, color: AppColors.txt, fontWeight: FontWeight.w500)),
    );
  }
}

/// Botão padrão de rodapé do detalhe (ex.: "Selecionar" / "Remover do deck").
class CardDetailActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const CardDetailActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.shadowAscending,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.15),
          ]),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
