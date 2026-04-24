import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/events/mission_events.dart';
import '../../../core/events/reward_events.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/extras_mission_spec.dart';
import '../../../domain/models/mission_progress.dart';

/// Sprint 3.1 Bloco 14.6c — state da `/quests` após redesign (lista
/// única com 6 seções sanfona, sem chips de navegação).
///
/// Carrega **todos** os grupos em paralelo num único `build()`:
///   - `dailyMissions` — `findByTab(daily)`
///   - `classMissions` — `findByTab(class)`
///   - `factionMissions` — `findByTab(faction)`
///   - `admissionMissions` — `findByTab(admission)`
///   - `extrasCatalog` — `ExtrasCatalogService.loadAll` (gate TODO
///      documentado em `docs/sprint_missoes/DEBITO_EXTRAS_GATE.md`)
///   - `individualMissions` — `findByTab(extras)` filtrado por
///      `modality == individual` OU `findByTab(individual)` direto
///      (tab_origin separa no schema)
///
/// **Removido** do Bloco 10a.1 (pré-14.6c):
///   - `activeTab` + `setActiveTab` — não há mais chips
///   - `categoryFilters` + `toggleCategoryFilter` + `clearFilters`
///   - `historyFilter` + `last7DaysWindow` + `filteredHistory` — tudo
///     migrou pro `HistoryScreenNotifier` na rota `/history` dedicada
class QuestsScreenState {
  final List<MissionProgress> dailyMissions;
  final List<MissionProgress> classMissions;
  final List<MissionProgress> factionMissions;
  final List<MissionProgress> admissionMissions;
  final List<MissionProgress> individualMissions;
  final List<ExtrasMissionSpec> extrasCatalog;

  const QuestsScreenState({
    this.dailyMissions = const [],
    this.classMissions = const [],
    this.factionMissions = const [],
    this.admissionMissions = const [],
    this.individualMissions = const [],
    this.extrasCatalog = const [],
  });

  /// Total de missões (ativas + completadas + falhas) somado por grupo —
  /// consumido pelo `QuestsHeader` no `done/total`.
  int get totalCount =>
      dailyMissions.length +
      classMissions.length +
      factionMissions.length +
      admissionMissions.length +
      individualMissions.length;

  /// Subset com `completedAt != null` em todas as seções — jogador vê
  /// quantas missões ele fechou no ciclo atual.
  int get doneCount {
    int c = 0;
    for (final m in dailyMissions) {
      if (m.completedAt != null) c++;
    }
    for (final m in classMissions) {
      if (m.completedAt != null) c++;
    }
    for (final m in factionMissions) {
      if (m.completedAt != null) c++;
    }
    for (final m in admissionMissions) {
      if (m.completedAt != null) c++;
    }
    for (final m in individualMissions) {
      if (m.completedAt != null) c++;
    }
    return c;
  }

  QuestsScreenState copyWith({
    List<MissionProgress>? dailyMissions,
    List<MissionProgress>? classMissions,
    List<MissionProgress>? factionMissions,
    List<MissionProgress>? admissionMissions,
    List<MissionProgress>? individualMissions,
    List<ExtrasMissionSpec>? extrasCatalog,
  }) {
    return QuestsScreenState(
      dailyMissions: dailyMissions ?? this.dailyMissions,
      classMissions: classMissions ?? this.classMissions,
      factionMissions: factionMissions ?? this.factionMissions,
      admissionMissions: admissionMissions ?? this.admissionMissions,
      individualMissions: individualMissions ?? this.individualMissions,
      extrasCatalog: extrasCatalog ?? this.extrasCatalog,
    );
  }
}

/// Notifier da `/quests` — carrega todos os grupos em paralelo, assina
/// 4 tipos de evento no bus pra auto-refresh.
class QuestsScreenNotifier
    extends AutoDisposeFamilyAsyncNotifier<QuestsScreenState, int> {
  @override
  Future<QuestsScreenState> build(int playerId) async {
    final bus = ref.read(appEventBusProvider);
    final repo = ref.read(missionRepositoryProvider);
    final extrasService = ref.read(extrasCatalogServiceProvider);

    final subCompleted = bus
        .on<MissionCompleted>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    final subFailed = bus
        .on<MissionFailed>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    final subReward = bus
        .on<RewardGranted>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    final subIndividualCreated = bus
        .on<IndividualCreated>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    ref.onDispose(() {
      subCompleted.cancel();
      subFailed.cancel();
      subReward.cancel();
      subIndividualCreated.cancel();
    });

    final results = await Future.wait([
      repo.findByTab(playerId, MissionTabOrigin.daily),
      repo.findByTab(playerId, MissionTabOrigin.classTab),
      repo.findByTab(playerId, MissionTabOrigin.faction),
      repo.findByTab(playerId, MissionTabOrigin.admission),
      repo.findByTab(playerId, MissionTabOrigin.extras),
      // 14.5: carrega estáticas + awakening extra do jogador (SharedPreferences).
      extrasService.loadAllForPlayer(playerId),
    ]);

    final extrasSpecs = (results[5] as List<ExtrasMissionSpec>)
        .where((e) => !e.isSecret)
        .toList(growable: false);

    // Individuais ficam persistidas com `tab_origin=extras` (decisão
    // do Bloco 11a — individuais é sub-seção visual de Extras). No
    // layout 14.6c separamos em seção própria, então filtramos pela
    // modality.
    final extrasTabMissions = results[4] as List<MissionProgress>;
    final individuals = extrasTabMissions
        .where((m) => m.modality == MissionModality.individual)
        .toList(growable: false);

    return QuestsScreenState(
      dailyMissions: results[0] as List<MissionProgress>,
      classMissions: results[1] as List<MissionProgress>,
      factionMissions: results[2] as List<MissionProgress>,
      admissionMissions: results[3] as List<MissionProgress>,
      individualMissions: individuals,
      extrasCatalog: extrasSpecs,
    );
  }

  /// Força re-query (pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final questsScreenNotifierProvider = AutoDisposeAsyncNotifierProviderFamily<
    QuestsScreenNotifier, QuestsScreenState, int>(
  QuestsScreenNotifier.new,
);
