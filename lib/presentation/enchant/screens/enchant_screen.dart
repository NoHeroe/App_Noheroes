import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/enums/item_type.dart';
import '../../../domain/models/enchant_result.dart';
import '../../../domain/models/enchant_spec.dart';
import '../../../domain/models/inventory_entry_with_spec.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../shared/tutorial_manager.dart';
import '../../shared/widgets/level_locked_view.dart';

// Sprint 2.3 Bloco 5 — tela /enchant.
// Gate: player.level >= 20 (reusa LevelLockedView do Bloco 0.B).
// 2 tabs: RUNAS (ativo) e SEIVAS (placeholder Sprint 2.4).
//
// Fluxo:
//   1. Tab RUNAS → lista runas do inventário do jogador
//   2. Tap em runa → bottom sheet com itens equipáveis do inventário
//      (exclui Colar da Guilda)
//   3. Tap em item → EnchantService.applyEnchantToItem
//   4. alreadyEnchantedSameSlot → AlertDialog de confirmação;
//      se confirmado → re-chama service com confirmReplacement=true
//   5. Outros rejeitos → snackbar contextual
class EnchantScreen extends ConsumerStatefulWidget {
  const EnchantScreen({super.key});

  @override
  ConsumerState<EnchantScreen> createState() => _EnchantScreenState();
}

