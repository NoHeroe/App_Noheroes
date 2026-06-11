import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../../domain/enums/item_type.dart';
import '../../../domain/enums/recipe_type.dart';
import '../../../domain/models/craft_result.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/recipe_spec.dart';
import '../../sanctuary/widgets/sanctuary_header_widgets.dart';
import '../../shared/widgets/level_locked_view.dart';

class ForgeScreen extends ConsumerStatefulWidget {
  const ForgeScreen({super.key});

  @override
  ConsumerState<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends ConsumerState<ForgeScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  List<RecipeSpec> _recipes = const [];
  Map<String, int> _currentMaterials = const {};
  Map<String, String> _itemNames = const {};
  Map<String, ItemType> _itemTypes = const {};
  int _currentCoins = 0;
  bool _loading = true;
  String? _error;

  // Receita selecionada (exibida na bigorna) + animação de faíscas.
  RecipeSpec? _selected;
  late final AnimationController _spark;
  bool _forging = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // Trocar de aba limpa a seleção (anvil sempre coerente com a aba ativa).
    _tab.addListener(() {
      if (_tab.indexIsChanging) setState(() => _selected = null);
    });
    _spark = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _tab.dispose();
    _spark.dispose();
    super.dispose();
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
      final snap = _snapshot();
      if (player == null || snap == null) {
        if (mounted) context.go('/login');
        return;
      }

      final catalog       = ref.read(recipesCatalogServiceProvider);
      final playerRecipes = ref.read(playerRecipesServiceProvider);
      final inventory     = ref.read(playerInventoryServiceProvider);
      final itemsCatalog  = ref.read(itemsCatalogServiceProvider);

      final available   = await catalog.findAvailableFor(snap);
      final unlocked    = await playerRecipes.listUnlockedOf(player.id);
      final inventoryEs = await inventory.listOf(player.id);
      final allItems    = await itemsCatalog.findAll();

      // Interseção: disponíveis E desbloqueadas.
      final unlockedKeys = unlocked.map((r) => r.key).toSet();
      final visible = available
          .where((r) => unlockedKeys.contains(r.key))
          .toList(growable: false);

      // Agrega quantidades de materiais do inventário (só entries unequipadas).
      final mats = <String, int>{};
      for (final e in inventoryEs) {
        if (e.entry.isEquipped) continue;
        mats[e.spec.key] = (mats[e.spec.key] ?? 0) + e.entry.quantity;
      }

      // Cache de nomes + types pra render (não depende do inventário — precisa
      // nome do item resultado mesmo quando player ainda não tem).
      final names = <String, String>{
        for (final it in allItems) it.key: it.name,
      };
      final types = <String, ItemType>{
        for (final it in allItems) it.key: it.type,
      };

