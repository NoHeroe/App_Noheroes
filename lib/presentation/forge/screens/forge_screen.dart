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
import '../../shared/widgets/feature_chip.dart';
import '../../shared/widgets/level_locked_view.dart';

// TODO Fase 5: asset próprio de bigorna medieval.
// Usando Icons.hardware (martelo pesado) como placeholder — zero colisão
// com Icons.gavel que já é usado pra weapon.
const _forgeHeaderIcon = Icons.hardware;

class ForgeScreen extends ConsumerStatefulWidget {
  const ForgeScreen({super.key});

  @override
  ConsumerState<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends ConsumerState<ForgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<RecipeSpec> _recipes = const [];
  Map<String, int> _currentMaterials = const {};
  Map<String, String> _itemNames = const {};
  Map<String, ItemType> _itemTypes = const {};
  int _currentCoins = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _tab.dispose();
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
      final updated = await PlayerDao(ref.read(appDatabaseProvider))
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
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.gold),
              )
            : _error != null
                ? _ErrorView(message: _error!)
                : Column(
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
    // Sprint 2.3 fix — chip Encantamento (lv20) no header da Forja.
    // Chip Forja em si não aparece aqui (estamos nela).
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
          const Icon(_forgeHeaderIcon, color: AppColors.gold, size: 22),
          const SizedBox(width: 8),
          Text(
            'FORJA',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.gold,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          FeatureChip(
            icon: Icons.auto_awesome,
            label: 'ENCANT.',
            route: '/enchant',
            requiredLevel: 20,
            playerLevel: playerLevel,
            color: AppColors.purpleLight,
          ),
          Text('🪙 $_currentCoins',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.gold)),
        ],
      ),
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
        onTap: () => _openDetails(list[i]),
      ),
    );
  }

  Future<void> _openDetails(RecipeSpec recipe) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => _RecipeDetailsSheet(
        recipe: recipe,
        currentMaterials: _currentMaterials,
        currentCoins: _currentCoins,
        itemNames: _itemNames,
        itemTypes: _itemTypes,
      ),
    );
    if (!mounted || confirmed != true) return;
    await _craft(recipe);
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final RecipeSpec recipe;
  final Map<String, int> currentMaterials;
  final int currentCoins;
  final Map<String, String> itemNames;
  final Map<String, ItemType> itemTypes;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.currentMaterials,
    required this.currentCoins,
    required this.itemNames,
    required this.itemTypes,
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
          border: Border.all(color: accent.withValues(alpha: 0.4)),
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
            const SizedBox(height: 12),
            _ActionButton(
              label: recipe.type.label.toUpperCase(),
              color: _canCraftPreview ? accent : AppColors.textMuted,
              enabled: _canCraftPreview,
              onTap: onTap,
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

class _RecipeDetailsSheet extends StatelessWidget {
  final RecipeSpec recipe;
  final Map<String, int> currentMaterials;
  final int currentCoins;
  final Map<String, String> itemNames;
  final Map<String, ItemType> itemTypes;

  const _RecipeDetailsSheet({
    required this.recipe,
    required this.currentMaterials,
    required this.currentCoins,
    required this.itemNames,
    required this.itemTypes,
  });

  bool get _canCraftPreview {
    for (final m in recipe.materials) {
      final have = currentMaterials[m.itemKey] ?? 0;
      if (have < m.quantity) return false;
    }
    if (currentCoins < recipe.costCoins) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final accent = recipe.type == RecipeType.forge
        ? AppColors.gold
        : AppColors.purpleLight;
    final producedQty = recipe.resultQuantity;
    final producedName =
        itemNames[recipe.resultItemKey] ?? recipe.resultItemKey;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.name,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 17,
                    color: accent,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            if (recipe.description.isNotEmpty)
              Text(recipe.description,
                  style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            const SizedBox(height: 16),
            _sectionTitle('RESULTADO'),
            const SizedBox(height: 6),
            Text(
              '$producedName ×$producedQty',
              style: GoogleFonts.roboto(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _sectionTitle('MATERIAIS'),
            const SizedBox(height: 6),
            ...recipe.materials.map((m) {
              final have = currentMaterials[m.itemKey] ?? 0;
              final color = _RecipeCard._materialColor(have, m.quantity);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        itemNames[m.itemKey] ?? m.itemKey,
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ),
                    Text('$have / ${m.quantity}',
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: color)),
                  ],
                ),
              );
            }),
            if (recipe.costCoins > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.monetization_on_outlined,
                      size: 14, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text('Custo: ${recipe.costCoins}',
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: currentCoins >= recipe.costCoins
                              ? AppColors.gold
                              : AppColors.hp)),
                ],
              ),
            ],
            if (recipe.requiredRank != null || recipe.requiredLevel > 1) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (recipe.requiredRank != null)
                    _TagBadge(
                      text:
                          'RANK ${recipe.requiredRank!.name.toUpperCase()}',
                      color: AppColors.gold,
                    ),
                  if (recipe.requiredLevel > 1)
                    _TagBadge(
                      text: 'LV ${recipe.requiredLevel}',
                      color: AppColors.purpleLight,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            _ActionButton(
              label: recipe.type == RecipeType.forge
                  ? 'CONFIRMAR FORJA'
                  : 'CONFIRMAR CRIAÇÃO',
              color: _canCraftPreview ? accent : AppColors.textMuted,
              enabled: _canCraftPreview,
              onTap: () => Navigator.pop(context, true),
            ),
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
            Icon(_forgeHeaderIcon,
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
