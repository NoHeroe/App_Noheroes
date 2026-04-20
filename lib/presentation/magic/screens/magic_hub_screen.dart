import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

// Placeholder da Fase 1 — estrutura de escolas de magia entra em sprint
// dedicada (Fase 2.x ou 3.x). Mana-users nível 25+ caem aqui.
class MagicHubScreen extends ConsumerWidget {
  const MagicHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.35),
                radius: 1.3,
                colors: [
                  Color(0xFF0E1A2E),
                  Color(0xFF050810),
                  AppColors.black,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: () => context.go('/sanctuary'),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'MAGIA',
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 15,
                              color: AppColors.mp,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.auto_awesome,
                    color: AppColors.mp.withValues(alpha: 0.5), size: 60),
                const SizedBox(height: 24),
                Text(
                  'SISTEMA DE MAGIA',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 14,
                    color: AppColors.mp,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    'Em desenvolvimento.\n\n'
                    'As escolas de magia serão entregues em sprint dedicada.',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: _BackButton(onTap: () => context.go('/sanctuary')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.mp.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.mp.withValues(alpha: 0.5), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'VOLTAR',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 12,
            color: AppColors.mp,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
