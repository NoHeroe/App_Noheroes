import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/daily_mission_events.dart';
import '../../core/utils/day_format.dart';
import '../enums/mission_category.dart';
import '../models/daily_mission.dart';
import '../models/daily_mission_status.dart';
import '../models/player_daily_mission_stats.dart';

/// Época 2 (ADR-0024) — port full-online do agregador de stats.
///
/// **Single writer** das tabelas `player_daily_mission_stats` e
/// `player_daily_subtask_volume`. Listeners fire-and-forget (exceptions
/// capturadas e logadas).
///
/// ## Atomicidade / RPCs
///
/// Os UPDATEs de stats são `col = col + 1` / `MAX(...)` / `bitmask |` /
/// `COALESCE(...)` — PostgREST não expressa isso, então cada write é uma
/// RPC server-side. As RPCs que JÁ existem (rpc_daily.sql):
///   - `record_daily_on_completed` (incrementOnCompleted composto)
///   - `increment_subtask_volume`  (volume terminal)
///
/// As demais RPCs de stats **NÃO existem ainda** e estão chamadas aqui
/// pelos nomes canônicos esperados (ver 'unresolved' no resumo):
///   - `increment_daily_generated`
///   - `increment_daily_partial`
///   - `increment_daily_failed`
///   - `update_daily_best_streak`
///   - `bump_daily_days_without_failing`
///   - `update_daily_consecutive_active_days`
///   - `mark_daily_pilar_balance_day`
///   - `increment_daily_today_count`
/// Todas refletem 1:1 os métodos do antigo `PlayerDailyMissionStatsDao`.
/// `findOrCreate` virou a garantia de row dentro de cada RPC
/// (insert ... on conflict do nothing), igual `record_daily_on_completed`.
class DailyMissionStatsService {
  final SupabaseClient _client;
  final AppEventBus _bus;

  /// Pra testes — substitui `DateTime.now()`. Default = wall clock.
  final DateTime Function() _clock;

  StreamSubscription<DailyMissionGenerated>? _genSub;
  StreamSubscription<DailyMissionCompleted>? _completedSub;
  StreamSubscription<DailyMissionFailed>? _failedSub;
  bool _started = false;

  DailyMissionStatsService({
    required SupabaseClient client,
    required AppEventBus bus,
    DateTime Function()? clock,
  })  : _client = client,
        _bus = bus,
        _clock = clock ?? DateTime.now;

  /// Subscreve nos 3 eventos terminais. Idempotente — `start()` chamado
  /// 2× vira noop.
  void start() {
    if (_started) return;
    _started = true;
    _genSub = _bus.on<DailyMissionGenerated>().listen(_onGenerated);
    _completedSub = _bus.on<DailyMissionCompleted>().listen(_onCompleted);
    _failedSub = _bus.on<DailyMissionFailed>().listen(_onFailed);
  }

  /// Cancela todas as subscriptions. Idempotente.
  Future<void> dispose() async {
    await _genSub?.cancel();
    await _completedSub?.cancel();
    await _failedSub?.cancel();
    _genSub = null;
    _completedSub = null;
    _failedSub = null;
    _started = false;
  }

  // ─── handlers ───────────────────────────────────────────────────────

  Future<void> _onGenerated(DailyMissionGenerated evt) async {
    try {
      await _client.rpc('increment_daily_generated', params: {
        'p_player': evt.playerId,
      });
      // Publish APÓS commit garante que readers vejam o estado novo.
      _bus.publish(
          DailyStatsUpdated(playerId: evt.playerId, eventType: 'generated'));
    } catch (e) {
      // ignore: avoid_print
      print('[stats] _onGenerated falhou pra player=${evt.playerId}: $e');
    }
  }

  Future<void> _onFailed(DailyMissionFailed evt) async {
    try {
      await _client.rpc('increment_daily_failed', params: {
        'p_player': evt.playerId,
      });
      // Volume terminal: soma `progressoAtual` das subs mesmo em failed.
      final mission = await _findMissionById(evt.missionId);
      if (mission != null) {
        await _addVolumeFromMission(mission);
      }
      _bus.publish(
          DailyStatsUpdated(playerId: evt.playerId, eventType: 'failed'));
    } catch (e) {
      // ignore: avoid_print
      print('[stats] _onFailed falhou pra player=${evt.playerId}: $e');
    }
  }