      if (!mounted) return;
      setState(() {
        _recipes = visible;
        _currentMaterials = mats;
        _itemNames = names;
        _itemTypes = types;
        _currentCoins = player.gold;
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

  Future<void> _craft(RecipeSpec recipe) async {
    final player = ref.read(currentPlayerProvider);
    final snap = _snapshot();
    if (player == null || snap == null) return;

    final svc = ref.read(craftingServiceProvider);
    final result = await svc.craft(
      playerId:  player.id,
      recipeKey: recipe.key,
      player:    snap,
    );
    if (!mounted) return;

    if (result.isOk) {
      // Refresca player pra refletir gold debitado.
      final updated = await PlayerDao(ref.read(supabaseClientProvider))
          .findById(player.id);
      if (!mounted) return;
      ref.read(currentPlayerProvider.notifier).state = updated;
      final qty = result.quantity ?? recipe.resultQuantity;
      final verb = recipe.type == RecipeType.forge ? 'Forjado' : 'Criado';
      _snack('$verb: ${_itemNames[recipe.resultItemKey] ?? recipe.resultItemKey}'
          ' ×$qty', success: true);
      await _reload();
    } else {
      _snack(_rejectLabel(result.reason!, recipe));
    }
  }

  String _rejectLabel(CraftRejectReason r, RecipeSpec recipe) {
    return switch (r) {
      CraftRejectReason.recipeNotFound     => 'Receita não encontrada.',
      CraftRejectReason.recipeNotUnlocked  => 'Você ainda não conhece esta receita.',
      CraftRejectReason.rankTooLow         =>
        'Rank da Guilda insuficiente (requer ${recipe.requiredRank?.name.toUpperCase() ?? "E"}).',
      CraftRejectReason.levelTooLow        =>
        'Nível insuficiente (requer ${recipe.requiredLevel}).',
      CraftRejectReason.stationMismatch    => 'Estação de trabalho incompatível.',
      CraftRejectReason.notEnoughMaterials => 'Materiais insuficientes.',
      CraftRejectReason.notEnoughCoins     =>
        'Ouro insuficiente (requer ${recipe.costCoins}).',
      CraftRejectReason.itemNotInCatalog   => 'Item resultado indisponível.',
      CraftRejectReason.inventoryFull      => 'Inventário cheio.',
      CraftRejectReason.dbError            => 'Erro ao processar.',
    };
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
      content: Text(message,
          style: GoogleFonts.roboto(
              fontSize: 13, color: AppColors.textPrimary)),
      duration: const Duration(milliseconds: 2500),
    ));
  }

  bool _previewCraftable(RecipeSpec r) {
    for (final m in r.materials) {
      if ((_currentMaterials[m.itemKey] ?? 0) < m.quantity) return false;
    }
    return _currentCoins >= r.costCoins;
  }

