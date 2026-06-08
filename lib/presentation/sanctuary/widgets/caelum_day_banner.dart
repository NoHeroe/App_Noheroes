import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';

/// Restyle Santuário (mockup v3) — "DIA EM CAELUM" como faixa central
/// (day strip): linha dourada → label → número → linha dourada.
/// Dados reais (`caelumDay`) preservados.
class CaelumDayBanner extends ConsumerWidget {
  const CaelumDayBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final day = player?.caelumDay ?? 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Rule(toRight: true),
        const SizedBox(width: 12),
        Text(
          'DIA EM CAELUM',
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            letterSpacing: 2.5,
            color: AppColors.txtMut,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$day',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        const _Rule(toRight: false),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  /// `toRight: true` → transparent→goldDk (linha da esquerda).
  final bool toRight;
  const _Rule({required this.toRight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: toRight
              ? [Colors.transparent, AppColors.goldDk]
              : [AppColors.goldDk, Colors.transparent],
        ),
      ),
    );
  }
}
