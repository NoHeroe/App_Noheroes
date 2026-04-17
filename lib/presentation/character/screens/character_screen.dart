import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import 'package:drift/drift.dart' show Variable, Value;
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../shared/widgets/nh_bottom_nav.dart';
import '../../shared/widgets/app_snack.dart';
import '../widgets/stats_panel.dart';

// Provider para itens equipados com dados do item
final equippedItemsProvider = FutureProvider.autoDispose<
    List<({InventoryTableData inv, ItemsTableData item})>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  final db = ref.read(appDatabaseProvider);
  final invRows = await (db.select(db.inventoryTable)
        ..where((t) => t.playerId.equals(player.id))
        ..where((t) => t.equippedSlot.isNotNull()))
      .get();
  final result = <({InventoryTableData inv, ItemsTableData item})>[];
  for (final inv in invRows) {
    final item = await (db.select(db.itemsTable)
          ..where((t) => t.id.equals(inv.itemId)))
        .getSingleOrNull();
    if (item != null) result.add((inv: inv, item: item));
  }
  return result;
});

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final equippedAsync = ref.watch(equippedItemsProvider);

    final equipped = equippedAsync.value ?? [];

    // Calcula bônus totais dos equipamentos
    int bonusStr = 0, bonusDex = 0, bonusInt = 0,
        bonusCon = 0, bonusSpi = 0, bonusHp = 0, bonusMp = 0;
    for (final e in equipped) {
      bonusStr += e.item.strBonus;
      bonusDex += e.item.dexBonus;
      bonusInt += e.item.intBonus;
      bonusCon += e.item.conBonus;
      bonusSpi += e.item.spiBonus;
      bonusHp  += e.item.hpBonus;
      bonusMp  += e.item.mpBonus;
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text('PERSONAGEM',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                      const Spacer(),
                      if ((player?.attributePoints ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '+${player!.attributePoints} pts disponíveis',
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 10, color: AppColors.gold),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    child: Column(
                      children: [
                        _buildAvatarFull(context, ref, equipped),
                        const SizedBox(height: 12),
                        _buildClassFaction(player),
                        const SizedBox(height: 12),
                        _buildAttributes(context, ref, player,
                            bonusStr, bonusDex, bonusInt,
                            bonusCon, bonusSpi, bonusHp, bonusMp),
                        const SizedBox(height: 12),
                        if (player != null) StatsPanel(player: player),
                        if (bonusHp > 0 || bonusMp > 0) ...[
                          const SizedBox(height: 12),
                          _buildEquipmentBonusSummary(
                              bonusHp, bonusMp, bonusStr,
                              bonusDex, bonusInt, bonusCon, bonusSpi),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: NhBottomNav(currentIndex: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFull(BuildContext context, WidgetRef ref,
      List<({InventoryTableData inv, ItemsTableData item})> equipped) {
    final screenH = MediaQuery.of(context).size.height;

    Map<String, ({InventoryTableData inv, ItemsTableData item})?> slotMap = {};
    for (final e in equipped) {
      final slot = e.inv.equippedSlot;
      if (slot != null) slotMap[slot.toLowerCase()] = e;
    }

    final leftSlots = [
      ('Capacete', Icons.security, 'head'),
      ('Peitoral', Icons.shield, 'chest'),
      ('Cinto', Icons.fitness_center_outlined, 'waist'),
    ];
    final rightSlots = [
      ('Botas', Icons.hiking, 'feet'),
      ('Luvas', Icons.back_hand_outlined, 'hands'),
      ('Escudo', Icons.shield_outlined, 'offhand'),
    ];
    final bottomSlots = [
      ('Arma', Icons.gavel, 'weapon'),
      ('Anel', Icons.circle_outlined, 'ring'),
      ('Acessório', Icons.auto_awesome, 'accessory'),
    ];

    return Container(
      height: screenH * 0.52,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        gradient: RadialGradient(colors: [
          AppColors.purple.withValues(alpha: 0.12),
          AppColors.surface,
        ]),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: leftSlots
                      .map((s) => _slot(context, ref, s.$1, s.$2,
                          slotMap[s.$3]))
                      .toList(),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.4)),
                        gradient: RadialGradient(colors: [
                          AppColors.purple.withValues(alpha: 0.2),
                          AppColors.shadowVoid,
                        ]),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.4),
                                  blurRadius: 40,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.blur_circular,
                              color: AppColors.purple, size: 90),
                          const Positioned(
                            bottom: 12,
                            child: Text('Avatar 2D',
                                style: TextStyle(
                                    fontFamily: 'CinzelDecorative',
                                    fontSize: 9,
                                    color: AppColors.textMuted,
                                    letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rightSlots
                      .map((s) => _slot(context, ref, s.$1, s.$2,
                          slotMap[s.$3]))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: bottomSlots
                .map((s) => _slot(context, ref, s.$1, s.$2,
                    slotMap[s.$3], wide: true))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    ({InventoryTableData inv, ItemsTableData item})? equipped, {
    bool wide = false,
  }) {
    final hasItem = equipped != null;
    final rarity = equipped?.item.rarity ?? 'common';
    final rarityColor = _rarityColor(rarity);

    return GestureDetector(
      onTap: hasItem
          ? () => _showItemDetail(context, ref, equipped!)
          : null,
      child: Container(
        width: wide ? 90 : 68,
        height: 68,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: hasItem
              ? rarityColor.withValues(alpha: 0.08)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasItem
                ? rarityColor.withValues(alpha: 0.6)
                : AppColors.border,
            width: hasItem ? 1.5 : 1,
          ),
        ),
        child: hasItem
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: rarityColor, size: 20),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      equipped!.item.name,
                      style: GoogleFonts.roboto(
                          fontSize: 7,
                          color: rarityColor,
                          height: 1.2),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.textMuted, size: 22),
                  const SizedBox(height: 4),
                  Text(label,
                      style: GoogleFonts.roboto(
                          fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
      ),
    );
  }

  void _showItemDetail(
    BuildContext context,
    WidgetRef ref,
    ({InventoryTableData inv, ItemsTableData item}) equipped,
  ) {
    final item = equipped.item;
    final rarity = item.rarity;
    final color = _rarityColor(rarity);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(rarity.toUpperCase(),
                    style: GoogleFonts.roboto(
                        fontSize: 9, color: color, letterSpacing: 1.5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.name,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 14, color: AppColors.textPrimary)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(item.description,
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            const SizedBox(height: 12),
            // Bônus
            if (_hasBonuses(item)) ...[
              Text('BÔNUS',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 10, color: AppColors.gold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: [
                  if (item.strBonus != 0) _bonusChip('FOR +${item.strBonus}', AppColors.hp),
                  if (item.dexBonus != 0) _bonusChip('DES +${item.dexBonus}', AppColors.shadowStable),
                  if (item.intBonus != 0) _bonusChip('INT +${item.intBonus}', AppColors.mp),
                  if (item.conBonus != 0) _bonusChip('CON +${item.conBonus}', AppColors.xp),
                  if (item.spiBonus != 0) _bonusChip('ESP +${item.spiBonus}', AppColors.gold),
                  if (item.hpBonus != 0)  _bonusChip('HP +${item.hpBonus}', AppColors.hp),
                  if (item.mpBonus != 0)  _bonusChip('MP +${item.mpBonus}', AppColors.mp),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Botão desequipar
            GestureDetector(
              onTap: () async {
                final db = ref.read(appDatabaseProvider);
                await (db.update(db.inventoryTable)
                      ..where((t) => t.id.equals(equipped.inv.id)))
                    .write(const InventoryTableCompanion(
                        equippedSlot: Value(null)));
                ref.invalidate(equippedItemsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.hp.withValues(alpha: 0.4)),
                  color: AppColors.hp.withValues(alpha: 0.06),
                ),
                child: Text('Desequipar',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: AppColors.hp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bonusChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.roboto(fontSize: 11, color: color)),
      );

  bool _hasBonuses(ItemsTableData item) =>
      item.strBonus != 0 || item.dexBonus != 0 || item.intBonus != 0 ||
      item.conBonus != 0 || item.spiBonus != 0 ||
      item.hpBonus != 0 || item.mpBonus != 0;

  Color _rarityColor(String rarity) => switch (rarity) {
        'legendary' => const Color(0xFFFF8C00),
        'epic'      => AppColors.purple,
        'rare'      => const Color(0xFF3070B3),
        'uncommon'  => const Color(0xFF4FA06B),
        'mythic'    => const Color(0xFFFF2D55),
        _           => AppColors.textMuted,
      };

  Widget _buildClassFaction(player) {
    if (player == null) return const SizedBox.shrink();
    final className = _className(player.classType ?? '');
    final factionName = _factionName(player.factionType ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLASSE',
                    style: GoogleFonts.roboto(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(className.isEmpty ? 'Sem classe' : className,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 13, color: AppColors.purple)),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FACÇÃO',
                      style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(factionName.isEmpty ? 'Nenhuma' : factionName,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 13, color: AppColors.gold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributes(
    BuildContext context,
    WidgetRef ref,
    player,
    int bonusStr, int bonusDex, int bonusInt,
    int bonusCon, int bonusSpi, int bonusHp, int bonusMp,
  ) {
    final attrs = [
      ('Força',        'strength',     (player?.strength     ?? 1), bonusStr, Icons.fitness_center,        AppColors.hp,          'Poder físico, dano e carga'),
      ('Destreza',     'dexterity',    (player?.dexterity    ?? 1), bonusDex, Icons.speed,                  AppColors.shadowStable,'Precisão, crítico e esquiva'),
      ('Inteligência', 'intelligence', (player?.intelligence ?? 1), bonusInt, Icons.psychology_outlined,    AppColors.mp,          'Dano mágico e resistência'),
      ('Constituição', 'constitution', (player?.constitution ?? 1), bonusCon, Icons.shield_outlined,        AppColors.xp,          'HP máximo e resistência física'),
      ('Espírito',     'spirit',       (player?.spirit       ?? 1), bonusSpi, Icons.self_improvement,       AppColors.gold,        'MP, vitalismo e estabilidade'),
    ];

    final hasPoints = (player?.attributePoints ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ATRIBUTOS',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
              if (hasPoints)
                Text('${player!.attributePoints} pts',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 16),
          ...attrs.map((a) {
            final base = a.$3 as int;
            final bonus = a.$4 as int;
            final total = base + bonus;
            final color = a.$6 as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(a.$5 as IconData, color: color, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a.$1 as String,
                          style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                    ),
                    // Valor total
                    Text('$total',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 14,
                            color: color,
                            fontWeight: FontWeight.bold)),
                    // Bônus de equipamento
                    if (bonus > 0) ...[
                      const SizedBox(width: 4),
                      Text('+$bonus',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: color.withValues(alpha: 0.7))),
                    ],
                    if (hasPoints) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _addPoint(context, ref, player!.id, a.$2 as String),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.15),
                            border: Border.all(color: color.withValues(alpha: 0.6)),
                          ),
                          child: Icon(Icons.add, color: color, size: 16),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (total / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(a.$7 as String,
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEquipmentBonusSummary(int hp, int mp, int str,
      int dex, int intel, int con, int spi) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BÔNUS DE EQUIPAMENTOS',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 10, color: AppColors.gold, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              if (hp > 0)   _bonusChip('HP +$hp',   AppColors.hp),
              if (mp > 0)   _bonusChip('MP +$mp',   AppColors.mp),
              if (str > 0)  _bonusChip('FOR +$str', AppColors.hp),
              if (dex > 0)  _bonusChip('DES +$dex', AppColors.shadowStable),
              if (intel > 0) _bonusChip('INT +$intel', AppColors.mp),
              if (con > 0)  _bonusChip('CON +$con', AppColors.xp),
              if (spi > 0)  _bonusChip('ESP +$spi', AppColors.gold),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addPoint(
      BuildContext context, WidgetRef ref, int playerId, String attr) async {
    final db = ref.read(appDatabaseProvider);
    final player = ref.read(currentPlayerProvider);
    if (player == null || player.attributePoints <= 0) return;

    final colMap = {
      'strength':     player.strength + 1,
      'dexterity':    player.dexterity + 1,
      'intelligence': player.intelligence + 1,
      'constitution': player.constitution + 1,
      'spirit':       player.spirit + 1,
    };
    final newVal = colMap[attr];
    if (newVal == null) return;

    await db.customUpdate(
      'UPDATE players SET $attr = ?, attribute_points = attribute_points - 1 WHERE id = ?',
      variables: [Variable.withInt(newVal), Variable.withInt(playerId)],
      updates: {db.playersTable},
    );
    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;
    if (context.mounted) AppSnack.success(context, '+1 $attr');
  }

  String _className(String c) => switch (c) {
        'warrior'      => 'Guerreiro',
        'colossus'     => 'Colosso',
        'monk'         => 'Monge',
        'rogue'        => 'Ladino',
        'hunter'       => 'Caçador',
        'druid'        => 'Druida',
        'mage'         => 'Mago',
        'shadowWeaver' => 'Tecelão Sombrio',
        _ => '',
      };

  String _factionName(String f) => switch (f) {
        'moon_clan'    => 'Clã da Lua',
        'sun_clan'     => 'Clã do Sol',
        'black_legion' => 'Legião Negra',
        'new_order'    => 'Nova Ordem',
        'trinity'      => 'Trindade',
        'renegades'    => 'Renegados',
        'error'        => 'ERROR',
        'guild'        => 'Guilda',
        _ => '',
      };
}