class _EnchantScreenState extends ConsumerState<EnchantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  String? _error;

  List<_RuneRow> _runeRows = const [];
  List<InventoryEntryWithSpec> _enchantable = const [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Sprint 2.3 Bloco 6 — redundância. Se o jogador entrou direto via
      // Dev Panel sem passar pelo santuário após atingir lv 20, a quest
      // dispara aqui. phase12Enchanter é idempotente via TutorialService
      // flag — zero risco de double-grant se sanctuary já rodou.
      if (!mounted) return;
      final player = ref.read(currentPlayerProvider);
      if (player != null && player.level >= 20) {
        await TutorialManager.phase12Enchanter(
          context,
          ref: ref,
          playerId: player.id,
        );
      }
      if (!mounted) return;
      await _reload();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final player = ref.read(currentPlayerProvider);
      if (player == null) {
        if (mounted) context.go('/login');
        return;
      }
      if (player.level < 20) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final inventory = ref.read(playerInventoryServiceProvider);
      final inv = await inventory.listOf(player.id);

      // Sprint 2.3 fix — runas agora vivem no player_inventory como
      // ItemType.rune. Agrega por item_key (stack quantity) pra mostrar
      // uma linha por tipo de runa.
      final runeQty = <String, int>{};
      final runeSpecs = <String, EnchantSpec>{};
      for (final e in inv) {
        if (e.spec.type != ItemType.rune) continue;
        runeQty[e.spec.key] =
            (runeQty[e.spec.key] ?? 0) + e.entry.quantity;
        runeSpecs.putIfAbsent(
          e.spec.key,
          () => EnchantSpec.fromItemSpec(e.spec),
        );
      }
      final rows = [
        for (final key in runeQty.keys)
          _RuneRow(spec: runeSpecs[key]!, quantity: runeQty[key]!),
      ];

      // Inventário do jogador — filtra equipáveis, não-equipados e não
      // sagrados. Itens equipados podem ser encantados também (runas
      // permanecem ao desequipar), mas pra esta primeira versão mostramos
      // todos pra máxima flexibilidade.
      final enchantable = inv.where((e) {
        const allowed = {
          ItemType.weapon,
          ItemType.armor,
          ItemType.shield,
          ItemType.accessory,
        };
        if (!allowed.contains(e.spec.type)) return false;
        if (e.spec.key == 'COLLAR_GUILD') return false;
        return true;
      }).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _runeRows = rows;
        _enchantable = enchantable;
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

  // Monta o snapshot a partir do player no provider — mesmo pattern de
  // ForgeScreen / ShopScreen.
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

  Future<void> _applyRuneToItem({
    required EnchantSpec rune,
    required InventoryEntryWithSpec target,
    bool confirmReplacement = false,
  }) async {
    final player = ref.read(currentPlayerProvider);
    final snap = _snapshot();
    if (player == null || snap == null) return;

    final svc = ref.read(enchantServiceProvider);
    final result = await svc.applyEnchantToItem(
      playerId:           player.id,
      inventoryItemId:    target.entry.id,
      enchantKey:         rune.key,
      player:             snap,
      playerGems:         player.gems,
      confirmReplacement: confirmReplacement,
    );

    if (!mounted) return;

    if (result.allowed) {
      // Refresca player pra gemas atualizadas.
      final db = ref.read(appDatabaseProvider);
      final updated = await db.managers.playersTable
          .filter((f) => f.id(player.id))
          .getSingleOrNull();
      if (!mounted) return;
      ref.read(currentPlayerProvider.notifier).state = updated;

      final replaced = result.replacedEnchant;
      final msg = replaced != null
          ? '${rune.name} aplicada em ${target.spec.name} '
              '(${replaced.name} perdida)'
          : '${rune.name} aplicada em ${target.spec.name}';
      _snack(msg, success: true);
      await _reload();
      return;
    }

    if (result.reason == EnchantRejectReason.alreadyEnchantedSameSlot) {
      // Soft-gate: pergunta se quer substituir.
      final current = await _resolveCurrentRuneLabel(target);
      final confirmed = await _showReplaceDialog(
        current: current,
        incoming: rune.name,
      );
      if (confirmed != true || !mounted) return;
      await _applyRuneToItem(
        rune: rune,
        target: target,
        confirmReplacement: true,
      );
      return;
    }

    _snack(_rejectLabel(result.reason!, rune, player.gems));
  }

  Future<String> _resolveCurrentRuneLabel(
      InventoryEntryWithSpec target) async {
    final key = target.entry.appliedRuneKey;
    if (key == null) return 'uma runa';
    // Sprint 2.3 fix — runas agora são items no items_catalog.
    final spec = await ref.read(itemsCatalogServiceProvider).findByKey(key);
    return spec?.name ?? key;
  }

  Future<bool?> _showReplaceDialog({
    required String current,
    required String incoming,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Substituir runa?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.gold, fontSize: 14)),
        content: Text(
          'Este item já tem "$current" aplicada. Substituir por '
          '"$incoming"? A runa atual será perdida.',
          style: GoogleFonts.roboto(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Substituir',
                style: GoogleFonts.roboto(color: AppColors.hp)),
          ),
        ],
      ),
    );
  }

  String _rejectLabel(
      EnchantRejectReason r, EnchantSpec rune, int playerGems) {
    return switch (r) {
      EnchantRejectReason.itemNotFound =>
        'Item não encontrado ou erro ao processar.',
      EnchantRejectReason.enchantNotFound =>
        'Runa não encontrada no catálogo.',
      EnchantRejectReason.enchantNotInInventory =>
        'Você não possui esta runa.',
      EnchantRejectReason.itemNotEnchantable =>
        'Este item não pode ser encantado.',
      EnchantRejectReason.rankInsufficient =>
        'Esta runa requer item rank '
            '${rune.requiredRank?.name.toUpperCase() ?? "?"} ou superior.',
      EnchantRejectReason.alreadyEnchantedSameSlot =>
        'Slot ocupado — confirme a substituição.',
      EnchantRejectReason.insufficientGems =>
        'Gemas insuficientes. Custo: ${rune.costGems ?? 0} 💎, '
            'você tem $playerGems.',
      EnchantRejectReason.classRestricted =>
        'Esta runa é restrita por classe.',
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
      duration: const Duration(milliseconds: 2800),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);
    final level = player?.level ?? 0;
    if (level < 20) {
      return LevelLockedView(
        requiredLevel: 20,
        currentLevel: level,
        featureName: 'Encantamento',
      );
    }
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.purpleLight),
              )
            : _error != null
                ? _ErrorView(message: _error!)
                : Column(
                    children: [
                      _buildHeader(player?.gems ?? 0),
                      _buildTabs(),
                      Expanded(child: _buildTabContent()),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(int gems) {
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
          const Icon(Icons.auto_awesome,
              color: AppColors.purpleLight, size: 22),
          const SizedBox(width: 8),
          Text('ENCANTAMENTO',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: AppColors.purpleLight,
                  letterSpacing: 3)),
          const Spacer(),
          Text('💎 $gems',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.purpleLight)),
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
      labelStyle:
          GoogleFonts.cinzelDecorative(fontSize: 11, letterSpacing: 2),
      unselectedLabelStyle:
          GoogleFonts.cinzelDecorative(fontSize: 11, letterSpacing: 2),
      tabs: const [
        Tab(text: 'RUNAS'),
        Tab(text: 'SEIVAS'),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tab,
      children: [
        _buildRunesTab(),
        const _SapPlaceholder(),
      ],
    );
  }

  Widget _buildRunesTab() {
    if (_runeRows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome,
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  size: 46),
              const SizedBox(height: 12),
              Text(
                'Você ainda não tem runas.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Complete a quest do Encantador\npara ganhar a primeira.',
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: _runeRows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final row = _runeRows[i];
        return _EnchantInventoryCard(
          rune: row.spec,
          quantity: row.quantity,
          onTap: () => _openItemPicker(row.spec),
        );
      },
    );
  }

  Future<void> _openItemPicker(EnchantSpec rune) async {
    final picked = await showModalBottomSheet<InventoryEntryWithSpec>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(
        rune: rune,
        items: _enchantable,
      ),
    );
    if (picked == null || !mounted) return;
    await _applyRuneToItem(rune: rune, target: picked);
  }
}

