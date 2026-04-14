import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import 'region_detail_screen.dart';

const _regions = [
  {
    'id': 'aureum',
    'name': 'Campos de Aureum',
    'subtitle': 'Região inicial de Caelum',
    'description': 'Campos vastos entre o dia e o crepúsculo. Ruínas de civilizações que ninguém consegue datar. É onde tudo começa.',
    'unlock_level': 1,
    'color': 0xFFC2A05A,
    'icon': 'wb_twilight',
    'npcs': ['Figura Desconhecida', 'Noryan Gray'],
    'quests_available': true,
  },
  {
    'id': 'ruins',
    'name': 'Ruínas Exteriores',
    'subtitle': 'Vestígios da Primeira Era',
    'description': 'Ruínas que guardam segredos da Primeira Era de Caelum. Perigo moderado. Recompensas consideráveis.',
    'unlock_level': 3,
    'color': 0xFF8B6914,
    'icon': 'account_balance',
    'npcs': ['Guardião das Ruínas'],
    'quests_available': true,
  },
  {
    'id': 'white_forest',
    'name': 'Floresta Branca',
    'subtitle': 'Onde a luz não chega ao chão',
    'description': 'Uma floresta densa onde a luz solar nunca toca o solo. Habitada por entidades que nem sempre são hostis.',
    'unlock_level': 8,
    'color': 0xFF4FA06B,
    'icon': 'forest',
    'npcs': ['Espírito da Floresta'],
    'quests_available': true,
  },
  {
    'id': 'shattered_valley',
    'name': 'Vale Estilhaçado',
    'subtitle': 'Fragmentos de um mundo partido',
    'description': 'Um vale onde a realidade parece fragmentada. Plataformas de terra flutuam sem explicação. Origem desconhecida.',
    'unlock_level': 12,
    'color': 0xFF6B4FA0,
    'icon': 'landscape',
    'npcs': ['Andarilho do Vale'],
    'quests_available': true,
  },
  {
    'id': 'vallarys',
    'name': 'Vallarys',
    'subtitle': 'Cidade dos Portais',
    'description': 'Uma cidade construída ao redor de portais dimensionais. Centro de comércio e poder político de Caelum.',
    'unlock_level': 20,
    'color': 0xFF3070B3,
    'icon': 'blur_circular',
    'npcs': ['Operadores de Vallarys'],
    'quests_available': false,
  },
  {
    'id': 'nova_draconis',
    'name': 'Nova Draconis',
    'subtitle': 'Território dos Draconianos',
    'description': 'Lar dos Draconianos. Território hostil para os não iniciados. Riquezas imensas para os corajosos.',
    'unlock_level': 30,
    'color': 0xFFB33030,
    'icon': 'whatshot',
    'npcs': ['Draconianos'],
    'quests_available': false,
  },
];

class RegionsScreen extends ConsumerWidget {
  const RegionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final level = player?.level ?? 1;

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
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('REGIÕES',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 16,
                          color: AppColors.gold,
                          letterSpacing: 2)),
                  const Spacer(),
                  Text('Nível $level',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                itemCount: _regions.length,
                itemBuilder: (ctx, i) {
                  final r = _regions[i];
                  final unlockLevel = r['unlock_level'] as int;
                  final locked = level < unlockLevel;
                  final color = Color(r['color'] as int);

                  return GestureDetector(
                    onTap: () {
                      if (locked) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(
                            'Desbloqueado no Nível $unlockLevel.',
                            style: GoogleFonts.roboto(color: Colors.white),
                          ),
                          backgroundColor: AppColors.surface,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ));
                        return;
                      }
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => RegionDetailScreen(region: r),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: locked
                              ? AppColors.border
                              : color.withValues(alpha: 0.4),
                          width: locked ? 1 : 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Banner da região
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14)),
                              gradient: LinearGradient(
                                colors: locked
                                    ? [
                                        AppColors.surfaceAlt,
                                        AppColors.surface,
                                      ]
                                    : [
                                        color.withValues(alpha: 0.3),
                                        color.withValues(alpha: 0.05),
                                      ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    locked
                                        ? Icons.lock_outline
                                        : Icons.explore_outlined,
                                    color: locked
                                        ? AppColors.textMuted
                                        : color,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          r['name'] as String,
                                          style: GoogleFonts.cinzelDecorative(
                                            fontSize: 13,
                                            color: locked
                                                ? AppColors.textMuted
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          r['subtitle'] as String,
                                          style: GoogleFonts.roboto(
                                            fontSize: 10,
                                            color: locked
                                                ? AppColors.textMuted
                                                : color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (locked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceAlt,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: Text(
                                        'Nv. $unlockLevel',
                                        style: GoogleFonts.roboto(
                                            fontSize: 10,
                                            color: AppColors.textMuted),
                                      ),
                                    )
                                  else
                                    Icon(Icons.chevron_right,
                                        color: color, size: 20),
                                ],
                              ),
                            ),
                          ),
                          // Descrição
                          if (!locked)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 10, 16, 12),
                              child: Text(
                                r['description'] as String,
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
