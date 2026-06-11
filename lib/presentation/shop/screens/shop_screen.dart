import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../../data/datasources/local/shops_service.dart';
import '../../../domain/enums/item_rarity.dart';
import '../../../domain/enums/item_type.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/shop_item_view.dart';
import '../../../domain/models/shop_spec.dart';
import '../../sanctuary/widgets/sanctuary_header_widgets.dart';
import '../../shared/widgets/level_locked_view.dart';

// Tela /shop/:shopKey — loja individual. Sem header: só wallet (padrão
// Santuário) + atalho de Inventário, filtro por tipo, lista de itens
// (bloqueados 100% cinza e ao final) e uma bancada com NPC embaixo.
class ShopScreen extends ConsumerStatefulWidget {
  final String shopKey;
  const ShopScreen({super.key, required this.shopKey});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ShopSpec? _shop;
  List<ShopItemView> _items = const [];
  bool _loading = true;
  String? _error;

  ItemType? _typeFilter; // null = Todos
  int _npcLine = 0; // linha atual da fala do NPC (tap cicla).

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  PlayerSnapshot? _snapshot() {
    final p = ref.read(currentPlayerProvider);
    if (p == null) return null;
    return PlayerSnapshot(
      level:      p.level,
      rank:       ItemEquipPolicy.parseRank(p.guildRank),
      classKey:   p.classType,
      factionKey: p.factionType,
    );
  }

