import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/asset_loader.dart';

class ShadowStatusCard extends ConsumerWidget {
  const ShadowStatusCard({super.key});

  static Color _colorFor(String state) => switch (state) {
    'unstable'  => AppColors.shadowObsessive,
    'chaotic'   => AppColors.shadowChaotic,
    'abyssal'   => AppColors.hp,
    'ascending' => AppColors.shadowAscending,
    _           => AppColors.shadowStable,
  };

  static String _labelFor(String state) => switch (state) {
    'unstable'  => 'Instável',
    'chaotic'   => 'Caótica',
    'abyssal'   => 'Abissal',
    'ascending' => 'Ascendente',
    _           => 'Estável',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final state  = player?.shadowState ?? 'stable';
    final color  = _colorFor(state);
    final label  = _labelFor(state);

    return FutureBuilder<String>(
      future: AssetLoader.getShadowPhrase(state),
      initialData: '...',
      builder: (context, snapshot) {
        final phrase = snapshot.data ?? '...';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                AppColors.surface,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.6), width: 1.5),
                  gradient: RadialGradient(
                    colors: [color.withOpacity(0.4), AppColors.shadowVoid],
                  ),
                ),
                child: Icon(Icons.blur_circular, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SUA SOMBRA',
                        style: GoogleFonts.roboto(
                            fontSize: 9,
                            color: AppColors.textMuted,
                            letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(label,
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 16, color: color)),
                    const SizedBox(height: 6),
                    Text(phrase,
                        style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
