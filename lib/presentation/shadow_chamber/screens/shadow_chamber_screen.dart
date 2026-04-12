import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class ShadowChamberScreen extends ConsumerWidget {
  const ShadowChamberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Atmosfera sombria
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, 0.0),
                radius: 1.0,
                colors: [Color(0xFF1A0520), AppColors.black],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text('CÂMARA DAS SOMBRAS',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 14,
                              color: AppColors.shadowStable,
                              letterSpacing: 2)),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    child: Column(
                      children: [
                        // Avatar sombrio
                        _buildShadowAvatar(player?.shadowName ?? 'Sombra'),
                        const SizedBox(height: 20),

                        // Estado atual
                        _buildStateCard(),
                        const SizedBox(height: 16),

                        // Métricas de disciplina
                        _buildDisciplineCard(),
                        const SizedBox(height: 16),

                        // Aviso de Shadow Quest
                        _buildShadowAlert(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Align(
            alignment: Alignment.bottomCenter,
            child: NhBottomNav(currentIndex: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowAvatar(String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shadowStable.withOpacity(0.3)),
        gradient: RadialGradient(colors: [
          AppColors.shadowVoid.withOpacity(0.8),
          AppColors.surface,
        ]),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.shadowVoid,
                  border: Border.all(
                      color: AppColors.shadowStable.withOpacity(0.6),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowStable.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.blur_circular,
                  color: AppColors.shadowStable, size: 60),
            ],
          ),
          const SizedBox(height: 12),
          Text('Sombra de $name',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('"Sua sombra observa em silêncio."',
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.shadowStable.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.shadowStable.withOpacity(0.4)),
            ),
            child: Text('ESTÁVEL',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 11,
                    color: AppColors.shadowStable,
                    letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard() {
    final states = [
      ('Corrupção', 0, AppColors.shadowChaotic),
      ('Estabilidade', 100, AppColors.shadowStable),
      ('Vitalismo', 0, AppColors.gold),
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
          Text('ESTADO DA SOMBRA',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11,
                  color: AppColors.gold,
                  letterSpacing: 2)),
          const SizedBox(height: 16),
          ...states.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.$1,
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    Text('${s.$2}%',
                        style: GoogleFonts.roboto(
                            fontSize: 12, color: s.$3)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.$2 / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(s.$3),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDisciplineCard() {
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
          Text('DISCIPLINA',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricItem('Streak', '0', 'dias', AppColors.purple),
              _metricItem('Hoje', '0/0', 'rituais', AppColors.shadowStable),
              _metricItem('Semana', '0%', 'conclusão', AppColors.mp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 22, color: color, fontWeight: FontWeight.bold)),
        Text(unit,
            style: GoogleFonts.roboto(
                fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildShadowAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.shadowStable.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.shadowStable.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.shadowStable, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sua sombra está estável. Continue mantendo seus rituais diários para evitar instabilidade.',
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
