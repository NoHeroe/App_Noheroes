import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';

class CaelumDayBanner extends ConsumerWidget {
  const CaelumDayBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item('DIA EM CAELUM', '${player?.caelumDay ?? 1}'),
          _divider(),
          _item('NÍVEL', '${player?.level ?? 1}'),
          _divider(),
          _item('SOMBRA', 'Estável', valueColor: AppColors.shadowStable),
        ],
      ),
    );
  }

  Widget _item(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 9, color: AppColors.textMuted, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: valueColor ?? AppColors.gold,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.border);
}
