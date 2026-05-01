import 'dart:async';

import '../../core/events/app_event_bus.dart';
import '../../core/events/daily_mission_events.dart';
import '../../core/utils/day_format.dart';
import '../../data/database/daos/daily_missions_dao.dart';
import '../../data/database/daos/player_daily_mission_stats_dao.dart';
import '../../data/database/daos/player_daily_subtask_volume_dao.dart';
import '../../data/database/daos/player_dao.dart';
import '../enums/mission_category.dart';
import '../models/daily_mission.dart';
import '../models/daily_mission_status.dart';

/// Sprint 3.3 Etapa 2.1a — agregador de stats all-time de daily missions.
///
/// **Single writer** das tabelas `player_daily_mission_stats` e
/// `player_daily_subtask_volume`. Outros services (Achievements em 2.1b)
/// só leem.
///
/// ## Tracking terminal
///
/// Volume de sub-tarefas + a maioria dos contadores atualizam só em
/// eventos terminais (`Completed`/`Partial`/`Failed`/`Generated`).
/// Decisão deliberada vs incremental (que exigiria cache em memória +
/// teria race condition com `DailyMissionProgressed`).
///
/// ## Threading
///
/// Listeners são fire-and-forget — exceptions internas são capturadas
/// e logadas pra não quebrar o stream do bus.
class DailyMissionStatsService {
  final PlayerDailyMissionStatsDao _statsDao;
  final PlayerDailySubtaskVolumeDao _volumeDao;
  final PlayerDao _playerDao;
  final DailyMissionsDao _missionsDao;
  final AppEventBus _bus;

  /// Pra testes — substitui `DateTime.now()`. Default = wall clock.
  final DateTime Function() _clock;

  StreamSubscription<DailyMissionGenerated>? _genSub;
  StreamSubscription<DailyMissionCompleted>? _completedSub;
  StreamSubscription<DailyMissionFailed>? _failedSub;
  bool _started = false;

  DailyMissionStatsService({
    required PlayerDailyMissionStatsDao statsDao,
    required PlayerDailySubtaskVolumeDao volumeDao,
    required PlayerDao playerDao,
    required DailyMissionsDao missionsDao,
    required AppEventBus bus,
    DateTime Function()? clock,
  })  : _statsDao = statsDao,
        _volumeDao = volumeDao,
        _playerDao = playerDao,
        _missionsDao = missionsDao,
        _bus = bus,
        _clock = clock ?? DateTime.now;

