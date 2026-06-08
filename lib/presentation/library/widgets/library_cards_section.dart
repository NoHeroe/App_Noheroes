import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Fatia 2 — Coleção de cartas (CASCA visual com dados MOCK). Sem pipeline
/// de dados real; isto é só a integração visual do card game. Vive como
/// seção dentro de `/library` (back volta pro hub).

enum _CardKind { creature, relic }

class _CardConcept {
  final String key;
  final String label;
  final Color color;
  const _CardConcept(this.key, this.label, this.color);
}

const _conceptVita = _CardConcept('vita', 'Vita', AppColors.conceptVita);
const _conceptNeutro =
    _CardConcept('neutro', 'Neutro', AppColors.conceptNeutro);
const _conceptChrysalis =
    _CardConcept('chrysalis', 'Chrysalis', AppColors.conceptChrysalis);
const _conceptCelestial =
    _CardConcept('celestial', 'Celestial', AppColors.conceptCelestial);
const _conceptMagico =
    _CardConcept('magico', 'Mágico', AppColors.conceptMagico);
const _conceptCorrompido =
    _CardConcept('corrompido', 'Corrompido', AppColors.conceptCorrompido);

const _allConcepts = <_CardConcept>[
  _conceptVita,
  _conceptNeutro,
  _conceptChrysalis,
  _conceptCelestial,
  _conceptMagico,
  _conceptCorrompido,
];

class _MockCard {
  final String name;
  final _CardKind kind;
  final _CardConcept concept;
  final Color rarity;
  final int cost;
  final int owned;
  final bool isNew;
  final IconData icon;
  // Criatura
  final int atk;
  final int pv;
  // Relíquia
  final String relicTag; // "Equipamento" | "Flash"

  const _MockCard({
    required this.name,
    required this.kind,
    required this.concept,
    required this.rarity,
    required this.cost,
    required this.owned,
    required this.icon,
    this.isNew = false,
    this.atk = 0,
    this.pv = 0,
    this.relicTag = '',
  });
}

const _creatures = <_MockCard>[
  _MockCard(
      name: 'Azuos',
      kind: _CardKind.creature,
      concept: _conceptVita,
      rarity: AppColors.cardElite,
      cost: 6,
      owned: 2,
      icon: Icons.pets,
      atk: 5,
      pv: 6),
  _MockCard(
      name: 'Koda Feet',
      kind: _CardKind.creature,
      concept: _conceptVita,
      rarity: AppColors.cardElite,
      cost: 4,
      owned: 1,
      icon: Icons.cruelty_free,
      isNew: true,
      atk: 4,
      pv: 5),
  _MockCard(
      name: 'Cerverus',
      kind: _CardKind.creature,
      concept: _conceptCorrompido,
      rarity: AppColors.cardLendaria,
      cost: 7,
      owned: 1,
      icon: Icons.whatshot,
      atk: 6,
      pv: 7),
  _MockCard(
      name: 'Voidrin',
      kind: _CardKind.creature,
      concept: _conceptCorrompido,
      rarity: AppColors.cardEpica,
      cost: 3,
      owned: 3,
      icon: Icons.blur_on,
      atk: 3,
      pv: 4),
  _MockCard(
      name: 'Dríade',
      kind: _CardKind.creature,
      concept: _conceptChrysalis,
      rarity: AppColors.cardRara,
      cost: 2,
      owned: 2,
      icon: Icons.eco,
      atk: 2,
      pv: 4),
  _MockCard(
      name: 'Sereia',
      kind: _CardKind.creature,
      concept: _conceptCelestial,
      rarity: AppColors.cardRara,
      cost: 3,
      owned: 1,
      icon: Icons.water,
      atk: 3,
      pv: 2),
  _MockCard(
      name: 'Elfo',
      kind: _CardKind.creature,
      concept: _conceptNeutro,
      rarity: AppColors.cardComum,
      cost: 1,
      owned: 4,
      icon: Icons.person,
      atk: 2,
      pv: 2),
  _MockCard(
      name: 'Sakura Anaoji',
      kind: _CardKind.creature,
      concept: _conceptMagico,
      rarity: AppColors.cardLendaria,
      cost: 5,
      owned: 1,
      icon: Icons.local_florist,
      atk: 4,
      pv: 5),
];