  Future<void> _onCompleted(DailyMissionCompleted evt) async {
    try {
      final mission = await _findMissionById(evt.missionId);
      final perf = mission == null ? null : calculatePerfectness(mission);
      final confirmedAt = mission?.completedAt ?? _clock();
      final today = formatDay(confirmedAt);

      // ANTI-CHEESE: confirmação ✓ com 0% (`avgFactor < 0.05`) NÃO conta.
      if (perf != null && !perf.zeroProgress) {
        final preStats = await _findOrReadStats(evt.playerId);
        final shouldResetToday = preStats?.lastTodayCountDate != today;
        await _client.rpc('increment_daily_today_count', params: {
          'p_player': evt.playerId,
          'p_reset_to_1_if_day_changed': shouldResetToday,
          'p_today_date': today,
        });
      }

      // Partial e fullCompleted vêm pelo mesmo evento — discrimina aqui.
      if (evt.partial) {
        await _client.rpc('increment_daily_partial', params: {
          'p_player': evt.playerId,
        });
        if (mission != null) {
          await _addVolumeFromMission(mission);
        }
        _bus.publish(
            DailyStatsUpdated(playerId: evt.playerId, eventType: 'completed'));
        return;
      }
      // fullCompleted = true a partir daqui.
      if (mission == null) return;
      final perfNN = perf!;

      final isPilarBalance =
          await _detectPilarBalanceDay(evt.playerId, mission.data);
      final isSpeedrun = _isSpeedrun(mission);

      await _client.rpc('record_daily_on_completed', params: {
        'p_player': evt.playerId,
        'p_is_perfect': perfNN.isPerfect,
        'p_is_super_perfect': perfNN.isSuperPerfect,
        'p_sub_tasks_completed': perfNN.subsCompleted,
        'p_sub_tasks_overshoot': perfNN.subsOvershoot,
        'p_confirmed_at_ms': confirmedAt.millisecondsSinceEpoch,
        'p_day_of_week': _dayOfWeekZeroIndexed(confirmedAt),
        'p_is_before_8am': isBefore8AM(confirmedAt),
        'p_is_after_10pm': isAfter10PM(confirmedAt),
        'p_is_weekend': isWeekend(confirmedAt),
        'p_is_speedrun': isSpeedrun,
        'p_zero_progress': perfNN.zeroProgress,
        'p_was_auto_confirmed': evt.wasAutoConfirmed,
      });

      // Volume — soma após increments principais.
      await _addVolumeFromMission(mission);

      // Streak best — lê player atualizado pelo progress service.
      final streak = await _readPlayerStreak(evt.playerId);
      if (streak != null) {
        await _client.rpc('update_daily_best_streak', params: {
          'p_player': evt.playerId,
          'p_current_streak': streak,
        });
      }

      // Transição diária: bumpDaysWithoutFailing + consecutiveActiveDays.
      final stats = await _findOrReadStats(evt.playerId);
      if (stats != null) {
        final lastActive = stats.lastActiveDay;
        if (lastActive != today) {
          final consecutive = lastActive != null &&
              _isYesterday(today: today, prev: lastActive);
          await _client.rpc('update_daily_consecutive_active_days', params: {
            'p_player': evt.playerId,
            'p_today': today,
            'p_consecutive': consecutive,
          });
          await _client.rpc('bump_daily_days_without_failing', params: {
            'p_player': evt.playerId,
          });
        }
      }

      // Pilar balance: marca o dia se 3+ modalidades fecharam.
      if (isPilarBalance) {
        await _client.rpc('mark_daily_pilar_balance_day', params: {
          'p_player': evt.playerId,
          'p_today': mission.data,
        });
      }

      _bus.publish(
          DailyStatsUpdated(playerId: evt.playerId, eventType: 'completed'));
    } catch (e) {
      // ignore: avoid_print
      print('[stats] _onCompleted falhou pra player=${evt.playerId}: $e');
    }
  }

  // ─── persistência / leitura (Supabase) ──────────────────────────────

  Future<DailyMission?> _findMissionById(int id) async {
    final row = await _client
        .from('daily_missions')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : DailyMission.fromMap(row);
  }

  Future<PlayerDailyMissionStats?> _findOrReadStats(String playerId) async {
    final row = await _client
        .from('player_daily_mission_stats')
        .select()
        .eq('player_id', playerId)
        .maybeSingle();
    return row == null ? null : PlayerDailyMissionStats.fromMap(row);
  }

