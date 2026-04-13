import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/xp_calculator.dart';
import '../../../data/database/app_database.dart';

class StatsPanel extends StatelessWidget {
  final PlayersTableData player;
  const StatsPanel({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final stats = XpCalculator.calcDerivedStats(
      strength:      player.strength,
      dexterity:     player.dexterity,
      intelligence:  player.intelligence,
      constitution:  player.constitution,
      spirit:        player.spirit,
      charisma:      player.charisma,
      level:         player.level,
      classType:     player.classType,
      factionType:   player.factionType,
    );

    final hasVitalism = ['warrior','colossus','rogue','hunter','shadowWeaver']
        .contains(player.classType);

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
          Text('ESTATÍSTICAS',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
          const SizedBox(height: 16),

          _group('OFENSIVO', [
            _StatRow('Dano Físico',    '${stats['physDmg']}',   AppColors.hp),
            _StatRow('Dano Mágico',   '${stats['magicDmg']}',  AppColors.mp),
            if (hasVitalism)
              _StatRow('Dano Vitalista', '${stats['vitalistDmg']}', AppColors.purple,
                  isSpecial: true),
            _StatRow('Crítico Físico', '${stats['physCrit']}%', AppColors.hp),
            _StatRow('Crítico Mágico', '${stats['magicCrit']}%',AppColors.mp),
            _StatRow('Precisão',       '${stats['accuracy']}',  AppColors.gold),
          ]),

          const SizedBox(height: 12),
          _group('DEFENSIVO', [
            _StatRow('Defesa Física',  '${stats['physDef']}',   AppColors.xp),
            _StatRow('Defesa Mágica',  '${stats['magicDef']}',  AppColors.mp),
            _StatRow('Evasão',         '${stats['evasion']}%',  AppColors.shadowStable),
            _StatRow('Resist. Sombra', '${stats['shadowRes']}', AppColors.shadowStable),
            _StatRow('Regeneração',    '+${stats['regen']}/turno', AppColors.shadowAscending),
          ]),

          const SizedBox(height: 12),
          _group('BÔNUS', [
            _StatRow('Bônus XP',   '+${stats['xpBonus']}%',   AppColors.purple),
            _StatRow('Bônus Ouro', '+${stats['goldBonus']}%',  AppColors.gold),
          ]),

          if (player.classType == null || player.classType!.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Escolha uma classe no nível 5 para desbloquear bônus de estatísticas.',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _group(String label, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 9,
                color: AppColors.textMuted,
                letterSpacing: 2)),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isSpecial;

  const _StatRow(this.label, this.value, this.color,
      {this.isSpecial = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isSpecial) ...[
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          Text(value,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