const _relics = <_MockCard>[
  _MockCard(
      name: 'Dragon Slayer',
      kind: _CardKind.relic,
      concept: _conceptCorrompido,
      rarity: AppColors.cardLendaria,
      cost: 5,
      owned: 1,
      icon: Icons.sports_martial_arts,
      relicTag: 'Equipamento'),
  _MockCard(
      name: 'Espada Curta',
      kind: _CardKind.relic,
      concept: _conceptNeutro,
      rarity: AppColors.cardComum,
      cost: 1,
      owned: 2,
      icon: Icons.sports_martial_arts,
      relicTag: 'Equipamento'),
  _MockCard(
      name: 'Poção de Cura',
      kind: _CardKind.relic,
      concept: _conceptNeutro,
      rarity: AppColors.cardComum,
      cost: 1,
      owned: 3,
      icon: Icons.local_drink,
      relicTag: 'Flash'),
  _MockCard(
      name: 'Cajado Rachado',
      kind: _CardKind.relic,
      concept: _conceptMagico,
      rarity: AppColors.cardComum,
      cost: 2,
      owned: 1,
      icon: Icons.auto_fix_high,
      relicTag: 'Equipamento'),
  _MockCard(
      name: 'Manto de Sombras',
      kind: _CardKind.relic,
      concept: _conceptCorrompido,
      rarity: AppColors.cardRara,
      cost: 3,
      owned: 1,
      icon: Icons.checkroom,
      isNew: true,
      relicTag: 'Equipamento'),
  _MockCard(
      name: 'Caco de Cristal',
      kind: _CardKind.relic,
      concept: _conceptMagico,
      rarity: AppColors.cardComum,
      cost: 1,
      owned: 2,
      icon: Icons.diamond_outlined,
      relicTag: 'Flash'),
];

class LibraryCardsSection extends StatefulWidget {
  final VoidCallback onBack;
  const LibraryCardsSection({super.key, required this.onBack});

  @override
  State<LibraryCardsSection> createState() => _LibraryCardsSectionState();
}

class _LibraryCardsSectionState extends State<LibraryCardsSection> {
  int _tab = 0; // 0 = criaturas, 1 = relíquias
  String _query = '';
  String? _conceptFilter; // null = Todos
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_MockCard> get _source => _tab == 0 ? _creatures : _relics;

