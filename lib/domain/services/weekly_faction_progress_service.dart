import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/events/app_event.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/events/crafting_events.dart';
import '../../core/events/daily_mission_events.dart';
import '../../core/events/diary_events.dart';
import '../../core/events/mission_events.dart';
import '../../core/events/reward_events.dart';
import '../../data/services/reward_grant_service.dart';
import '../enums/mission_tab_origin.dart';
import '../exceptions/reward_exceptions.dart';
import '../models/mission_progress.dart';
import '../models/player_snapshot.dart';
import '../models/reward_declared.dart';
import '../repositories/mission_repository.dart';
import 'reward_resolve_service.dart';
import 'weekly_faction_validator.dart';

/// FATIA B2b — listener ACUMULATIVO do motor semanal de facção.
///
/// Época 2 (ADR-0024) — full-online Supabase. Espelha a ESTRUTURA do
/// `FactionAdmissionProgressService`, mas é **acumulativo**: soma
/// sub-tasks completas e **nunca** rejeita. A única escrita de DB
/// (persistência do metaJson) vira um `update` PostgREST single-write;
/// não há multi-write atômico aqui (cada missão é processada
/// isoladamente). Diferenças vs admissão:
/// - SEM reject, SEM penalidade de reputação, SEM lock, SEM
///   `is_unlocked`/sequenciamento (a semanal tem 1 missão, todas as
///   sub-tasks abertas desde o assign).
/// - `DailyMissionFailed` **só re-avalia** — nunca reprova.
/// - Conclusão antecipada: se TODAS as sub-tasks ficam `completed` antes
///   do fim da semana, paga o reward CHEIO (progressPct=100) e marca a
///   missão `completed`. A Fatia C (reset) paga a fração ≥50% na
///   expiração das missões que sobrarem incompletas.
///
/// ## Eventos consumidos
///
/// | Evento | Efeito |
/// |---|---|
/// | `DailyMissionCompleted` / `DailyMissionFailed` | re-avalia (modality_count, perfect_day, etc.) |
/// | `MissionCompleted` | re-avalia (individual_completed_window) |
/// | `DiaryEntryCreated` | re-avalia (diary_entry_window) |
/// | `RewardGranted` | re-avalia (gold_earned / gold_balance) |
/// | `ItemCrafted` / `ItemEnchanted` | incrementa contador `equipment_improved` (+1) e re-avalia |
///
/// ## Serialização (read-modify-write do metaJson)
///
/// Todos os handlers são enfileirados num único encadeamento (`_tail`).
/// Isso garante processamento **sequencial** — dois eventos em sequência
/// rápida não interleavam writes do metaJson nem perdem incremento do
/// contador `equipment_improved`.
///
/// ## Limitação do `equipment_improved`
///
/// É o ÚNICO sub-type que **não reconcilia com o DB** — não há tabela
/// timestampada de forja/encanto. O contador depende de capturar cada
/// `ItemCrafted`/`ItemEnchanted` enquanto o service está ativo.
class WeeklyFactionProgressService {
  final SupabaseClient _client;
  final AppEventBus _bus;
  final WeeklyFactionValidator _validator;
  final MissionRepository _missionRepo;
  final RewardResolveService _resolver;
  final RewardGrantService _granter;
  final Future<PlayerSnapshot> Function(String playerId) _resolvePlayer;

  final List<StreamSubscription> _subs = [];

  /// Encadeamento serial de tasks — garante read-modify-write atômico do
  /// metaJson entre eventos concorrentes.
  Future<void> _tail = Future<void>.value();

  WeeklyFactionProgressService({
    required SupabaseClient client,
    required AppEventBus bus,
    required WeeklyFactionValidator validator,
    required MissionRepository missionRepo,
    required RewardResolveService resolver,
    required RewardGrantService granter,
    required Future<PlayerSnapshot> Function(String playerId) resolvePlayer,
  })  : _client = client,
        _bus = bus,
        _validator = validator,
        _missionRepo = missionRepo,
        _resolver = resolver,
        _granter = granter,
        _resolvePlayer = resolvePlayer;

