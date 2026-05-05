import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/enums/equipment_slot.dart';
import '../../../domain/enums/item_rarity.dart';
import '../../../domain/models/faction_buff_multipliers.dart';
import '../../../domain/models/inventory_entry_with_spec.dart';
import '../../shared/widgets/feature_chip.dart';
import '../../shared/widgets/nh_bottom_nav.dart';
import '../../shared/widgets/app_snack.dart';
import '../widgets/stats_panel.dart';

// Equipamento do jogador via playerEquipmentService. Substitui a leitura
// direta de inventoryTable/itemsTable antigos (Sprint 2.1 Bloco 5.5).
final equippedItemsProvider =
    FutureProvider.autoDispose<List<InventoryEntryWithSpec>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return const [];
  return ref.read(playerEquipmentServiceProvider).equippedItemsOf(player.id);
});

// Sprint 2.3 fix (B5) — stats agregados de equipamentos + runas aplicadas.
// Usa o método async do service (soma spec.stats + rune.effects).
// O método síncrono ItemEquipPolicy.aggregateStatsFromEquippedEntries só
// soma spec.stats e NÃO enxerga runas — era o bug anterior.
final aggregatedEquipmentStatsProvider =
    FutureProvider.autoDispose<Map<String, num>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return const {};
  // Mantém dependência de equippedItemsProvider pra re-agregar quando
  // equipamento muda (invalidate cascata).
  ref.watch(equippedItemsProvider);
  return ref.read(playerEquipmentServiceProvider)
      .aggregatedStatsOf(player.id);
});