  // Forja a receita selecionada com animação de faíscas na bigorna.
  Future<void> _craftSelected() async {
    final r = _selected;
    if (r == null || _forging || !_previewCraftable(r)) return;
    setState(() => _forging = true);
    _spark.forward(from: 0);
    await _craft(r); // valida + debita + reload (mantém _selected).
    if (!mounted) return;
    setState(() => _forging = false);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Sprint 2.3 Bloco 0.B — Forja requer nível 6.
    final player = ref.watch(currentPlayerProvider);
    final level = player?.level ?? 0;
    if (level < 6) {
      return LevelLockedView(
        requiredLevel: 6,
        currentLevel: level,
        featureName: 'Forja',
      );
    }
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const _ForgeBackground(),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold),
                  )
                : _error != null
                    ? _ErrorView(message: _error!)
                    : Column(
                        children: [
                          _topBar(),
                          const SizedBox(height: 8),
                          _miniInventory(),
                          const SizedBox(height: 10),
                          _anvilStation(),
                          const SizedBox(height: 6),
                          _buildTabs(),
                          Expanded(child: _buildTabContent()),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // Topo SEM título: voltar + atalhos (Inventário, Ferreiro, Encant.) + wallet
  // no padrão do Santuário.
  Widget _topBar() {
    final playerLevel = ref.watch(currentPlayerProvider)?.level ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => context.go('/sanctuary'),
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
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
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
              _pillButton(Icons.backpack_outlined, 'INVENTÁRIO',
                  AppColors.purpleLight, () => context.go('/inventory')),
              const SizedBox(height: 6),
              _pillButton(Icons.hardware, 'FERREIRO', AppColors.gold,
                  () => context.push('/shop/blacksmith_aureum')),
              const SizedBox(height: 6),
              _pillButton(Icons.auto_awesome, 'ENCANT.', AppColors.purpleLight,
                  () {
                if (playerLevel >= 20) {
                  context.go('/enchant');
                } else {
                  _snack('O Encantamento abre no Nível 20.');
                }
              }),
            ],
          ),
          const SizedBox(width: 8),
          const SanctuaryWalletPills(),
        ],
      ),
    );
  }

  Widget _pillButton(
      IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
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
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 9.5,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.txt)),
          ],
        ),
      ),
    );
  }

  // Miniatura do inventário: slots de materiais (>=5), scroll horizontal.
  Widget _miniInventory() {
    final mats = _currentMaterials.entries
        .where((e) => _itemTypes[e.key] == ItemType.material && e.value > 0)
        .toList()
      ..sort((a, b) =>
          (_itemNames[a.key] ?? a.key).compareTo(_itemNames[b.key] ?? b.key));
    final slots = math.max(5, mats.length);
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: slots,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i >= mats.length) return const _MatSlot();
          final e = mats[i];
          return _MatSlot(
            icon: _RecipeCard._typeIcon(
                _itemTypes[e.key] ?? ItemType.material),
            qty: e.value,
            name: _itemNames[e.key] ?? e.key,
          );
        },
      ),
    );
  }

  // Bigorna com o slot do item selecionado + faíscas ao forjar.
  Widget _anvilStation() {
    final r = _selected;
    final accent = (r?.type == RecipeType.forge)
        ? AppColors.gold
        : (r?.type == RecipeType.craft
            ? AppColors.purpleLight
            : AppColors.gold);
    final type = r == null
        ? null
        : (_itemTypes[r.resultItemKey] ?? ItemType.misc);
    final name = r == null
        ? 'Escolha uma receita abaixo'
        : (_itemNames[r.resultItemKey] ?? r.resultItemKey);
    final craftable = r != null && _previewCraftable(r);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 132,
            child: AnimatedBuilder(
              animation: _spark,
              builder: (_, __) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bigorna desenhada.
                    const Positioned.fill(
                      child: CustomPaint(painter: _AnvilPainter()),
                    ),
                    // Slot do item (sobre a face da bigorna).
                    Align(
                      alignment: const Alignment(0, -0.55),
                      child: Transform.scale(
                        scale: 1.0 + math.sin(_spark.value * math.pi) * 0.12,
                        child: _itemSlot(type, accent),
                      ),
                    ),
                    // Faíscas.
                    if (_spark.value > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _SparkPainter(_spark.value),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 12,
                letterSpacing: 1,
                color: r == null ? AppColors.txtMut : AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          _ActionButton(
            label: r == null
                ? 'SELECIONE UMA RECEITA'
                : (r.type == RecipeType.forge ? 'FORJAR' : 'CRIAR'),
            color: (craftable && !_forging) ? accent : AppColors.textMuted,
            enabled: craftable && !_forging,
            onTap: _craftSelected,
          ),
        ],
      ),
    );
  }

  Widget _itemSlot(ItemType? type, Color accent) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241A12), Color(0xFF0E0906)],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.6),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: 14,
              spreadRadius: 1),
        ],
      ),
      child: type == null
          ? const Icon(Icons.add, color: AppColors.txtMut, size: 22)
          : Icon(_RecipeCard._typeIcon(type), color: accent, size: 30),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tab,
      indicatorColor: AppColors.purpleLight,
      labelColor: AppColors.purpleLight,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: GoogleFonts.cinzelDecorative(
          fontSize: 11, letterSpacing: 2),
      unselectedLabelStyle: GoogleFonts.cinzelDecorative(
          fontSize: 11, letterSpacing: 2),
      tabs: const [
        Tab(text: 'CRIAR'),
        Tab(text: 'FORJAR'),
      ],
    );
  }

  Widget _buildTabContent() {
    final craft = _recipes
        .where((r) => r.type == RecipeType.craft)
        .toList(growable: false);
    final forge = _recipes
        .where((r) => r.type == RecipeType.forge)
        .toList(growable: false);
    return TabBarView(
      controller: _tab,
      children: [
        _buildList(craft, RecipeType.craft),
        _buildList(forge, RecipeType.forge),
      ],
    );
  }

  Widget _buildList(List<RecipeSpec> list, RecipeType type) {
    if (list.isEmpty) return _EmptyList(type: type);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RecipeCard(
        recipe: list[i],
        currentMaterials: _currentMaterials,
        currentCoins: _currentCoins,
        itemNames: _itemNames,
        itemTypes: _itemTypes,
        selected: _selected?.key == list[i].key,
        onTap: () => setState(() => _selected = list[i]),
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final RecipeSpec recipe;
  final Map<String, int> currentMaterials;
  final int currentCoins;
  final Map<String, String> itemNames;
  final Map<String, ItemType> itemTypes;
  final bool selected;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.currentMaterials,
    required this.currentCoins,
    required this.itemNames,
    required this.itemTypes,
    required this.selected,
    required this.onTap,
  });

  bool get _canCraftPreview {
    // Preview visual — não substitui a validação do CraftingService.
    for (final m in recipe.materials) {
      final have = currentMaterials[m.itemKey] ?? 0;
      if (have < m.quantity) return false;
    }
    if (currentCoins < recipe.costCoins) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final resultType = itemTypes[recipe.resultItemKey] ?? ItemType.misc;
    final accent = recipe.type == RecipeType.forge
        ? AppColors.gold
        : AppColors.purpleLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: accent.withValues(alpha: selected ? 0.9 : 0.4),
              width: selected ? 1.8 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.3), blurRadius: 12)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(_typeIcon(resultType), color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            letterSpacing: 1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TagBadge(
                            text: recipe.type.label.toUpperCase(),
                            color: accent,
                          ),
                          if (recipe.requiredRank != null) ...[
                            const SizedBox(width: 6),
                            _TagBadge(
                              text: 'RANK ${recipe.requiredRank!.name.toUpperCase()}',
                              color: AppColors.gold,
                            ),
                          ],
                          if (recipe.requiredLevel > 1) ...[
                            const SizedBox(width: 6),
                            _TagBadge(
                              text: 'LV ${recipe.requiredLevel}',
                              color: AppColors.purpleLight,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                recipe.description,
                style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            ...recipe.materials.map((m) {
              final have = currentMaterials[m.itemKey] ?? 0;
              final color = _materialColor(have, m.quantity);
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        itemNames[m.itemKey] ?? m.itemKey,
                        style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$have/${m.quantity}',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: color)),
                  ],
                ),
              );
            }),
            if (recipe.costCoins > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.circle,
                      size: 6,
                      color: currentCoins >= recipe.costCoins
                          ? AppColors.shadowAscending
                          : AppColors.hp),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Custo',
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ),
                  Text('🪙 ${recipe.costCoins}',
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: currentCoins >= recipe.costCoins
                              ? AppColors.gold
                              : AppColors.hp)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  selected
                      ? 'NA BIGORNA'
                      : (_canCraftPreview
                          ? 'TOCAR P/ FORJAR'
                          : 'MATERIAIS FALTANDO'),
                  style: GoogleFonts.roboto(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: selected
                          ? accent
                          : (_canCraftPreview
                              ? AppColors.txt2
                              : AppColors.textMuted)),
                ),
                const SizedBox(width: 5),
                Icon(
                  selected ? Icons.check_circle : Icons.chevron_right,
                  size: 14,
                  color: selected ? accent : AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _materialColor(int have, int need) {
    if (have >= need) return AppColors.shadowAscending;
    if (have == 0) return AppColors.textMuted;
    return AppColors.hp;
  }

  static IconData _typeIcon(ItemType t) => switch (t) {
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.12 : 0.05),
          border: Border.all(
              color: color.withValues(alpha: enabled ? 0.55 : 0.25),
              width: 1.4),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.cinzelDecorative(
              fontSize: 12, color: color, letterSpacing: 3),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final RecipeType type;
  const _EmptyList({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = type.label.toUpperCase();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hardware,
                color: AppColors.textMuted.withValues(alpha: 0.3), size: 46),
            const SizedBox(height: 12),
            Text(
              'Você ainda não conhece receitas de $label.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete missões, compre na Guilda\nou descubra via loot.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

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
          const Row(
            children: [
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

// ── Fundo temático da Forja: brasa pulsante embaixo + faíscas + vignette ─────
class _ForgeBackground extends StatefulWidget {
  const _ForgeBackground();

  @override
  State<_ForgeBackground> createState() => _ForgeBackgroundState();
}

class _ForgeBackgroundState extends State<_ForgeBackground>
    with TickerProviderStateMixin {
  late final AnimationController _embers;
  late final AnimationController _glow;
  late final List<_BgEmber> _specs;

  @override
  void initState() {
    super.initState();
    _embers = AnimationController(
        vsync: this, duration: const Duration(seconds: 11))
      ..repeat();
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2300))
      ..repeat(reverse: true);
    final rnd = math.Random(19);
    _specs = List.generate(14, (_) {
      return _BgEmber(
        x: rnd.nextDouble(),
        size: 1.3 + rnd.nextDouble() * 1.5,
        phase: rnd.nextDouble(),
        // Inteiro: sem flick no reinício do loop.
        speed: (rnd.nextInt(2) + 1).toDouble(),
        drift: (rnd.nextDouble() - 0.5) * 0.06,
      );
    });
  }

  @override
  void dispose() {
    _embers.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base radial quente.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.45),
              radius: 1.25,
              colors: [Color(0xFF2A1A10), Color(0xFF150D08), Color(0xFF090605)],
              stops: [0.0, 0.5, 0.85],
            ),
          ),
        ),
        // Brasa da fornalha pulsando no rodapé.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _glow,
            builder: (_, __) {
              final f = 0.78 + _glow.value * 0.22;
              return Align(
                alignment: const Alignment(0, 1.25),
                child: Container(
                  width: 520,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF7A1A).withValues(alpha: 0.22 * f),
                        const Color(0xFFFF5A1A).withValues(alpha: 0.07 * f),
                        const Color(0x00FF5A1A),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Faíscas subindo.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _embers,
            builder: (_, __) => CustomPaint(
              painter: _BgEmbersPainter(_embers.value, _specs),
              size: Size.infinite,
            ),
          ),
        ),
        // Vignette.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [Color(0x00000000), Color(0x99000000)],
              stops: [0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _BgEmber {
  final double x, size, phase, speed, drift;
  const _BgEmber({
    required this.x,
    required this.size,
    required this.phase,
    required this.speed,
    required this.drift,
  });
}

class _BgEmbersPainter extends CustomPainter {
  final double t;
  final List<_BgEmber> embers;
  const _BgEmbersPainter(this.t, this.embers);

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final e in embers) {
      final p = (t * e.speed + e.phase) % 1.0;
      const rise = 640.0;
      final y = size.height - p * rise;
      if (y < -10 || y > size.height + 10) continue;
      final x =
          e.x * size.width + math.sin(p * math.pi * 2) * e.drift * size.width;
      final alpha = math.sin(p * math.pi).clamp(0.0, 1.0);
      const amber = Color(0xFFFFB347);
      glow.color = amber.withValues(alpha: 0.7 * alpha);
      canvas.drawCircle(Offset(x, y), e.size + 1.5, glow);
      final core = Paint()..color = amber.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), e.size, core);
    }
  }

  @override
  bool shouldRepaint(covariant _BgEmbersPainter old) => old.t != t;
}