// ── Widgets ────────────────────────────────────────────────────────────

class _RuneRow {
  final EnchantSpec spec;
  final int quantity;
  const _RuneRow({required this.spec, required this.quantity});
}

class _EnchantInventoryCard extends StatelessWidget {
  final EnchantSpec rune;
  final int quantity;
  final VoidCallback onTap;

  const _EnchantInventoryCard({
    required this.rune,
    required this.quantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.purpleLight.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            AppColors.purpleLight.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.purpleLight, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rune.name,
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              letterSpacing: 1),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (rune.requiredRank != null)
                            _TagBadge(
                              text: 'RANK '
                                  '${rune.requiredRank!.name.toUpperCase()}',
                              color: AppColors.gold,
                            ),
                          const SizedBox(width: 6),
                          if ((rune.costGems ?? 0) > 0)
                            _TagBadge(
                              text: '💎 ${rune.costGems}',
                              color: AppColors.purpleLight,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text('×$quantity',
                    style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            if (rune.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rune.description,
                style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (rune.effects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: rune.effects
                    .map((e) => _TagBadge(
                          text: '${e.key}: ${e.value}',
                          color: AppColors.shadowAscending,
                        ))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemPickerSheet extends StatelessWidget {
  final EnchantSpec rune;
  final List<InventoryEntryWithSpec> items;

  const _ItemPickerSheet({required this.rune, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplicar "${rune.name}" em...',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: AppColors.purpleLight,
                    letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('Selecione um item equipável do seu inventário.',
                style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4)),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Nenhum item equipável no inventário.',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ItemPickerCard(
                    entry: items[i],
                    onTap: () => Navigator.pop(context, items[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemPickerCard extends StatelessWidget {
  final InventoryEntryWithSpec entry;
  final VoidCallback onTap;

  const _ItemPickerCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasRune = entry.entry.appliedRuneKey != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: hasRune
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(_typeIcon(entry.spec.type),
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(entry.spec.name,
                            style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (hasRune) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.auto_awesome,
                            color: AppColors.gold, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (entry.spec.requiredRank != null)
                        Text(
                            'Rank '
                            '${entry.spec.requiredRank!.name.toUpperCase()}',
                            style: GoogleFonts.roboto(
                                fontSize: 10,
                                color: AppColors.textMuted)),
                      if (hasRune) ...[
                        const SizedBox(width: 8),
                        Text('• ${entry.entry.appliedRuneKey}',
                            style: GoogleFonts.roboto(
                                fontSize: 10, color: AppColors.gold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
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

  static IconData _typeIcon(ItemType t) => switch (t) {
        ItemType.weapon => Icons.gavel,
        ItemType.armor => Icons.shield_outlined,
        ItemType.shield => Icons.shield,
        ItemType.accessory => Icons.circle_outlined,
        _ => Icons.inventory_2_outlined,
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
      child: Text(text,
          style: GoogleFonts.roboto(
              fontSize: 9, color: color, letterSpacing: 1)),
    );
  }
}

class _SapPlaceholder extends StatelessWidget {
  const _SapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                color: AppColors.textMuted.withValues(alpha: 0.5),
                size: 46),
            const SizedBox(height: 12),
            Text('Seivas',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            const SizedBox(height: 6),
            Text('Em breve — Sprint 2.4',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic)),
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