  Future<void> _reload() async {
    try {
      final player = ref.read(currentPlayerProvider);
      final snap   = _snapshot();
      if (player == null || snap == null) {
        if (mounted) context.go('/login');
        return;
      }
      final svc  = ref.read(shopsServiceProvider);
      final shop = await svc.findByKey(widget.shopKey);
      if (shop == null) {
        if (mounted) context.go('/shops');
        return;
      }
      final items = await svc.itemsOf(
        shopKey:     widget.shopKey,
        player:      snap,
        playerCoins: player.gold,
        playerGems:  player.gems,
        playerInsignias: player.insignias,
      );
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e\n\n$st';
      });
    }
  }

  Future<void> _buy(ShopItemView view) async {
    final player = ref.read(currentPlayerProvider);
    final snap   = _snapshot();
    if (player == null || snap == null || _shop == null) return;

    final svc = ref.read(shopsServiceProvider);
    final result = await svc.buyItem(
      shopKey:     _shop!.key,
      itemKey:     view.spec.key,
      playerId:    player.id,
      player:      snap,
      playerCoins: player.gold,
      playerGems:  player.gems,
      playerInsignias: player.insignias,
    );
    if (!mounted) return;

    if (result.isOk) {
      // Refresca player no provider pra refletir o ouro debitado.
      final updated = await PlayerDao(ref.read(supabaseClientProvider))
          .findById(player.id);
      if (!mounted) return;
      ref.read(currentPlayerProvider.notifier).state = updated;
      _snack('${view.spec.name} comprado.', success: true);
      await _reload();
    } else {
      _snack(_rejectLabel(result.reason!));
    }
  }

  String _rejectLabel(BuyRejectReason r) => switch (r) {
        BuyRejectReason.insufficientCoins      => 'Ouro insuficiente.',
        BuyRejectReason.insufficientGems       => 'Gemas insuficientes.',
        BuyRejectReason.insufficientInsignias  => 'Insígnias insuficientes.',
        BuyRejectReason.levelTooLow            => 'Nível insuficiente.',
        BuyRejectReason.rankTooLow             => 'Rank insuficiente.',
        BuyRejectReason.classRestricted        => 'Classe não permitida.',
        BuyRejectReason.factionRestricted      => 'Facção não permitida.',
        BuyRejectReason.shopRejectsPlayerRank  => 'Esta loja exige rank.',
        BuyRejectReason.shopRejectsPlayerFaction => 'Esta loja exige facção específica.',
        BuyRejectReason.blockedBySourcePolicy  => 'Item indisponível em loja.',
        BuyRejectReason.itemNotInShop          => 'Item não está nesta loja.',
        BuyRejectReason.itemNotInCatalog       => 'Item inexistente.',
        BuyRejectReason.shopNotFound           => 'Loja não encontrada.',
        BuyRejectReason.noPriceDefined         => 'Preço não definido.',
        BuyRejectReason.dbError                => 'Erro ao processar.',
      };

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF0E0E1A),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: (success ? AppColors.shadowAscending : AppColors.hp)
              .withValues(alpha: 0.6),
        ),
      ),
      content: Text(message,
          style: GoogleFonts.roboto(
              fontSize: 13, color: AppColors.textPrimary)),
      duration: const Duration(milliseconds: 2200),
    ));
  }

  // Itens visíveis: filtra por tipo e empurra os BLOQUEADOS pro fim.
  List<ShopItemView> _visibleItems() {
    Iterable<ShopItemView> src = _items;
    if (_typeFilter != null) {
      src = src.where((v) => v.spec.type == _typeFilter);
    }
    final unlocked = src.where((v) => v.canInteract).toList();
    final locked = src.where((v) => !v.canInteract).toList();
    return [...unlocked, ...locked];
  }

  @override
  Widget build(BuildContext context) {
    // Sprint 2.3 Bloco 0.B — Ferreiro de Aureum requer nível 6.
    if (widget.shopKey == 'blacksmith_aureum') {
      final player = ref.watch(currentPlayerProvider);
      final level = player?.level ?? 0;
      if (level < 6) {
        return LevelLockedView(
          requiredLevel: 6,
          currentLevel: level,
          featureName: 'Ferreiro de Aureum',
          onBack: () => context.go('/shops'),
        );
      }
    }
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold),
                  )
                : _error != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: SelectableText(
                          'Erro ao carregar loja:\n\n$_error',
                          style: const TextStyle(
                              color: AppColors.hp,
                              fontSize: 11,
                              fontFamily: 'monospace'),
                        ),
                      )
                    : _content(),
          ),
        ],
      ),
    );
  }

  // Fundo quente sutil (mantém a lista legível, sem a atmosfera cheia).
  Widget _background() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.7),
          radius: 1.3,
          colors: [Color(0xFF231711), Color(0xFF120C09), Color(0xFF0A0705)],
          stops: [0.0, 0.5, 0.85],
        ),
      ),
    );
  }

  Widget _content() {
    final visible = _visibleItems();
    return Column(
      children: [
        _topBar(),
        const SizedBox(height: 8),
        _typeFilterBar(),
        const SizedBox(height: 6),
        Expanded(
          child: visible.isEmpty
              ? _emptyShop()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final v = visible[i];
                    final tile = _ItemRow(view: v, onBuy: () => _buy(v));
                    // Bloqueado = 100% cinza (dessaturado).
                    return v.canInteract
                        ? tile
                        : ColorFiltered(
                            colorFilter: _grayscale, child: tile);
                  },
                ),
        ),
        _benchNpc(),
      ],
    );
  }

  // Topo: voltar (esq) + wallet (Santuário) com o botão de Inventário logo
  // abaixo. Sem título — header removido.
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.go('/shops'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A1B12), Color(0xFF0B0705)],
                ),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.goldLt, size: 15),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SanctuaryWalletPills(),
              const SizedBox(height: 8),
              _inventoryButton(),
              // Atalho pra Forja preservado quando a loja é o Ferreiro.
              if (_shop?.key == 'blacksmith_aureum') ...[
                const SizedBox(height: 6),
                _pillButton(
                    Icons.hardware, 'FORJA', AppColors.gold, () => context.go('/forge')),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _inventoryButton() => _pillButton(
      Icons.backpack_outlined, 'INVENTÁRIO', AppColors.purpleLight,
      () => context.go('/inventory'));

  Widget _pillButton(
      IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xE6141019), Color(0xE60A080E)],
          ),
          border: Border.all(color: AppColors.borderViolet),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.txt)),
          ],
        ),
      ),
    );
  }

  // Filtro por tipo — chips com os tipos presentes na loja + "Todos".
  Widget _typeFilterBar() {
    final types = <ItemType>{for (final v in _items) v.spec.type}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    if (types.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _typeChip(null, 'Todos', Icons.apps),
          for (final t in types)
            _typeChip(t, _typeLabel(t), _typeIconOf(t)),
        ],
      ),
    );
  }

  Widget _typeChip(ItemType? type, String label, IconData icon) {
    final selected = _typeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: () => setState(() => _typeFilter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
                        blurRadius: 8)
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: selected ? AppColors.goldLt : AppColors.txt2),
              const SizedBox(width: 5),
              Text(label,
                  style: GoogleFonts.roboto(
                      fontSize: 11.5,
                      color: selected ? AppColors.goldLt : AppColors.txt2)),
            ],
          ),
        ),
      ),
    );
  }

  // Bancada com NPC — espaço de interação no rodapé. Tap cicla a fala.
  Widget _benchNpc() {
    final vendor = _vendorFor(_shop);
    final line = vendor.lines[_npcLine % vendor.lines.length];
    return GestureDetector(
      onTap: () => setState(() => _npcLine++),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3A2415), Color(0xFF1C110A)],
          ),
          border: Border(
            top: BorderSide(color: Color(0xFF6E4A28), width: 2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar do NPC (silhueta).
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF4A3320), Color(0xFF1A0F08)],
                ),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.55), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      blurRadius: 10),
                ],
              ),
              child: Icon(vendor.icon,
                  color: AppColors.goldLt.withValues(alpha: 0.9), size: 26),
            ),
            const SizedBox(width: 12),
            // Balão de fala.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vendor.name.toUpperCase(),
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: AppColors.gold)),
                  const SizedBox(height: 4),
                  Text('"$line"',
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                          color: AppColors.txt2)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chat_bubble_outline,
                size: 16, color: AppColors.gold.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _emptyShop() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          _typeFilter != null
              ? 'Nenhum item desse tipo nesta loja.'
              : 'Nenhum item disponível nesta loja.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
              fontSize: 12, color: AppColors.textMuted, height: 1.5),
        ),
      ),
    );
  }

  // ── Vendedor (persona por papel; sem inventar nomes próprios de lore) ──
  _Vendor _vendorFor(ShopSpec? shop) {
    switch (shop?.type) {
      case 'guild':
        return const _Vendor('Comerciante da Guilda', Icons.shield_outlined, [
          'Equipamento de confiança pra quem serve à Guilda.',
          'Rank fala mais alto aqui. Mostre o seu.',
          'Precisa de algo resistente? Veio ao lugar certo.',
        ]);
      case 'faction':
        return const _Vendor('Mercador da Facção', Icons.flag_outlined, [
          'Só os nossos compram aqui. Sorte a sua.',
          'Insígnias valem mais que ouro neste balcão.',
          'A facção provê pra quem prova lealdade.',
        ]);
      default:
        if (shop?.key == 'blacksmith_aureum') {
          return const _Vendor('Ferreiro de Aureum', Icons.hardware, [
            'Aço quente, preço justo. O que vai levar?',
            'Toda lâmina aqui passou pela minha bigorna.',
            'Quer forjar algo? A Forja fica logo ali.',
          ]);
        }
        return const _Vendor('Mercador de Aureum', Icons.storefront_outlined, [
          'Bem-vindo! Dá uma olhada no que chegou hoje.',
          'Suprimentos, poções, o básico do aventureiro.',
          'Ouro na mão? Então estamos entendidos.',
        ]);
    }
  }

  static String _typeLabel(ItemType t) => switch (t) {
        ItemType.weapon     => 'Arma',
        ItemType.armor      => 'Armadura',
        ItemType.accessory  => 'Acessório',
        ItemType.shield     => 'Escudo',
        ItemType.tome       => 'Tomo',
        ItemType.relic      => 'Relíquia',
        ItemType.consumable => 'Consumível',
        ItemType.material   => 'Material',
        _                   => 'Outro',
      };

  static IconData _typeIconOf(ItemType t) => switch (t) {
        ItemType.weapon     => Icons.gavel,
        ItemType.armor      => Icons.shield_outlined,
        ItemType.accessory  => Icons.circle_outlined,
        ItemType.shield     => Icons.shield,
        ItemType.tome       => Icons.menu_book_outlined,
        ItemType.relic      => Icons.auto_awesome,
        ItemType.consumable => Icons.local_pharmacy_outlined,
        ItemType.material   => Icons.category_outlined,
        _                   => Icons.inventory_2_outlined,
      };
}

