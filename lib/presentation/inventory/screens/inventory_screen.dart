import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/enums/item_rarity.dart';
import '../../../domain/enums/item_type.dart';
import '../../../domain/enums/source_type.dart';
import '../../../domain/models/inventory_entry_with_spec.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

enum _Filter { all, equippable, consumable, material, special }

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Future<List<InventoryEntryWithSpec>>? _future;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reload() {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      final empty = Future<List<InventoryEntryWithSpec>>.value(const []);
      setState(() { _future = empty; });
      return;
    }
    final svc = ref.read(playerInventoryServiceProvider);
    final future = svc.listOf(player.id);
    setState(() { _future = future; });
  }

  PlayerSnapshot? _snapshotFromCurrent() {
    final p = ref.read(currentPlayerProvider);
    if (p == null) return null;
    return PlayerSnapshot(
      level: p.level,
      rank: ItemEquipPolicy.parseRank(p.guildRank),
      classKey: p.classType,
      factionKey: p.factionType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabs(),
                Expanded(child: _buildTabContent()),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/sanctuary'),
            child: const Icon(Icons.arrow_back_ios,
                color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'INVENTÁRIO',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.gold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          FutureBuilder<List<InventoryEntryWithSpec>>(
            future: _future,
            builder: (_, snap) {
              final n = snap.data?.length ?? 0;
              return Text('$n itens',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.textMuted));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tab,
      isScrollable: true,
      indicatorColor: AppColors.purpleLight,
      labelColor: AppColors.purpleLight,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: GoogleFonts.cinzelDecorative(
          fontSize: 11, letterSpacing: 2),
      unselectedLabelStyle: GoogleFonts.cinzelDecorative(
          fontSize: 11, letterSpacing: 2),
      tabs: const [
        Tab(text: 'TUDO'),
        Tab(text: 'EQUIPÁVEL'),
        Tab(text: 'CONSUMÍVEIS'),
        Tab(text: 'MATERIAIS'),
        Tab(text: 'ESPECIAIS'),
        Tab(text: 'FORJA'),
      ],
    );
  }

  Widget _buildTabContent() {
    return FutureBuilder<List<InventoryEntryWithSpec>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.purple),
          );
        }
        if (snap.hasError) {
          return _ErrorView(
              message: 'Erro ao carregar inventário:\n\n'
                  '${snap.error}\n\n'
                  '${snap.stackTrace ?? ""}');
        }
        final items = snap.data ?? const <InventoryEntryWithSpec>[];
        return TabBarView(
          controller: _tab,
          children: [
            _buildList(_filterBy(items, _Filter.all)),
            _buildList(_filterBy(items, _Filter.equippable)),
            _buildList(_filterBy(items, _Filter.consumable)),
            _buildList(_filterBy(items, _Filter.material)),
            _buildList(_filterBy(items, _Filter.special)),
            const _ForgeShortcut(),
          ],
        );
      },
    );
  }

  List<InventoryEntryWithSpec> _filterBy(
    List<InventoryEntryWithSpec> items,
    _Filter filter,
  ) {
    switch (filter) {
      case _Filter.all:
        return items;
      case _Filter.equippable:
        return items.where((e) => e.spec.isEquippable).toList();
      case _Filter.consumable:
        return items.where((e) => e.spec.isConsumable).toList();
      case _Filter.material:
        return items.where((e) => e.spec.type == ItemType.material).toList();
      case _Filter.special:
        const specialTypes = {
          ItemType.lore,
          ItemType.key,
          ItemType.chest,
          ItemType.cosmetic,
          ItemType.title,
          ItemType.currency,
          ItemType.darkItem,
        };
        return items.where((e) => specialTypes.contains(e.spec.type)).toList();
    }
  }

  Widget _buildList(List<InventoryEntryWithSpec> items) {
    if (items.isEmpty) {
      return _EmptyListView();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _InventoryCard(
        item: items[i],
        onTap: () => _openDetails(items[i]),
      ),
    );
  }

  Future<void> _openDetails(InventoryEntryWithSpec item) async {
    final action = await showModalBottomSheet<_DetailAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ItemDetailsSheet(item: item),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _DetailAction.equip:
        await _equip(item);
      case _DetailAction.unequip:
        await _unequip(item);
      case _DetailAction.consume:
        await _consume(item);
    }
  }

  Future<void> _equip(InventoryEntryWithSpec item) async {
    final snapshot = _snapshotFromCurrent();
    if (snapshot == null) return;
    final svc = ref.read(playerEquipmentServiceProvider);
    final result = await svc.equip(
      playerId: item.entry.playerId,
      inventoryId: item.entry.id,
      player: snapshot,
    );
    if (!mounted) return;
    if (result.isOk) {
      _snack('${item.spec.name} equipado.', success: true);
    } else {
      _snack(_rejectLabel(result.reason!, item.spec.requiredLevel));
    }
    _reload();
  }

  Future<void> _unequip(InventoryEntryWithSpec item) async {
    final slot = item.spec.slot;
    if (slot == null) return;
    final svc = ref.read(playerEquipmentServiceProvider);
    await svc.unequip(playerId: item.entry.playerId, slot: slot);
    if (!mounted) return;
    _snack('${item.spec.name} desequipado.');
    _reload();
  }

  Future<void> _consume(InventoryEntryWithSpec item) async {
    final svc = ref.read(playerInventoryServiceProvider);
    final ok = await svc.consumeItem(item.entry.id);
    if (!mounted) return;
    _snack(ok ? '${item.spec.name} consumido.' : 'Não foi possível consumir.');
    _reload();
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF0E0E1A),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: (success ? AppColors.shadowAscending : AppColors.gold)
              .withValues(alpha: 0.6),
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.roboto(fontSize: 13, color: AppColors.textPrimary),
      ),
      duration: const Duration(milliseconds: 2500),
    ));
  }

  String _rejectLabel(RejectReason reason, int requiredLevel) {
    return switch (reason) {
      RejectReason.notEquippable     => 'Este item não pode ser equipado.',
      RejectReason.tooLowLevel       => 'Nível insuficiente (requer $requiredLevel).',
      RejectReason.tooLowRank        => 'Rank da Guilda insuficiente.',
      RejectReason.classRestricted   => 'Sua classe não pode equipar isto.',
      RejectReason.factionRestricted => 'Sua facção não pode equipar isto.',
      RejectReason.slotOccupied      => 'Slot ocupado.',
    };
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline, color: AppColors.hp, size: 24),
              SizedBox(width: 8),
              Text('DEBUG',
                  style: TextStyle(
                      color: AppColors.hp,
                      fontSize: 12,
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            message,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

// Sprint 2.2 Bloco 7 — aba "Forja" no inventário. Não lista itens — é atalho
// de navegação pra /forge.
class _ForgeShortcut extends StatelessWidget {
  const _ForgeShortcut();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 24, 36, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(Icons.hardware,
                  color: AppColors.gold, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'Acesso rápido à Forja',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 14,
                  color: AppColors.gold,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Criar armas, armaduras e processar materiais.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('/forge'),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.55),
                      width: 1.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'IR PRA FORJA',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 12,
                      color: AppColors.gold,
                      letterSpacing: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.3), size: 46),
          const SizedBox(height: 12),
          Text('Nenhum item aqui.',
              style: GoogleFonts.roboto(
                  color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryEntryWithSpec item;
  final VoidCallback onTap;

  const _InventoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rarityColor = item.spec.rarity.color;
    final isEquipped = item.entry.isEquipped;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
              ),
              child: Icon(_typeIcon(item.spec.type),
                  color: rarityColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.spec.name,
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              letterSpacing: 1),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isEquipped) ...[
                        const SizedBox(width: 6),
                        const _TagBadge(
                          text: 'EQUIP.',
                          color: AppColors.shadowAscending,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TagBadge(
                        text: item.spec.rarity.label.toUpperCase(),
                        color: rarityColor,
                      ),
                      if (item.spec.rank != null) ...[
                        const SizedBox(width: 6),
                        _TagBadge(
                          text: 'RANK ${item.spec.rank!.name.toUpperCase()}',
                          color: AppColors.gold,
                        ),
                      ],
                      if (item.spec.isUnique) ...[
                        const SizedBox(width: 6),
                        const _TagBadge(
                            text: 'ÚNICO', color: AppColors.purpleLight),
                      ],
                      if (item.spec.isSecret) ...[
                        const SizedBox(width: 6),
                        const _TagBadge(text: 'SECRETO', color: AppColors.hp),
                      ],
                      if (item.entry.quantity > 1) ...[
                        const SizedBox(width: 8),
                        Text('×${item.entry.quantity}',
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                  if (item.spec.durabilityMax != null &&
                      item.entry.durabilityCurrent != null) ...[
                    const SizedBox(height: 6),
                    _DurabilityBar(
                      current: item.entry.durabilityCurrent!,
                      max: item.spec.durabilityMax!,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(ItemType t) => switch (t) {
        ItemType.weapon     => Icons.gavel,
        ItemType.armor      => Icons.shield_outlined,
        ItemType.accessory  => Icons.circle_outlined,
        ItemType.shield     => Icons.shield,
        ItemType.tome       => Icons.menu_book_outlined,
        ItemType.relic      => Icons.auto_awesome,
        ItemType.consumable => Icons.local_pharmacy_outlined,
        ItemType.material   => Icons.category_outlined,
        ItemType.chest      => Icons.inventory_2_outlined,
        ItemType.key        => Icons.key,
        ItemType.title      => Icons.workspace_premium,
        ItemType.cosmetic   => Icons.brush_outlined,
        ItemType.lore       => Icons.history_edu_outlined,
        ItemType.currency   => Icons.diamond_outlined,
        ItemType.darkItem   => Icons.dark_mode_outlined,
        ItemType.misc       => Icons.help_outline,
      };
}

class _TagBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _TagBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
            fontSize: 9, color: color, letterSpacing: 0.8),
      ),
    );
  }
}

class _DurabilityBar extends StatelessWidget {
  final int current;
  final int max;
  const _DurabilityBar({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final color = pct > 0.5
        ? AppColors.shadowAscending
        : (pct > 0.2 ? AppColors.gold : AppColors.hp);
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$current/$max',
            style: GoogleFonts.roboto(fontSize: 9, color: color)),
      ],
    );
  }
}