// ── Slot de material da miniatura do inventário ─────────────────────────────
class _MatSlot extends StatelessWidget {
  final IconData? icon;
  final int? qty;
  final String? name;
  const _MatSlot({this.icon, this.qty, this.name});

  @override
  Widget build(BuildContext context) {
    final filled = icon != null;
    final slot = Container(
      width: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241A12), Color(0xFF0E0906)],
        ),
        border: Border.all(
          color: filled
              ? AppColors.gold.withValues(alpha: 0.45)
              : AppColors.borderViolet.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon ?? Icons.add,
              size: filled ? 22 : 16,
              color: filled
                  ? AppColors.goldLt.withValues(alpha: 0.9)
                  : AppColors.txtMut.withValues(alpha: 0.5),
            ),
          ),
          if (qty != null)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xCC0B0705),
                ),
                child: Text('×$qty',
                    style: GoogleFonts.roboto(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldLt)),
              ),
            ),
        ],
      ),
    );
    return filled ? Tooltip(message: name ?? '', child: slot) : slot;
  }
}

// ── Bigorna (silhueta metálica) ─────────────────────────────────────────────
class _AnvilPainter extends CustomPainter {
  const _AnvilPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final faceW = math.min(w * 0.66, 210.0);
    final faceTop = h * 0.46;
    const faceH = 18.0;
    final faceL = cx - faceW / 2, faceR = cx + faceW / 2;
    final waistTop = faceTop + faceH;
    final waistH = h * 0.20;
    final waistTopHalf = faceW * 0.18, waistBotHalf = faceW * 0.12;
    final baseTop = waistTop + waistH;
    final baseH = h * 0.12;
    final baseHalf = faceW * 0.34;
    final bottom = baseTop + baseH;

