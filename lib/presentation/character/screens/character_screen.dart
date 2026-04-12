import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text('PERSONAGEM',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                      const Spacer(),
                      Text('Nível ${player?.level ?? 1}',
                          style: GoogleFonts.roboto(
                              fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    child: Column(
                      children: [
                        // Avatar placeholder
                        _buildAvatar(player?.shadowName ?? 'Sombra'),
                        const SizedBox(height: 20),

                        // Info da classe
                        _buildClassCard(),
                        const SizedBox(height: 16),

                        // Atributos
                        _buildAttributesCard(player?.level ?? 1),
                        const SizedBox(height: 16),

                        // Stats de combate
                        _buildStatsCard(player),
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

  Widget _buildAvatar(String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: RadialGradient(
          colors: [
            AppColors.purple.withOpacity(0.1),
            AppColors.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.purple, width: 2),
              gradient: RadialGradient(colors: [
                AppColors.purple.withOpacity(0.3),
                AppColors.shadowVoid,
              ]),
            ),
            child: const Icon(Icons.blur_circular,
                color: AppColors.purple, size: 50),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 20, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Sombra Sem Forma',
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('SEM CLASSE · Rank E',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 10,
                    color: AppColors.gold,
                    letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLASSE',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple.withOpacity(0.1),
                  border: Border.all(
                      color: AppColors.purple.withOpacity(0.3)),
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.textMuted, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Classe não escolhida',
                        style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Desbloqueada no Nível 5',
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesCard(int level) {
    final attrs = [
      ('Força',       Icons.fitness_center,  AppColors.hp,           level),
      ('Destreza',    Icons.speed,            AppColors.shadowStable, level),
      ('Constituição',Icons.shield_outlined,  AppColors.mp,           level),
      ('Inteligência',Icons.psychology_outlined, AppColors.xp,        level),
      ('Espírito',    Icons.self_improvement, AppColors.gold,         level),
      ('Carisma',     Icons.people_outline,   AppColors.purple,       level),
    ];

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
          Text('ATRIBUTOS',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
          const SizedBox(height: 16),
          ...attrs.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(a.$2, color: a.$3, size: 16),
                const SizedBox(width: 10),
                SizedBox(width: 100,
                  child: Text(a.$1,
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textSecondary))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (a.$4 / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(a.$3),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${a.$4}',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatsCard(player) {
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
          Row(
            children: [
              _statItem('Nível', '${player?.level ?? 1}', AppColors.xp),
              _statItem('Ouro', '${player?.gold ?? 0}', AppColors.gold),
              _statItem('Streak', '${player?.streakDays ?? 0}d', AppColors.shadowStable),
              _statItem('Dia em Caelum', '${player?.caelumDay ?? 1}', AppColors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 18, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
