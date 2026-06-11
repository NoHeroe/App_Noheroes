import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_game.dart';
import 'game_card_face.dart';

/// Uma carta a revelar: o modelo do catálogo (`CreatureCard`|`RelicCard`) +
/// se é nova na coleção do jogador.
class PackRevealEntry {
  final Object card; // CreatureCard | RelicCard
  final bool isNew;
  const PackRevealEntry({required this.card, required this.isNew});
}

/// Revelação de pacote em TELA CHEIA, estilo Clash Royale: as cartas surgem
/// uma a uma (toque em qualquer lugar pra avançar), com brilho por raridade e
/// selo NOVA. Um mini-botão PULAR salta direto pro resumo (grid das 5). É
/// empurrada via Navigator (rota opaca) e dá pop ao concluir.
class PackRevealOverlay extends StatefulWidget {
  final List<PackRevealEntry> entries;
  const PackRevealOverlay({super.key, required this.entries});

  /// Abre a revelação em tela cheia. No-op se [entries] vazio.
  static Future<void> show(
      BuildContext context, List<PackRevealEntry> entries) {
    if (entries.isEmpty) return Future.value();
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => PackRevealOverlay(entries: entries),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<PackRevealOverlay> createState() => _PackRevealOverlayState();
}

class _PackRevealOverlayState extends State<PackRevealOverlay> {
  int _index = 0;
  bool _summary = false;

  int get _total => widget.entries.length;

  void _advance() {
    if (_summary) return;
    if (_index >= _total - 1) {
      setState(() => _summary = true);
    } else {
      setState(() => _index++);
    }
  }

  void _skip() => setState(() => _summary = true);