    final path = Path()
      ..moveTo(faceL, faceTop)
      ..lineTo(faceR, faceTop)
      ..lineTo(faceR + 26, faceTop + faceH * 0.45) // bico (horn)
      ..lineTo(faceR, faceTop + faceH)
      ..lineTo(cx + waistTopHalf, waistTop)
      ..lineTo(cx + waistBotHalf, baseTop)
      ..lineTo(cx + baseHalf, baseTop)
      ..lineTo(cx + baseHalf * 0.9, bottom)
      ..lineTo(cx - baseHalf * 0.9, bottom)
      ..lineTo(cx - baseHalf, baseTop)
      ..lineTo(cx - waistBotHalf, baseTop)
      ..lineTo(cx - waistTopHalf, waistTop)
      ..lineTo(faceL, faceTop + faceH)
      ..close();

    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3C3C46), Color(0xFF17171C)],
      ).createShader(Rect.fromLTWH(0, faceTop, w, bottom - faceTop));
    canvas.drawShadow(path, Colors.black, 6, true);
    canvas.drawPath(path, body);

    // Brilho na aresta superior da face.
    final hi = Paint()
      ..color = const Color(0xFF6A6A78)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(faceL, faceTop), Offset(faceR, faceTop), hi);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Faíscas da forja (t: 0→1) ───────────────────────────────────────────────
