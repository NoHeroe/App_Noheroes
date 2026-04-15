import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../shared/widgets/nh_bottom_nav.dart';
import '../../shared/widgets/app_snack.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopProvider);
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header com ouro
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/sanctuary'),
                        child: const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text('MERCADO',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/inventory'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 14),
                            const SizedBox(width: 4),
                            Text('Inventário', style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textSecondary)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          const Text('🪙', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text('${player?.gold ?? 0}',
                              style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                ),

                // Itens da loja
                Expanded(
                  child: shopAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.purple)),
                    error: (e, _) => Center(
                        child: Text('Erro: $e',
                            style: const TextStyle(
                                color: AppColors.textMuted))),
                    data: (items) => ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _ShopCard(
                        shopItem: items[i],
                        playerGold: player?.gold ?? 0,
                        onBuy: () =>
                            _buy(context, ref, items[i], player?.gold ?? 0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: NhBottomNav(currentIndex: 1),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context, WidgetRef ref,
      ShopWithItem shopItem, int gold) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final error = await ref.read(inventoryDaoProvider).buyItem(
      playerId: player.id,
      itemId: shopItem.item.id,
      price: shopItem.shop.price,
      playerGold: gold,
      currency: shopItem.shop.currency,
    );

    if (error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.shadowChaotic,
        ));
      }
      return;
    }

    // Desconta ouro
    await PlayerDao(ref.read(appDatabaseProvider))
        .addGold(player.id, -shopItem.shop.price);

    // Atualiza dados
    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;
    ref.invalidate(inventoryProvider);
    ref.invalidate(shopProvider);

    if (context.mounted) {
      AppSnack.success(context, '${shopItem.item.name} adquirido!');
    }
  }
}

class _ShopCard extends StatelessWidget {
  final ShopWithItem shopItem;
  final int playerGold;
  final VoidCallback onBuy;

  const _ShopCard({
    required this.shopItem,
    required this.playerGold,
    required this.onBuy,
  });

  Color get _rarityColor => switch (shopItem.item.rarity) {
    'common'    => AppColors.rarityCommon,
    'uncommon'  => AppColors.rarityUncommon,
    'rare'      => AppColors.rarityRare,
    'epic'      => AppColors.rarityEpic,
    'legendary' => AppColors.rarityLegendary,
    _ => AppColors.rarityCommon,
  };

  bool get _canAfford => playerGold >= shopItem.shop.price;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _rarityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _rarityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _rarityColor.withOpacity(0.3)),
            ),
            child: Icon(_typeIcon, color: _rarityColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopItem.item.name,
                    style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(shopItem.item.description,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
                if (shopItem.shop.requiredLevel > 1)
                  Text('Nível ${shopItem.shop.requiredLevel}+ necessário',
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _canAfford ? onBuy : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _canAfford
                    ? AppColors.gold.withOpacity(0.15)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _canAfford
                      ? AppColors.gold.withOpacity(0.5)
                      : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  Text('${shopItem.shop.price}',
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: _canAfford
                              ? AppColors.gold
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _typeIcon => switch (shopItem.item.type) {
    'weapon'     => Icons.gavel,
    'armor'      => Icons.shield,
    'consumable' => Icons.local_pharmacy_outlined,
    'material'   => Icons.category_outlined,
    'accessory'  => Icons.circle_outlined,
    _ => Icons.store_outlined,
  };
}
