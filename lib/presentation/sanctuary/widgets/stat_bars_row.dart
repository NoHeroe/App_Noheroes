import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/vitalism_calculator.dart';
import '../../../data/database/tables/players_table_ext.dart';

class StatBarsRow extends ConsumerWidget {
  const StatBarsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usa stream reativo — atualiza automaticamente
    final playerAsync = ref.watch(playerStreamProvider);
    final player = playerAsync.value ?? ref.watch(currentPlayerProvider);

    // Sprint 3.4 Etapa C hotfix #2 (P1-C) — `maxHp` lê do
    // `effectiveAttributesProvider` (pós-buff de facção), não do DB
    // direto. Mantém consistência com /personagem (player Nova Ordem
    // vê 110/X em ambas as telas, não 100/X aqui e 110 lá).
    // Fallback pra `player.maxHp` enquanto provider carrega.
    final effective = ref.watch(effectiveAttributesProvider).value;

    final hp      = player?.hp ?? 100;
    final maxHp   = effective?.maxHpEffective ?? (player?.maxHp ?? 100);
    final mp      = player?.mp ?? 100;
    final maxMp   = player?.maxMp ?? 100;
    final xp      = player?.xp ?? 0;
    final xpToNext= player?.xpToNext ?? 100;
    final hasVitalism = player?.isVitalist ?? false;
    final classType = player?.classTypeEnum;
    final vitMax = (hasVitalism && classType != null)
        ? VitalismCalculator.calculateMaxVitalism(
            hp: maxHp,
            classType: classType,
            level: player?.level ?? 1,
          )
        : 0;
    final vitVal = (player?.currentVitalism ?? 0).clamp(0, vitMax);

    final classChosen = player?.classType != null &&
        player!.classType!.isNotEmpty;
    final hasMana = classChosen && !hasVitalism;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _StatBar(label: 'HP', value: hp, max: maxHp,
              color: AppColors.hp, icon: Icons.favorite),
          const SizedBox(height: 10),
          // Vitalismo substitui MP; sem classe = sem barra secundária
          if (hasVitalism) ...[
            _StatBar(label: 'VT', value: vitVal, max: vitMax,
                color: AppColors.purple, icon: Icons.bolt),
            const SizedBox(height: 10),
          ] else if (hasMana) ...[
            _StatBar(label: 'MP', value: mp, max: maxMp,
                color: AppColors.mp, icon: Icons.auto_awesome),
            const SizedBox(height: 10),
          ],
          _StatBar(label: 'XP', value: xp, max: xpToNext,
              color: AppColors.xp, icon: Icons.star),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final IconData icon;

  const _StatBar({
    required this.label, required this.value,
    required this.max, required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        SizedBox(width: 28,
            child: Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 1))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value/$max',
            style: GoogleFonts.roboto(
                fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
