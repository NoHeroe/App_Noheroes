import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/datasources/local/guild_ascension_service.dart';
import '../../shared/widgets/milestone_popup.dart';
import '../../shared/widgets/reward_toast.dart';

final ascensionServiceProvider = Provider<GuildAscensionService>((ref) {
  return GuildAscensionService(ref.read(appDatabaseProvider));
});

final ascensionMissionsProvider =
    FutureProvider.autoDispose<List<GuildAscensionTableData>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  final rank = player.guildRank;
  if (rank == 's' || rank == 'none') return [];
  final service = ref.read(ascensionServiceProvider);
  await service.initCycle(player.id, rank);
  return service.getMissions(player.id, rank);
});

class AscensionTab extends ConsumerWidget {
  const AscensionTab({super.key});

  static const _rankLabels = {
    'e': 'E', 'd': 'D', 'c': 'C', 'b': 'B', 'a': 'A', 's': 'S',
  };
  static const _rankColors = {
    'e': AppColors.textMuted,
    'd': Color(0xFF4FA06B),
    'c': Color(0xFF3070B3),
    'b': Color(0xFF8B3DFF),
    'a': Color(0xFFFF8C00),
    's': Color(0xFFFFD700),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final missionsAsync = ref.watch(ascensionMissionsProvider);
    final rank = player?.guildRank ?? 'none';

    if (rank == 'none') {
      return Center(
        child: Text('Entre na Guilda primeiro.',
            style: GoogleFonts.roboto(color: AppColors.textMuted)),
      );
    }

    if (rank == 's') {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 48),
          const SizedBox(height: 12),
          Text('Rank S — Lenda de Caelum',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 14, color: Color(0xFFFFD700))),
          const SizedBox(height: 8),
          Text('Você chegou ao topo.',
              style: GoogleFonts.roboto(color: AppColors.textMuted)),
        ]),
      );
    }

    return missionsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(
          child: Text('Erro: $e',
              style: const TextStyle(color: AppColors.textMuted))),
      data: (missions) {
        if (missions.isEmpty) {
          return Center(
            child: Text('Nenhuma missão de ascensão disponível.',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          );
        }

        final nextRank = missions.first.rankTo;
        final rankColor = _rankColors[rank] ?? AppColors.textMuted;
        final nextColor = _rankColors[nextRank] ?? AppColors.gold;

        // Verifica se todas completadas
        final allDone = missions.every((m) => m.completed);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // Header do ciclo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nextColor.withValues(alpha: 0.4)),
                gradient: LinearGradient(colors: [
                  nextColor.withValues(alpha: 0.06),
                  AppColors.surface,
                ]),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(_rankLabels[rank] ?? rank.toUpperCase(),
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 20, color: rankColor)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: nextColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: nextColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(_rankLabels[nextRank] ?? nextRank.toUpperCase(),
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 20, color: nextColor)),
                ),
                const Spacer(),
                Text('${missions.where((m) => m.completed).length}/${missions.length}',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 14, color: nextColor)),
              ]),
            ),
            const SizedBox(height: 16),

            // Botão de ascender se todas completas
            if (allDone)
              GestureDetector(
                onTap: () => _ascend(context, ref, player!.id, rank),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: nextColor.withValues(alpha: 0.6), width: 1.5),
                    gradient: LinearGradient(colors: [
                      nextColor.withValues(alpha: 0.15),
                      nextColor.withValues(alpha: 0.05),
                    ]),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_circle_up, color: nextColor, size: 20),
                      const SizedBox(width: 8),
                      Text('ASCENDER PARA RANK ${_rankLabels[nextRank]}',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 11,
                              color: nextColor,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
              ),

            // Lista de missões
            ...missions.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              final isUnlocked =
                  (player?.level ?? 1) >= m.unlockLevel;
              final isPending = !m.completed &&
                  missions.take(idx).every((prev) => prev.completed);
              final isLocked = !isUnlocked ||
                  (!m.completed &&
                      missions.take(idx).any((prev) => !prev.completed));

              return _buildMissionCard(
                  context, m, isUnlocked, isPending, isLocked, nextColor);
            }),
          ],
        );
      },
    );
  }

  Widget _buildMissionCard(
    BuildContext context,
    GuildAscensionTableData m,
    bool isUnlocked,
    bool isPending,
    bool isLocked,
    Color accentColor,
  ) {
    final pct = m.progressTarget > 0
        ? (m.progress / m.progressTarget).clamp(0.0, 1.0)
        : 0.0;

    Color borderColor;
    if (m.completed) {
      borderColor = AppColors.shadowAscending.withValues(alpha: 0.5);
    } else if (isPending) {
      borderColor = accentColor.withValues(alpha: 0.6);
    } else {
      borderColor = AppColors.border;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked && !m.completed
            ? AppColors.surfaceAlt
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isLocked ? 1 : 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Step badge
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: m.completed
                    ? AppColors.shadowAscending.withValues(alpha: 0.15)
                    : isPending
                        ? accentColor.withValues(alpha: 0.15)
                        : AppColors.surfaceAlt,
                border: Border.all(
                    color: m.completed
                        ? AppColors.shadowAscending
                        : isPending
                            ? accentColor
                            : AppColors.border),
              ),
              child: Center(
                child: m.completed
                    ? const Icon(Icons.check,
                        color: AppColors.shadowAscending, size: 14)
                    : Text('${m.step}',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 11,
                            color: isPending
                                ? accentColor
                                : AppColors.textMuted)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isLocked && !m.completed
                  ? Row(children: [
                      const Icon(Icons.lock_outline,
                          color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Text('Nível ${m.unlockLevel}',
                          style: GoogleFonts.roboto(
                              fontSize: 12, color: AppColors.textMuted)),
                    ])
                  : Text(m.title,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: m.completed
                              ? AppColors.textMuted
                              : AppColors.textPrimary)),
            ),
            if (m.completed)
              const Icon(Icons.check_circle_outline,
                  color: AppColors.shadowAscending, size: 16),
          ]),

          // Conteúdo — só visível quando desbloqueado e é a missão atual
          if (!isLocked || m.completed) ...[
            const SizedBox(height: 8),
            Text(m.description,
                style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(m.completed
                    ? AppColors.shadowAscending
                    : accentColor),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${m.progress} / ${m.progressTarget}',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textMuted)),
                Row(children: [
                  Icon(Icons.auto_awesome, color: AppColors.xp, size: 11),
                  const SizedBox(width: 3),
                  Text('+${m.xpReward} XP',
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.xp)),
                  const SizedBox(width: 8),
                  Icon(Icons.monetization_on_outlined,
                      color: AppColors.gold, size: 11),
                  const SizedBox(width: 3),
                  Text('+${m.goldReward}',
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.gold)),
                ]),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _ascend(BuildContext context, WidgetRef ref,
      int playerId, String currentRank) async {
    final service = ref.read(ascensionServiceProvider);
    final newRank = await service.ascend(playerId, currentRank);
    if (newRank == null) return;

    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;
    ref.invalidate(ascensionMissionsProvider);

    if (context.mounted) {
      MilestonePopup.show(
        context,
        title: 'Rank ${newRank.toUpperCase()}',
        subtitle: 'Ascensão da Guilda',
        message: 'Seu Colar da Guilda evoluiu. Você agora é Rank ${newRank.toUpperCase()} — um dos poucos que chegaram aqui.',
        icon: Icons.arrow_circle_up,
        color: const Color(0xFFFFD700),
      );
    }
  }
}
