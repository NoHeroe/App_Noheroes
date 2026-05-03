import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/events/app_event.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/daily_mission_events.dart';
import '../../../core/events/diary_events.dart';
import '../../../core/events/faction_events.dart';
import '../../../core/events/mission_events.dart';
import '../../../core/events/reward_events.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/repositories/mission_repository.dart';
import '../../../domain/repositories/player_faction_reputation_repository.dart';
import '../../../domain/services/faction_admission_sub_task_types.dart';
import '../../../domain/services/faction_admission_validator.dart';
import '../../../domain/services/faction_reputation_service.dart';
import '../../database/app_database.dart';

/// Sprint 3.4 Sub-Etapa B.2 — listener que re-avalia sub-tasks de
/// admissão eliminatória ao receber eventos terminais. Single point
/// of truth pro lifecycle: progresso, sequenciamento (missão N+1
/// desbloqueada quando N completar), reset em falha.
///
/// ## Eventos consumidos
///
/// | Evento | Sub-types afetados |
/// |---|---|
/// | `DailyMissionCompleted` | daily_count_window, full_perfect_day, no_partial_day, exact_daily_count, zero_failed (status=failed), zero_category (modalidade alvo) |
/// | `MissionCompleted` (modality=individual) | individual_completed_window |
/// | `DiaryEntryCreated` | diary_entry_window |
/// | `RewardGranted` | gold_earned_via_quests_window, gold_balance_threshold |
///
/// Re-avaliação é via `FactionAdmissionValidator.evaluate` — service
/// puro stateless. Esta camada **persiste** o resultado em metaJson da
/// MissionProgress (via re-encode JSON).
///
/// ## Fluxo
///
/// 1. Evento terminal chega.
/// 2. Lê todas as MissionProgress com `tabOrigin=admission` ativas
///    (status pending E `is_unlocked=true` em metaJson) do player.
///    Ignora missões com factionId='guild' (defesa em profundidade).
/// 3. Pra cada missão, pra cada sub-task ainda incompleta:
///    a. Verifica se a janela expirou — se sim, dispara
///       `FactionAdmissionRejected` reason=window_expired.
///    b. Re-avalia via validator. Se `achieved` → marca `completed=true`
///       em metaJson. Se `failed` (irrecuperável) → dispara
///       `FactionAdmissionRejected` reason=sub_task_failed:<sub_type>
///       ou `exact_count_overshoot:<missionId>`.
/// 4. Se TODAS as sub-tasks da missão estão `completed=true` → marca
///    missão como completed (via `MissionRepository.markCompleted`),
///    dispara `FactionAdmissionQuestCompleted`. Promove próxima missão
///    da sequência (atualiza `is_unlocked=true` + `window_start_ms=now`
///    + recaptura snapshot_rank).
/// 5. Se a missão completada era a última, dispara
///    `FactionAdmissionApproved` → cascateia `FactionJoined`.
///
/// ## Reset em falha
///
/// Handler de `FactionAdmissionRejected` (cascata interna):
/// - Marca todas as missões da admissão (factionId+playerId,
///   tabOrigin=admission, status=pending) como failed.
/// - Aplica -10 reputação na facção via `FactionReputationService`.
/// - Set `lockedUntil = now + 48h` em `player_faction_membership`.
/// - Reverte `players.faction_type` pra 'none'.
class FactionAdmissionProgressService {
  final AppDatabase _db;
  final AppEventBus _bus;
  final FactionAdmissionValidator _validator;
  final MissionRepository _missionRepo;
  final FactionReputationService _factionRep;
  final PlayerFactionReputationRepository _factionRepo;

  final List<StreamSubscription> _subs = [];

  FactionAdmissionProgressService({
    required AppDatabase db,
    required AppEventBus bus,
    required FactionAdmissionValidator validator,
    required MissionRepository missionRepo,
    required FactionReputationService factionRep,
    required PlayerFactionReputationRepository factionRepo,
  })  : _db = db,
        _bus = bus,
        _validator = validator,
        _missionRepo = missionRepo,
        _factionRep = factionRep,
        _factionRepo = factionRepo;

