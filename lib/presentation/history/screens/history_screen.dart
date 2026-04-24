import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_bg.dart';
import '../../../domain/models/mission_progress.dart';
import '../../quests/widgets/history_filter_chips.dart';
import '../../quests/widgets/history_mission_card.dart';
import '../../quests/widgets/mission_counters.dart';
import '../../quests/widgets/weekly_missions_chart.dart';
import '../providers/history_screen_notifier.dart';

/// Sprint 3.1 Bloco 14.6c — rota dedicada `/history` (saiu da aba
/// chip de `/quests` no redesign).
///
/// Layout:
///   - Header (seta voltar → /sanctuary + "HISTÓRICO" CinzelDecorative)
///   - `AnimatedBg` compartilhado (mesmo do login / quests)
///   - `WeeklyMissionsChart` + `MissionCounters` (reutilizados Bloco 12)
///   - `HistoryFilterChips` (reutilizado Bloco 12)
///   - Lista agrupada por data (HOJE / ONTEM / HÁ N DIAS) — pattern
///     v0.28.2 `history_screen.dart` linhas 143-151
///   - `HistoryMissionCard` por entrada (reutilizado Bloco 12)
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    if (player == null) {
      return const Scaffold(body: Center(child: Text('Sem jogador.')));
    }
    final asyncState =
        ref.watch(historyScreenNotifierProvider(player.id));
    final notifier =
        ref.read(historyScreenNotifierProvider(player.id).notifier);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBg(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: asyncState.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.purple)),
                    error: (e, _) => Center(
                      child: Text('Erro: $e',
                          style: const TextStyle(color: AppColors.hp)),
                    ),
                    data: (state) => _Body(
                      state: state,
                      onSelectFilter: notifier.setFilter,
                      onRefresh: notifier.refresh,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('history-back'),
            onTap: () => context.go('/sanctuary'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'HISTÓRICO',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.gold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final HistoryScreenState state;
  final ValueChanged<HistoryFilter> onSelectFilter;
  final Future<void> Function() onRefresh;

  const _Body({
    required this.state,
    required this.onSelectFilter,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = state.filtered;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey('history-list'),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: WeeklyMissionsChart(
                missionsLast7Days: state.last7DaysWindow),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MissionCounters(
              missionsLast7Days: state.last7DaysWindow,
              totalQuestsCompleted: state.totalQuestsCompleted,
            ),
          ),
          const SizedBox(height: 12),
          HistoryFilterChips(
            active: state.filter,
            onSelect: onSelectFilter,
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 40),
              child: Text(
                'Nada no histórico ainda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            ..._buildGroupedList(filtered),
        ],
      ),
    );
  }

  /// Agrupa por dia (HOJE / ONTEM / HÁ N DIAS) — pattern v0.28.2
  /// `history_screen.dart` linhas 90-115 + 143-151 adaptado pra
  /// `MissionProgress` (usa `coalesce(completedAt, failedAt)`).
  List<Widget> _buildGroupedList(List<MissionProgress> missions) {
    final grouped = <String, List<MissionProgress>>{};
    for (final m in missions) {
      final when = m.completedAt ?? m.failedAt;
      if (when == null) continue;
      final key = _dateLabel(when);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(
          entry.key,
          style: GoogleFonts.cinzelDecorative(
            fontSize: 10,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
      ));
      for (final m in entry.value) {
        widgets.add(HistoryMissionCard(mission: m));
      }
    }
    return widgets;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'HOJE';
    if (diff == 1) return 'ONTEM';
    return 'HÁ $diff DIAS';
  }
}
