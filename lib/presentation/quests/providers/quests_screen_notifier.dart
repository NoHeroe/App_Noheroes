import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/events/daily_mission_events.dart';
import '../../../core/events/mission_events.dart';
import '../../../core/events/reward_events.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/daily_mission.dart';
import '../../../domain/models/extras_mission_spec.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/services/daily_mission_progress_service.dart';

/// Sprint 3.2 Etapa 1.3.A — state da `/quests` adaptado.
///
/// **Mudou em relação à 3.1 Bloco 14.6c:**
///   - `dailyMissions` (legacy `MissionProgress` da tab daily) **dropado
///     da UI** — o backend `MissionAssignmentService` continua existindo,
///     mas a tela não consome mais. Substituído pelas novas
///     `dailyMissionsNew` (Etapa 1.2).
///   - `processRollover` é executado ANTES de `getTodayMissions` no
///     `build()` — garante fechamento do dia anterior antes de exibir.
///   - Listeners adicionais: `DailyMissionProgressed`,
///     `DailyMissionCompleted`, `DailyMissionFailed` invalidam o
///     notifier pra auto-refresh.
class QuestsScreenState {
  /// Sprint 3.2 Etapa 1.2 — missões diárias dinâmicas (DailyMission).
  final List<DailyMission> dailyMissionsNew;

  final List<MissionProgress> classMissions;
  final List<MissionProgress> factionMissions;
  final List<MissionProgress> admissionMissions;
  final List<MissionProgress> individualMissions;
  final List<ExtrasMissionSpec> extrasCatalog;

  const QuestsScreenState({
    this.dailyMissionsNew = const [],
    this.classMissions = const [],
    this.factionMissions = const [],
    this.admissionMissions = const [],
    this.individualMissions = const [],
    this.extrasCatalog = const [],
  });

  int get totalCount =>
      dailyMissionsNew.length +
      classMissions.length +
      factionMissions.length +
      admissionMissions.length +
      individualMissions.length;