enum _DetailAction { equip, unequip, consume }

class _ItemDetailsSheet extends StatelessWidget {
  final InventoryEntryWithSpec item;
  const _ItemDetailsSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final spec = item.spec;
    final isEquipped = item.entry.isEquipped;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spec.name,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 17,
                    color: spec.rarity.color,
                    letterSpacing: 2)),
            if (spec.rank != null) ...[
              const SizedBox(height: 4),
              Text('Rank ${spec.rank!.name.toUpperCase()}',
                  style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.gold,
                      letterSpacing: 1)),
            ],
            const SizedBox(height: 14),
            Text(spec.description,
                style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            if (spec.stats.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('ATRIBUTOS'),
              const SizedBox(height: 6),
              for (final entry in spec.stats.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Text('+ ${entry.value}',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 12, color: AppColors.gold)),
                      const SizedBox(width: 10),
                      Text(entry.key.toUpperCase(),
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
            ],
            if (spec.effects.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('EFEITOS'),
              const SizedBox(height: 6),
              for (final entry in spec.effects.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• ${entry.key}: ${entry.value}',
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.5)),
                ),
            ],
            if (spec.sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('ORIGEM'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in spec.sources)
                    _TagBadge(
                      text: (s.type?.label ?? s.rawType ?? '???').toUpperCase(),
                      color: AppColors.purpleLight,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            _buildActions(context, spec, isEquipped),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.cinzelDecorative(
            fontSize: 11, color: AppColors.purpleLight, letterSpacing: 3),
      );

  Widget _buildActions(BuildContext context, spec, bool isEquipped) {
    final actions = <Widget>[];
    if (spec.isEquippable && spec.slot != null) {
      if (isEquipped) {
        actions.add(_ActionButton(
          label: 'Desequipar',
          color: AppColors.gold,
          onTap: () => Navigator.pop(context, _DetailAction.unequip),
        ));
      } else {
        actions.add(_ActionButton(
          label: 'Equipar',
          color: AppColors.purpleLight,
          onTap: () => Navigator.pop(context, _DetailAction.equip),
        ));
      }
    }
    if (spec.isConsumable) {
      actions.add(_ActionButton(
        label: 'Usar',
        color: AppColors.shadowAscending,
        onTap: () => Navigator.pop(context, _DetailAction.consume),
      ));
    }
    if (actions.isEmpty) return const SizedBox();
    return Column(children: [
      for (int i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        actions[i],
      ],
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.4),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.cinzelDecorative(
              fontSize: 12, color: color, letterSpacing: 3),
        ),
      ),
    );
  }
}