  void _done() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _summary ? _buildSummary() : _buildReveal(),
      ),
    );
  }

  // ── Revelação carta a carta ─────────────────────────────────────────
  Widget _buildReveal() {
    final entry = widget.entries[_index];
    final rarity = _rarityOf(entry.card);
    final glow = _rarityColor(rarity);
    final media = MediaQuery.of(context);
    final cardW = (media.size.width * 0.60).clamp(180.0, 280.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Stack(
        children: [
          // Glow radial por raridade atrás da carta.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [
                    glow.withValues(alpha: 0.34),
                    glow.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Carta central animada (entra escalando + brilho), por índice.
          Center(
            child: _cardHero(entry, cardW, glow)
                .animate(key: ValueKey(_index))
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 360.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 220.ms)
                .shimmer(
                    delay: 240.ms,
                    duration: 700.ms,
                    color: glow.withValues(alpha: 0.55)),
          ),
          // Contador "x / n" no topo.
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_index + 1} / $_total',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    color: AppColors.goldLt,
                    letterSpacing: 2),
              ),
            ),
          ),
          // Mini-botão PULAR (canto superior direito).
          Positioned(top: 4, right: 12, child: _skipButton()),
          // Dica de toque (rodapé).
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'toque para continuar',
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.txtMut,
                    letterSpacing: 1),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                  duration: 900.ms, begin: 0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardHero(PackRevealEntry entry, double width, Color glow) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.isNew) ...[
          _novaBadge(),
          const SizedBox(height: 10),
        ],
        GameCardFace(
          name: _nameOf(entry.card),
          cost: _costOf(entry.card),
          concepts: _conceptsOf(entry.card),
          rarity: _rarityOf(entry.card),
          artIcon: _artIconOf(entry.card),
          effects: _effectsOf(entry.card),
          footer: _footerOf(entry.card),
          width: width,
          glowColor: glow.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          _rarityLabel(_rarityOf(entry.card)).toUpperCase(),
          style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: glow,
              letterSpacing: 3,
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── Resumo (grid das 5) ─────────────────────────────────────────────
  Widget _buildSummary() {
    return Column(
      children: [
        const SizedBox(height: 14),
        Text(
          'CARTAS OBTIDAS',
          style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: AppColors.goldLt,
              letterSpacing: 3),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.entries.where((e) => e.isNew).length} novas de $_total',
          style: GoogleFonts.roboto(fontSize: 12, color: AppColors.txtMut),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _total,
              itemBuilder: (_, i) {
                final e = widget.entries[i];
                return Stack(
                  children: [
                    GameCardFace(
                      name: _nameOf(e.card),
                      cost: _costOf(e.card),
                      concepts: _conceptsOf(e.card),
                      rarity: _rarityOf(e.card),
                      artIcon: _artIconOf(e.card),
                      effects: _effectsOf(e.card),
                      footer: _footerOf(e.card),
                    ),
                    if (e.isNew)
                      const Positioned(top: 4, right: 4, child: _MiniNova()),
                  ],
                )
                    .animate()
                    .fadeIn(delay: (i * 60).ms, duration: 260.ms)
                    .slideY(begin: 0.12, end: 0);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: _continueButton(),
        ),
      ],
    );
  }

  // ── Controles ───────────────────────────────────────────────────────
  Widget _skipButton() {
    return GestureDetector(
      onTap: _skip,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xB3100C15),
          border: Border.all(color: AppColors.borderViolet),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PULAR',
                style: GoogleFonts.roboto(
                    fontSize: 11.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.txt2)),
            const SizedBox(width: 4),
            const Icon(Icons.fast_forward_rounded,
                size: 15, color: AppColors.txt2),
          ],
        ),
      ),
    );
  }

  Widget _continueButton() {
    return GestureDetector(
      onTap: _done,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [
            AppColors.purple.withValues(alpha: 0.4),
            AppColors.purple.withValues(alpha: 0.16),
          ]),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.6)),
        ),
        child: Text('CONTINUAR',
            style: GoogleFonts.roboto(
                fontSize: 14,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: AppColors.txt)),
      ),
    );
  }

  Widget _novaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.gold.withValues(alpha: 0.16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
      ),
      child: Text('NOVA',
          style: GoogleFonts.roboto(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: AppColors.goldLt)),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.08, duration: 700.ms);
  }

  // ── Acessores do modelo (CreatureCard | RelicCard) ──────────────────
  String _nameOf(Object card) =>
      card is CreatureCard ? card.nome : (card as RelicCard).nome;

  int _costOf(Object card) =>
      card is CreatureCard ? card.cost : (card as RelicCard).cost;

  List<CardConcept> _conceptsOf(Object card) =>
      card is CreatureCard ? card.concepts : (card as RelicCard).concepts;

  Rarity _rarityOf(Object card) =>
      card is CreatureCard ? card.rarity : (card as RelicCard).rarity;

  List<IconData> _effectsOf(Object card) => card is CreatureCard
      ? effectIconsFromAbilities(card.abilities)
      : const <IconData>[];

  IconData _artIconOf(Object card) {
    if (card is CreatureCard) return _damageIcon(card.damageType);
    return (card as RelicCard).isFlash ? Icons.bolt : Icons.shield_outlined;
  }

  Widget _footerOf(Object card) {
    if (card is CreatureCard) {
      return Row(
        children: [
          typeGlyph(card.damageType, size: 12),
          const SizedBox(width: 3),
          Text('${card.atk}',
              style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold)),
          const Spacer(),
          const Icon(Icons.favorite, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text('${card.hp}',
              style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.conceptChrysalis)),
        ],
      );
    }
    final r = card as RelicCard;
    return Center(
      child: Text(r.isFlash ? 'FLASH' : 'EQUIP.',
          style: GoogleFonts.roboto(
              fontSize: 8.5, letterSpacing: 1, color: AppColors.txtMut)),
    );
  }

  // ── Mapa raridade → cor / rótulo (espelha a Coleção/Pacotes) ────────
  Color _rarityColor(Rarity r) {
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

  String _rarityLabel(Rarity r) {
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

  IconData _damageIcon(DamageType t) {
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
}

class _MiniNova extends StatelessWidget {
  const _MiniNova();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.gold.withValues(alpha: 0.85),
      ),
      child: Text('NOVA',
          style: GoogleFonts.roboto(
              fontSize: 7.5,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
              color: Colors.black)),
    );
  }
}
