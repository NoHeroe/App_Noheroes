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
import '../../../domain/models/enchant_spec.dart';
import '../../../domain/models/inventory_entry_with_spec.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../shared/widgets/feature_chip.dart';

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
    _tab = TabController(length: 5, vsync: this);
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
    // Sprint 2.3 fix — inventário é sub-tela de /character (acesso pelo
    // header), não precisa da nav bar do santuário. NhBottomNav removido
    // (estava emprestando indevidamente currentIndex:1 de Missões).
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Sprint 2.3 fix — chips de acesso a Forja e Encantamento substituem
    // a antiga aba FORJA do inventário. Gates: lv6 pra forja, lv20 pra enchant.
    final playerLevel = ref.watch(currentPlayerProvider)?.level ?? 0;
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
          FeatureChip(
            icon: Icons.hardware,
            label: 'FORJA',
            route: '/forge',
            requiredLevel: 6,
            playerLevel: playerLevel,
          ),
          FeatureChip(
            icon: Icons.auto_awesome,
            label: 'ENCANT.',
            route: '/enchant',
            requiredLevel: 20,
            playerLevel: playerLevel,
            color: AppColors.purpleLight,
          ),
          // Sprint 2.3 fix (B1) — contagem de itens removida (causava
          // overflow em telas pequenas quando chips FORJA + ENCANT. estavam
          // visíveis simultaneamente). Contagem por aba já é implícita nos
          // cards listados.
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
      // Sprint 2.3 fix (B2) — runas têm isConsumable=true (consumo real é
      // via EnchantService na transação atômica), mas NÃO devem aparecer
      // na aba CONSUMÍVEIS junto com poções/etc. Agrupadas com MATERIAIS
      // por decisão UX (ingredientes + runas = consumíveis passivos).
      case _Filter.consumable:
        return items.where((e) =>
            e.spec.isConsumable && e.spec.type != ItemType.rune).toList();
      case _Filter.material:
        return items.where((e) =>
            e.spec.type == ItemType.material ||
            e.spec.type == ItemType.rune).toList();
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
    // Sprint 2.3 Bloco 7.1 — pré-resolve specs de runa/seiva aplicadas pra
    // manter o sheet stateless. Catálogo é cached, custo desprezível.
    EnchantSpec? appliedRune;
    EnchantSpec? appliedSap;
    final runeKey = item.entry.appliedRuneKey;
    final sapKey = item.entry.appliedSapKey;
    if (runeKey != null || sapKey != null) {
      // Sprint 2.3 fix — runas agora vivem no items_catalog como ItemType.rune;
      // convertemos via EnchantSpec.fromItemSpec. Seivas continuam TBD (2.4).
      final catalog = ref.read(itemsCatalogServiceProvider);
      if (runeKey != null) {
        final item = await catalog.findByKey(runeKey);
        if (item != null) appliedRune = EnchantSpec.fromItemSpec(item);
      }
      if (sapKey != null) {
        final item = await catalog.findByKey(sapKey);
        if (item != null) appliedSap = EnchantSpec.fromItemSpec(item);
      }
    }
    if (!mounted) return;

    final action = await showModalBottomSheet<_DetailAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ItemDetailsSheet(
        item: item,
        appliedRune: appliedRune,
        appliedSap: appliedSap,
      ),
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
    // Sprint 2.3 Bloco 7.1 — badge ✨ quando item tem runa/seiva aplicada.
    final hasEnchant = item.entry.appliedRuneKey != null ||
        item.entry.appliedSapKey != null;

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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: rarityColor.withValues(alpha: 0.4)),
                  ),
                  child: Icon(_typeIcon(item.spec.type),
                      color: rarityColor, size: 22),
                ),
                if (hasEnchant)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(
                            color: AppColors.purpleLight, width: 1.2),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.purpleLight, size: 11),
                    ),
                  ),
              ],
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
        ItemType.rune       => Icons.auto_awesome,
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
  final EnchantSpec? appliedRune;
  final EnchantSpec? appliedSap;
  const _ItemDetailsSheet({
    required this.item,
    this.appliedRune,
    this.appliedSap,
  });

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
            // Sprint 2.3 Bloco 7.1 — seção Encantamento (runa e/ou seiva
            // aplicada no item). Schema já suporta seiva; UI mostra, mesmo
            // que Sprint 2.4 ainda não ative o sistema de cargas.
            if (appliedRune != null || appliedSap != null) ...[
              const SizedBox(height: 12),
              _sectionTitle('ENCANTAMENTO'),
              const SizedBox(height: 6),
              if (appliedRune != null) _buildEnchantRow(appliedRune!, 'Runa'),
              if (appliedSap != null) ...[
                if (appliedRune != null) const SizedBox(height: 6),
                _buildEnchantRow(
                  appliedSap!,
                  'Seiva',
                  charges: item.entry.sapChargesRemaining,
                ),
              ],
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

  Widget _buildEnchantRow(EnchantSpec enchant, String kindLabel,
      {int? charges}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome,
                color: AppColors.purpleLight, size: 13),
            const SizedBox(width: 6),
            Text(enchant.name,
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Text('($kindLabel)',
                style: GoogleFonts.roboto(
                    fontSize: 10, color: AppColors.textMuted)),
            if (charges != null) ...[
              const SizedBox(width: 6),
              Text('• $charges cargas',
                  style: GoogleFonts.roboto(
                      fontSize: 10, color: AppColors.gold)),
            ],
          ],
        ),
        if (enchant.effects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 19, top: 2),
            child: Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                for (final e in enchant.effects)
                  Text('+${e.value} ${e.key}',
                      style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: AppColors.shadowAscending)),
              ],
            ),
          ),
      ],
    );
  }

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
    // Sprint 2.3 fix (B4) — runas são marcadas is_consumable pra serem
    // consumidas pela EnchantService (dentro da transação atômica de
    // aplicação). NUNCA devem aparecer com botão "Usar" genérico — que só
    // decrementa quantity sem aplicar effect (engine de effects é Fase 4).
    // Aplicação real de runa acontece em /enchant.
    if (spec.isConsumable && spec.type != ItemType.rune) {
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
