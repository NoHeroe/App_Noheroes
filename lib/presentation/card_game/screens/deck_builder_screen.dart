import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_models.dart';
import '../../../domain/card_game/hero.dart';
import '../card_hero_prefs.dart';
import '../card_ownership.dart';
import '../deck_repository.dart';
import '../../shared/widgets/nh_back_button.dart';
import '../widgets/game_card_face.dart';
import '../../shared/widgets/nh_atmosphere.dart';

/// Construtor de Deck (ACDA).
///
/// Carrega catálogo + posse + deck ativo. O jogador monta 9 criaturas + 9
/// relíquias a partir das cartas que POSSUI. Tap adiciona/remove (sem
/// duplicatas). Dica de compatibilidade soft marca relíquias que não casam com
/// nenhuma criatura do deck atual. Salvar grava o deck ativo e volta.
class DeckBuilderScreen extends ConsumerStatefulWidget {
  const DeckBuilderScreen({super.key});

  @override
  ConsumerState<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends ConsumerState<DeckBuilderScreen> {
  int _tab = 0; // 0 = criaturas, 1 = relíquias
  CardConcept? _conceptFilter; // null = Todos

  // Seleção atual (ids), em ordem de inserção.
  final List<String> _creatureIds = [];
  final List<String> _relicIds = [];

  bool _seeded = false; // pré-carrega o deck ativo só uma vez.
  bool _saving = false;

  HeroId _hero = HeroId.trapaceiro; // ADR-0028: herói representante (prefs).

  static const int _max = 9;

  // Paginação horizontal: 9 cartas por página (3x3), com setas + swipe.
  static const int _perPage = 9;
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    CardHeroPrefs.get().then((h) {
      if (mounted) setState(() => _hero = h);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Seletor de HERÓI representante (ADR-0028): 5 chips horizontais; tocar salva
  /// no prefs. A passiva é fixa; a descrição mostra passiva + ativa.
  Widget _heroSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HERÓI · ${heroLabel(_hero)}',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 12, color: AppColors.goldLt, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text('${heroPassive(_hero)}  ·  Ativa: ${heroActive(_hero)}',
              style: GoogleFonts.roboto(fontSize: 9.5, color: AppColors.txtMut)),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final h in HeroId.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _hero = h);
                        CardHeroPrefs.set(h);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: h == _hero
                              ? AppColors.purple.withValues(alpha: 0.30)
                              : const Color(0x33100C15),
                          border: Border.all(
                              color: h == _hero
                                  ? AppColors.purpleLight
                                  : AppColors.borderViolet),
                        ),
                        child: Text(heroLabel(h),
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: h == _hero
                                    ? AppColors.txt
                                    : AppColors.txtMut)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aplica uma mudança de filtro/aba e VOLTA pra primeira página.
  void _onFilterChanged(VoidCallback change) {
    setState(() {
      change();
      _page = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(_catalogProvider);
    final ownedAsync = ref.watch(cardOwnershipProvider);
    final deckAsync = ref.watch(activeDeckProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const NhAtmosphere(
            glow: Color(0xFF8B3DFF),
            base: [Color(0xFF1A0020), Color(0xFF0A000A), AppColors.black],
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 4),
                _heroSelector(),
                Expanded(
                  child: _buildContent(catalogAsync, ownedAsync, deckAsync),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<CardCatalog> catalogAsync,
    AsyncValue<Set<String>> ownedAsync,
    AsyncValue<PlayerDeck?> deckAsync,
  ) {
    // Loading: enquanto o catálogo não chega (peça crítica).
    if (catalogAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.purpleLt, strokeWidth: 2.4),
      );
    }
    if (catalogAsync.hasError || !catalogAsync.hasValue) {
      return _errorBody('Não foi possível carregar o catálogo de cartas.');
    }

    final catalog = catalogAsync.value!;
    // Posse/deck assíncronos: tratamos sem crashar (vazio se ainda carregando
    // ou erro). Sem player logado → posse vazia, deck null.
    final owned = ownedAsync.value ?? const <String>{};

    // Pré-carrega o deck ativo na seleção, uma vez, quando disponível.
    if (!_seeded && deckAsync.hasValue) {
      final deck = deckAsync.value;
      if (deck != null) {
        _creatureIds.addAll(deck.creatureIds.where(owned.contains));
        _relicIds.addAll(deck.relicIds.where(owned.contains));
      }
      _seeded = true;
    }

    final ownedCreatures = catalog.creatures
        .where((c) => owned.contains(c.id) && _byConcept(c.concepts))
        .toList();
    final ownedRelics = catalog.relics
        .where((r) => owned.contains(r.id) && _byConcept(r.concepts))
        .toList();

    // Criaturas atualmente no deck (resolvidas) — usadas pra checar
    // compatibilidade das relíquias.
    final deckCreatures = <CreatureCard>[
      for (final c in catalog.creatures)
        if (_creatureIds.contains(c.id)) c,
    ];

    return Column(
      children: [
        // Preview do DECK: 2 filas de 9 (criaturas + relíquias).
        _buildDeckPreview(catalog),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildTabs(),
        ),
        const SizedBox(height: 8),
        // Filtro de conceito (chips compactos, igual à coleção).
        _buildConceptFilters(),
        const SizedBox(height: 8),
        Expanded(
          child: _tab == 0
              ? _buildCreatureGrid(ownedCreatures)
              : _buildRelicGrid(ownedRelics, deckCreatures),
        ),
        // Contador + Salvar no RODAPÉ.
        _buildStatusBar(),
        const SizedBox(height: 6),
      ],
    );
  }

  bool _byConcept(List<CardConcept> concepts) =>
      _conceptFilter == null || concepts.contains(_conceptFilter);

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          NhBackButton(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/library'),
          ),
        ],
      ),
    );
  }

  // ── Barra de status + botão salvar ──────────────────────────────────
  Widget _buildStatusBar() {
    final cOk = _creatureIds.length == _max;
    final rOk = _relicIds.length == _max;
    final canSave = cOk && rOk && !_saving;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderViolet),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Criaturas '),
                    TextSpan(
                      text: '${_creatureIds.length}/$_max',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cOk ? AppColors.shadowAscending : AppColors.gold,
                      ),
                    ),
                    TextSpan(
                      text: '   ·   ',
                      style: GoogleFonts.roboto(
                          fontSize: 13, color: AppColors.txtMut),
                    ),
                    const TextSpan(text: 'Relíquias '),
                    TextSpan(
                      text: '${_relicIds.length}/$_max',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: rOk ? AppColors.shadowAscending : AppColors.gold,
                      ),
                    ),
                  ],
                  style: GoogleFonts.roboto(
                      fontSize: 13, color: AppColors.txt2),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SaveButton(
              enabled: canSave,
              saving: _saving,
              onTap: canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs (criaturas / relíquias) ────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xCC120E18),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Row(
        children: [
          Expanded(child: _tabBtn(0, 'CRIATURAS', Icons.pets)),
          Expanded(child: _tabBtn(1, 'RELÍQUIAS', Icons.shield_outlined)),
        ],
      ),
    );
  }

  Widget _tabBtn(int index, String label, IconData icon) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => _onFilterChanged(() => _tab = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: active
              ? AppColors.purple.withValues(alpha: 0.20)
              : Colors.transparent,
          border: Border.all(
            color: active
                ? AppColors.purple.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: active ? AppColors.purpleLt : AppColors.txt2),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: active ? AppColors.purpleLt : AppColors.txt2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Preview do DECK: 2 filas de 9 miniaturas (criaturas + relíquias) ─
  Widget _buildDeckPreview(CardCatalog catalog) {
    final creatureById = {for (final c in catalog.creatures) c.id: c};
    final relicById = {for (final r in catalog.relics) r.id: r};

    Widget creatureSlot(int i) {
      if (i >= _creatureIds.length) return _miniSlot();
      final c = creatureById[_creatureIds[i]];
      if (c == null) return _miniSlot();
      return _miniSlot(
        concept: _conceptColor(c.concepts),
        rarity: c.rarity,
        icon: _damageIcon(c.damageType),
        onTap: () => _toggleCreature(c.id),
      );
    }

    Widget relicSlot(int i) {
      if (i >= _relicIds.length) return _miniSlot();
      final r = relicById[_relicIds[i]];
      if (r == null) return _miniSlot();
      return _miniSlot(
        concept: _conceptColor(r.concepts),
        rarity: r.rarity,
        icon: r.isFlash ? Icons.bolt : Icons.shield_outlined,
        onTap: () => _toggleRelic(r.id),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _deckPreviewRow(Icons.pets, creatureSlot),
          const SizedBox(height: 6),
          _deckPreviewRow(Icons.shield_outlined, relicSlot),
        ],
      ),
    );
  }

  Widget _deckPreviewRow(IconData lead, Widget Function(int) slotBuilder) {
    return Row(
      children: [
        Icon(lead, size: 13, color: AppColors.txtMut),
        const SizedBox(width: 6),
        for (int i = 0; i < _max; i++) ...[
          Expanded(child: AspectRatio(aspectRatio: 0.82, child: slotBuilder(i))),
          if (i < _max - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }

  /// Miniatura de slot do deck. Preenchido = ícone + cor de conceito + ponto
  /// de raridade; vazio = moldura tracejada apagada. Tap remove do deck.
  Widget _miniSlot({
    Color? concept,
    Rarity? rarity,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final filled = icon != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: filled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (concept ?? AppColors.purple).withValues(alpha: 0.4),
                    const Color(0xFF0B0810),
                  ],
                )
              : null,
          color: filled ? null : const Color(0x33100C15),
          border: Border.all(
            color: filled
                ? (concept ?? AppColors.purple).withValues(alpha: 0.6)
                : AppColors.borderViolet.withValues(alpha: 0.5),
          ),
        ),
        child: filled
            ? Stack(
                children: [
                  Center(
                    child: Icon(icon,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  if (rarity != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _rarityColor(rarity),
                        ),
                      ),
                    ),
                ],
              )
            : const Center(
                child: Icon(Icons.add,
                    size: 12, color: AppColors.borderViolet),
              ),
      ),
    );
  }

  // ── Filtro de conceito (chips compactos em Wrap, igual à coleção) ───
  Widget _buildConceptFilters() {
    const styles = <(CardConcept, String, Color)>[
      (CardConcept.vitalismo, 'Vita', AppColors.conceptVita),
      (CardConcept.neutro, 'Neutro', AppColors.conceptNeutro),
      (CardConcept.chrysalis, 'Chrysalis', AppColors.conceptChrysalis),
      (CardConcept.celestial, 'Celestial', AppColors.conceptCelestial),
      (CardConcept.magico, 'Mágico', AppColors.conceptMagico),
      (CardConcept.corrompido, 'Corrompido', AppColors.conceptCorrompido),
    ];
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
            onTap: () => _onFilterChanged(() => _conceptFilter = null),
          ),
          for (final s in styles)
            _chip(
              label: s.$2,
              dot: s.$3,
              selected: _conceptFilter == s.$1,
              onTap: () => _onFilterChanged(() => _conceptFilter = s.$1),
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

  // ── Grid de criaturas adquiridas (paginado 3x3) ─────────────────────
  Widget _buildCreatureGrid(List<CreatureCard> creatures) {
    if (creatures.isEmpty) {
      return _emptyBody('Você ainda não possui criaturas.');
    }
    return _pagedGrid(creatures.length, (i) {
      final c = creatures[i];
      final inDeck = _creatureIds.contains(c.id);
      final footer = Row(
        children: [
          typeGlyph(c.damageType, size: 12),
          const SizedBox(width: 3),
          Text('${c.atk}',
              style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold)),
          const Spacer(),
          const Icon(Icons.favorite, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text('${c.hp}',
              style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.conceptChrysalis)),
        ],
      );
      return GestureDetector(
        onTap: () => _toggleCreature(c.id),
        child: GameCardFace(
          name: c.nome,
          cost: c.cost,
          concepts: c.concepts,
          rarity: c.rarity,
          artIcon: _damageIcon(c.damageType),
          showItemSlot: false,
          effects: effectIconsFromAbilities(c.abilities),
          footer: footer,
          borderOverride: inDeck ? AppColors.shadowAscending : null,
          glowColor: inDeck
              ? AppColors.shadowAscending.withValues(alpha: 0.4)
              : null,
          cornerBadge: inDeck
              ? const Icon(Icons.check_circle,
                  size: 16, color: AppColors.shadowAscending)
              : null,
        ),
      );
    });
  }

  // ── Grid de relíquias adquiridas (paginado 3x3 + aviso de dead card) ─
  Widget _buildRelicGrid(
    List<RelicCard> relics,
    List<CreatureCard> deckCreatures,
  ) {
    if (relics.isEmpty) {
      return _emptyBody('Você ainda não possui relíquias.');
    }
    return _pagedGrid(relics.length, (i) {
      final r = relics[i];
      final inDeck = _relicIds.contains(r.id);
      // Dica soft: relíquia que não casa com nenhuma criatura do deck atual
      // (e o deck tem criaturas) é uma "dead card". Universais sempre ok.
      final dead = deckCreatures.isNotEmpty &&
          !r.isUniversal &&
          !deckCreatures.any(r.isCompatibleWith);
      final footer = Center(
        child: Text(
          dead ? 'INCOMPATÍVEL' : (r.isFlash ? 'FLASH' : 'EQUIP.'),
          style: GoogleFonts.roboto(
              fontSize: 8.5,
              letterSpacing: 1,
              color: dead ? AppColors.gold : AppColors.txtMut),
        ),
      );
      final highlight =
          inDeck ? AppColors.shadowAscending : (dead ? AppColors.gold : null);
      return GestureDetector(
        onTap: () => _toggleRelic(r.id),
        child: GameCardFace(
          name: r.nome,
          cost: r.cost,
          concepts: r.concepts,
          rarity: r.rarity,
          artIcon: r.isFlash ? Icons.bolt : Icons.shield_outlined,
          showItemSlot: false,
          footer: footer,
          borderOverride: highlight,
          glowColor: highlight?.withValues(alpha: 0.4),
          cornerBadge: inDeck
              ? const Icon(Icons.check_circle,
                  size: 16, color: AppColors.shadowAscending)
              : (dead
                  ? const Icon(Icons.warning_amber_rounded,
                      size: 15, color: AppColors.gold)
                  : null),
        ),
      );
    });
  }

  // ── Paginação 3x3 (setas + swipe), igual à coleção mas 9 por página ──
  Widget _pagedGrid(int total, Widget Function(int) tileBuilder) {
    final pageCount = (total / _perPage).ceil().clamp(1, 9999);
    final safePage = _page.clamp(0, pageCount - 1);
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _pageArrow(
                icon: Icons.chevron_left_rounded,
                enabled: safePage > 0,
                onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (p) => setState(() => _page = p),
                  itemCount: pageCount,
                  itemBuilder: (_, page) => _grid3x3(page, total, tileBuilder),
                ),
              ),
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
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text('Página ${safePage + 1}/$pageCount',
                style: GoogleFonts.roboto(
                    fontSize: 10, letterSpacing: 1, color: AppColors.txtMut)),
          ),
      ],
    );
  }

  /// Uma página com até 9 tiles em grade 3x3.
  Widget _grid3x3(int page, int total, Widget Function(int) tileBuilder) {
    final start = page * _perPage;
    Widget cell(int offset) {
      final i = start + offset;
      if (i >= total) return const SizedBox.shrink();
      return Center(
        child: AspectRatio(aspectRatio: 0.72, child: tileBuilder(i)),
      );
    }

    Widget gridRow(int base) => Expanded(
          child: Row(
            children: [
              Expanded(child: cell(base)),
              const SizedBox(width: 8),
              Expanded(child: cell(base + 1)),
              const SizedBox(width: 8),
              Expanded(child: cell(base + 2)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Column(
        children: [
          gridRow(0),
          const SizedBox(height: 8),
          gridRow(3),
          const SizedBox(height: 8),
          gridRow(6),
        ],
      ),
    );
  }

  Widget _pageArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26,
        alignment: Alignment.center,
        child: Icon(icon,
            size: 28,
            color: enabled
                ? AppColors.purpleLt
                : AppColors.txtMut.withValues(alpha: 0.3)),
      ),
    );
  }

  // ── Toggles ─────────────────────────────────────────────────────────
  void _toggleCreature(String id) {
    setState(() {
      if (_creatureIds.contains(id)) {
        _creatureIds.remove(id);
      } else if (_creatureIds.length < _max) {
        _creatureIds.add(id);
      }
    });
  }

  void _toggleRelic(String id) {
    setState(() {
      if (_relicIds.contains(id)) {
        _relicIds.remove(id);
      } else if (_relicIds.length < _max) {
        _relicIds.add(id);
      }
    });
  }

  // ── Salvar ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      _showSnack('Faça login para salvar o deck.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(deckRepositoryProvider);
      final existing = ref.read(activeDeckProvider).value;
      final deck = PlayerDeck(
        id: existing?.id,
        name: existing?.name ?? 'Meu Deck',
        creatureIds: List<String>.from(_creatureIds),
        relicIds: List<String>.from(_relicIds),
        isActive: true,
      );
      await repo.saveActive(playerId: player.id, deck: deck);
      ref.invalidate(activeDeckProvider);
      if (!mounted) return;
      _showSnack('Deck salvo.');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/library');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Falha ao salvar o deck: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.conceptCorrompido : AppColors.purpleDark,
      ),
    );
  }

  // ── Estados auxiliares ──────────────────────────────────────────────
  Widget _emptyBody(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.roboto(fontSize: 13, color: AppColors.txt2)),
            const SizedBox(height: 6),
            Text('Adquira cartas na Coleção para montar seu deck.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _errorBody(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.conceptCorrompido, size: 40),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.roboto(fontSize: 13, color: AppColors.txt2)),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => context.go('/library'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// FutureProvider de catálogo dedicado à tela (cacheia o load).
final _catalogProvider = FutureProvider<CardCatalog>((ref) {
  return CardCatalog.load();
});

// ── Mapeamentos (espelham a Coleção) ──────────────────────────────────
Color _conceptColor(List<CardConcept> concepts) {
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

/// Botão Salvar compacto.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.saving,
    required this.onTap,
  });

  final bool enabled;
  final bool saving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.shadowAscending : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: enabled ? 0.18 : 0.06),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.shadowAscending),
              )
            else
              Icon(Icons.save_outlined, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              'SALVAR',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