  List<_MockCard> get _filtered => _source.where((c) {
        final byQuery = _query.isEmpty ||
            c.name.toLowerCase().contains(_query.toLowerCase());
        final byConcept =
            _conceptFilter == null || c.concept.key == _conceptFilter;
        return byQuery && byConcept;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final cards = _filtered;
    final owned = _source.where((c) => c.owned > 0).length;
    final total = _source.length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabs(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearch(),
          ),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 12),
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Text('Nenhuma carta encontrada.',
                        style: GoogleFonts.roboto(color: AppColors.txtMut)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 142 / 206,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (_, i) => _CardTile(card: cards[i]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text.rich(
              TextSpan(
                text: _tab == 0
                    ? 'Criaturas coletadas '
                    : 'Relíquias coletadas ',
                style: GoogleFonts.roboto(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: AppColors.txtMut),
                children: [
                  TextSpan(
                    text: '$owned',
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' / $total'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF221A2E), Color(0xFF0B0910)],
                ),
                border: Border.all(color: AppColors.borderViolet),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.txt2, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COLEÇÃO',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.goldLt,
                  shadows: [
                    Shadow(
                        color: AppColors.gold.withValues(alpha: 0.5),
                        blurRadius: 12),
                  ],
                ),
              ),
              Text(
                'Biblioteca · seu acervo',
                style: GoogleFonts.roboto(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: AppColors.txtMut),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tabs (vidro deslizante) ─────────────────────────────────────────
  Widget _buildTabs() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xCC120E18), Color(0xCC0A080E)],
            ),
            border: Border.all(color: AppColors.borderViolet),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final tabW = (c.maxWidth - 8) / 2;
              return Stack(
                children: [
                  // Indicador deslizante
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment:
                        _tab == 0 ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: tabW,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple.withValues(alpha: 0.28),
                            AppColors.purple.withValues(alpha: 0.16),
                          ],
                        ),
                        border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.4)),
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.purpleGlow45, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _tabBtn(0, 'CRIATURAS', Icons.pets, tabW),
                      _tabBtn(1, 'RELÍQUIAS', Icons.shield_outlined, tabW),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(int index, String label, IconData icon, double w) {
    final active = _tab == index;
    final color = active ? AppColors.txt : AppColors.txt2;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: SizedBox(
        width: w,
        height: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.purpleLt : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: active ? AppColors.purpleLt : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search ──────────────────────────────────────────────────────────
  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF100C15), Color(0xFF09070C)],
        ),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.txtMut, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.roboto(
                  fontSize: 13, color: AppColors.txt),
              cursorColor: AppColors.purpleLt,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Buscar carta...',
                hintStyle: GoogleFonts.roboto(
                    fontSize: 13, color: AppColors.txtMut),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filtros (chips) ─────────────────────────────────────────────────
  Widget _buildFilters() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(label: 'Todos', selected: _conceptFilter == null, onTap: () {
            setState(() => _conceptFilter = null);
          }),
          for (final concept in _allConcepts) ...[
            const SizedBox(width: 8),
            _chip(
              label: concept.label,
              dot: concept.color,
              selected: _conceptFilter == concept.key,
              onTap: () => setState(() => _conceptFilter = concept.key),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? dot,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xB3100C15),
          border: Border.all(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.6)
                : AppColors.borderViolet,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      blurRadius: 8),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                color: selected ? AppColors.goldLt : AppColors.txt2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card tile ──────────────────────────────────────────────────────────
class _CardTile extends StatelessWidget {
  final _MockCard card;
  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = card.concept.color;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF211A2E), Color(0xFF0B0810)],
        ),
        border: Border.all(color: c.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Art
            Expanded(
              flex: 58,
              child: Stack(
                children: [
                  // Fundo + silhueta
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
                                c.withValues(alpha: 0.45),
                                const Color(0xFF0B0810),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(card.icon,
                              size: 46,
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        // fade escuro embaixo
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
                  // Custo (losango top-left)
                  Positioned(top: 0, left: 0, child: _CostDiamond(card.cost)),
                  // Owned (top-right)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0xCC0B0810),
                        border: Border.all(color: AppColors.goldDk),
                      ),
                      child: Text('×${card.owned}',
                          style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              color: AppColors.goldLt,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  // NOVO badge
                  if (card.isNew)
                    Positioned(
                      top: 24,
                      right: 2,
                      child: Transform.rotate(
                        angle: 0.08,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [AppColors.goldLt, AppColors.gold],
                            ),
                          ),
                          child: Text('NOVO',
                              style: GoogleFonts.roboto(
                                  fontSize: 8,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1206))),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Plate — gema raridade + nome
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.rarity,
                    boxShadow: [
                      BoxShadow(
                          color: card.rarity.withValues(alpha: 0.6),
                          blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.txt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Stats (criatura) ou tag (relíquia)
            if (card.kind == _CardKind.creature)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(
                    icon: Icons.colorize,
                    iconColor: const Color(0xFFF0D9A0),
                    value: card.atk,
                    valueColor: AppColors.conceptMagico,
                  ),
                  _Stat(
                    icon: Icons.favorite,
                    iconColor: const Color(0xFFFF9B9B),
                    value: card.pv,
                    valueColor: AppColors.conceptCorrompido,
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  card.relicTag.toUpperCase(),
                  style: GoogleFonts.roboto(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: AppColors.txtMut),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final Color valueColor;
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Text('$value',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

class _CostDiamond extends StatelessWidget {
  final int cost;
  const _CostDiamond(this.cost);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _DiamondClipper(),
      child: Container(
        width: 26,
        height: 26,
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
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