  /// Subscreve nos 3 eventos terminais. Idempotente — `start()` chamado
  /// 2× vira noop.
  void start() {
    if (_started) return;
    _started = true;
    _genSub = _bus.on<DailyMissionGenerated>().listen(_onGenerated);
    _completedSub =
        _bus.on<DailyMissionCompleted>().listen(_onCompleted);
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
      await _statsDao.incrementGenerated(evt.playerId);
      // Sprint 3.3 Etapa 2.1b — coordenação com AchievementsService.
      // Publish APÓS commit garante que readers vejam o estado novo.
      _bus.publish(DailyStatsUpdated(
          playerId: evt.playerId, eventType: 'generated'));
    } catch (e) {
      // ignore: avoid_print
      print('[stats] _onGenerated falhou pra player=${evt.playerId}: $e');
    }
  }

  Future<void> _onFailed(DailyMissionFailed evt) async {
    try {
      await _statsDao.incrementFailed(evt.playerId);
      // Volume terminal: soma `progressoAtual` das subs mesmo em failed
      // (semanticamente — o jogador fez algum esforço, fica registrado).
      final mission = await _missionsDao.findById(evt.missionId);
      if (mission != null) {
        await _addVolumeFromMission(mission);
      }
      // Sprint 3.3 Etapa 2.1b — coordenação com AchievementsService.
      _bus.publish(DailyStatsUpdated(
          playerId: evt.playerId, eventType: 'failed'));
    } catch (e) {
      // ignore: avoid_print
      print('[stats] _onFailed falhou pra player=${evt.playerId}: $e');
    }
  }

  Future<void> _onCompleted(DailyMissionCompleted evt) async {
    try {
      // Sprint 3.3 Etapa 2.1c-δ — fetch mission UMA vez no topo pra
      // calcular `zeroProgress` antes do anti-cheese guard. Substitui
      // os 2 fetches separados (um em partial branch, outro em
      // fullCompleted) — net win + necessário pro novo guard.
      final mission = await _missionsDao.findById(evt.missionId);
      final perf =
          mission == null ? null : calculatePerfectness(mission);
      final confirmedAt = mission?.completedAt ?? _clock();
      final today = formatDay(confirmedAt);

      // Sprint 3.3 Etapa 2.1c-δ — incrementa `daily_today_count` com
      // reset lazy YYYY-MM-DD. ANTI-CHEESE: confirmação ✓ com 0%
      // (`avgFactor < 0.05`) NÃO conta. Conta tanto fullCompleted
      // quanto partial — semântica é "engajou com a missão hoje", não
      // "fechou perfeitamente". Mission ausente → skip silencioso (sem
      // perf, não dá pra avaliar zeroProgress).
      if (perf != null && !perf.zeroProgress) {
        final preStats = await _statsDao.findOrCreate(evt.playerId);
        final shouldResetToday = preStats.lastTodayCountDate != today;
        await _statsDao.incrementTodayCount(
          evt.playerId,
          resetTo1IfDayChanged: shouldResetToday,
          todayDate: today,
        );
      }

      // Partial e fullCompleted vêm pelo mesmo evento — discrimina aqui.
      if (evt.partial) {
        await _statsDao.incrementPartial(evt.playerId);
        if (mission != null) {
          await _addVolumeFromMission(mission);
        }
        // Sprint 3.3 Etapa 2.1b — coordenação com AchievementsService.
        _bus.publish(DailyStatsUpdated(
            playerId: evt.playerId, eventType: 'completed'));
        return;
      }
      // fullCompleted = true a partir daqui.
      if (mission == null) return;
      // `perf` deriva de `mission` via ternário no topo — quando mission
      // é non-null, perf também é. Assert local pra Dart inferir.
      final perfNN = perf!;

      final isPilarBalance =
          await _detectPilarBalanceDay(evt.playerId, mission.data);
      final isSpeedrun = _isSpeedrun(mission);

      await _statsDao.incrementOnCompleted(
        evt.playerId,
        isPerfect: perfNN.isPerfect,
        isSuperPerfect: perfNN.isSuperPerfect,
        subTasksCompleted: perfNN.subsCompleted,
        subTasksOvershoot: perfNN.subsOvershoot,
        confirmedAt: confirmedAt,
        dayOfWeek: _dayOfWeekZeroIndexed(confirmedAt),
        isBefore8AM: isBefore8AM(confirmedAt),
        isAfter10PM: isAfter10PM(confirmedAt),
        isWeekend: isWeekend(confirmedAt),
        isSpeedrun: isSpeedrun,
        zeroProgress: perfNN.zeroProgress,
        // Sprint 3.3 Etapa 2.1c-β — propagado do evento. Auto-confirm
        // bumpa total_auto_confirm_completions; manual+zero bumpa
        // total_zero_progress_manual_confirms (anti-cheese).
        wasAutoConfirmed: evt.wasAutoConfirmed,
      );

      // Volume — soma após increments principais.
      await _addVolumeFromMission(mission);

      // Streak best — lê player atualizado pelo daily_mission_progress_service.
      final player = await _playerDao.findById(evt.playerId);
      if (player != null) {
        await _statsDao.updateBestStreak(
            evt.playerId, player.dailyMissionsStreak);
      }

      // Transição diária: bumpDaysWithoutFailing + consecutiveActiveDays.
      // Lê stats DEPOIS dos increments pra usar lastActiveDay correto.
      final stats = await _statsDao.findByPlayerId(evt.playerId);
      if (stats != null) {
        final lastActive = stats.lastActiveDay;
        if (lastActive != today) {
          final consecutive = lastActive != null &&
              _isYesterday(today: today, prev: lastActive);
          await _statsDao.updateConsecutiveActiveDays(
            evt.playerId,
            today: today,
            consecutive: consecutive,
          );
          // Bump daysWithoutFailing 1× por dia novo de completed sem fail
          // anterior. Como `incrementFailed` já zera a contagem, basta
          // bumpar aqui — se houve fail hoje, contagem já é 0 e bump
          // recomeça do zero (correto).
          await _statsDao.bumpDaysWithoutFailing(evt.playerId);
        }
      }

      // Pilar balance: marca o dia se 3+ modalidades fecharam.
      if (isPilarBalance) {
        await _statsDao.markPilarBalanceDay(evt.playerId, mission.data);
      }

      // Sprint 3.3 Etapa 2.1b — coordenação com AchievementsService.
      _bus.publish(DailyStatsUpdated(
          playerId: evt.playerId, eventType: 'completed'));
    } catch (e) {
      // ignore: avoid_print
      print('[stats] _onCompleted falhou pra player=${evt.playerId}: $e');
    }
  }

  // ─── helpers ────────────────────────────────────────────────────────

  Future<void> _addVolumeFromMission(DailyMission mission) async {
    for (final sub in mission.subTarefas) {
      if (sub.progressoAtual > 0) {
        await _volumeDao.incrementVolume(
          mission.playerId,
          sub.subTaskKey,
          sub.progressoAtual,
        );
      }
    }
  }

  Future<bool> _detectPilarBalanceDay(
      int playerId, String dayKey) async {
    final missions =
        await _missionsDao.findByPlayerAndDate(playerId, dayKey);
    final modalidades = <MissionCategory>{};
    for (final m in missions) {
      if (m.status == DailyMissionStatus.completed ||
          m.status == DailyMissionStatus.partial) {
        modalidades.add(m.modalidade);
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
  /// `factor` = `progressoAtual / escalaAlvo` por sub-task. Sub-task com
  /// `escalaAlvo == 0` é ignorada no cálculo de média (defesa contra
  /// missões malformadas).
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
      ts.weekday == DateTime.saturday ||
      ts.weekday == DateTime.sunday;

  /// 0 = domingo .. 6 = sábado (alinhado ao bitmask). `DateTime.weekday`
  /// retorna 1=mon..7=sun, então convertemos.
  static int _dayOfWeekZeroIndexed(DateTime ts) {
    return ts.weekday == DateTime.sunday ? 0 : ts.weekday;
  }

  /// `prev` é o dia imediatamente anterior a `today`? Compara só o dia
  /// civil (ambos em formato YYYY-MM-DD). Tolera virada de mês/ano.
  static bool _isYesterday(
      {required String today, required String prev}) {
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
