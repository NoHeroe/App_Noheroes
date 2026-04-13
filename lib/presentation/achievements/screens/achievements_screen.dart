import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/achievement_dao.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(achievementsProvider);
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('CONQUISTAS',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 16,
                          color: AppColors.gold,
                          letterSpacing: 2)),
                  const Spacer(),
                  allAsync.when(
                    data: (all) => unlockedAsync.when(
                      data: (u) => Text('${u.length}/${all.length}',
                          style: GoogleFonts.roboto(
                              fontSize: 12, color: AppColors.textMuted)),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),

            // Lista
            Expanded(
              child: allAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.purple)),
                error: (e, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.hp, size: 40),
                        const SizedBox(height: 12),
                        Text('Erro ao carregar conquistas:',
                            style: GoogleFonts.roboto(
                                color: AppColors.textMuted,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(e.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                                color: AppColors.hp, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                data: (all) => unlockedAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.purple)),
                  error: (e, _) => Center(
                    child: Text('Erro: $e',
                        style: GoogleFonts.roboto(
                            color: AppColors.hp, fontSize: 12)),
                  ),
                  data: (unlocked) {
                    final unlockedKeys =
                        unlocked.map((u) => u.achievementKey).toSet();

                    if (all.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events_outlined,
                                color: AppColors.textMuted.withValues(alpha: 0.3),
                                size: 48),
                            const SizedBox(height: 12),
                            Text('Nenhuma conquista encontrada.',
                                style: GoogleFonts.roboto(
                                    color: AppColors.textMuted,
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            Text('O banco pode precisar ser reiniciado.',
                                style: GoogleFonts.roboto(
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.6),
                                    fontSize: 11)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: all.length,
                      itemBuilder: (_, i) {
                        final a = all[i];
                        final done = unlockedKeys.contains(a.key);
                        if (a.isSecret && !done) return _SecretCard();
                        return _AchievementCard(
                            achievement: a, unlocked: done);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementsTableData achievement;
  final bool unlocked;

  const _AchievementCard(
      {required this.achievement, required this.unlocked});

  Color get _catColor => switch (achievement.category) {
        'progression' => AppColors.xp,
        'habits'      => AppColors.shadowStable,
        'shadow'      => AppColors.shadowChaotic,
        'exploration' => AppColors.gold,
        'social'      => AppColors.mp,
        _             => AppColors.purple,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? _catColor.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? _catColor.withValues(alpha: 0.15)
                  : AppColors.surfaceAlt,
              border: Border.all(
                color: unlocked
                    ? _catColor.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Icon(
              unlocked
                  ? Icons.emoji_events
                  : Icons.emoji_events_outlined,
              color: unlocked ? _catColor : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 13,
                        color: unlocked
                            ? AppColors.textPrimary
                            : AppColors.textMuted)),
                const SizedBox(height: 3),
                Text(achievement.description,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
                if (unlocked) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('+${achievement.xpReward} XP',
                        style: GoogleFonts.roboto(
                            fontSize: 10, color: AppColors.xp)),
                    const SizedBox(width: 8),
                    Text('+${achievement.goldReward} 🪙',
                        style: GoogleFonts.roboto(
                            fontSize: 10, color: AppColors.gold)),
                    if (achievement.gemReward > 0) ...[
                      const SizedBox(width: 8),
                      Text('+${achievement.gemReward} 💎',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: AppColors.mp)),
                    ],
                  ]),
                ],
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle,
                color: AppColors.shadowAscending, size: 20),
        ],
      ),
    );
  }
}

class _SecretCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.lock_outline,
                color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conquista Secreta',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 3),
              Text('Continue sua jornada para revelar.',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