// Sprint 3.4 Etapa C — `factionBuffSnapshotProvider` e
// `effectiveAttributesProvider` foram promovidos pra `lib/app/providers.dart`
// (escopo global) no hotfix #2 (P1-C). Outros widgets (StatBarsRow do
// Santuário) também precisavam consumir os mesmos valores efetivos, pra
// manter consistência entre /personagem e Santuário (player Nova Ordem
// vê maxHp 110 nas duas telas).

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final equippedAsync = ref.watch(equippedItemsProvider);
    final equipped = equippedAsync.value ?? const <InventoryEntryWithSpec>[];

    // Sprint 2.3 fix (B5) — stats agregados via service async (inclui runas).
    // Antes usava ItemEquipPolicy.aggregateStatsFromEquippedEntries direto
    // (síncrono, só spec.stats) — runas nunca eram somadas.
    final aggregatedAsync = ref.watch(aggregatedEquipmentStatsProvider);
    final stats = aggregatedAsync.value ?? const <String, num>{};

    // Sprint 3.4 Etapa C — buffs de facção em runtime.
    final buffSnapshot =
        ref.watch(factionBuffSnapshotProvider).value ?? FactionBuffSnapshot.empty;
    final effective =
        ref.watch(effectiveAttributesProvider).value ?? EffectiveAttributes.empty;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(player),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    child: Column(
                      children: [
                        _buildAvatarFull(context, ref, equipped),
                        const SizedBox(height: 12),
                        _buildClassFaction(player),
                        const SizedBox(height: 12),
                        _buildGuildRankCard(player),
                        const SizedBox(height: 12),
                        _buildAttributes(context, ref, player, effective),
                        const SizedBox(height: 12),
                        if (player != null) StatsPanel(player: player),
                        if (buffSnapshot.applied.isNotEmpty ||
                            buffSnapshot.pending.isNotEmpty ||
                            buffSnapshot.multipliers.hasDebuff ||
                            effective.maxHpDelta > 0) ...[
                          const SizedBox(height: 12),
                          _buildFactionBuffsSection(
                              buffSnapshot, effective),
                        ],
                        if (stats.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildEquipmentStatsSummary(stats),
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

  Widget _buildHeader(player) {
    // Sprint 2.3 fix — chips de acesso a Forja (lv6) e Encantamento (lv20).
    final playerLevel = player?.level ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            'PERSONAGEM',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 16, color: AppColors.gold, letterSpacing: 2),
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
          if ((player?.attributePoints ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                '+${player!.attributePoints} pts disponíveis',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 10, color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarFull(BuildContext context, WidgetRef ref,
      List<InventoryEntryWithSpec> equipped) {
    final screenH = MediaQuery.of(context).size.height;

    // Mapeia slot (dbValue do enum) → item equipado.
    final slotMap = <String, InventoryEntryWithSpec>{};
    for (final e in equipped) {
      if (e.spec.slot != null) slotMap[e.spec.slot!.dbValue] = e;
    }

    final leftSlots = [
      ('Capacete', Icons.security, 'head'),
      ('Peitoral', Icons.shield, 'chest'),
      ('Cinto', Icons.fitness_center_outlined, 'waist'),
    ];
    final rightSlots = [
      ('Botas', Icons.hiking, 'feet'),
      ('Luvas', Icons.back_hand_outlined, 'hands'),
      ('Escudo', Icons.shield_outlined, 'off_hand'),
    ];
    final bottomSlots = [
      ('Arma', Icons.gavel, 'main_hand'),
      ('Anel', Icons.circle_outlined, 'ring'),
      ('Colar', Icons.auto_awesome, 'necklace'),
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
                      .map((s) =>
                          _slot(context, ref, s.$1, s.$2, slotMap[s.$3]))
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
                            color:
                                AppColors.purple.withValues(alpha: 0.4)),
                        gradient: RadialGradient(colors: [
                          AppColors.purple.withValues(alpha: 0.2),
                          AppColors.shadowVoid,
                        ]),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.purple.withValues(alpha: 0.4),
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
                      .map((s) =>
                          _slot(context, ref, s.$1, s.$2, slotMap[s.$3]))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: bottomSlots
                .map((s) =>
                    _slot(context, ref, s.$1, s.$2, slotMap[s.$3], wide: true))
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
    InventoryEntryWithSpec? equipped, {
    bool wide = false,
  }) {
    final hasItem = equipped != null;
    final rarityColor = equipped?.spec.rarity.color ?? AppColors.textMuted;

    return GestureDetector(
      onTap: hasItem ? () => _showItemDetail(context, ref, equipped) : null,
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
                      equipped.spec.name,
                      style: GoogleFonts.roboto(
                          fontSize: 7, color: rarityColor, height: 1.2),
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
    InventoryEntryWithSpec equipped,
  ) {
    final spec = equipped.spec;
    final color = spec.rarity.color;

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(spec.rarity.label.toUpperCase(),
                      style: GoogleFonts.roboto(
                          fontSize: 9, color: color, letterSpacing: 1.5)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(spec.name,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 14, color: AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(spec.description,
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            if (spec.stats.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('BÔNUS',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 10,
                      color: AppColors.gold,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final entry in spec.stats.entries)
                    _bonusChip(
                      '${entry.key.toUpperCase()} +${entry.value}',
                      AppColors.gold,
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Sprint 2.3 fix (B5) — mostra runa aplicada no item equipado
            // com seus efeitos (resolve async via FutureBuilder).
            if (equipped.entry.appliedRuneKey != null)
              _AppliedRuneSection(runeKey: equipped.entry.appliedRuneKey!),
            GestureDetector(
              onTap: () async {
                final slot = spec.slot;
                if (slot == null) return;
                await ref.read(playerEquipmentServiceProvider).unequip(
                      playerId: equipped.entry.playerId,
                      slot: slot,
                    );
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

  Widget _buildGuildRankCard(player) {
    if (player == null) return const SizedBox.shrink();
    final rank = ItemEquipPolicy.parseRank(player.guildRank);
    final color = _rankColor(rank);
    final letter = rank == null ? '—' : rank.name.toUpperCase();
    final title = rank == null ? 'SEM RANK' : 'RANK $letter';
    final next = rank == null ? GuildRank.e : GuildRankSystem.next(rank);
    final nextLabel = next == null
        ? 'Você atingiu o rank máximo.'
        : 'Próximo rank: ${next.name.toUpperCase()} — '
            'requer Teste de Ascensão (Sprint 3.4).';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 26,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GUILDA',
                    style: GoogleFonts.roboto(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(title,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: color,
                        letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(
                  nextLabel,
                  style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _rankColor(GuildRank? rank) => switch (rank) {
        null           => Colors.grey,
        GuildRank.e    => Colors.brown,
        GuildRank.d    => const Color(0xFFC0C0C0), // prata
        GuildRank.c    => const Color(0xFFFFD54F), // ouro fosco
        GuildRank.b    => AppColors.gold,
        GuildRank.a    => AppColors.purple,
        GuildRank.s    => Colors.deepOrange,
      };

  Widget _buildAttributes(BuildContext context, WidgetRef ref, player,
      EffectiveAttributes effective) {
    // Sprint 3.4 Etapa C — `effective` traz valores pós-buff de facção.
    // Pra atributos com delta != 0, rendererá "12 → 13 (+1)" ao lado do
    // valor base. Atributos sem buff (constitution, spirit) renderizam
    // sem indicador.
    final attrs = [
      ('Força',        'strength',     (player?.strength     ?? 1),
          Icons.fitness_center,         AppColors.hp,           'Poder físico, dano e carga',
          effective.strengthEffective, effective.strengthDelta),
      ('Destreza',     'dexterity',    (player?.dexterity    ?? 1),
          Icons.speed,                  AppColors.shadowStable, 'Precisão, crítico e esquiva',
          effective.dexterityEffective, effective.dexterityDelta),
      ('Inteligência', 'intelligence', (player?.intelligence ?? 1),
          Icons.psychology_outlined,    AppColors.mp,           'Dano mágico e resistência',
          effective.intelligenceEffective, effective.intelligenceDelta),
      ('Constituição', 'constitution', (player?.constitution ?? 1),
          Icons.shield_outlined,        AppColors.xp,           'HP máximo e resistência física',
          (player?.constitution ?? 1), 0),
      ('Espírito',     'spirit',       (player?.spirit       ?? 1),
          Icons.self_improvement,       AppColors.gold,         'MP, vitalismo e estabilidade',
          (player?.spirit ?? 1), 0),
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
                      fontSize: 11,
                      color: AppColors.gold,
                      letterSpacing: 2)),
              if (hasPoints)
                Text('${player!.attributePoints} pts',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 16),
          ...attrs.map((a) {
            final base = a.$3 as int;
            final color = a.$5 as Color;
            final eff = a.$7 as int;
            final delta = a.$8 as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(a.$4 as IconData, color: color, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a.$1 as String,
                          style: GoogleFonts.roboto(
                              fontSize: 13, color: AppColors.textPrimary)),
                    ),
                    if (delta > 0) ...[
                      Text('$base → ',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 12, color: AppColors.textMuted)),
                      Text('$eff',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 14,
                              color: color,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('(+$delta)',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: AppColors.gold)),
                    ] else
                      Text('$base',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 14,
                              color: color,
                              fontWeight: FontWeight.bold)),
                    if (hasPoints) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _addPoint(
                            context, ref, player!.id, a.$2 as String),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.15),
                            border: Border.all(
                                color: color.withValues(alpha: 0.6)),
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
                      value: (base / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(a.$6 as String,
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

  // Sprint 3.4 Etapa C — seção de buffs de facção. Mostra:
  // 1. Alerta de DEBUFF DE SAÍDA (-30% XP/gold) com timestamp se ativo
  // 2. Lista de buffs APLICADOS (verde) — runtime hoje
  // 3. Linha de ATRIBUTOS EFETIVOS pra maxHp (str/dex/int já aparecem
  //    em _buildAttributes acima)
  // 4. Lista de buffs FUTUROS (cinza) — pending narrativos
  // Sprint 3.4 Etapa C hotfix #1:
  // - Texto contextual quando debuff ativo: buffs visíveis mas
  //   "neutralizados pelo debuff" (player ainda é member da facção)
  // - Linha "HP Máximo: 100 → 110 (+10)" quando maxHpDelta > 0
  Widget _buildFactionBuffsSection(
      FactionBuffSnapshot snap, EffectiveAttributes effective) {
    final m = snap.multipliers;

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
          if (m.hasDebuff) ...[
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.hp, size: 16),
              const SizedBox(width: 6),
              Text('DEBUFF DE SAÍDA',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 11,
                      color: AppColors.hp,
                      letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 8),
            Text(
              '-30% XP / -30% ouro até ${_fmtDebuffEnd(m.debuffEndsAt)}',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
          ],
          if (snap.applied.isNotEmpty) ...[
            Text('BUFFS ATIVOS',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 11,
                    color: AppColors.shadowAscending,
                    letterSpacing: 2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: snap.applied
                  .map((e) => _bonusChip(e.label, AppColors.shadowAscending))
                  .toList(growable: false),
            ),
            if (m.hasDebuff) ...[
              const SizedBox(height: 8),
              Text(
                'Buffs suspensos pelo debuff de saída — efeito real -30%.',
                style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
              ),
            ],
            if (effective.maxHpDelta > 0 || snap.pending.isNotEmpty)
              const SizedBox(height: 14),
          ],
          if (effective.maxHpDelta > 0) ...[
            Text('ATRIBUTOS EFETIVOS',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 11,
                    color: AppColors.gold,
                    letterSpacing: 2)),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.favorite, color: AppColors.hp, size: 14),
              const SizedBox(width: 8),
              Text('HP Máximo:',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.textPrimary)),
              const SizedBox(width: 6),
              Text(
                '${effective.maxHpBase} → ${effective.maxHpEffective}',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 13,
                    color: AppColors.hp,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text('(+${effective.maxHpDelta})',
                  style: GoogleFonts.roboto(
                      fontSize: 10, color: AppColors.gold)),
            ]),
            if (snap.pending.isNotEmpty) const SizedBox(height: 14),
          ],
          if (snap.pending.isNotEmpty) ...[
            Text('BUFFS FUTUROS',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: snap.pending
                  .map((e) => _bonusChip(e.label, AppColors.textMuted))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDebuffEnd(DateTime? at) {
    if (at == null) return '?';
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(at.day)}/${pad(at.month)} ${pad(at.hour)}:${pad(at.minute)}';
  }

  // Novo: mostra stats agregados dos itens equipados (chaves livres —
  // atk/def/agi/crit/...). Substitui o antigo bloco de bônus fixos.
  Widget _buildEquipmentStatsSummary(Map<String, num> stats) {
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
                  fontSize: 10,
                  color: AppColors.gold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final entry in stats.entries)
                _bonusChip(
                  '${entry.key.toUpperCase()} +${entry.value}',
                  AppColors.gold,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sprint 3.3 Etapa 2.1c-α — delega ao
  /// `PlayerDao.distributePointWithEvent` (incrementa atributo +
  /// `total_attribute_points_spent` numa única operação) e publica
  /// `AttributePointSpent` no AppEventBus pra alimentar trigger
  /// `event_attribute_point_spent`.
  ///
  /// Substituiu o `customUpdate` direto que bypassava contador all-time.
  Future<void> _addPoint(
      BuildContext context, WidgetRef ref, int playerId, String attr) async {
    final db = ref.read(appDatabaseProvider);
    final player = ref.read(currentPlayerProvider);
    if (player == null || player.attributePoints <= 0) return;

    final result = await PlayerDao(db).distributePointWithEvent(playerId, attr);
    if (!result.isOk) {
      if (context.mounted) {
        AppSnack.success(context, result.error ?? 'Erro ao distribuir ponto');
      }
      return;
    }

    // Sprint 3.3 Etapa 2.1c-α — caller publica evento (PlayerDao
    // mantém-se desacoplado do AppEventBus por ADR 0016).
    ref.read(appEventBusProvider).publish(result.event!);

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
        _              => '',
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
        _              => '',
      };
}

// Sprint 2.3 fix (B5) — seção "ENCANTAMENTO" no detail sheet do item
// equipado. Resolve a runa assíncrona via FutureBuilder + itemsCatalog cache.
class _AppliedRuneSection extends ConsumerWidget {
  final String runeKey;
  const _AppliedRuneSection({required this.runeKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.read(itemsCatalogServiceProvider);
    return FutureBuilder<dynamic>(
      future: catalog.findByKey(runeKey),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final rune = snap.data;
        if (rune == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.purpleLight, size: 12),
                  const SizedBox(width: 6),
                  Text('ENCANTAMENTO',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 10,
                          color: AppColors.purpleLight,
                          letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 8),
              Text(rune.name as String,
                  style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final e in (rune.effects as Map<String, dynamic>)
                      .entries)
                    if (e.value is num)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.purpleLight
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.purpleLight
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '+${e.value} ${e.key}',
                          style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: AppColors.purpleLight),
                        ),
                      ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
