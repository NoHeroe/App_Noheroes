import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_models.dart';
import '../../card_game/card_ownership.dart';

/// Fatia 2 — Coleção de cartas. Casca visual ORIGINAL preservada (tabs/busca/
/// filtros por conceito/grid), mas a FONTE DE DADOS agora é o catálogo REAL do
/// ACDA (`CardCatalog.load()`: 80 criaturas + 176 relíquias) em vez do mock.
///
/// Estados: desbloqueado (colorido) vs bloqueado (dessaturado + cadeado), com
/// inspeção sempre liberada (tap abre detalhe). Vive como seção dentro de
/// `/library` (back volta pro hub).

enum _CardKind { creature, relic }

/// Filtro de visão da coleção (combina com tab/busca/conceito).
enum _OwnershipView { all, owned, locked }

// ── Mapeamento conceito → cor/label (cores reais de AppColors) ───────────────
class _ConceptStyle {
  final String label;
  final Color color;
  const _ConceptStyle(this.label, this.color);
}

const Map<CardConcept, _ConceptStyle> _conceptStyles = {
  CardConcept.vitalismo: _ConceptStyle('Vita', AppColors.conceptVita),
  CardConcept.neutro: _ConceptStyle('Neutro', AppColors.conceptNeutro),
  CardConcept.chrysalis: _ConceptStyle('Chrysalis', AppColors.conceptChrysalis),
  CardConcept.celestial: _ConceptStyle('Celestial', AppColors.conceptCelestial),
  CardConcept.magico: _ConceptStyle('Mágico', AppColors.conceptMagico),
  CardConcept.corrompido:
      _ConceptStyle('Corrompido', AppColors.conceptCorrompido),
};

_ConceptStyle _styleOf(CardConcept c) =>
    _conceptStyles[c] ?? const _ConceptStyle('?', AppColors.conceptNeutro);

Color _conceptColor(List<CardConcept> concepts) =>
    concepts.isEmpty ? AppColors.conceptNeutro : _styleOf(concepts.first).color;

// ── Mapeamento raridade → cor/label ──────────────────────────────────────────
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

// ── Mapeamento tipo de dano → ícone/label ────────────────────────────────────
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

String _damageLabel(DamageType t) {
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

/// View-model unificado: adapta `CreatureCard`/`RelicCard` para a casca de UI.
class _CardVM {
  final String id;
  final String name;
  final _CardKind kind;
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

  const _CardVM({
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
  });

  Color get conceptColor => _conceptColor(concepts);
  Color get rarityColor => _rarityColor(rarity);

  factory _CardVM.fromCreature(CreatureCard c) => _CardVM(
        id: c.id,
        name: c.nome,
        kind: _CardKind.creature,
        concepts: c.concepts,
        rarity: c.rarity,
        cost: c.cost,
        icon: _damageIcon(c.damageType),
        atk: c.atk,
        pv: c.hp,
        damageType: c.damageType,
        relicSlots: c.relicSlots,
        abilities: c.abilities,
      );

  factory _CardVM.fromRelic(RelicCard r) => _CardVM(
        id: r.id,
        name: r.nome,
        kind: _CardKind.relic,
        concepts: r.concepts,
        rarity: r.rarity,
        cost: r.cost,
        icon: r.isFlash ? Icons.bolt : Icons.shield_outlined,
        relicTag: r.isFlash ? 'Flash' : 'Equipamento',
        grants: r.grants,
        isUniversal: r.isUniversal,
      );
}

class LibraryCardsSection extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const LibraryCardsSection({super.key, required this.onBack});

  @override
  ConsumerState<LibraryCardsSection> createState() =>
      _LibraryCardsSectionState();
}

class _LibraryCardsSectionState extends ConsumerState<LibraryCardsSection> {
  int _tab = 0; // 0 = criaturas, 1 = relíquias
  String _query = '';
  CardConcept? _conceptFilter; // null = Todos
  _OwnershipView _view = _OwnershipView.all; // default = Todas
  final _searchCtrl = TextEditingController();

  // Paginação horizontal: 4 cartas por página (2x2), com setas + swipe.
  static const int _perPage = 4;
  final PageController _pageController = PageController();
  int _page = 0;

  late final Future<CardCatalog> _catalogFuture = CardCatalog.load();

