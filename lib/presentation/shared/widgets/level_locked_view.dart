import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

// Sprint 2.3 Bloco 0.B — view reusável de bloqueio por nível.
// Renderizada no lugar de conteúdos que exigem player.level >= requiredLevel
// (ex: Ferreiro de Aureum, Forja).
class LevelLockedView extends StatelessWidget {
  final int requiredLevel;
  final int currentLevel;
  final String featureName;
  final VoidCallback? onBack;

  const LevelLockedView({
    super.key,
    required this.requiredLevel,
    required this.currentLevel,
    required this.featureName,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: onBack ?? () => context.go('/sanctuary'),
                  ),
                  Text(featureName.toUpperCase(),
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 13,
                          color: AppColors.gold,
                          letterSpacing: 3)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textMuted.withValues(alpha: 0.08),
                          border: Border.all(
                              color: AppColors.textMuted.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: Icon(Icons.lock_outline,
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                            size: 44),
                      ),
                      const SizedBox(height: 20),
                      Text(featureName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text('Desbloqueado no nível $requiredLevel',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5)),
                      const SizedBox(height: 6),
                      Text('Você está no nível $currentLevel',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
