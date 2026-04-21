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
import '../../shared/widgets/level_locked_view.dart';

// Tela /shop/:shopKey — loja individual. Lista itens filtrados, compra via
// ShopsService.buyItem retornando BuyResult.
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
    );
    if (!mounted) return;

    if (result.isOk) {
      // Refresca player no provider pra refletir o ouro debitado.
      final updated = await PlayerDao(ref.read(appDatabaseProvider))
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
      body: SafeArea(
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
                : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _items.isEmpty
                        ? _emptyShop()
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 14, 16, 28),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _ItemRow(
                              view: _items[i],
                              onBuy: () => _buy(_items[i]),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => context.go('/shops'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_shop?.name ?? '').toUpperCase(),
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 13,
                      color: AppColors.gold,
                      letterSpacing: 3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_shop?.description.isNotEmpty ?? false)
                  Text(_shop!.description,
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Sprint 2.2 Bloco 7 — atalho contextual pra Forja quando loja é o
          // Ferreiro de Aureum. Outras lojas não mostram.
          if (_shop?.key == 'blacksmith_aureum')
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => context.go('/forge'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hardware,
                          size: 12, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text('FORJA',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 10,
                              color: AppColors.gold,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          Consumer(
            builder: (_, ref, __) {
              final p = ref.watch(currentPlayerProvider);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('🪙 ${p?.gold ?? 0}',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.gold)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyShop() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          'Nenhum item disponível pra teu nível/rank nesta loja.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
              fontSize: 12, color: AppColors.textMuted, height: 1.5),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ShopItemView view;
  final Future<void> Function() onBuy;
  const _ItemRow({required this.view, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    // Sprint 2.2 pós-teste: soft-gate. Itens com canInteract=false aparecem
    // com opacidade reduzida + tap abre AlertDialog explicando o motivo
    // (em vez de filtrar silenciosamente).
    final rarityColor = view.spec.rarity.color;
    final locked = !view.canInteract;
    final color = locked ? AppColors.textMuted : rarityColor;
    final textColor =
        locked ? AppColors.textMuted : AppColors.textPrimary;
    final priceText = view.priceCoins != null
        ? '🪙 ${view.priceCoins}'
        : (view.priceGems != null ? '💎 ${view.priceGems}' : '—');

    return Opacity(
      opacity: locked ? 0.55 : 1.0,
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
                            : (view.canAfford ? 'COMPRAR' : 'SEM OURO'),
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