  @override
  void dispose() {
    _searchCtrl.dispose();
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

  List<_CardVM> _sourceFor(CardCatalog catalog) => _tab == 0
      ? catalog.creatures.map(_CardVM.fromCreature).toList()
      : catalog.relics.map(_CardVM.fromRelic).toList();

  List<_CardVM> _filter(List<_CardVM> source, Set<String> owned) =>
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
    // Posse REAL é assíncrona: enquanto carrega/erro, trata como "nada
    // desbloqueado" (não crasha; UI mostra tudo bloqueado). Sem player
    // logado o provider já devolve set vazio.
    final owned =
        ref.watch(cardOwnershipProvider).value ?? const <String>{};
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
                        itemBuilder: (_, page) => _cardPage(cards, page, owned),
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
                      : 'Relíquias desbloqueadas ',
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
  Widget _cardPage(List<_CardVM> cards, int page, Set<String> owned) {
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

  void _openDetail(_CardVM card, bool unlocked) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardDetailSheet(card: card, unlocked: unlocked),
    );
  }

  // ── Header: voltar + BUSCA (sem título — busca no lugar dele) ────────
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
          const SizedBox(width: 12),
          Expanded(child: _buildSearch()),
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
              final tabW = (c.maxWidth - 6) / 2;
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
              onChanged: (v) => _onFilterChanged(() => _query = v),
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
          for (final entry in _conceptStyles.entries)
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
  final _CardVM card;
  final bool unlocked;
  final VoidCallback onTap;
  const _CardTile({
    required this.card,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile(context);
    // Bloqueado: dessatura o tile inteiro (saturação 0) + cadeado sobreposto.
    return GestureDetector(
      onTap: onTap,
      child: unlocked
          ? tile
          : Stack(
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: Opacity(opacity: 0.85, child: tile),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xCC0B0810),
                        border: Border.all(
                            color: AppColors.borderViolet, width: 1.4),
                      ),
                      child: const Icon(Icons.lock,
                          size: 20, color: AppColors.txt2),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final c = card.conceptColor;
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
                  // Custo (losango top-left) — criaturas E relíquias têm custo.
                  Positioned(top: 0, left: 0, child: _CostDiamond(card.cost)),
                  // Multi-conceito: pontos dos conceitos extras (top-right)
                  if (card.concepts.length > 1)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        children: [
                          for (final extra in card.concepts.skip(1))
                            Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _styleOf(extra).color,
                                  border: Border.all(
                                      color: const Color(0xCC0B0810),
                                      width: 1),
                                ),
                              ),
                            ),
                        ],
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
                    color: card.rarityColor,
                    boxShadow: [
                      BoxShadow(
                          color: card.rarityColor.withValues(alpha: 0.6),
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

// ── Detalhe (BottomSheet) — inspeção sempre liberada ─────────────────────────
class _CardDetailSheet extends StatelessWidget {
  final _CardVM card;
  final bool unlocked;
  const _CardDetailSheet({required this.card, required this.unlocked});

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
              // grip
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
                        colors: [
                          c.withValues(alpha: 0.5),
                          const Color(0xFF0B0810),
                        ],
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
                              '${_rarityLabel(card.rarity)} · '
                              '${card.kind == _CardKind.creature ? 'Criatura' : 'Relíquia'}',
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

              // Aviso de bloqueio (mas exibe tudo)
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
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: AppColors.txtMut)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final concept in card.concepts)
                    _conceptPill(_styleOf(concept)),
                  if (card.kind == _CardKind.relic && card.isUniversal)
                    _tagPill('Universal', AppColors.conceptNeutro),
                ],
              ),
              const SizedBox(height: 16),

              // Stats grid
              ..._buildStatRows(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStatRows() {
    final rows = <Widget>[];

    if (card.kind == _CardKind.creature) {
      rows.add(_statRow('Custo', '${card.cost}', Icons.local_fire_department));
      rows.add(_statRow('Ataque', '${card.atk}', Icons.colorize));
      rows.add(_statRow('PV', '${card.pv}', Icons.favorite));
      if (card.damageType != null) {
        rows.add(_statRow('Tipo de dano', _damageLabel(card.damageType!),
            _damageIcon(card.damageType!)));
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
          rows.add(_statRow(
              'Bônus de ataque', '+${g.atkBonus}', Icons.colorize));
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
              _damageLabel(g.attackType!), _damageIcon(g.attackType!)));
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
                style: GoogleFonts.roboto(
                    fontSize: 12.5, color: AppColors.txt2)),
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

  Widget _effectBlock(String text) {
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
          Text('EFEITO',
              style: GoogleFonts.roboto(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AppColors.txtMut)),
          const SizedBox(height: 6),
          Text(text,
              style: GoogleFonts.roboto(
                  fontSize: 13, height: 1.4, color: AppColors.txt)),
        ],
      ),
    );
  }

  Widget _conceptPill(_ConceptStyle s) {
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