  Future<int?> _readPlayerStreak(String playerId) async {
    final row = await _client
        .from('players')
        .select('daily_missions_streak')
        .eq('id', playerId)
        .maybeSingle();
    return row == null
        ? null
        : (row['daily_missions_streak'] as num?)?.toInt() ?? 0;
  }

  Future<void> _addVolumeFromMission(DailyMission mission) async {
    for (final sub in mission.subTarefas) {
      if (sub.progressoAtual > 0) {
        await _client.rpc('increment_subtask_volume', params: {
          'p_player': mission.playerId,
          'p_sub_task_key': sub.subTaskKey,
          'p_delta': sub.progressoAtual,
        });
      }
    }
  }

  Future<bool> _detectPilarBalanceDay(String playerId, String dayKey) async {
    final rows = await _client
        .from('daily_missions')
        .select('modalidade, status')
        .eq('player_id', playerId)
        .eq('data', dayKey);
    final modalidades = <MissionCategory>{};
    for (final r in (rows as List)) {
      final m = r as Map<String, dynamic>;
      final status =
          DailyMissionStatusCodec.fromStorage(m['status'] as String);
      if (status == DailyMissionStatus.completed ||
          status == DailyMissionStatus.partial) {
        modalidades
            .add(MissionCategoryCodec.fromStorage(m['modalidade'] as String));
      }
    }
    return modalidades.length >= 3;
  }

  bool _isSpeedrun(DailyMission mission) {
    final completedAt = mission.completedAt;
    if (completedAt == null) return false;
    final delta = completedAt.difference(mission.createdAt);
    return delta < const Duration(hours: 12);
  }

  // ─── perfectness ─────────────────────────────────────────────────────

  /// Calcula métricas de qualidade de uma missão fechada.
  ///
  /// - `isSuperPerfect`: avg factor >= 2.0 (200%+ médio)
  /// - `isPerfect`: avg factor >= 3.0 (300%+ médio — limite SOULSLIKE)
  /// - `subsCompleted`: count de subs com `completed=true`
  /// - `subsOvershoot`: count de subs com `progressoAtual > escalaAlvo`
  /// - `zeroProgress`: avg factor < 0.05 (confirmou ✓ sem fazer nada)
  static ({
    bool isPerfect,
    bool isSuperPerfect,
    int subsCompleted,
    int subsOvershoot,
    bool zeroProgress,
  }) calculatePerfectness(DailyMission mission) {
    int subsCompleted = 0;
    int subsOvershoot = 0;
    double sumFactor = 0;
    int factorCount = 0;
    for (final s in mission.subTarefas) {
      if (s.completed) subsCompleted++;
      if (s.escalaAlvo > 0 && s.progressoAtual > s.escalaAlvo) {
        subsOvershoot++;
      }
      if (s.escalaAlvo > 0) {
        sumFactor += s.progressoAtual / s.escalaAlvo;
        factorCount++;
      }
    }
    final avgFactor = factorCount == 0 ? 0.0 : sumFactor / factorCount;
    return (
      isPerfect: avgFactor >= 3.0,
      isSuperPerfect: avgFactor >= 2.0,
      subsCompleted: subsCompleted,
      subsOvershoot: subsOvershoot,
      zeroProgress: avgFactor < 0.05,
    );
  }

  // ─── helpers temporais (públicos pra testes) ───────────────────────

  static bool isBefore8AM(DateTime ts) => ts.hour < 8;
  static bool isAfter10PM(DateTime ts) => ts.hour >= 22;
  static bool isWeekend(DateTime ts) =>
      ts.weekday == DateTime.saturday || ts.weekday == DateTime.sunday;

  /// 0 = domingo .. 6 = sábado (alinhado ao bitmask). `DateTime.weekday`
  /// retorna 1=mon..7=sun, então convertemos.
  static int _dayOfWeekZeroIndexed(DateTime ts) {
    return ts.weekday == DateTime.sunday ? 0 : ts.weekday;
  }

  /// `prev` é o dia imediatamente anterior a `today`? Compara só o dia
  /// civil (ambos em formato YYYY-MM-DD). Tolera virada de mês/ano.
  static bool _isYesterday({required String today, required String prev}) {
    DateTime parse(String s) {
      final parts = s.split('-');
      return DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }

    final t = parse(today);
    final p = parse(prev);
    return t.difference(p).inDays == 1;
  }
}
