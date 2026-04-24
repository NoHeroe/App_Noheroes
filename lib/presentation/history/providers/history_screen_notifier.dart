import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/events/mission_events.dart';
import '../../../domain/models/mission_progress.dart';
import '../../quests/widgets/history_filter_chips.dart';

/// Sprint 3.1 Bloco 14.6c — state da `/history` agora como rota
/// dedicada (saiu da aba chip de `/quests`).
///
/// Carrega em paralelo:
///   - `findHistorical(playerId)` — todas as missões não-ativas
///   - `findCompletedInWindow(from: now-7d, to: now)` — janela pro
///     chart + counters
///
/// Filtro `HistoryFilter` aplicado client-side sobre `allHistory`
/// via `filtered`. O `totalQuestsCompleted` vem do `players` — lê
/// do `currentPlayerProvider` (já é `PlayersTableData`).
class HistoryScreenState {
  final List<MissionProgress> allHistory;
  final List<MissionProgress> last7DaysWindow;
  final HistoryFilter filter;
  final int totalQuestsCompleted;

  const HistoryScreenState({
    required this.allHistory,
    required this.last7DaysWindow,
    required this.filter,
    required this.totalQuestsCompleted,
  });

  List<MissionProgress> get filtered {
    switch (filter) {
      case HistoryFilter.todas:
        return allHistory;
      case HistoryFilter.concluidas:
        return allHistory
            .where((m) => m.completedAt != null)
            .toList(growable: false);
      case HistoryFilter.falhadas:
        return allHistory
            .where((m) => m.failedAt != null)
            .toList(growable: false);
    }
  }

  HistoryScreenState copyWith({
    List<MissionProgress>? allHistory,
    List<MissionProgress>? last7DaysWindow,
    HistoryFilter? filter,
    int? totalQuestsCompleted,
  }) {
    return HistoryScreenState(
      allHistory: allHistory ?? this.allHistory,
      last7DaysWindow: last7DaysWindow ?? this.last7DaysWindow,
      filter: filter ?? this.filter,
      totalQuestsCompleted:
          totalQuestsCompleted ?? this.totalQuestsCompleted,
    );
  }
}

class HistoryScreenNotifier
    extends AutoDisposeFamilyAsyncNotifier<HistoryScreenState, int> {
  @override
  Future<HistoryScreenState> build(int playerId) async {
    final bus = ref.read(appEventBusProvider);
    final repo = ref.read(missionRepositoryProvider);

    final prev = state.valueOrNull;
    final filter = prev?.filter ?? HistoryFilter.todas;

    final subCompleted = bus
        .on<MissionCompleted>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    final subFailed = bus
        .on<MissionFailed>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    ref.onDispose(() {
      subCompleted.cancel();
      subFailed.cancel();
    });

    final now = DateTime.now();
    final results = await Future.wait([
      repo.findHistorical(playerId),
      repo.findCompletedInWindow(
        playerId,
        from: now.subtract(const Duration(days: 7)),
        to: now,
      ),
    ]);

    final player = ref.read(currentPlayerProvider);
    return HistoryScreenState(
      allHistory: results[0],
      last7DaysWindow: results[1],
      filter: filter,
      totalQuestsCompleted: player?.totalQuestsCompleted ?? 0,
    );
  }

  /// Muda filtro client-side, zero re-query.
  void setFilter(HistoryFilter f) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.filter == f) return;
    state = AsyncValue.data(current.copyWith(filter: f));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final historyScreenNotifierProvider = AutoDisposeAsyncNotifierProviderFamily<
    HistoryScreenNotifier, HistoryScreenState, int>(
  HistoryScreenNotifier.new,
);
