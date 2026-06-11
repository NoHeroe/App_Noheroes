import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Botão de voltar PADRÃO do app (telas não-in-game) — caixa arredondada com
/// gradiente escuro + borda/ícone dourados, no visual dos mercados/biblioteca.
class NhBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  const NhBackButton({super.key, required this.onTap, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF221A2E), Color(0xFF0B0910)],
          ),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.goldLt, size: 16),
      ),
    );
  }
}
