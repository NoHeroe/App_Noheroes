import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Text('INVENTÁRIO',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                      const Spacer(),
                      inventoryAsync.when(
                        data: (inv) => Text(
                            '${inv.length} itens',
                            style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: AppColors.textMuted)),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tab,
                  indicatorColor: AppColors.purple,
                  labelColor: AppColors.purple,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: GoogleFonts.roboto(fontSize: 12),
                  tabs: const [
                    Tab(text: 'Todos'),
                    Tab(text: 'Equipamentos'),
                    Tab(text: 'Consumíveis'),
                  ],
                ),

                Expanded(
                  child: inventoryAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.purple)),
                    error: (e, _) => Center(
                        child: Text('Erro: $e',
                            style: const TextStyle(
                                color: AppColors.textMuted))),
                    data: (items) => TabBarView(
                      controller: _tab,
                      children: [
                        _buildList(items, null),
                        _buildList(items.where((i) =>
                            i.item.slot != null).toList(), null),
                        _buildList(items.where((i) =>
                            i.item.isConsumable).toList(), null),
                      ],
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

  Widget _buildList(List<InventoryWithItem> items, String? filter) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                color: AppColors.textMuted.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text('Nenhum item aqui.',
                style: GoogleFonts.roboto(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Visite a loja para adquirir itens.',
                style: GoogleFonts.roboto(
                    color: AppColors.textMuted.withOpacity(0.6),
                    fontSize: 11)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: items.length,
      itemBuilder: (_, i) => _ItemCard(
        inv: items[i],
        onEquip: items[i].item.slot != null
            ? () => _equip(items[i])
            : null,
      ),
    );
  }

  Future<void> _equip(InventoryWithItem inv) async {
    await ref.read(inventoryDaoProvider).equipItem(
        inv.entry.id, inv.item.slot!);
    ref.invalidate(inventoryProvider);
  }
}

class _ItemCard extends StatelessWidget {
  final InventoryWithItem inv;
  final VoidCallback? onEquip;

  const _ItemCard({required this.inv, this.onEquip});

  Color get _rarityColor => switch (inv.item.rarity) {
    'common'    => AppColors.rarityCommon,
    'uncommon'  => AppColors.rarityUncommon,
    'rare'      => AppColors.rarityRare,
    'epic'      => AppColors.rarityEpic,
    'legendary' => AppColors.rarityLegendary,
    'mythic'    => AppColors.rarityMythic,
    _ => AppColors.rarityCommon,
  };

  String get _rarityLabel => switch (inv.item.rarity) {
    'common'    => 'Comum',
    'uncommon'  => 'Incomum',
    'rare'      => 'Raro',
    'epic'      => 'Épico',
    'legendary' => 'Lendário',
    'mythic'    => 'Mítico',
    _ => 'Comum',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rarityColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          // Ícone com raridade
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _rarityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _rarityColor.withOpacity(0.4)),
            ),
            child: Icon(_typeIcon, color: _rarityColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(inv.item.name,
                        style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                    if (inv.entry.isEquipped) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.shadowAscending.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Equipado',
                            style: GoogleFonts.roboto(
                                fontSize: 9,
                                color: AppColors.shadowAscending)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(inv.item.description,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _rarityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_rarityLabel,
                          style: GoogleFonts.roboto(
                              fontSize: 9, color: _rarityColor)),
                    ),
                    if (inv.entry.quantity > 1) ...[
                      const SizedBox(width: 6),
                      Text('x${inv.entry.quantity}',
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Botão equipar
          if (onEquip != null && !inv.entry.isEquipped)
            GestureDetector(
              onTap: onEquip,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.purple.withOpacity(0.4)),
                ),
                child: Text('Equipar',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.purple)),
              ),
            ),
        ],
      ),
    );
  }

  IconData get _typeIcon => switch (inv.item.type) {
    'weapon'     => Icons.gavel,
    'armor'      => Icons.shield,
    'helmet'     => Icons.security,
    'boots'      => Icons.hiking,
    'gloves'     => Icons.back_hand_outlined,
    'shoulders'  => Icons.accessibility_new,
    'relic'      => Icons.auto_awesome,
    'accessory'  => Icons.circle_outlined,
    'consumable' => Icons.local_pharmacy_outlined,
    'material'   => Icons.category_outlined,
    _ => Icons.inventory_2_outlined,
  };
}
