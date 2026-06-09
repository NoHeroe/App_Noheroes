import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_models.dart';
import '../card_ownership.dart';
import '../deck_repository.dart';

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

  // Seleção atual (ids), em ordem de inserção.
  final List<String> _creatureIds = [];
  final List<String> _relicIds = [];

  bool _seeded = false; // pré-carrega o deck ativo só uma vez.
  bool _saving = false;

  static const int _max = 9;

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(_catalogProvider);
    final ownedAsync = ref.watch(cardOwnershipProvider);
    final deckAsync = ref.watch(activeDeckProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [Color(0xFF1A0020), Color(0xFF0A000A), AppColors.black],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
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

    final ownedCreatures =
        catalog.creatures.where((c) => owned.contains(c.id)).toList();
    final ownedRelics =
        catalog.relics.where((r) => owned.contains(r.id)).toList();

    // Criaturas atualmente no deck (resolvidas) — usadas pra checar
    // compatibilidade das relíquias.
    final deckCreatures = <CreatureCard>[
      for (final c in catalog.creatures)
        if (_creatureIds.contains(c.id)) c,
    ];

    return Column(
      children: [
        _buildStatusBar(),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildTabs(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _tab == 0
              ? _buildCreatureGrid(ownedCreatures)
              : _buildRelicGrid(ownedRelics, deckCreatures),
        ),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/library'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONSTRUTOR DE DECK',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 15,
                        color: AppColors.purpleLight,
                        letterSpacing: 2)),
                Text('Monte 9 criaturas + 9 relíquias',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
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
      onTap: () => setState(() => _tab = index),
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

  // ── Grid de criaturas adquiridas ────────────────────────────────────
  Widget _buildCreatureGrid(List<CreatureCard> creatures) {
    if (creatures.isEmpty) {
      return _emptyBody('Você ainda não possui criaturas.');
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.74,
      ),
      itemCount: creatures.length,
      itemBuilder: (_, i) {
        final c = creatures[i];
        final inDeck = _creatureIds.contains(c.id);
        return _DeckCardTile(
          name: c.nome,
          concepts: c.concepts,
          rarity: c.rarity,
          icon: _damageIcon(c.damageType),
          cost: c.cost,
          atk: c.atk,
          pv: c.hp,
          inDeck: inDeck,
          warning: false,
          onTap: () => _toggleCreature(c.id),
        );
      },
    );
  }

  // ── Grid de relíquias adquiridas (+ aviso de dead card) ─────────────
  Widget _buildRelicGrid(
    List<RelicCard> relics,
    List<CreatureCard> deckCreatures,
  ) {
    if (relics.isEmpty) {
      return _emptyBody('Você ainda não possui relíquias.');
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.74,
      ),
      itemCount: relics.length,
      itemBuilder: (_, i) {
        final r = relics[i];
        final inDeck = _relicIds.contains(r.id);
        // Dica soft: relíquia que não casa com nenhuma criatura do deck atual
        // (e o deck tem criaturas) é uma "dead card". Universais sempre ok.
        final dead = deckCreatures.isNotEmpty &&
            !r.isUniversal &&
            !deckCreatures.any(r.isCompatibleWith);
        return _DeckCardTile(
          name: r.nome,
          concepts: r.concepts,
          rarity: r.rarity,
          icon: r.isFlash ? Icons.bolt : Icons.shield_outlined,
          cost: r.cost,
          atk: null,
          pv: null,
          relicTag: r.isFlash ? 'Flash' : 'Equip.',
          inDeck: inDeck,
          warning: dead,
          onTap: () => _toggleRelic(r.id),
        );
      },
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
      context.go('/library');
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

/// Tile compacto pro grid do construtor. Destaque quando no deck; aviso
/// (borda/ícone âmbar) quando "dead card" (relíquia incompatível).
class _DeckCardTile extends StatelessWidget {
  const _DeckCardTile({
    required this.name,
    required this.concepts,
    required this.rarity,
    required this.icon,
    required this.inDeck,
    required this.warning,
    required this.onTap,
    this.cost,
    this.atk,
    this.pv,
    this.relicTag,
  });

  final String name;
  final List<CardConcept> concepts;
  final Rarity rarity;
  final IconData icon;
  final bool inDeck;
  final bool warning;
  final VoidCallback onTap;
  final int? cost;
  final int? atk;
  final int? pv;
  final String? relicTag;

  @override
  Widget build(BuildContext context) {
    final c = _conceptColor(concepts);
    final borderColor = inDeck
        ? AppColors.shadowAscending
        : (warning ? AppColors.gold : c.withValues(alpha: 0.35));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF211A2E), Color(0xFF0B0810)],
          ),
          border: Border.all(
            color: borderColor,
            width: inDeck ? 2 : 1,
          ),
          boxShadow: inDeck
              ? [
                  BoxShadow(
                    color: AppColors.shadowAscending.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: c.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Art
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: DecoratedBox(
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
                        child: Center(
                          child: Icon(icon,
                              size: 30,
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    if (cost != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3A4FAE),
                          ),
                          child: Text('$cost',
                              style: GoogleFonts.cinzelDecorative(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    // Marca de seleção / aviso (top-right)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: inDeck
                          ? const Icon(Icons.check_circle,
                              size: 18, color: AppColors.shadowAscending)
                          : (warning
                              ? const Icon(Icons.warning_amber_rounded,
                                  size: 16, color: AppColors.gold)
                              : const SizedBox.shrink()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _rarityColor(rarity),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.txt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              if (atk != null && pv != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.colorize,
                            size: 11, color: Color(0xFFF0D9A0)),
                        const SizedBox(width: 2),
                        Text('$atk',
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.conceptMagico)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite,
                            size: 11, color: Color(0xFFFF9B9B)),
                        const SizedBox(width: 2),
                        Text('$pv',
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.conceptCorrompido)),
                      ],
                    ),
                  ],
                )
              else
                Center(
                  child: Text(
                    warning
                        ? 'INCOMPATÍVEL'
                        : (relicTag ?? '').toUpperCase(),
                    style: GoogleFonts.roboto(
                        fontSize: 8.5,
                        letterSpacing: 1,
                        color: warning ? AppColors.gold : AppColors.txtMut),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
