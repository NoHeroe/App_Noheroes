import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_models.dart';
import '../../../domain/card_game/hero.dart';
import '../../card_game/screens/stellar_forge_screen.dart';
import '../../card_game/card_ownership.dart';
import '../../card_game/card_economy.dart';
import '../../card_game/widgets/game_card_face.dart';
import '../../card_game/widgets/card_detail_sheet.dart';
import '../../card_game/widgets/card_back.dart';
import '../../shared/widgets/nh_back_button.dart';

/// Fatia 2 — Coleção de cartas. Casca visual ORIGINAL preservada (tabs/busca/
/// filtros por conceito/grid), mas a FONTE DE DADOS agora é o catálogo REAL do
/// ACDA (`CardCatalog.load()`: 80 criaturas + 176 relíquias) em vez do mock.
///
/// Estados: desbloqueado (colorido) vs bloqueado (dessaturado + cadeado), com
/// inspeção sempre liberada (tap abre detalhe). Vive como seção dentro de
/// `/library` (back volta pro hub).

/// Filtro de visão da coleção (combina com tab/busca/conceito).
enum _OwnershipView { all, owned, locked }

// VM, helpers de conceito/raridade/dano e o detalhe vivem em
// `card_detail_sheet.dart` (compartilhados com o Deck Builder → inspeção
// idêntica). `CardVM`, `CardVMKind`, `kConceptStyles`, `showCardDetail`, etc.

class LibraryCardsSection extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const LibraryCardsSection({super.key, required this.onBack});

  @override
  ConsumerState<LibraryCardsSection> createState() =>
      _LibraryCardsSectionState();
}

class _LibraryCardsSectionState extends ConsumerState<LibraryCardsSection> {
  int _tab = 0; // 0 = criaturas, 1 = relíquias
  static const String _query = ''; // busca removida (CEO 2026-06-12)
  CardConcept? _conceptFilter; // null = Todos
  _OwnershipView _view = _OwnershipView.all; // default = Todas

  // Paginação horizontal: 4 cartas por página (2x2), com setas + swipe.
  static const int _perPage = 4;
  final PageController _pageController = PageController();
  int _page = 0;

