import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/npc_reputation_service.dart';
import '../../../data/database/app_database.dart';

final reputationProvider =
    FutureProvider.autoDispose<List<NpcReputationTableData>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  final db = ref.read(appDatabaseProvider);
  return NpcReputationService(db).getAll(player.id);
});

const _npcMeta = {
  'unknown_figure':  ('Figura Desconhecida', 'O que te encontrou nas ruínas'),
  'noryan_gray':     ('Noryan Gray', 'Mestre da Guilda'),
  'azuos':           ('Azuos', 'Líder do Clã da Lua'),
  'koda':            ('Koda', 'Líder do Clã do Sol'),
  'yuna_lannatary':  ('Yuna Lannatary', 'Comandante da Legião Negra'),
  'new_order_agent': ('Agente da Nova Ordem', 'Representante da Nova Ordem'),
  'trinity_priest':  ('Sacerdote da Trindade', 'Guardião dos Três Aspectos'),
  'renegade_leader': ('Líder dos Renegados', 'Voz dos Sem Facção'),
  'chrysalis_agent': ('Agente Chrysalis', 'Operador da Facção ERROR'),
};

class ReputationScreen extends ConsumerStatefulWidget {
  const ReputationScreen({super.key});

  @override
  ConsumerState<ReputationScreen> createState() => _ReputationScreenState();
}

class _ReputationScreenState extends ConsumerState<ReputationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repAsync = ref.watch(reputationProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/sanctuary'),
                        child: const Icon(Icons.arrow_back_ios,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('REPUTAÇÃO',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TabBar(
                    controller: _tabs,
                    indicatorColor: AppColors.gold,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: GoogleFonts.cinzelDecorative(
                        fontSize: 10, letterSpacing: 1),
                    tabs: const [
                      Tab(text: 'NPCs'),
                      Tab(text: 'FACÇÕES'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  // ABA NPCs
                  repAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.purple)),
                error: (e, _) => Center(
                    child: Text('Erro: $e',
                        style: const TextStyle(color: AppColors.textMuted))),
                data: (reps) {
                  final repMap = {for (final r in reps) r.npcId: r};
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    children: _npcMeta.entries.map((e) {
                      final npcId = e.key;
                      final meta = e.value;
                      final rep = repMap[npcId];
                      final value = rep?.reputation ?? 50;
                      final level = NpcReputationService.levelFromValue(value);
                      final label = NpcReputationService.labelFromLevel(level);
                      final color = _levelColor(level);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.1),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.4)),
                              ),
                              child: Icon(Icons.person_outline,
                                  color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(meta.$1,
                                      style: GoogleFonts.cinzelDecorative(
                                          fontSize: 11,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(meta.$2,
                                      style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: value / 100,
                                      backgroundColor: AppColors.border,
                                      valueColor:
                                          AlwaysStoppedAnimation(color),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.4)),
                              ),
                              child: Text(label,
                                  style: GoogleFonts.roboto(
                                      fontSize: 10, color: color)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
                  // ABA FACÇÕES
                  const _FactionReputationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(NpcRepLevel level) => switch (level) {
        NpcRepLevel.hostile     => AppColors.hp,
        NpcRepLevel.distrustful => AppColors.shadowChaotic,
        NpcRepLevel.neutral     => AppColors.textMuted,
        NpcRepLevel.ally        => AppColors.mp,
        NpcRepLevel.loyal       => AppColors.shadowAscending,
        NpcRepLevel.devout      => AppColors.gold,
      };
}

const _factionMeta = {
  'moon_clan':    ('Clã da Lua',       Icons.nightlight_round),
  'sun_clan':     ('Clã do Sol',       Icons.wb_sunny_outlined),
  'black_legion': ('Legião Negra',     Icons.shield_outlined),
  'new_order':    ('Nova Ordem',       Icons.account_balance_outlined),
  'trinity':      ('Trindade',         Icons.blur_circular_outlined),
  'renegades':    ('Renegados',        Icons.bolt_outlined),
  'error':        ('ERROR',            Icons.error_outline),
  'guild':        ('Guilda',           Icons.store_outlined),
};

class _FactionReputationTab extends ConsumerWidget {
  const _FactionReputationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final playerFaction = player?.factionType ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: _factionMeta.entries.map((e) {
        final factionId = e.key;
        final meta = e.value;
        final isPlayer = playerFaction == factionId;
        // Reputação base: 50 (Neutro) para todas, exceto a do jogador que começa em 60
        final rep = isPlayer ? 60 : 40;
        final level = NpcReputationService.levelFromValue(rep);
        final label = NpcReputationService.labelFromLevel(level);
        final color = _factionColor(factionId);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isPlayer
                    ? color.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(meta.$2, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(meta.$1,
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 11,
                              color: AppColors.textPrimary)),
                      if (isPlayer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: color.withValues(alpha: 0.4)),
                          ),
                          child: Text('Sua facção',
                              style: GoogleFonts.roboto(
                                  fontSize: 9, color: color)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rep / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(label,
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: color)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _factionColor(String id) => switch (id) {
        'moon_clan'    => const Color(0xFF3070B3),
        'sun_clan'     => const Color(0xFFC2A05A),
        'black_legion' => const Color(0xFF8B2020),
        'new_order'    => const Color(0xFF6B4FA0),
        'trinity'      => const Color(0xFF4FA06B),
        'renegades'    => const Color(0xFFB36B00),
        'error'        => const Color(0xFF7B2FBE),
        'guild'        => AppColors.gold,
        _              => AppColors.textMuted,
      };
}