  /// Lock de 48h após reprovação (cooldown anti re-tentativa imediata).
  static const Duration _rejectLock = Duration(hours: 48);

  /// Penalidade de reputação por reprovação.
  static const int _rejectRepDelta = -10;

  void start() {
    _subs.add(_bus.on<DailyMissionCompleted>().listen(_onAnyEvent));
    _subs.add(_bus.on<MissionCompleted>().listen(_onAnyEvent));
    _subs.add(_bus.on<DiaryEntryCreated>().listen(_onAnyEvent));
    _subs.add(_bus.on<RewardGranted>().listen(_onAnyEvent));
    _subs.add(
        _bus.on<FactionAdmissionRejected>().listen(_handleRejection));
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// Handler unificado pra qualquer evento terminal — re-avalia todas
  /// as missões ativas do player. Pattern simples; performance OK pra
  /// MVP (max 2-5 missões × 1-3 sub-tasks ativas por player).
  Future<void> _onAnyEvent(AppEvent evt) async {
    // AppEvent.playerId é nullable na base abstract; subtypes
    // concretos override pra non-null. Defensivo guard.
    final playerId = evt.playerId;
    if (playerId == null) return;
    try {
      await _evaluatePlayer(playerId);
    } catch (e, st) {
      // ignore: avoid_print
      print('[admission-progress] _evaluatePlayer falhou: $e\n$st');
    }
  }

  Future<void> _evaluatePlayer(int playerId) async {
    final all =
        await _missionRepo.findByTab(playerId, MissionTabOrigin.admission);
    final active = all.where((m) =>
        m.completedAt == null && m.failedAt == null);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final mission in active) {
      Map<String, dynamic> meta;
      try {
        meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      // Defesa em profundidade — Guilda não tem admissão eliminatória.
      if (meta['faction_id'] == 'guild') continue;
      // Só avalia se a missão está desbloqueada.
      if (meta['is_unlocked'] != true) continue;

      final factionId = meta['faction_id'] as String?;
      if (factionId == null) continue;

      // Janela expirada?
      final windowStartMs = (meta['window_start_ms'] as int?) ?? 0;
      final windowDurationMs =
          (meta['window_duration_ms'] as int?) ?? (48 * 60 * 60 * 1000);
      if (windowStartMs > 0 &&
          nowMs > windowStartMs + windowDurationMs) {
        await _rejectAdmission(
          playerId: playerId,
          factionId: factionId,
          missionId: meta['mission_id'] as String? ?? mission.missionKey,
          reason:
              'window_expired:${meta['mission_id'] ?? mission.missionKey}',
        );
        return; // sai — admissão inteira foi resetada
      }

      // Re-avalia sub-tasks.
      final rawSubs = (meta['sub_tasks'] as List?) ?? const [];
      final subs = <Map<String, dynamic>>[];
      var anyChanged = false;
      var allCompleted = true;

      for (final raw in rawSubs) {
        final m = (raw as Map).cast<String, dynamic>();
        if (m['completed'] == true) {
          subs.add(m);
          continue;
        }
        // Constrói FactionAdmissionSubTask pra avaliação.
        final subTask = FactionAdmissionSubTask.fromJson(m);
        final eval = await _validator.evaluate(
            playerId: playerId, subTask: subTask);

        if (eval.failed) {
          await _rejectAdmission(
            playerId: playerId,
            factionId: factionId,
            missionId:
                meta['mission_id'] as String? ?? mission.missionKey,
            reason: subTask.subType ==
                    FactionAdmissionSubTaskTypes.exactDailyCountWindow
                ? 'exact_count_overshoot:${meta['mission_id']}'
                : 'sub_task_failed:${subTask.subType}',
          );
          return;
        }
        if (eval.achieved) {
          m['completed'] = true;
          anyChanged = true;
        } else {
          allCompleted = false;
        }
        subs.add(m);
      }

      if (anyChanged) {
        // Persiste estado atualizado em metaJson.
        meta['sub_tasks'] = subs;
        await _persistMeta(mission.id, meta);
      }

      if (allCompleted && rawSubs.isNotEmpty) {
        await _completeMissionAndPromoteNext(
            mission: mission, meta: meta, playerId: playerId);
        // Re-avalia depois pra cobrir cascata (próxima missão pode
        // ter sub-task achievable já no estado atual — raro mas
        // possível com snapshot_rank).
      }
    }
  }

  Future<void> _persistMeta(int missionId, Map<String, dynamic> meta) async {
    await _db.customUpdate(
      'UPDATE player_mission_progress SET meta_json = ? WHERE id = ?',
      variables: [
        Variable.withString(jsonEncode(meta)),
        Variable.withInt(missionId),
      ],
      updates: {_db.playerMissionProgressTable},
    );
  }

  Future<void> _completeMissionAndPromoteNext({
    required MissionProgress mission,
    required Map<String, dynamic> meta,
    required int playerId,
  }) async {
    final factionId = meta['faction_id'] as String;
    final missionId =
        meta['mission_id'] as String? ?? mission.missionKey;

    // 1. Marca missão como completed.
    await _missionRepo.markCompleted(mission.id,
        at: DateTime.now(), rewardClaimed: true);

    // 2. Lista todas as missões dessa admissão (factionId, playerId)
    //    em ordem (autoincrement id reflete ordem de criação que
    //    bate com o catálogo).
    final all = await _missionRepo.findByTab(
        playerId, MissionTabOrigin.admission);
    final ofFaction = all.where((m) {
      try {
        final dec = jsonDecode(m.metaJson);
        return dec is Map && dec['faction_id'] == factionId;
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // Index 1-based da missão atual.
    final index = ofFaction.indexWhere((m) => m.id == mission.id) + 1;
    final total = ofFaction.length;

    _bus.publish(FactionAdmissionQuestCompleted(
      playerId: playerId,
      factionId: factionId,
      questIndex: index,
      totalQuests: total,
      missionId: missionId,
    ));

    if (index < total) {
      // 3a. Promove próxima missão.
      final next = ofFaction[index]; // 0-based, próximo após current
      await _unlockMission(next, playerId);
    } else {
      // 3b. Última missão — admissão APROVADA.
      await _approveAdmission(playerId, factionId);
    }
  }

  Future<void> _unlockMission(MissionProgress mission, int playerId) async {
    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (meta['is_unlocked'] == true) return; // já desbloqueada

    // Recaptura snapshot_rank no momento do unlock (player pode ter
    // subido durante missão anterior).
    final playerRow = await (_db.select(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .getSingleOrNull();
    final newSnapshotRank = playerRow?.guildRank ?? 'none';

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    meta['is_unlocked'] = true;
    meta['window_start_ms'] = nowMs;
    meta['snapshot_rank'] = newSnapshotRank;

    // Atualiza windowStartMs e snapshotRank de cada sub-task pra que
    // o validator use a janela nova.
    final rawSubs = (meta['sub_tasks'] as List?) ?? const [];
    final updatedSubs = <Map<String, dynamic>>[];
    for (final raw in rawSubs) {
      final s = (raw as Map).cast<String, dynamic>();
      s['window_start_ms'] = nowMs;
      s['snapshot_rank'] = newSnapshotRank;
      updatedSubs.add(s);
    }
    meta['sub_tasks'] = updatedSubs;

    await _persistMeta(mission.id, meta);
  }

  Future<void> _approveAdmission(int playerId, String factionId) async {
    // Promove faction_type pra X (de pending:X).
    await _db.customUpdate(
      'UPDATE players SET faction_type = ? WHERE id = ?',
      variables: [
        Variable.withString(factionId),
        Variable.withInt(playerId),
      ],
      updates: {_db.playersTable},
    );

    // Cria/promove membership row.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      'INSERT OR IGNORE INTO player_faction_membership '
      '(player_id, faction_id, joined_at, left_at, locked_until, '
      ' debuff_until, admission_attempts) '
      'VALUES (?, ?, ?, NULL, NULL, NULL, 0)',
      [playerId, factionId, nowMs],
    );
    await _db.customStatement(
      'UPDATE player_faction_membership SET joined_at = ? '
      'WHERE player_id = ? AND faction_id = ? AND joined_at IS NULL',
      [nowMs, playerId, factionId],
    );

    final attemptCount =
        await _readAttemptCount(playerId, factionId);

    _bus.publish(FactionAdmissionApproved(
      playerId: playerId,
      factionId: factionId,
      attemptCount: attemptCount,
    ));
    // Cascata pra retrocompatibilidade com listeners existentes.
    _bus.publish(FactionJoined(playerId: playerId, factionId: factionId));
  }

  Future<int> _readAttemptCount(int playerId, String factionId) async {
    final rows = await _db.customSelect(
      'SELECT admission_attempts FROM player_faction_membership '
      'WHERE player_id = ? AND faction_id = ? LIMIT 1',
      variables: [
        Variable.withInt(playerId),
        Variable.withString(factionId),
      ],
    ).get();
    return rows.isNotEmpty
        ? rows.first.read<int>('admission_attempts')
        : 1;
  }

  /// Dispara reject — primeiro emite o evento (pra outros listeners
  /// reagirem). [_handleRejection] cuida do reset (lock + reputação +
  /// faction_type).
  Future<void> _rejectAdmission({
    required int playerId,
    required String factionId,
    required String missionId,
    required String reason,
  }) async {
    final attemptCount = await _readAttemptCount(playerId, factionId);
    _bus.publish(FactionAdmissionRejected(
      playerId: playerId,
      factionId: factionId,
      attemptCount: attemptCount,
      reason: reason,
      missionId: missionId,
    ));
  }

  Future<void> _handleRejection(FactionAdmissionRejected evt) async {
    try {
      // 1. Marca todas as missões da admissão como failed.
      final all = await _missionRepo.findByTab(
          evt.playerId, MissionTabOrigin.admission);
      final ofFaction = all.where((m) {
        if (m.completedAt != null || m.failedAt != null) return false;
        try {
          final dec = jsonDecode(m.metaJson);
          return dec is Map && dec['faction_id'] == evt.factionId;
        } catch (_) {
          return false;
        }
      });
      for (final mission in ofFaction) {
        await _missionRepo.markFailed(mission.id, at: DateTime.now());
      }

      // 2. -10 reputação (D1: niet=failed; reset=falha).
      await _factionRepo.delta(
          evt.playerId, evt.factionId, _rejectRepDelta);
      // Sem propagação aliada/rival neste delta (admission reject
      // afeta apenas a facção tentada). Se for desejável, futuro
      // sprint pode usar `_factionRep.adjustReputation` em vez do
      // repo direto.
      // ignore: unused_local_variable
      final _ = _factionRep;

      // 3. Lock 48h em player_faction_membership.
      final lockUntilMs = DateTime.now()
          .add(_rejectLock)
          .millisecondsSinceEpoch;
      await _db.customStatement(
        'UPDATE player_faction_membership SET locked_until = ? '
        'WHERE player_id = ? AND faction_id = ?',
        [lockUntilMs, evt.playerId, evt.factionId],
      );

      // 4. Reverte faction_type pra 'none' (player pode tentar outras
      //    facções imediatamente; só esta facção fica em cooldown).
      await _db.customUpdate(
        "UPDATE players SET faction_type = 'none' WHERE id = ?",
        variables: [Variable.withInt(evt.playerId)],
        updates: {_db.playersTable},
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[admission-progress] _handleRejection falhou: $e\n$st');
    }
  }
}