  int get doneCount {
    int c = 0;
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

  /// Sub-tarefas das diárias concluídas hoje (cross-missions). Usado
  /// pelo `DailyQuestsHeader` na barra geral.
  int get dailySubTasksDone {
    int c = 0;
    for (final m in dailyMissionsNew) {
      for (final s in m.subTarefas) {
        if (s.completed) c++;
      }
    }
    return c;
  }

  /// Total de sub-tarefas das diárias hoje (3 × 3 = 9 quando rolou geração).
  int get dailySubTasksTotal {
    int c = 0;
    for (final m in dailyMissionsNew) {
      c += m.subTarefas.length;
    }
    return c;
  }

  QuestsScreenState copyWith({
    List<DailyMission>? dailyMissionsNew,
    List<MissionProgress>? classMissions,
    List<MissionProgress>? factionMissions,
    List<MissionProgress>? admissionMissions,
    List<MissionProgress>? individualMissions,
    List<ExtrasMissionSpec>? extrasCatalog,
  }) {
    return QuestsScreenState(
      dailyMissionsNew: dailyMissionsNew ?? this.dailyMissionsNew,
      classMissions: classMissions ?? this.classMissions,
      factionMissions: factionMissions ?? this.factionMissions,
      admissionMissions: admissionMissions ?? this.admissionMissions,
      individualMissions: individualMissions ?? this.individualMissions,
      extrasCatalog: extrasCatalog ?? this.extrasCatalog,
    );
  }
}

class QuestsScreenNotifier
    extends AutoDisposeFamilyAsyncNotifier<QuestsScreenState, int> {
  @override
  Future<QuestsScreenState> build(int playerId) async {
    final bus = ref.read(appEventBusProvider);
    final repo = ref.read(missionRepositoryProvider);
    final extrasService = ref.read(extrasCatalogServiceProvider);
    final dailyGenerator = ref.read(dailyMissionGeneratorServiceProvider);
    final dailyRollover = ref.read(dailyMissionRolloverServiceProvider);

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

    // Sprint 3.2 Etapa 1.3.A — listeners das missões diárias novas.
    final subDailyProgressed = bus
        .on<DailyMissionProgressed>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    final subDailyCompleted = bus
        .on<DailyMissionCompleted>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    final subDailyFailed = bus
        .on<DailyMissionFailed>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());

    ref.onDispose(() {
      subCompleted.cancel();
      subFailed.cancel();
      subReward.cancel();
      subIndividualCreated.cancel();
      subDailyProgressed.cancel();
      subDailyCompleted.cancel();
      subDailyFailed.cancel();
    });

    // Etapa 1.2 — fecha dia anterior ANTES de gerar/exibir hoje.
    // Sequencial pra garantir streak/rewards aplicados antes do query.
    await dailyRollover.processRollover(playerId);
    final dailyToday =
        await dailyGenerator.getTodayMissions(playerId);

    // Sprint 3.4 Etapa C hotfix #3 (P0-F) — re-avalia admissões antes
    // de listar pra UI. Expiração de janela é passiva (não emite
    // evento), então sem trigger explícito ao carregar /quests,
    // missão com janela expirada ficava zumbi (UI mostrava
    // "expirada" calculando do metaJson, mas state persistente
    // continuava active). `evaluatePlayer` roda `_processMission`
    // em todas as admissões ativas — handler do hotfix #1 detecta
    // expiração + re-avalia sub-tasks com expired=true; rejeita
    // se alguma falhou ou completa se todas achieved no fechamento.
    await ref
        .read(factionAdmissionProgressServiceProvider)
        .evaluatePlayer(playerId);

    final results = await Future.wait([
      repo.findByTab(playerId, MissionTabOrigin.classTab),
      repo.findByTab(playerId, MissionTabOrigin.faction),
      repo.findByTab(playerId, MissionTabOrigin.admission),
      repo.findByTab(playerId, MissionTabOrigin.extras),
      extrasService.loadAllForPlayer(playerId),
    ]);

    final extrasSpecs = (results[4] as List<ExtrasMissionSpec>)
        .where((e) => !e.isSecret)
        .toList(growable: false);

    final extrasTabMissions = results[3] as List<MissionProgress>;
    final individuals = extrasTabMissions
        .where((m) => m.modality == MissionModality.individual)
        .toList(growable: false);

    // Sprint 3.4 Sub-Etapa B.2 hotfix #2 — filtra missões de admissão
    // já encerradas (completed ou failed). Player vê apenas o que
    // ainda está em progresso ou cadeado. Quando admissão completa
    // de fato, aba some (vazia) — bom feedback. Histórico curto
    // ("completed há < 24h" como feedback positivo) é dívida D10.
    final admissionActive = (results[2] as List<MissionProgress>)
        .where((m) => m.completedAt == null && m.failedAt == null)
        .toList(growable: false);

    return QuestsScreenState(
      dailyMissionsNew: dailyToday,
      classMissions: results[0] as List<MissionProgress>,
      factionMissions: results[1] as List<MissionProgress>,
      admissionMissions: admissionActive,
      individualMissions: individuals,
      extrasCatalog: extrasSpecs,
    );
  }

  /// Pull-to-refresh.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Sprint 3.2 Etapa 1.3.A — encaminha incremento pro
  /// `DailyMissionProgressService`. Service emite eventos que
  /// auto-disparam `invalidateSelf` via listener.
  Future<void> incrementDailySubTask({
    required int missionId,
    required String subTaskKey,
    required int delta,
  }) async {
    await ref.read(dailyMissionProgressServiceProvider).incrementSubTask(
          missionId: missionId,
          subTaskKey: subTaskKey,
          delta: delta,
        );
  }

  /// Hotfix Etapa 1.3.A — encaminha confirmação manual (clique ✓).
  /// Service decide status final (completed/partial/failed) e dispara
  /// reward + evento. Idempotência: se já fechada, captura
  /// [RewardAlreadyGrantedException] silenciosamente.
  Future<void> confirmDailyMission({required int missionId}) async {
    try {
      await ref
          .read(dailyMissionProgressServiceProvider)
          .confirmCompletion(missionId: missionId);
    } on RewardAlreadyGrantedException {
      // Double-tap — segue pra sync mesmo assim.
    }
    // Etapa 1.3.C hotfix-5 — confirmCompletion grava XP/gold no banco mas
    // currentPlayerProvider é StateProvider manual. Refetch + set garante
    // que /quests header counter, /santuario topBar e /perfil reflitam o
    // novo saldo. Padrão idêntico ao usado em profile_screen e dev_panel.
    final db = ref.read(appDatabaseProvider);
    final fresh = await (db.select(db.playersTable)
          ..where((t) => t.id.equals(arg)))
        .getSingleOrNull();
    if (fresh != null) {
      ref.read(currentPlayerProvider.notifier).state = fresh;
    }
  }
}

final questsScreenNotifierProvider = AutoDisposeAsyncNotifierProviderFamily<
    QuestsScreenNotifier, QuestsScreenState, int>(
  QuestsScreenNotifier.new,
);