/// Persona do vendedor da bancada (papel + ícone + falas que ciclam no tap).
class _Vendor {
  final String name;
  final IconData icon;
  final List<String> lines;
  const _Vendor(this.name, this.icon, this.lines);
}

/// Matriz de dessaturação (cinza 100%) para itens bloqueados.
const ColorFilter _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

class _ItemRow extends StatelessWidget {
  final ShopItemView view;
  final Future<void> Function() onBuy;
  const _ItemRow({required this.view, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    // Soft-gate: itens com canInteract=false aparecem dessaturados (cinza,
    // aplicado pelo ColorFiltered de fora) + tap abre o motivo.
    final rarityColor = view.spec.rarity.color;
    final locked = !view.canInteract;
    final color = locked ? AppColors.textMuted : rarityColor;
    final textColor =
        locked ? AppColors.textMuted : AppColors.textPrimary;
    final priceText = view.priceCoins != null
        ? '🪙 ${view.priceCoins}'
        : view.priceGems != null
            ? '💎 ${view.priceGems}'
            : view.priceInsignias != null
                ? '🎖️ ${view.priceInsignias}'
                : '—';
    final cantAffordLabel = view.priceInsignias != null
        ? 'SEM INSÍGNIAS'
        : view.priceGems != null
            ? 'SEM GEMAS'
            : 'SEM OURO';

    return Opacity(
      opacity: locked ? 0.85 : 1.0,
      child: GestureDetector(
        onTap: locked ? () => _showLockReason(context) : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(_typeIcon(view.spec.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(view.spec.name,
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 12,
                            color: textColor,
                            letterSpacing: 1),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(view.spec.description,
                        style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(view.spec.rarity.label.toUpperCase(),
                            rarityColor),
                        if (view.spec.rank != null) ...[
                          const SizedBox(width: 6),
                          _badge('RANK ${view.spec.rank!.name.toUpperCase()}',
                              AppColors.gold),
                        ],
                        if (locked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_outline,
                              size: 12, color: AppColors.textMuted),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(priceText,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: (!locked && view.canAfford)
                              ? AppColors.gold
                              : AppColors.textMuted)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: locked
                        ? () => _showLockReason(context)
                        : (view.canAfford ? onBuy : null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _actionBgColor(locked, view.canAfford)
                            .withValues(alpha: 0.1),
                        border: Border.all(
                            color: _actionBgColor(locked, view.canAfford)
                                .withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        locked
                            ? 'BLOQUEADO'
                            : (view.canAfford ? 'COMPRAR' : cantAffordLabel),
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 10,
                            color: _actionBgColor(locked, view.canAfford),
                            letterSpacing: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _actionBgColor(bool locked, bool canAfford) {
    if (locked) return AppColors.textMuted;
    if (!canAfford) return AppColors.textMuted;
    return AppColors.gold;
  }

  void _showLockReason(BuildContext context) {
    final reason = view.rejectReasonLabel ?? 'Item indisponível.';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          view.spec.name,
          style: GoogleFonts.cinzelDecorative(
              color: view.spec.rarity.color,
              fontSize: 14,
              letterSpacing: 1.5),
        ),
        content: Row(
          children: [
            const Icon(Icons.lock_outline,
                color: AppColors.textMuted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason,
                style: GoogleFonts.roboto(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.45),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: GoogleFonts.cinzelDecorative(
                    color: AppColors.gold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(text,
            style: GoogleFonts.roboto(
                fontSize: 9, color: color, letterSpacing: 0.8)),
      );

  IconData _typeIcon(ItemType t) => switch (t) {
        ItemType.weapon     => Icons.gavel,
        ItemType.armor      => Icons.shield_outlined,
        ItemType.accessory  => Icons.circle_outlined,
        ItemType.shield     => Icons.shield,
        ItemType.tome       => Icons.menu_book_outlined,
        ItemType.relic      => Icons.auto_awesome,
        ItemType.consumable => Icons.local_pharmacy_outlined,
        ItemType.material   => Icons.category_outlined,
        _                   => Icons.inventory_2_outlined,
      };
}
