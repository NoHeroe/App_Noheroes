import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/nh_atmosphere.dart';
import '../../shared/widgets/nh_back_button.dart';
import '../../sanctuary/widgets/sanctuary_header_widgets.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_models.dart';
import '../card_ownership.dart';
import '../widgets/pack_reveal_overlay.dart';
import '../widgets/weekly_shop_section.dart';

/// Tela de Pacotes (ACDA — obtenção de cartas).
///
/// Fluxo server-authoritative via RPCs Supabase:
/// - `buy_pack` debita 224 gold e +1 pacote;
/// - `open_pack` consome 1 pacote, sorteia 5 cartas (server-side) e grava em
///   `player_cards`.
///
/// A UI mostra gold atual + nº de pacotes, e revela as 5 cartas sorteadas
/// (nome + cor de conceito/raridade do catálogo + selo NOVA/repetida). Após
/// comprar/abrir, reatualiza o `currentPlayer` (gold) e invalida o
/// `cardOwnershipProvider` (Coleção reflete cartas novas).
class PacksScreen extends ConsumerStatefulWidget {
  const PacksScreen({super.key});

  @override
  ConsumerState<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends ConsumerState<PacksScreen> {
  bool _loadingHeader = true; // carga inicial (catálogo + tipos + counts)
  bool _busy = false; // comprando/abrindo (trava global)
  String? _opening; // pack_type sendo aberto (spinner no card)
  String? _buying; // pack_type sendo comprado

  CardCatalog? _catalog;
  List<Map<String, dynamic>> _packs = const []; // pack_catalog
  Map<String, int> _counts = const {}; // pack_type -> count possuído
  String? _loadError;

  /// Resultado da última abertura. null = sem revelação.
  List<_RevealCard>? _reveal;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final catalog = await CardCatalog.load();
      final client = ref.read(supabaseClientProvider);
      final packsRaw = await client
          .from('pack_catalog')
          .select()
          .order('sort', ascending: true);
      final packs = (packsRaw as List).cast<Map<String, dynamic>>();
      final counts = await _fetchCounts();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _packs = packs;
        _counts = counts;
        _loadingHeader = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Não foi possível carregar os pacotes.';
        _loadingHeader = false;
      });
    }
  }

  /// Lê os counts de TODOS os tipos de pacote do jogador (RLS filtra).
  Future<Map<String, int>> _fetchCounts() async {
    final client = ref.read(supabaseClientProvider);
    final rows = await client.from('player_packs').select('pack_type, count');
    final list = (rows as List).cast<Map<String, dynamic>>();
    return {
      for (final r in list)
        (r['pack_type'] as String): ((r['count'] as int?) ?? 0),
    };
  }

  /// Refetcha o player (gold mudou no servidor) e atualiza o provider.
  Future<void> _refreshPlayer() async {
    final updated = await ref.read(authDsProvider).currentSession();
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.roboto(color: AppColors.txt)),
          backgroundColor: const Color(0xFF1A1326),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ── Comprar ─────────────────────────────────────────────────────────
  Future<void> _buy(String type) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _buying = type;
    });
    try {
      final player = ref.read(currentPlayerProvider);
      if (player == null) {
        _snack('Sessão expirada.');
        return;
      }
      final res = await ref.read(supabaseClientProvider).rpc(
        'buy_pack',
        params: {'p_player': player.id, 'p_type': type},
      );
      final map = (res as Map).cast<String, dynamic>();
      final ok = map['ok'] == true;
      if (!ok) {
        switch (map['reason']) {
          case 'insufficient_gold':
            _snack('Ouro insuficiente');
          case 'insufficient_gems':
            _snack('Gemas insuficientes');
          default:
            _snack('Não foi possível comprar o pacote.');
        }
        return;
      }
      await _refreshPlayer();
      final counts = await _fetchCounts();
      if (!mounted) return;
      setState(() => _counts = counts);
      _snack('Pacote comprado!');
    } catch (e) {
      _snack('Erro de rede. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _buying = null;
        });
      }
    }
  }

  // ── Abrir ───────────────────────────────────────────────────────────
  Future<void> _open(String type) async {
    if (_busy || (_counts[type] ?? 0) < 1) return;
    setState(() {
      _busy = true;
      _opening = type;
      _reveal = null;
    });
    try {
      final player = ref.read(currentPlayerProvider);
      if (player == null) {
        _snack('Sessão expirada.');
        return;
      }
      final res = await ref.read(supabaseClientProvider).rpc(
        'open_pack',
        params: {'p_player': player.id, 'p_type': type},
      );
      final map = (res as Map).cast<String, dynamic>();
      final ok = map['ok'] == true;
      if (!ok) {
        if (map['reason'] == 'no_pack') {
          _snack('Você não tem pacotes para abrir.');
        } else {
          _snack('Não foi possível abrir o pacote.');
        }
        return;
      }
      final cardsRaw = (map['cards'] as List?) ?? const [];
      final reveal = cardsRaw
          .map((e) => _RevealCard.fromRpc(
                (e as Map).cast<String, dynamic>(),
                _catalog,
              ))
          .toList(growable: false);
      // Resolve os modelos completos do catálogo p/ a revelação em tela cheia.
      final entries = _buildRevealEntries(cardsRaw);

      // Consumiu 1 pacote no servidor: atualiza counts e invalida posse.
      final counts = await _fetchCounts();
      ref.invalidate(cardOwnershipProvider);
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _reveal = reveal;
      });
      // Revelação em tela cheia (Clash Royale): carta a carta + PULAR.
      await PackRevealOverlay.show(context, entries);
      // O overlay já mostrou tudo; limpa o reveal inline (fallback) pra ele não
      // ficar sobrando atrás. Se entries veio vazio (catálogo sem match), mantém
      // o reveal inline em lista como degradação.
      if (entries.isNotEmpty && mounted) {
        setState(() => _reveal = null);
      }
    } catch (e) {
      _snack('Erro de rede. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _opening = null;
        });
      }
    }
  }

  /// Resolve as cartas cruas da RPC (`card_id`/`kind`/`is_new`) nos modelos
  /// completos do catálogo, pra alimentar a revelação em tela cheia. Cartas
  /// fora do catálogo são puladas (a revelação degrada pro recap em lista).
  List<PackRevealEntry> _buildRevealEntries(List cardsRaw) {
    final cat = _catalog;
    if (cat == null) return const [];
    final out = <PackRevealEntry>[];
    for (final raw in cardsRaw) {
      final json = (raw as Map).cast<String, dynamic>();
      final cardId = json['card_id'] as String? ?? '';
      final kind = json['kind'] as String? ?? 'creature';
      final isNew = json['is_new'] == true;
      Object? card;
      if (kind == 'relic') {
        final m = cat.relics.where((r) => r.id == cardId);
        if (m.isNotEmpty) card = m.first;
      } else {
        final m = cat.creatures.where((c) => c.id == cardId);
        if (m.isNotEmpty) card = m.first;
      }
      if (card != null) out.add(PackRevealEntry(card: card, isNew: isNew));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);
    final gold = player?.gold ?? 0;

    final gems = player?.gems ?? 0;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const NhAtmosphere(
            glow: Color(0xFF8B3DFF),
            base: [Color(0xFF1A0020), Color(0xFF0A000A), AppColors.black],
          ),
          SafeArea(
            child: DefaultTabController(
              length: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const TabBar(
                    indicatorColor: AppColors.gold,
                    labelColor: AppColors.goldLt,
                    unselectedLabelColor: AppColors.txtMut,
                    tabs: [Tab(text: 'PACOTES'), Tab(text: 'MERCADO')],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBody(gold, gems),
                        const WeeklyShopSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int gold, int gems) {
    if (_loadingHeader) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.purpleLt, strokeWidth: 2.4),
      );
    }
    if (_loadError != null) {
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
                _loadError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 13, color: AppColors.txt2),
              ),
            ],
          ),
        ),
      );
    }

    // CEO 2026-06-12: mesmo padrão da Forja Estelar — grid 2 colunas de cards
    // verticais (ícone + nome), botões empilhados, quantidade no topo-direito.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72, // levemente alongado
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _packs.length,
          itemBuilder: (_, i) => _packCard(_packs[i], gold, gems),
        ),
        if (_reveal != null) ...[
          const SizedBox(height: 12),
          _buildReveal(_reveal!),
        ],
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  // Header SEM título (CEO 2026-06-12): só voltar + carteira PADRÃO do Santuário.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          NhBackButton(
            onTap: () => context.canPop() ? context.pop() : context.go('/library'),
          ),
          const Spacer(),
          const SanctuaryWalletPills(),
        ],
      ),
    );
  }

  // ── Card de pacote (vertical, padrão Forja Estelar) ─────────────────
  Widget _packCard(Map<String, dynamic> pack, int gold, int gems) {
    final type = pack['pack_type'] as String;
    final name = (pack['display_name'] as String?) ?? 'Pacote';
    final count = _counts[type] ?? 0;
    final buyable = pack['buyable'] == true;
    final priceGold = (pack['price_gold'] as num?)?.toInt();
    final priceGems = (pack['price_gems'] as num?)?.toInt();

    final useGems = (priceGems ?? 0) > 0;
    final hasBuy = buyable && (useGems ? (priceGems ?? 0) > 0 : (priceGold ?? 0) > 0);
    final affordable = useGems
        ? gems >= (priceGems ?? 0)
        : ((priceGold ?? 0) > 0 && gold >= (priceGold ?? 0));
    final canBuy = hasBuy && affordable && !_busy;
    final canOpen = count >= 1 && !_busy;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF221A2E), Color(0xFF0B0810)],
            ),
            border: Border.all(
                color: count > 0
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : AppColors.purple.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone grande centralizado
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: RadialGradient(colors: [
                    AppColors.purple.withValues(alpha: 0.55),
                    const Color(0xFF0B0810),
                  ]),
                  border:
                      Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
                ),
                child:
                    const Icon(Icons.inventory_2, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 8),
              // Nome abaixo do ícone
              Text(name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldLt)),
              const SizedBox(height: 10),
              // Botões empilhados: comprar (símbolo + valor) em cima · abrir embaixo.
              if (hasBuy) ...[
                _buyButton(useGems, useGems ? priceGems! : priceGold!, canBuy,
                    _buying == type, () => _buy(type)),
                const SizedBox(height: 6),
              ],
              _openButton(canOpen, _opening == type, () => _open(type)),
              if (!hasBuy && count == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Eventos / recompensas',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          fontSize: 9.5, color: AppColors.txtMut)),
                ),
            ],
          ),
        ),
        // Quantidade no topo-direito.
        Positioned(top: 6, right: 6, child: _qtyBadge(count)),
      ],
    );
  }

  Widget _buyButton(
      bool gems, int price, bool enabled, bool loading, VoidCallback onTap) {
    final color = gems ? AppColors.purpleLt : AppColors.gold;
    final icon = gems ? Icons.diamond_outlined : Icons.monetization_on;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: color, strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: color),
                    const SizedBox(width: 5),
                    Text('$price',
                        style: GoogleFonts.robotoMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _openButton(bool enabled, bool loading, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.purple.withValues(alpha: 0.16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
          ),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.purpleLt, strokeWidth: 2),
                )
              : Text('ABRIR',
                  style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.purpleLt)),
        ),
      ),
    );
  }

  Widget _qtyBadge(int count) {
    final on = count > 0;
    final color = on ? AppColors.gold : AppColors.txtMut;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xCC0B0810),
        border: Border.all(color: color.withValues(alpha: on ? 0.6 : 0.35)),
      ),
      child: Text('x$count',
          style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: on ? AppColors.goldLt : AppColors.txtMut)),
    );
  }

  // ── Revelação das 5 cartas ──────────────────────────────────────────
  Widget _buildReveal(List<_RevealCard> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CARTAS REVELADAS',
          style: GoogleFonts.roboto(
              fontSize: 11, letterSpacing: 1.8, color: AppColors.txtMut),
        ),
        const SizedBox(height: 10),
        for (final c in cards) ...[
          _revealRow(c),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _revealRow(_RevealCard c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF181221), Color(0xFF0A0810)],
        ),
        border: Border.all(color: c.conceptColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Gema de raridade
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.rarityColor,
              boxShadow: [
                BoxShadow(
                    color: c.rarityColor.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            c.kind == 'relic' ? Icons.shield_outlined : Icons.pets,
            size: 16,
            color: c.conceptColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.txt),
                ),
                Text(
                  '${c.rarityLabel} · ${c.kind == 'relic' ? 'Relíquia' : 'Criatura'}',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.txt2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _newBadge(c.isNew),
        ],
      ),
    );
  }

  Widget _newBadge(bool isNew) {
    final color = isNew ? AppColors.gold : AppColors.txtMut;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        isNew ? 'NOVA' : 'repetida',
        style: GoogleFonts.roboto(
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: isNew ? AppColors.goldLt : AppColors.txt2,
        ),
      ),
    );
  }
}

