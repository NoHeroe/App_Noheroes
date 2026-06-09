import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/events/app_event.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/daily_mission_events.dart';
import '../../../core/events/diary_events.dart';
import '../../../core/events/faction_events.dart';
import '../../../core/events/mission_events.dart';
import '../../../core/events/reward_events.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/repositories/mission_repository.dart';
import '../../../domain/repositories/player_faction_reputation_repository.dart';
import '../../../domain/services/faction_admission_sub_task_types.dart';
import '../../../domain/services/faction_admission_validator.dart';
import '../../../domain/services/faction_reputation_service.dart';
import '../../../domain/services/mission_assignment_service.dart';

/// Sprint 3.4 Sub-Etapa B.2 — listener que re-avalia sub-tasks de
/// admissão eliminatória ao receber eventos terminais. Single point
/// of truth pro lifecycle: progresso, sequenciamento (missão N+1
/// desbloqueada quando N completar), reset em falha.
///
/// Época 2 (ADR-0024) — full-online Supabase. As operações ATÔMICAS
/// multi-write (aprovação e rejeição) viram RPCs
/// (`approve_faction_admission`, `reject_faction_admission`) — não
/// reimplementamos a atomicidade no cliente. Os reads de `players` e
/// `player_faction_membership` e a persistência single-write do
/// metaJson viram chamadas PostgREST.
///
/// ## Eventos consumidos
///
/// | Evento | Sub-types afetados |
/// |---|---|
/// | `DailyMissionCompleted` | daily_count_window, full_perfect_day, no_partial_day, exact_daily_count, zero_failed, zero_category |
/// | `MissionCompleted` (modality=individual) | individual_completed_window |
/// | `DiaryEntryCreated` | diary_entry_window |
/// | `RewardGranted` | gold_earned_via_quests_window, gold_balance_threshold |
///
/// ## Reset em falha (RPC `reject_faction_admission`)
///
/// - markFailed em todas as missões da admissão (factionId+playerId).
/// - Aplica -10 reputação na facção (sem propagação — paridade com Dart).
/// - Set `locked_until = now + 48h` em `player_faction_membership`.
/// - Reverte `players.faction_type` pra 'none'.
class FactionAdmissionProgressService {
  final SupabaseClient _client;
  final AppEventBus _bus;
  final FactionAdmissionValidator _validator;
  final MissionRepository _missionRepo;
  // ignore: unused_field
  final FactionReputationService _factionRep;
  // ignore: unused_field
  final PlayerFactionReputationRepository _factionRepo;
  // FATIA B4 (Fix gatilho-JOIN) — atribui a semanal de facção na hora da
  // aprovação, sem esperar o boot do Santuário.
  final MissionAssignmentService _assignment;

  final List<StreamSubscription> _subs = [];

  FactionAdmissionProgressService({
    required SupabaseClient client,
    required AppEventBus bus,
    required FactionAdmissionValidator validator,
    required MissionRepository missionRepo,
    required FactionReputationService factionRep,
    required PlayerFactionReputationRepository factionRepo,
    required MissionAssignmentService assignment,
  })  : _client = client,
        _bus = bus,
        _validator = validator,
        _missionRepo = missionRepo,
        _factionRep = factionRep,
        _factionRepo = factionRepo,
        _assignment = assignment;

  /// Lock de 48h após reprovação (cooldown anti re-tentativa imediata).
  static const Duration _rejectLock = Duration(hours: 48);

  /// Penalidade de reputação por reprovação.
  static const int _rejectRepDelta = -10;

  void start() {
    _subs.add(_bus.on<DailyMissionCompleted>().listen(_onAnyEvent));
    // Sprint 3.4 Etapa C hotfix #2 (P0-E) — DailyMissionFailed também
    // dispara re-avaliação (zero_failed_window / zero_category_window).
    _subs.add(_bus.on<DailyMissionFailed>().listen(_onAnyEvent));
    _subs.add(_bus.on<MissionCompleted>().listen(_onAnyEvent));
    _subs.add(_bus.on<DiaryEntryCreated>().listen(_onAnyEvent));
    _subs.add(_bus.on<RewardGranted>().listen(_onAnyEvent));
    _subs.add(_bus.on<FactionAdmissionRejected>().listen(_handleRejection));
    // Sprint 3.4 hotfix B.2 — handler externo de FactionAdmissionApproved
    // (idempotente; cobre flow do dev panel).
    _subs.add(_bus.on<FactionAdmissionApproved>().listen(_handleApproved));
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// Handler unificado pra qualquer evento terminal — re-avalia todas
  /// as missões ativas do player.
  Future<void> _onAnyEvent(AppEvent evt) async {
    final playerId = evt.playerId;
    if (playerId == null) return;
    try {
      await _evaluatePlayer(playerId);
    } catch (e, st) {
      // ignore: avoid_print
      print('[admission-progress] _evaluatePlayer falhou: $e\n$st');
    }
  }

  /// Sprint 3.4 Etapa C hotfix #3 (P0-F) — exposto público pra que
  /// callers (ex: `QuestsScreenNotifier.build`) possam disparar
  /// re-avaliação on-demand (expiração de janela é passiva).
  Future<void> evaluatePlayer(String playerId) => _evaluatePlayer(playerId);

  Future<void> _evaluatePlayer(String playerId) async {
    final all =
        await _missionRepo.findByTab(playerId, MissionTabOrigin.admission);
    final active =
        all.where((m) => m.completedAt == null && m.failedAt == null);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final mission in active) {
      try {
        await _processMission(mission, playerId, nowMs);
      } catch (e, st) {
        // ignore: avoid_print
        print('[admission-progress] missão ${mission.id} falhou: '
            '$e\n$st');
        continue;
      }
    }
  }

