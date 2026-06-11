import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/nh_atmosphere.dart';
import '../../shared/widgets/nh_back_button.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_models.dart';
import '../card_ownership.dart';
import '../widgets/pack_reveal_overlay.dart';

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
  static const int _packPrice = 224;
  static const String _packType = 'padrao';

  bool _loadingHeader = true; // carga inicial (count + catálogo)
  bool _buying = false;
  bool _opening = false;

  int _packCount = 0;
  CardCatalog? _catalog;
  String? _loadError;

  /// Resultado da última abertura (5 cartas reveladas). null = sem revelação.
  List<_RevealCard>? _reveal;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final catalog = await CardCatalog.load();
      final count = await _fetchPackCount();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _packCount = count;
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

  /// Lê o count de pacotes do tipo padrão (RLS filtra o jogador; null = 0).
  Future<int> _fetchPackCount() async {
    final client = ref.read(supabaseClientProvider);
    final row = await client
        .from('player_packs')
        .select('count')
        .eq('pack_type', _packType)
        .maybeSingle();
    if (row == null) return 0;
    return (row['count'] as int?) ?? 0;
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
  Future<void> _buy() async {
    if (_buying || _opening) return;
    setState(() => _buying = true);
    try {
      final player = ref.read(currentPlayerProvider);
      if (player == null) {
        _snack('Sessão expirada.');
        return;
      }
      final res = await ref.read(supabaseClientProvider).rpc(
        'buy_pack',
        params: {'p_player': player.id},
      );
      final map = (res as Map).cast<String, dynamic>();
      final ok = map['ok'] == true;
      if (!ok) {
        if (map['reason'] == 'insufficient_gold') {
          _snack('Ouro insuficiente');
        } else {
          _snack('Não foi possível comprar o pacote.');
        }
        return;
      }
      // Sucesso: gold debitado + 1 pacote. Reatualiza gold e count.
      await _refreshPlayer();
      final count = await _fetchPackCount();
      if (!mounted) return;
      setState(() => _packCount = count);
      _snack('Pacote comprado!');
    } catch (e) {
      _snack('Erro de rede. Tente novamente.');
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  // ── Abrir ───────────────────────────────────────────────────────────
  Future<void> _open() async {
    if (_buying || _opening || _packCount < 1) return;
    setState(() {
      _opening = true;
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
        params: {'p_player': player.id},
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

      // Consumiu 1 pacote no servidor: atualiza count e invalida posse.
      final count = await _fetchPackCount();
      ref.invalidate(cardOwnershipProvider);
      if (!mounted) return;
      setState(() {
        _packCount = count;
        _reveal = reveal;
      });
      // Revelação em tela cheia (Clash Royale): carta a carta + PULAR.
      await PackRevealOverlay.show(context, entries);
    } catch (e) {
      _snack('Erro de rede. Tente novamente.');
    } finally {
      if (mounted) setState(() => _opening = false);
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(gold),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(gold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int gold) {
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildPackCard(gold),
        const SizedBox(height: 20),
        if (_reveal != null) _buildReveal(_reveal!),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(int gold) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          NhBackButton(
            onTap: () => context.canPop() ? context.pop() : context.go('/library'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PACOTES',
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
                  'Obtenção de cartas',
                  style: GoogleFonts.roboto(
                      fontSize: 11, letterSpacing: 2, color: AppColors.txtMut),
                ),
              ],
            ),
          ),
          _goldPill(gold),
        ],
      ),
    );
  }

  Widget _goldPill(int gold) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xB3100C15),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 15, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            '$gold',
            style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.goldLt),
          ),
        ],
      ),
    );
  }

  // ── Card do Pacote Padrão ───────────────────────────────────────────
  Widget _buildPackCard(int gold) {
    final canBuy = gold >= _packPrice && !_buying && !_opening;
    final canOpen = _packCount >= 1 && !_buying && !_opening;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF221A2E), Color(0xFF0B0810)],
        ),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.45)),
        boxShadow: const [
          BoxShadow(color: AppColors.purpleGlow45, blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.55),
                      const Color(0xFF0B0810),
                    ],
                  ),
                  border:
                      Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.inventory_2,
                    size: 28, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pacote Padrão',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLt),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '5 cartas · $_packPrice de ouro',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.txt2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x33100C15),
              border: Border.all(color: AppColors.borderViolet),
            ),
            child: Row(
              children: [
                const Icon(Icons.backpack_outlined,
                    size: 16, color: AppColors.txt2),
                const SizedBox(width: 8),
                Text('Pacotes que você tem:',
                    style: GoogleFonts.roboto(
                        fontSize: 12.5, color: AppColors.txt2)),
                const Spacer(),
                Text(
                  '$_packCount',
                  style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldLt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'COMPRAR ($_packPrice)',
                  icon: Icons.shopping_cart_outlined,
                  enabled: canBuy,
                  loading: _buying,
                  primary: false,
                  onTap: _buy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: 'ABRIR',
                  icon: Icons.auto_awesome,
                  enabled: canOpen,
                  loading: _opening,
                  primary: true,
                  onTap: _open,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required bool loading,
    required bool primary,
    required VoidCallback onTap,
  }) {
    final base = primary ? AppColors.purple : AppColors.gold;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                base.withValues(alpha: 0.32),
                base.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: base.withValues(alpha: 0.55)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: AppColors.txt, strokeWidth: 2.2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: AppColors.txt),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.txt,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
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