  late final Future<CardCatalog> _catalogFuture = CardCatalog.load();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Aplica uma mudança de filtro e VOLTA pra primeira página.
  void _onFilterChanged(VoidCallback change) {
    setState(() {
      change();
      _page = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  List<CardVM> _sourceFor(CardCatalog catalog) => switch (_tab) {
        0 => catalog.creatures.map(CardVM.fromCreature).toList(),
        1 => catalog.relics.map(CardVM.fromRelic).toList(),
        _ => HeroId.values.map(CardVM.fromHero).toList(),
      };

  List<CardVM> _filter(List<CardVM> source, Set<String> owned) =>
      source.where((c) {
        final byQuery = _query.isEmpty ||
            c.name.toLowerCase().contains(_query.toLowerCase());
        final byConcept =
            _conceptFilter == null || c.concepts.contains(_conceptFilter);
        final unlocked = isCardUnlocked(id: c.id, owned: owned);
        final byView = switch (_view) {
          _OwnershipView.all => true,
          _OwnershipView.owned => unlocked,
          _OwnershipView.locked => !unlocked,
        };
        return byQuery && byConcept && byView;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: voltar + BUSCA (no lugar do antigo título).
          _buildHeader(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabs(),
          ),
          const SizedBox(height: 10),
          // Filtro de posse logo ABAIXO de criaturas/relíquias.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildViewSelector(),
          ),
          const SizedBox(height: 10),
          // Conceitos: chips compactos em Wrap (sem scroll horizontal).
          _buildFilters(),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<CardCatalog>(
              future: _catalogFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.purpleLt, strokeWidth: 2.4),
                  );
                }
                if (snap.hasError || !snap.hasData) {
                  return _buildError();
                }
                return _buildBody(snap.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.conceptCorrompido, size: 36),
            const SizedBox(height: 10),
            Text(
              'Não foi possível carregar a coleção.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 13, color: AppColors.txt2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CardCatalog catalog) {
    // Aba HERÓIS (CEO 2026-06-12): os 5 heróis fluem pelo MESMO grid de cartas
    // (já estão no cards_catalog/player_cards → posse e nível funcionam).
    // Posse REAL é assíncrona: enquanto carrega/erro, trata como "nada
    // desbloqueado" (não crasha; UI mostra tudo bloqueado). Sem player
    // logado o provider já devolve set vazio.
    final owned =
        ref.watch(cardOwnershipProvider).value ?? const <String>{};
    final levels =
        ref.watch(cardLevelsProvider).value ?? const <String, int>{};
    final source = _sourceFor(catalog);
    final cards = _filter(source, owned);

    final ownedCount =
        source.where((c) => isCardUnlocked(id: c.id, owned: owned)).length;
    final total = source.length;

    final pageCount = cards.isEmpty ? 0 : ((cards.length - 1) ~/ _perPage) + 1;
    final safePage = pageCount == 0 ? 0 : _page.clamp(0, pageCount - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: cards.isEmpty
              ? Center(
                  child: Text('Nenhuma carta encontrada.',
                      style: GoogleFonts.roboto(color: AppColors.txtMut)),
                )
              : Row(
                  children: [
                    // Seta ESQUERDA (página anterior).
                    _pageArrow(
                      icon: Icons.chevron_left_rounded,
                      enabled: safePage > 0,
                      onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut),
                    ),
                    // 4 cartas (2x2) por página — swipe horizontal também funciona.
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (p) => setState(() => _page = p),
                        itemCount: pageCount,
                        itemBuilder: (_, page) =>
                          _cardPage(cards, page, owned, levels),
                      ),
                    ),
                    // Seta DIREITA (próxima página).
                    _pageArrow(
                      icon: Icons.chevron_right_rounded,
                      enabled: safePage < pageCount - 1,
                      onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut),
                    ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Column(
            children: [
              if (pageCount > 1)
                Text('Página ${safePage + 1}/$pageCount',
                    style: GoogleFonts.roboto(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppColors.txtMut)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: _tab == 0
                      ? 'Criaturas desbloqueadas '
                      : _tab == 1
                          ? 'Relíquias desbloqueadas '
                          : 'Heróis desbloqueados ',
                  style: GoogleFonts.roboto(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: AppColors.txtMut),
                  children: [
                    TextSpan(
                      text: '$ownedCount',
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
            ],
          ),
        ),
      ],
    );
  }

  /// Uma página com até 4 cartas em grade 2x2 (preenche a altura disponível).
  Widget _cardPage(
      List<CardVM> cards, int page, Set<String> owned, Map<String, int> levels) {
    final start = page * _perPage;
    Widget cell(int offset) {
      final i = start + offset;
      if (i >= cards.length) return const SizedBox.shrink();
      final card = cards[i];
      final unlocked = isCardUnlocked(id: card.id, owned: owned);
      return Center(
        child: AspectRatio(
          aspectRatio: 142 / 206,
          child: _CardTile(
            card: card,
            unlocked: unlocked,
            level: levels[card.id] ?? 1,
            onTap: () => _openDetail(card, unlocked),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              Expanded(child: cell(0)),
              const SizedBox(width: 12),
              Expanded(child: cell(1)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(children: [
              Expanded(child: cell(2)),
              const SizedBox(width: 12),
              Expanded(child: cell(3)),
            ]),
          ),
        ],
      ),
    );
  }

  /// Seta de paginação (lateral). Esmaece quando desabilitada.
  Widget _pageArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        alignment: Alignment.center,
        child: Icon(icon,
            size: 30,
            color: enabled
                ? AppColors.purpleLt
                : AppColors.txtMut.withValues(alpha: 0.3)),
      ),
    );
  }

  void _openDetail(CardVM card, bool unlocked) {
    // Coleção: detalhe COM economia (criar/aprimorar/desencantar).
    showCardDetail(context, card: card, unlocked: unlocked, showEconomy: true);
  }