  void start() {
    _subs.add(_bus.on<DailyMissionCompleted>().listen(_onTerminal));
    // DailyMissionFailed SÓ re-avalia (acumulativo nunca reprova).
    _subs.add(_bus.on<DailyMissionFailed>().listen(_onTerminal));
    _subs.add(_bus.on<MissionCompleted>().listen(_onTerminal));
    _subs.add(_bus.on<DiaryEntryCreated>().listen(_onTerminal));
    _subs.add(_bus.on<RewardGranted>().listen(_onTerminal));
    _subs.add(_bus.on<ItemCrafted>().listen(_onEquipment));
    _subs.add(_bus.on<ItemEnchanted>().listen(_onEquipment));
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  // ─── handlers de evento ───────────────────────────────────────────

  void _onTerminal(AppEvent evt) {
    final playerId = evt.playerId;
    if (playerId == null) return;
    _enqueue(() => _evaluatePlayer(playerId));
  }

  void _onEquipment(AppEvent evt) {
    final playerId = evt.playerId;
    if (playerId == null) return;
    _enqueue(() => _registerEquipmentImprovement(playerId));
  }

  /// Enfileira [task] no encadeamento serial. Erros são logados sem
  /// quebrar a fila (o próximo task ainda roda).
  Future<void> _enqueue(Future<void> Function() task) {
    final next = _tail.then((_) => task());
    _tail = next.catchError((Object e, StackTrace st) {
      // ignore: avoid_print
      print('[weekly-progress] task falhou: $e\n$st');
    });
    return next;
  }

  /// Re-avaliação on-demand (ex: `QuestsScreenNotifier.build`). Vai pela
  /// mesma fila serial.
  Future<void> evaluatePlayer(String playerId) =>
      _enqueue(() => _evaluatePlayer(playerId));

  /// Registra UMA melhoria de equipamento (forja/encanto) on-demand —
  /// mesmo caminho dos handlers de `ItemCrafted`/`ItemEnchanted`, pela
  /// fila serial. Exposto pra callers/testes.
  Future<void> registerEquipmentImprovement(String playerId) =>
      _enqueue(() => _registerEquipmentImprovement(playerId));

  /// Future que resolve quando a fila atual esvazia (testes).
  Future<void> settle() => _tail;

  // ─── núcleo ────────────────────────────────────────────────────────

  Future<void> _evaluatePlayer(String playerId) async {
    final all =
        await _missionRepo.findByTab(playerId, MissionTabOrigin.faction);
    final active =
        all.where((m) => m.completedAt == null && m.failedAt == null);
    for (final mission in active) {
      try {
        await _processMission(mission, playerId);
      } catch (e, st) {
        // ignore: avoid_print
        print('[weekly-progress] missão ${mission.id} falhou: $e\n$st');
      }
    }
  }

  Future<void> _processMission(
      MissionProgress mission, String playerId) async {
    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final weekStartMs = (meta['week_start_ms'] as int?) ?? 0;
    final weekEndMs = (meta['week_end_ms'] as int?) ?? 0;
    // Defesa: metaJson sem janela semanal não é uma weekly do motor B2a.
    if (weekStartMs == 0 || weekEndMs == 0) return;

    final rawSubs = (meta['sub_tasks'] as List?) ?? const [];
    if (rawSubs.isEmpty) return;

    final subs = <Map<String, dynamic>>[];
    var anyChanged = false;
    var allCompleted = true;

    for (final raw in rawSubs) {
      final m = (raw as Map).cast<String, dynamic>();
      if (m['completed'] == true) {
        subs.add(m);
        continue;
      }
      WeeklyFactionSubTask subTask;
      try {
        subTask = WeeklyFactionSubTask.fromJson(m);
      } catch (e) {
        // ignore: avoid_print
        print('[weekly-progress] sub-task inválida: $e — pulando');
        subs.add(m);
        allCompleted = false;
        continue;
      }
      final eval = await _validator.evaluate(
        playerId: playerId,
        subTask: subTask,
        weekStartMs: weekStartMs,
        weekEndMs: weekEndMs,
      );
      if (eval.achieved) {
        m['completed'] = true;
        anyChanged = true;
      } else {
        allCompleted = false;
      }
      subs.add(m);
    }

    if (anyChanged) {
      meta['sub_tasks'] = subs;
      await _persistMeta(mission.id, meta);
    }

    // Conclusão antecipada — paga reward cheio + marca completed.
    if (allCompleted) {
      await _grantWeeklyReward(mission, meta, playerId);
    }
  }

  /// Incrementa o contador `equipment_improved` (+1) em cada missão
  /// faction ativa com essa sub-task !completed, persiste, e re-avalia
  /// (o validator lê o `current` → marca completed ao bater target).
  Future<void> _registerEquipmentImprovement(String playerId) async {
    final all =
        await _missionRepo.findByTab(playerId, MissionTabOrigin.faction);
    final active =
        all.where((m) => m.completedAt == null && m.failedAt == null);
    for (final mission in active) {
      try {
        final meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
        final rawSubs = (meta['sub_tasks'] as List?) ?? const [];
        if (rawSubs.isEmpty) continue;
        final subs = <Map<String, dynamic>>[];
        var changed = false;
        for (final raw in rawSubs) {
          final m = (raw as Map).cast<String, dynamic>();
          if (m['sub_type'] == WeeklyFactionSubTaskTypes.equipmentImproved &&
              m['completed'] != true) {
            m['current'] = ((m['current'] as int?) ?? 0) + 1;
            changed = true;
          }
          subs.add(m);
        }
        if (changed) {
          meta['sub_tasks'] = subs;
          await _persistMeta(mission.id, meta);
        }
      } catch (e, st) {
        // ignore: avoid_print
        print('[weekly-progress] equipment incr falhou (missão '
            '${mission.id}): $e\n$st');
      }
    }
    // Reconcilia: marca completed/early-complete com o current novo.
    await _evaluatePlayer(playerId);
  }

  /// Resolve+concede o reward CHEIO (progressPct=100) da missão semanal.
  ///
  /// Idempotência: `RewardGrantService.grant` faz `markCompleted`
  /// (`rewardClaimed=true`) DENTRO da própria operação e checa
  /// `rewardClaimed` — uma 2ª chamada lança `RewardAlreadyGrantedException`
  /// (capturada). Como `_evaluatePlayer` só itera missões ATIVAS
  /// (`completedAt == null`), o `RewardGranted` emitido pós-commit
  /// re-dispara a avaliação mas a missão já está completa → não re-paga.
  Future<void> _grantWeeklyReward(
      MissionProgress mission, Map<String, dynamic> meta,
      String playerId) async {
    final rewardMap = (meta['reward'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final declared = RewardDeclared.fromJson(rewardMap);
    final snapshot = await _resolvePlayer(playerId);
    final resolved =
        await _resolver.resolve(declared, snapshot, progressPct: 100);
    try {
      await _granter.grant(
        missionProgressId: mission.id,
        playerId: playerId,
        resolved: resolved,
      );
    } on RewardAlreadyGrantedException {
      // Race residual / re-entrada — outra chamada já pagou. Idempotente.
    }
  }

  /// Single-write do metaJson via PostgREST. `missionId` é PK de linha
  /// (bigserial = int) — NÃO é o playerId.
  Future<void> _persistMeta(int missionId, Map<String, dynamic> meta) async {
    await _client
        .from('player_mission_progress')
        .update({'meta_json': jsonEncode(meta)}).eq('id', missionId);
  }
}