class _SparkPainter extends CustomPainter {
  final double t;
  const _SparkPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final cx = size.width / 2;
    final oy = size.height * 0.225; // origem ≈ centro do slot
    final origin = Offset(cx, oy);

    // Flash central.
    final flashA = math.sin(t * math.pi).clamp(0.0, 1.0);
    final flash = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFE0A3).withValues(alpha: 0.55 * flashA),
        const Color(0x00FFB347),
      ]).createShader(Rect.fromCircle(center: origin, radius: 34));
    canvas.drawCircle(origin, 34, flash);

    // Partículas.
    const n = 18;
    final alpha = (1 - t).clamp(0.0, 1.0);
    for (var i = 0; i < n; i++) {
      final ang = (i / n) * 2 * math.pi - math.pi / 2; // viés pra cima
      final speed = 0.6 + ((i * 53) % 10) / 10 * 0.7;
      final dist = t * 72 * speed;
      final px = cx + math.cos(ang) * dist;
      final py = oy + math.sin(ang) * dist - t * 12 * speed;
      final dir = Offset(math.cos(ang), math.sin(ang));
      final p = Paint()
        ..color = (i.isEven ? const Color(0xFFFFB347) : const Color(0xFFFF8A3D))
            .withValues(alpha: alpha)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
      canvas.drawLine(
        Offset(px, py),
        Offset(px + dir.dx * 5, py + dir.dy * 5),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.t != t;
}