  // ── Header: voltar + FORJA ESTELAR (CEO 2026-06-12: substitui a busca) ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          NhBackButton(onTap: widget.onBack),
          const Spacer(),
          Text('Forja Estelar',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: AppColors.goldLt, letterSpacing: 1)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const StellarForgeScreen()),
            ),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A1B40), Color(0xFF140D22)],
                ),
                border: Border.all(
                    color: AppColors.goldLt.withValues(alpha: 0.75), width: 1.4),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 20, color: AppColors.goldLt),
            ),
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
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xCC120E18), Color(0xCC0A080E)],
            ),
            border: Border.all(color: AppColors.borderViolet),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final tabW = c.maxWidth / 3;
              return Stack(
                children: [
                  // Indicador deslizante (3 posições: criaturas/relíquias/heróis).
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: _tab == 0
                        ? Alignment.centerLeft
                        : _tab == 1
                            ? Alignment.center
                            : Alignment.centerRight,
                    child: Container(
                      width: tabW,
                      height: 30,
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
                      _tabBtn(2, 'HERÓIS', Icons.shield_moon, tabW),
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
      onTap: () => _onFilterChanged(() => _tab = index),
      child: SizedBox(
        width: w,
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.purpleLt : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: active ? AppColors.purpleLt : color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ── Filtros de conceito (chips compactos em Wrap, sem scroll) ───────
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [
          _chip(
              label: 'Todos',
              selected: _conceptFilter == null,
              onTap: () => _onFilterChanged(() => _conceptFilter = null)),
          for (final entry in kConceptStyles.entries)
            _chip(
              label: entry.value.label,
              dot: entry.value.color,
              selected: _conceptFilter == entry.key,
              onTap: () => _onFilterChanged(() => _conceptFilter = entry.key),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  // ── Seletor de visão (Adquiridas · Bloqueadas · Todas) ──────────────
  Widget _buildViewSelector() {
    return Row(
      children: [
        Expanded(
          child: _viewSeg(_OwnershipView.owned, 'ADQUIRIDAS', Icons.check_circle_outline),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _viewSeg(_OwnershipView.locked, 'BLOQUEADAS', Icons.lock_outline),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _viewSeg(_OwnershipView.all, 'TODAS', Icons.grid_view),
        ),
      ],
    );
  }

  Widget _viewSeg(_OwnershipView view, String label, IconData icon) {
    final selected = _view == view;
    return GestureDetector(
      onTap: () => _onFilterChanged(() => _view = view),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? AppColors.purple.withValues(alpha: 0.18)
              : const Color(0xB3100C15),
          border: Border.all(
            color: selected
                ? AppColors.purple.withValues(alpha: 0.5)
                : AppColors.borderViolet,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.purpleGlow45, blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 13,
                color: selected ? AppColors.purpleLt : AppColors.txt2),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.purpleLt : AppColors.txt2,
                ),
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
  final CardVM card;
  final bool unlocked;
  final int level;
  final VoidCallback onTap;
  const _CardTile({
    required this.card,
    required this.unlocked,
    required this.onTap,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Bloqueada (CEO 2026-06-12): mostra a COSTA da carta (card_back.png, mesmo
    // png do verso in-game) em CINZA + cadeado. O tap continua abrindo o detalhe
    // (inspeção sempre liberada). Desbloqueada: a face normal (GameCardFace).
    return GestureDetector(
      onTap: onTap,
      child: unlocked
          ? _buildTile(context)
          : Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0, 0, 0, 1, 0, //
                    ]),
                    child: CardBack(),
                  ),
                ),
                Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xCC0B0810),
                      border:
                          Border.all(color: AppColors.borderViolet, width: 1.4),
                    ),
                    child:
                        const Icon(Icons.lock, size: 20, color: AppColors.txt2),
                  ),
                ),
              ],
            ),
    );
  }

  /// Carta com o MESMO visual da partida (GameCardFace), sem o slot de item.
  /// Quando a carta está aprimorada (level > 1) mostra stats EFETIVOS (+10%/nv)
  /// e um selo "Nv X".
  Widget _buildTile(BuildContext context) {
    final isCreature = card.kind == CardVMKind.creature;
    final atkEff = cgScaleStat(card.atk, level);
    final pvEff = cgScaleStat(card.pv, level);
    // Rodapé: criatura = ATK/PV · relíquia = tag · herói = "HERÓI" (sem stats).
    final Widget footer = isCreature
        ? Row(
            children: [
              typeGlyph(card.damageType ?? DamageType.corpoACorpo, size: 12),
              const SizedBox(width: 3),
              Text('$atkEff',
                  style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
              const Spacer(),
              const Icon(Icons.favorite, size: 10, color: Colors.white),
              const SizedBox(width: 3),
              Text('$pvEff',
                  style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.conceptChrysalis)),
            ],
          )
        : Center(
            child: Text(card.isHero ? 'HERÓI' : card.relicTag.toUpperCase(),
                style: GoogleFonts.roboto(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: AppColors.txtMut)),
          );

    return GameCardFace(
      name: card.name,
      cost: card.cost,
      concepts: card.concepts,
      rarity: card.rarity,
      artIcon: card.icon,
      showItemSlot: false, // coleção não mostra slot de item
      showCost: !card.isHero, // herói não tem custo de cristal
      effects: isCreature
          ? effectGlyphsFromAbilities(card.abilities)
          : const <EffectBadge>[],
      footer: footer,
      cornerBadge: level > 1
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.gold.withValues(alpha: 0.9),
              ),
              child: Text('Nv $level',
                  style: GoogleFonts.roboto(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.black)),
            )
          : null,
    );
  }
}
