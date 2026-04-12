import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class ShadowChamberScreen extends ConsumerWidget {
  const ShadowChamberScreen({super.key});

  // Dados por estado
  static const _stateData = {
    'stable': (
      label: 'Estável',
      color: AppColors.shadowStable,
      phrase: 'Sua sombra observa em silêncio. O equilíbrio persiste.',
      corruption: 0,
    ),
    'unstable': (
      label: 'Instável',
      color: AppColors.shadowObsessive,
      phrase: 'Algo dentro de você está inquieto. Atenção.',
      corruption: 30,
    ),
    'chaotic': (
      label: 'Caótica',
      color: AppColors.shadowChaotic,
      phrase: 'A sombra se agita. Você está perdendo o controle.',
      corruption: 60,
    ),
    'abyssal': (
      label: 'Abissal',
      color: AppColors.hp,
      phrase: 'Você está à beira do abismo. Enfrente-a antes que seja tarde.',
      corruption: 90,
    ),
    'ascending': (
      label: 'Ascendente',
      color: AppColors.shadowAscending,
      phrase: 'Sua sombra recua. A luz emerge da disciplina.',
      corruption: 0,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final state = player?.shadowState ?? 'stable';
    final data = _stateData[state] ?? _stateData['stable']!;
    final corruption = player?.shadowCorruption ?? 0;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  data.color.withOpacity(0.08),
                  AppColors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text('CÂMARA DAS SOMBRAS',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          color: data.color,
                          letterSpacing: 2)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    child: Column(
                      children: [
                        _buildShadowAvatar(
                            player?.shadowName ?? 'Sombra', state, data.color),
                        const SizedBox(height: 16),
                        _buildStateCard(state, data.color, data.label,
                            data.phrase, corruption),
                        const SizedBox(height: 16),
                        _buildDisciplineCard(ref, player),
                        const SizedBox(height: 16),
                        _buildShadowInfo(state, data.color),
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

  Widget _buildShadowAvatar(String name, String state, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: RadialGradient(
            colors: [color.withOpacity(0.06), AppColors.surface]),
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
                  border: Border.all(color: color.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5)
                  ],
                ),
              ),
              Icon(Icons.blur_circular, color: color, size: 60),
              // Efeitos por estado
              if (state == 'chaotic' || state == 'abyssal')
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.hp),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Sombra de $name',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              _stateData[state]?.label.toUpperCase() ?? 'ESTÁVEL',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: color, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard(String state, Color color, String label,
      String phrase, int corruption) {
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
                  fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('"$phrase"',
              style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5)),
          const SizedBox(height: 16),

          // Barras de estado
          _stateBar('Corrupção', corruption, 100, AppColors.shadowChaotic),
          const SizedBox(height: 8),
          _stateBar('Estabilidade', 100 - corruption, 100, AppColors.shadowStable),
          const SizedBox(height: 8),
          _stateBar('Vitalismo', 0, 100, AppColors.gold),
        ],
      ),
    );
  }

  Widget _stateBar(String label, int value, int max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text('$value%',
                style: GoogleFonts.roboto(fontSize: 11, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / max).clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDisciplineCard(WidgetRef ref, player) {
    final habitsAsync = ref.watch(habitsProvider);
    final total = habitsAsync.value?.length ?? 0;
    final done = habitsAsync.value?.where((h) => h.isDone).length ?? 0;

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
              _metricItem('Streak', '${player?.streakDays ?? 0}',
                  'dias', AppColors.purple),
              _metricItem('Hoje', '$done/$total',
                  'rituais', AppColors.shadowStable),
              _metricItem('Dia', '${player?.caelumDay ?? 1}',
                  'em Caelum', AppColors.mp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(
      String label, String value, String unit, Color color) {
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

  Widget _buildShadowInfo(String state, Color color) {
    final tips = switch (state) {
      'stable'    => 'Continue mantendo seus rituais. A consistência é sua força.',
      'unstable'  => 'Você falhou em alguns rituais. Retome antes que piore.',
      'chaotic'   => 'Padrão de falhas detectado. A Shadow Quest pode emergir em breve.',
      'abyssal'   => 'Estado crítico. Complete rituais urgentemente para estabilizar.',
      'ascending' => 'Você superou um estado sombrio. Aproveite os bônus de ascensão.',
      _           => 'Mantenha seus rituais diários.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tips,
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}
