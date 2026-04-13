import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class BattleHubScreen extends StatelessWidget {
  const BattleHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Atmosfera
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [Color(0xFF1A0020), Color(0xFF0A000A), AppColors.black],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/sanctuary'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.surface,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.textSecondary, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CAMPO DE BATALHA',
                                style: GoogleFonts.cinzelDecorative(
                                    fontSize: 14,
                                    color: AppColors.hp,
                                    letterSpacing: 2)),
                            Text('Escolha seu modo de combate',
                                style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Aviso em breve
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.construction, color: AppColors.gold, size: 14),
                      const SizedBox(width: 8),
                      Text('Sistema de combate em desenvolvimento',
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.gold,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),

                // Modos
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // PvE
                      _sectionLabel('PvE — SOLO & GRUPO'),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: 'DUNGEONS',
                        subtitle: '1 a 5 jogadores',
                        description: 'Enfrente criaturas de Caelum em masmorras procedurais. Cada run é única.',
                        icon: Icons.castle_outlined,
                        color: AppColors.purple,
                        difficulty: 'Variável',
                        tag: 'PvE',
                      ),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: 'RAIDS',
                        subtitle: '1 a 5 jogadores',
                        description: 'Batalhas épicas contra bosses de Caelum. Recompensas lendárias.',
                        icon: Icons.local_fire_department_outlined,
                        color: AppColors.hp,
                        difficulty: 'Alta',
                        tag: 'PvE',
                      ),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: 'TOWERS',
                        subtitle: 'Solo — Infinito',
                        description: 'Suba andares de uma torre dimensional. Quanto mais alto, mais poderoso o inimigo.',
                        icon: Icons.stacked_bar_chart,
                        color: AppColors.mp,
                        difficulty: 'Crescente',
                        tag: 'PvE',
                      ),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: 'SHADOW BOSS',
                        subtitle: 'Solo — Pessoal',
                        description: 'Enfrente a manifestação da sua própria sombra. O maior inimigo é você mesmo.',
                        icon: Icons.blur_circular,
                        color: AppColors.shadowChaotic,
                        difficulty: 'Extrema',
                        tag: 'SOMBRA',
                        isHighlight: true,
                      ),

                      const SizedBox(height: 20),

                      // PvP
                      _sectionLabel('PvP — CONFRONTO'),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: '1v1 ARENA',
                        subtitle: 'Duelo direto',
                        description: 'Confronto de build, habilidade e estratégia. Sem equipe para salvar você.',
                        icon: Icons.sports_martial_arts,
                        color: AppColors.gold,
                        difficulty: 'Alta',
                        tag: 'PvP',
                      ),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: '2v2 ARENA',
                        subtitle: 'Dupla coordenada',
                        description: 'Coordene com um aliado para derrotar a dupla adversária.',
                        icon: Icons.group_outlined,
                        color: AppColors.gold,
                        difficulty: 'Alta',
                        tag: 'PvP',
                      ),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: '5v5 ARENA',
                        subtitle: 'Batalha em time',
                        description: 'O modo mais estratégico. Composição, sinergia e execução definem o vencedor.',
                        icon: Icons.groups_outlined,
                        color: AppColors.gold,
                        difficulty: 'Muito Alta',
                        tag: 'PvP',
                      ),

                      const SizedBox(height: 20),

                      // Fendas
                      _sectionLabel('FENDAS DIMENSIONAIS'),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: 'FENDA DO VAZIO',
                        subtitle: 'Evento — Temporário',
                        description: 'Fendas que abrem espontaneamente em Caelum. Entrar tem risco real. Loot exclusivo.',
                        icon: Icons.blur_on,
                        color: AppColors.shadowVoid,
                        difficulty: 'Imprevisível',
                        tag: 'EVENTO',
                      ),
                      const SizedBox(height: 10),
                      _ModeCard(
                        title: 'FENDA DE CHRYSALIS',
                        subtitle: 'Evento — Raro',
                        description: 'Fendas biológicas. Mutantes e corrupções N1–N6. Fonte de seiva pura.',
                        icon: Icons.coronavirus_outlined,
                        color: AppColors.shadowAscending,
                        difficulty: 'Extrema',
                        tag: 'EVENTO',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(label,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 10,
                color: AppColors.textMuted,
                letterSpacing: 2)),
      );
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String difficulty;
  final String tag;
  final bool isHighlight;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.tag,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight ? color.withValues(alpha: 0.6) : AppColors.border,
          width: isHighlight ? 1.5 : 1,
        ),
        gradient: isHighlight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.1),
                  AppColors.surface,
                ],
              )
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),

                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: GoogleFonts.cinzelDecorative(
                                  fontSize: 13, color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.4)),
                            ),
                            child: Text(tag,
                                style: GoogleFonts.roboto(
                                    fontSize: 8,
                                    color: color,
                                    letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: color)),
                      const SizedBox(height: 6),
                      Text(description,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.flash_on,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('Dificuldade: $difficulty',
                              style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selo EM BREVE
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('EM BREVE',
                  style: GoogleFonts.roboto(
                      fontSize: 9,
                      color: AppColors.textMuted,
                      letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
