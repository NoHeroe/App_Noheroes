import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
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
import '../../../domain/models/player_snapshot.dart';
import '../../shared/widgets/feature_chip.dart';
import '../../shared/widgets/nh_bottom_nav.dart';
import '../../shared/widgets/app_snack.dart';
// Sprint 3.4 Etapa D (D17) — barras de status (HP/VT|MP/XP) migraram do
// Santuário pra cá, renderizadas acima dos atributos.
import '../../shared/widgets/stat_bars_row.dart';
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
                        // HP/VT/XP no TOPO, acima do modelo 3D.
                        const StatBarsRow(),
                        const SizedBox(height: 12),
                        _buildAvatarFull(context, ref, equipped),
                        const SizedBox(height: 12),
                        _buildClassFaction(player),
                        const SizedBox(height: 12),
                        _buildGuildRankCard(player),
                        const SizedBox(height: 12),
                        _buildAttributes(context, ref, player, effective),
                        const SizedBox(height: 12),
                        if (player != null)
                          // Estatísticas em acordeão (fechado por padrão).
                          _AccordionSection(
                            title: 'ESTATÍSTICAS',
                            child: StatsPanel(
                              player: player,
                              factionXpBonusPct:
                                  ((buffSnapshot.multipliers.xpMult - 1.0) * 100)
                                      .round(),
                              factionGoldBonusPct:
                                  ((buffSnapshot.multipliers.goldMult - 1.0) *
                                          100)
                                      .round(),
                            ),
                          ),
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
            child: NhBottomNav(currentIndex: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(player) {
    // Sprint 2.3 fix — chip de acesso a Encantamento (lv20). FORJA removido
    // daqui (acesso pela Mercearia/Ferreiro).
    final playerLevel = player?.level ?? 0;
    // Header sem título: só os atalhos + badge de pontos, alinhados à direita
    // e com wrap pra nunca estourar a tela em telas estreitas.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
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

    // Slots reordenados (CEO): bota<->luva, depois bota<->cinto. Resultado:
    // esquerda = Capacete/Peitoral/Botas; direita = Luvas/Cinto/Escudo.
    final leftSlots = [
      ('Capacete', Icons.security, 'head'),
      ('Peitoral', Icons.shield, 'chest'),
      ('Botas', Icons.hiking, 'feet'),
    ];
    final rightSlots = [
      ('Luvas', Icons.back_hand_outlined, 'hands'),
      ('Cinto', Icons.fitness_center_outlined, 'waist'),
      ('Escudo', Icons.shield_outlined, 'off_hand'),
    ];
    final bottomSlots = [
      ('Arma', Icons.gavel, 'main_hand'),
      ('Anel', Icons.circle_outlined, 'ring'),
      ('Colar', Icons.auto_awesome, 'necklace'),
    ];

    Widget slotColumn(List<(String, IconData, String)> slots) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: slots
              .map((s) =>
                  _slot(context, ref, s.$1, s.$2, slotMap[s.$3], s.$3))
              .toList(),
        );

    // Modelo 3D ocupa ~98% da caixa; os slots ficam SOBRE o modelo (ele ao
    // centro/fundo). Botão de edição no topo-centro.
    return Container(
      height: screenH * 0.52,
      padding: const EdgeInsets.all(6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        gradient: RadialGradient(colors: [
          AppColors.purple.withValues(alpha: 0.12),
          AppColors.surface,
        ]),
      ),
      child: Stack(
        children: [
          // Modelo 3D preenchendo a caixa.
          const Positioned.fill(child: _Character3DView()),
          // Slots laterais sobrepostos.
          Positioned(
            left: 2,
            top: 44,
            bottom: 56,
            child: Center(child: slotColumn(leftSlots)),
          ),
          Positioned(
            right: 2,
            top: 44,
            bottom: 56,
            child: Center(child: slotColumn(rightSlots)),
          ),
          // Slots inferiores.
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bottomSlots
                  .map((s) => _slot(context, ref, s.$1, s.$2, slotMap[s.$3],
                      s.$3, wide: true))
                  .toList(),
            ),
          ),
          // Botão de edição (topo-centro) → editor de personagem (futuro).
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Center(child: _editButton(context)),
          ),
        ],
      ),
    );
  }

  Widget _editButton(BuildContext context) {
    return GestureDetector(
      onTap: () => AppSnack.warning(
          context, 'Editor de personagem — em breve (recurso premium).'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2030), Color(0xFF0B0910)],
          ),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.2), blurRadius: 10),
          ],
        ),
        child: Text('EDITAR',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 10, letterSpacing: 1.5, color: AppColors.goldLt)),
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    InventoryEntryWithSpec? equipped,
    String slotDbValue, {
    bool wide = false,
  }) {
    final hasItem = equipped != null;
    final rarityColor = equipped?.spec.rarity.color ?? AppColors.textMuted;

    return GestureDetector(
      // Tocar abre o mini-inventário do slot pra trocar/equipar sem sair.
      onTap: () => _openSlotSheet(context, ref, slotDbValue, label, equipped),
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

  // Abre o mini-inventário do slot: equipar/trocar/desequipar sem sair.
  void _openSlotSheet(
    BuildContext context,
    WidgetRef ref,
    String slotDbValue,
    String label,
    InventoryEntryWithSpec? equipped,
  ) {
    final slot = EquipmentSlotParser.fromString(slotDbValue);
    if (slot == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EquipSwapSheet(slot: slot, slotLabel: label),
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
            final eff = a.$7 as int;
            final delta = a.$8;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    // Paleta padronizada: ícone/numeros/botoes em dourado.
                    Icon(a.$4, color: AppColors.goldLt, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a.$1,
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
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('(+$delta)',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: AppColors.goldLt)),
                    ] else
                      Text('$base',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 14,
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold)),
                    if (hasPoints) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _addPoint(
                            context, ref, player!.id, a.$2),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.15),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.6)),
                          ),
                          child: const Icon(Icons.add,
                              color: AppColors.goldLt, size: 16),
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
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(a.$6,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: m.hasDebuff
                ? AppColors.hp.withValues(alpha: 0.4)
                : AppColors.gold.withValues(alpha: 0.25)),
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
      BuildContext context, WidgetRef ref, String playerId, String attr) async {
    final client = ref.read(supabaseClientProvider);
    final player = ref.read(currentPlayerProvider);
    if (player == null || player.attributePoints <= 0) return;

    final result =
        await PlayerDao(client).distributePointWithEvent(playerId, attr);
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
        'lone_wolf'    => 'Lobo Solitário',
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

// ── Modelo 3D do personagem (placeholder: character.glb do projeto antigo) ──
// Ocupa o mesmo espaço/slot do antigo "Avatar 2D". Toca a animação embutida.
class _Character3DView extends StatefulWidget {
  const _Character3DView();

  @override
  State<_Character3DView> createState() => _Character3DViewState();
}

class _Character3DViewState extends State<_Character3DView> {
  final Flutter3DController _controller = Flutter3DController();

  @override
  Widget build(BuildContext context) {
    return Flutter3DViewer(
      src: 'assets/models/character.glb',
      controller: _controller,
      progressBarColor: AppColors.purpleLight,
      enableTouch: true,
      onLoad: (modelAddress) async {
        // Toca a primeira animação embutida no glb (placeholder).
        try {
          final anims = await _controller.getAvailableAnimations();
          if (anims.isNotEmpty) {
            _controller.playAnimation(animationName: anims.first);
          }
        } catch (_) {
          _controller.playAnimation();
        }
        // Câmera padrão: enquadra do torso pra cima, mais próxima. O usuário
        // ainda pode orbitar/zoom livremente. (Valores podem precisar de ajuste
        // fino conforme o modelo final.)
        try {
          _controller.setCameraTarget(0, 1.35, 0);
          _controller.setCameraOrbit(0, 82, 1.4);
        } catch (_) {}
      },
    );
  }
}

// ── Mini-inventário do slot: equipar / trocar / desequipar sem sair ─────────
class _EquipSwapSheet extends ConsumerStatefulWidget {
  final EquipmentSlot slot;
  final String slotLabel;
  const _EquipSwapSheet({required this.slot, required this.slotLabel});

  @override
  ConsumerState<_EquipSwapSheet> createState() => _EquipSwapSheetState();
}

class _EquipSwapSheetState extends ConsumerState<_EquipSwapSheet> {
  Future<List<InventoryEntryWithSpec>>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      _future = Future.value(const []);
      return;
    }
    _future = ref.read(playerInventoryServiceProvider).listOf(player.id);
  }

  PlayerSnapshot? _snapshot() {
    final p = ref.read(currentPlayerProvider);
    if (p == null) return null;
    return PlayerSnapshot(
      level: p.level,
      rank: ItemEquipPolicy.parseRank(p.guildRank),
      classKey: p.classType,
      factionKey: p.factionType,
    );
  }

  Future<void> _equip(InventoryEntryWithSpec item) async {
    final snap = _snapshot();
    if (snap == null || _busy) return;
    setState(() => _busy = true);
    final res = await ref.read(playerEquipmentServiceProvider).equip(
          playerId: item.entry.playerId,
          inventoryId: item.entry.id,
          player: snap,
        );
    ref.invalidate(equippedItemsProvider);
    if (!mounted) return;
    if (res.isOk) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Não foi possível equipar.',
            style: GoogleFonts.roboto(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _unequip(InventoryEntryWithSpec item) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(playerEquipmentServiceProvider).unequip(
          playerId: item.entry.playerId,
          slot: widget.slot,
        );
    ref.invalidate(equippedItemsProvider);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.66),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.backpack_outlined,
                  size: 16, color: AppColors.purpleLight),
              const SizedBox(width: 8),
              Text(widget.slotLabel.toUpperCase(),
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: FutureBuilder<List<InventoryEntryWithSpec>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.purpleLight)),
                  );
                }
                final all = snap.data ?? const <InventoryEntryWithSpec>[];
                final forSlot =
                    all.where((e) => e.spec.slot == widget.slot).toList();
                final equipped =
                    forSlot.where((e) => e.entry.isEquipped).toList();
                final others =
                    forSlot.where((e) => !e.entry.isEquipped).toList();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (equipped.isNotEmpty) ...[
                        _label('EQUIPADO'),
                        const SizedBox(height: 6),
                        _equippedRow(equipped.first),
                        const SizedBox(height: 16),
                      ],
                      _label(equipped.isEmpty ? 'EQUIPAR' : 'TROCAR POR'),
                      const SizedBox(height: 6),
                      if (others.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Nenhum outro item para este slot no inventário.',
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        )
                      else
                        ...others.map(_swapRow),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.cinzelDecorative(
          fontSize: 10, color: AppColors.gold, letterSpacing: 2));

  Widget _equippedRow(InventoryEntryWithSpec item) {
    final color = item.spec.rarity.color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.spec.name,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 12, color: AppColors.textPrimary)),
                if (item.spec.stats.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.spec.stats.entries
                        .map((e) => '${e.key} +${e.value}')
                        .join('  ·  '),
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
                if (item.entry.appliedRuneKey != null) ...[
                  const SizedBox(height: 8),
                  _AppliedRuneSection(runeKey: item.entry.appliedRuneKey!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _busy ? null : () => _unequip(item),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.hp.withValues(alpha: 0.5)),
                color: AppColors.hp.withValues(alpha: 0.06),
              ),
              child: Text('DESEQUIPAR',
                  style: GoogleFonts.roboto(
                      fontSize: 9, letterSpacing: 1, color: AppColors.hp)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swapRow(InventoryEntryWithSpec item) {
    final color = item.spec.rarity.color;
    final snap = _snapshot();
    final canEquip = snap == null
        ? true
        : ItemEquipPolicy.canEquipItem(item: item.spec, player: snap).isOk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: (!canEquip || _busy) ? null : () => _equip(item),
        child: Opacity(
          opacity: canEquip ? 1.0 : 0.45,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.spec.name,
                          style: GoogleFonts.roboto(
                              fontSize: 12, color: AppColors.textPrimary)),
                      if (item.spec.stats.isNotEmpty)
                        Text(
                          item.spec.stats.entries
                              .map((e) => '${e.key} +${e.value}')
                              .join('  ·  '),
                          style: GoogleFonts.roboto(
                              fontSize: 9, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                Icon(
                  canEquip ? Icons.swap_horiz : Icons.lock_outline,
                  size: 16,
                  color: canEquip ? AppColors.gold : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Seção em acordeão (fechada por padrão). O child traz o próprio card. ─────
class _AccordionSection extends StatefulWidget {
  final String title;
  final Widget child;
  const _AccordionSection({required this.title, required this.child});

  @override
  State<_AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<_AccordionSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(widget.title,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 11,
                        color: AppColors.gold,
                        letterSpacing: 2)),
                const Spacer(),
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.goldLt, size: 20),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: widget.child,
          ),
          crossFadeState:
              _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}