  /// Processa UMA missão isoladamente. Retorna early sem persistir nada
  /// quando metaJson é inválido / missão não aplicável.
  Future<void> _processMission(
      MissionProgress mission, String playerId, int nowMs) async {
    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    // Defesa em profundidade — Guilda não tem admissão eliminatória.
    if (meta['faction_id'] == 'guild') return;
    // Só avalia se a missão está desbloqueada.
    if (meta['is_unlocked'] != true) return;

    final factionId = meta['faction_id'] as String?;
    if (factionId == null) return;

    // Janela expirada?
    final windowStartMs = (meta['window_start_ms'] as int?) ?? 0;
    final windowDurationMs =
        (meta['window_duration_ms'] as int?) ?? (48 * 60 * 60 * 1000);
    final expired =
        windowStartMs > 0 && nowMs > windowStartMs + windowDurationMs;

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
      FactionAdmissionSubTask subTask;
      try {
        subTask = FactionAdmissionSubTask.fromJson(m);
      } catch (e) {
        // ignore: avoid_print
        print('[admission-progress] sub-task inválida: $e — pulando');
        subs.add(m);
        allCompleted = false;
        continue;
      }
      final eval = await _validator.evaluate(
          playerId: playerId, subTask: subTask, expired: expired);

      if (eval.failed) {
        await _rejectAdmission(
          playerId: playerId,
          factionId: factionId,
          missionId: meta['mission_id'] as String? ?? mission.missionKey,
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

    // Sprint 3.4 Etapa C hotfix #1 — janela expirou E nem todas as
    // sub-tasks ficaram achieved → rejeita admissão.
    if (expired && !allCompleted) {
      await _rejectAdmission(
        playerId: playerId,
        factionId: factionId,
        missionId: meta['mission_id'] as String? ?? mission.missionKey,
        reason: 'window_expired:${meta['mission_id'] ?? mission.missionKey}',
      );
      return;
    }

    if (anyChanged) {
      meta['sub_tasks'] = subs;
      await _persistMeta(mission.id, meta);
    }

    if (allCompleted && rawSubs.isNotEmpty) {
      await _completeMissionAndPromoteNext(
          mission: mission, meta: meta, playerId: playerId);
    }
  }

  /// Single-write do metaJson via PostgREST. `missionId` é PK de linha
  /// (bigserial = int) — NÃO é o playerId.
  Future<void> _persistMeta(int missionId, Map<String, dynamic> meta) async {
    await _client
        .from('player_mission_progress')
        .update({'meta_json': jsonEncode(meta)}).eq('id', missionId);
  }

  Future<void> _completeMissionAndPromoteNext({
    required MissionProgress mission,
    required Map<String, dynamic> meta,
    required String playerId,
  }) async {
    final factionId = meta['faction_id'] as String;
    final missionId = meta['mission_id'] as String? ?? mission.missionKey;

    // 1. Marca missão como completed.
    await _missionRepo.markCompleted(mission.id,
        at: DateTime.now(), rewardClaimed: true);

    // 2. Lista todas as missões dessa admissão (factionId, playerId)
    //    em ordem (id reflete ordem de criação que bate com o catálogo).
    final all =
        await _missionRepo.findByTab(playerId, MissionTabOrigin.admission);
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

  Future<void> _unlockMission(MissionProgress mission, String playerId) async {
    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (meta['is_unlocked'] == true) return; // já desbloqueada

    // Recaptura snapshot_rank no momento do unlock.
    final playerRow = await _client
        .from('players')
        .select('guild_rank')
        .eq('id', playerId)
        .maybeSingle();
    final newSnapshotRank = (playerRow?['guild_rank'] as String?) ?? 'none';

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    meta['is_unlocked'] = true;
    meta['window_start_ms'] = nowMs;
    meta['snapshot_rank'] = newSnapshotRank;

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

  /// Aprovação atômica via RPC `approve_faction_admission` (promove
  /// faction_type + welcome bonus +100 insígnias idempotente + upsert
  /// da membership). Depois atribui a semanal de facção (domínio
  /// Missions, fora da RPC) e emite os eventos client-side.
  Future<void> _approveAdmission(String playerId, String factionId) async {
    await _client.rpc('approve_faction_admission', params: {
      'p_player': playerId,
      'p_faction': factionId,
    });

    // FATIA B4 (Fix gatilho-JOIN) — atribui a semanal AGORA. Idempotente.
    await _assignWeeklyOnJoin(playerId, factionId);

    final attemptCount = await _readAttemptCount(playerId, factionId);

    _bus.publish(FactionAdmissionApproved(
      playerId: playerId,
      factionId: factionId,
      attemptCount: attemptCount,
    ));
    // Cascata pra retrocompatibilidade com listeners existentes.
    _bus.publish(FactionJoined(playerId: playerId, factionId: factionId));
  }

  /// FATIA B4 (Fix gatilho-JOIN) — atribui a semanal de facção no momento
  /// em que o player entra numa facção (aprovação real OU dev tool).
  /// Idempotente. Erros logados, nunca propagados.
  Future<void> _assignWeeklyOnJoin(String playerId, String factionId) async {
    try {
      final row = await _client
          .from('players')
          .select('guild_rank, total_gold_earned_via_quests')
          .eq('id', playerId)
          .maybeSingle();
      if (row == null) return;
      final guildRankRaw = (row['guild_rank'] as String?) ?? 'e';
      final baselineGold =
          (row['total_gold_earned_via_quests'] as num?)?.toInt() ?? 0;
      final rank = GuildRankSystem.fromString(guildRankRaw);
      await _assignment.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: factionId,
        playerRank: rank,
        baselineGoldEarned: baselineGold,
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[admission-progress] _assignWeeklyOnJoin falhou: $e\n$st');
    }
  }

  Future<int> _readAttemptCount(String playerId, String factionId) async {
    final row = await _client
        .from('player_faction_membership')
        .select('admission_attempts')
        .eq('player_id', playerId)
        .eq('faction_id', factionId)
        .maybeSingle();
    return (row?['admission_attempts'] as num?)?.toInt() ?? 1;
  }

  /// Dispara reject — emite o evento. [_handleRejection] cuida do reset
  /// atômico via RPC.
  Future<void> _rejectAdmission({
    required String playerId,
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

  /// Sprint 3.4 hotfix B.2 — handler idempotente de
  /// `FactionAdmissionApproved`. Cobre o caso onde o evento é emitido
  /// externamente (ex: dev panel) sem `_approveAdmission` interno.
  ///
  /// `approve_faction_admission` é idempotente no servidor (guard de
  /// welcome bonus + upsert da membership), então podemos chamá-la sem
  /// re-checar `faction_type` aqui.
  Future<void> _handleApproved(FactionAdmissionApproved evt) async {
    try {
      final row = await _client
          .from('players')
          .select('faction_type')
          .eq('id', evt.playerId)
          .maybeSingle();
      if (row == null) return;
      final current = row['faction_type'] as String?;
      // Já promovido pelo flow normal (_approveAdmission rodou).
      if (current == evt.factionId) return;

      // Promove agora (cobre flow externo do dev panel). RPC idempotente
      // — não recredita welcome bonus se já era membro.
      await _client.rpc('approve_faction_admission', params: {
        'p_player': evt.playerId,
        'p_faction': evt.factionId,
      });

      // FATIA B4 (Fix gatilho-JOIN) — atribui a semanal na hora.
      await _assignWeeklyOnJoin(evt.playerId, evt.factionId);

      _bus.publish(
          FactionJoined(playerId: evt.playerId, factionId: evt.factionId));
    } catch (e, st) {
      // ignore: avoid_print
      print('[admission-progress] _handleApproved falhou: $e\n$st');
    }
  }

  /// Reset atômico via RPC `reject_faction_admission` (markFailed das
  /// missões + -10 rep sem propagação + lock 48h + faction_type='none').
  Future<void> _handleRejection(FactionAdmissionRejected evt) async {
    try {
      final lockUntilMs =
          DateTime.now().add(_rejectLock).millisecondsSinceEpoch;
      await _client.rpc('reject_faction_admission', params: {
        'p_player': evt.playerId,
        'p_faction': evt.factionId,
        'p_lock_until_ms': lockUntilMs,
        'p_rep_delta': _rejectRepDelta,
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('[admission-progress] _handleRejection falhou: $e\n$st');
    }
  }
}