// ── Cor por raridade/conceito (espelha a Coleção) ────────────────────────────
Color _rarityColorFor(Rarity r) {
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

String _rarityLabelFor(Rarity r) {
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

Color _conceptColorFor(CardConcept c) {
  switch (c) {
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

/// View-model de uma carta revelada. Resolve nome/conceito a partir do catálogo
/// (via `card_id`); cai num fallback seguro se o id não estiver no catálogo.
class _RevealCard {
  final String name;
  final String kind; // 'creature' | 'relic'
  final bool isNew;
  final Color conceptColor;
  final Color rarityColor;
  final String rarityLabel;

  const _RevealCard({
    required this.name,
    required this.kind,
    required this.isNew,
    required this.conceptColor,
    required this.rarityColor,
    required this.rarityLabel,
  });

  factory _RevealCard.fromRpc(Map<String, dynamic> json, CardCatalog? catalog) {
    final cardId = json['card_id'] as String? ?? '';
    final kind = json['kind'] as String? ?? 'creature';
    final isNew = json['is_new'] == true;

    // Raridade: prefere o catálogo (autoritativo); usa a string da RPC como
    // fallback. Se nada casar, default comum.
    Rarity? rarity;
    String name = cardId;
    List<CardConcept> concepts = const [];

    if (catalog != null) {
      if (kind == 'relic') {
        final relic = catalog.relics.where((r) => r.id == cardId);
        if (relic.isNotEmpty) {
          name = relic.first.nome;
          rarity = relic.first.rarity;
          concepts = relic.first.concepts;
        }
      } else {
        final creature = catalog.creatures.where((c) => c.id == cardId);
        if (creature.isNotEmpty) {
          name = creature.first.nome;
          rarity = creature.first.rarity;
          concepts = creature.first.concepts;
        }
      }
    }

    rarity ??= _safeRarity(json['rarity'] as String?);

    final conceptColor = concepts.isEmpty
        ? AppColors.conceptNeutro
        : _conceptColorFor(concepts.first);

    return _RevealCard(
      name: name,
      kind: kind,
      isNew: isNew,
      conceptColor: conceptColor,
      rarityColor: _rarityColorFor(rarity),
      rarityLabel: _rarityLabelFor(rarity),
    );
  }

  static Rarity _safeRarity(String? raw) {
    if (raw == null) return Rarity.comum;
    try {
      return rarityFromString(raw);
    } catch (_) {
      return Rarity.comum;
    }
  }
}
