import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_game.dart';
import 'game_card_face.dart';

/// Botão do "livro" (glossário) reutilizável — abre a Legenda com todos os tipos
/// de dano, status e habilidades/buffs descritos. Usado na PARTIDA e nos headers
/// de Criar Deck e Coleção (CEO 2026-06-14). Sem estado/ref: seguro em qualquer
/// tela.
class GlossaryButton extends StatelessWidget {
  const GlossaryButton({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(Icons.menu_book,
          size: size, color: color ?? AppColors.textSecondary),
      tooltip: 'Legenda',
      onPressed: () => showCardGlossary(context),
    );
  }
}

/// Abre o glossário (Legenda) do card game: tipos de dano, status do tabuleiro e
/// TODAS as habilidades/buffs agrupadas. Auto-contido (só usa helpers top-level),
/// então funciona em qualquer tela. Extraído de `card_match_screen._showLegend`.
void showCardGlossary(BuildContext context) {
  Widget typeRow(DamageType t, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: damageTypeColor(t).withValues(alpha: 0.28),
                border: Border.all(color: damageTypeColor(t), width: 1),
              ),
              child: typeGlyph(t, size: 12),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.robotoMono(
                      fontSize: 11, color: AppColors.textPrimary)),
            ),
          ],
        ),
      );

  Widget statusRow(IconData icon, Color color, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.robotoMono(
                      fontSize: 10.5, color: AppColors.textSecondary)),
            ),
          ],
        ),
      );

  Widget sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(t,
            style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.gold)),
      );

  Widget abilityRow(AbilityKeyword k) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8C66A), Color(0xFF8A6A2A)],
                ),
              ),
              child: keywordGlyph(k).build(size: 11, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.robotoMono(
                      fontSize: 10.5, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                        text: '${abilityKeywordLabel(k)} — ',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    TextSpan(text: keywordDescription(k)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  // Habilidades agrupadas pelos lotes (ordem do enum).
  const offensive = [
    AbilityKeyword.provocar,
    AbilityKeyword.ataqueDuplo,
    AbilityKeyword.alcance,
    AbilityKeyword.inspirar,
    AbilityKeyword.pisotear,
    AbilityKeyword.cristalDeDrenagem,
    AbilityKeyword.rouboDePv,
    AbilityKeyword.investida,
    AbilityKeyword.furia,
    AbilityKeyword.cristalAdicional,
    AbilityKeyword.antiAereo,
    AbilityKeyword.quebraArmadura,
    AbilityKeyword.explosaoMagica,
  ];
  const defensive = [
    AbilityKeyword.escudo,
    AbilityKeyword.voo,
    AbilityKeyword.silencio,
    AbilityKeyword.furtividade,
    AbilityKeyword.espinhos,
    AbilityKeyword.escudoEspelhado,
    AbilityKeyword.escudoSagrado,
    AbilityKeyword.contraAtaque,
    AbilityKeyword.reflexoMagico,
    AbilityKeyword.inabalavel,
    AbilityKeyword.imunidade,
    AbilityKeyword.perseveranca,
    AbilityKeyword.vigilante,
    AbilityKeyword.encantarArmadura,
    AbilityKeyword.espinhoDeEscudo,
    AbilityKeyword.nevoa,
    AbilityKeyword.esquiva,
  ];
  const status = [
    AbilityKeyword.sangramento,
    AbilityKeyword.veneno,
    AbilityKeyword.atordoar,
    AbilityKeyword.enredar,
    AbilityKeyword.desmoralizar,
    AbilityKeyword.suprimirMagia,
    AbilityKeyword.doenca,
    AbilityKeyword.surto,
    AbilityKeyword.nevoaToxica,
  ];
  const exotic = [
    AbilityKeyword.andorinha,
    AbilityKeyword.crescimento,
    AbilityKeyword.mimico,
    AbilityKeyword.zumbi,
    AbilityKeyword.ressurreicao,
    AbilityKeyword.transformar,
  ];

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1426),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderViolet),
      ),
      title: Text('Legenda',
          style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipos de dano',
                style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold)),
            const SizedBox(height: 4),
            typeRow(DamageType.corpoACorpo, 'Corpo a corpo — ataca da frente'),
            typeRow(DamageType.aDistancia, 'À distância — ataca da retaguarda'),
            typeRow(DamageType.magico, 'Mágico — mira o menor PV'),
            typeRow(DamageType.vitalismo,
                'Vitalismo — dano verdadeiro (sem armadura)'),
            typeRow(DamageType.cura, 'Cura — restaura PV de um aliado'),
            const SizedBox(height: 10),
            Text('Status no tabuleiro',
                style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold)),
            const SizedBox(height: 4),
            statusRow(Icons.shield, const Color(0xFF9FB4D8),
                'Armadura — reduz dano físico'),
            statusRow(Icons.auto_awesome, AppColors.conceptMagico,
                'Armadura mágica — reduz dano mágico'),
            statusRow(Icons.water_drop, AppColors.hp,
                'Sangramento — dano/turno (nº = acúmulos), some sozinho'),
            statusRow(Icons.science, AppColors.conceptChrysalis,
                'Veneno — 1 dano/turno permanente (cura remove)'),
            statusRow(Icons.coronavirus, AppColors.purpleLight,
                'Doença — suprime buffs; alvo do Surto'),
            statusRow(Icons.stars, AppColors.gold,
                'Atordoado — pula o próximo ataque'),
            statusRow(Icons.hub, AppColors.conceptVita,
                'Enredado — sem Voo, pula o próximo ataque'),
            statusRow(Icons.trending_down, const Color(0xFFE08A4A),
                'Desmoralizado / Suprimido — ataque reduzido'),
            sectionTitle('Habilidades · Ofensivas / utilidade'),
            for (final k in offensive) abilityRow(k),
            sectionTitle('Habilidades · Defensivas'),
            for (final k in defensive) abilityRow(k),
            sectionTitle('Habilidades · Status / controle'),
            for (final k in status) abilityRow(k),
            sectionTitle('Habilidades · Exóticas'),
            for (final k in exotic) abilityRow(k),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Fechar',
              style: GoogleFonts.robotoMono(color: AppColors.purpleLight)),
        ),
      ],
    ),
  );
}
