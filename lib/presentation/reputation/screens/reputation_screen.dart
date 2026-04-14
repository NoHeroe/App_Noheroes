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

class ReputationScreen extends ConsumerWidget {
  const ReputationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repAsync = ref.watch(reputationProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
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
            ),
            Expanded(
              child: repAsync.when(
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
