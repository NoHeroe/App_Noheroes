import '../../data/database/daos/daily_missions_dao.dart';
import '../../data/database/daos/player_dao.dart';
import '../models/daily_mission.dart';
import '../models/daily_mission_status.dart';
import 'daily_mission_progress_service.dart';

/// Sprint 3.2 Etapa 1.2 — fechamento de missões pendentes do dia
/// anterior + atualização de streak.
///
/// Idempotente: usa `lastDailyMissionRollover` (player) pra detectar
/// "primeira abertura do dia". Re-chamadas no mesmo dia são noop.
///
/// Critério de fechamento por missão:
/// - 100% (status=completed) — já fechou normal, ignora.
/// - Sub-tarefas completas ≥ 1: marca **partial** + dispara reward
///   parcial via [DailyMissionProgressService.applyPartialReward].
/// - Sub-tarefas completas = 0: marca **failed**, sem reward.
///
/// Streak (`dailyMissionsStreak`):
/// - Todas as missões do dia anterior fecharam `completed`: +1.
/// - Qualquer `partial`/`failed` no dia anterior: reseta a 0.
/// - Sem missões no dia anterior (jogador novo, app fechado): noop
///   sobre streak (não incrementa nem zera).
class DailyMissionRolloverService {
  final DailyMissionsDao _missionsDao;
  final PlayerDao _playerDao;
  final DailyMissionProgressService _progress;

  DailyMissionRolloverService({
    required DailyMissionsDao missionsDao,
    required PlayerDao playerDao,
    required DailyMissionProgressService progress,
  })  : _missionsDao = missionsDao,
        _playerDao = playerDao,
        _progress = progress;

  Future<void> processRollover(int playerId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final player = await _playerDao.findById(playerId);
    if (player == null) return;

    if (!_isFirstOpenOfTheDay(player.lastDailyMissionRollover, at)) {
      return;
    }

    final todayStr = _dateStr(at);
    final yesterdayStr = _dateStr(at.subtract(const Duration(days: 1)));

    // 1) Fecha pendentes/parciais com data < hoje (não só ontem — pode
    //    ter dia pulado se app ficou fechado).
    final pending =
        await _missionsDao.findPendingBefore(playerId, todayStr);
    for (final m in pending) {
      final completas = m.completedSubCount;
      if (completas >= 1) {
        await _progress.applyPartialReward(
          mission: m,
          subCompletas: completas,
        );
      } else {
        await _progress.markFailed(
          missionId: m.id,
          reason: 'rollover-zero-progress',
        );
      }
    }

    // 2) Streak — usa missões de ONTEM (jurisdição: streak conta dias
    //    consecutivos). Se nem teve missão ontem, mantém streak.
    final yesterday =
        await _missionsDao.findByPlayerAndDate(playerId, yesterdayStr);
    if (yesterday.isNotEmpty) {
      final allFull = yesterday.every(
          (m) => _statusAfterRollover(m) == DailyMissionStatus.completed);
      if (allFull) {
        await _playerDao.incrementDailyMissionsStreak(playerId);
      } else {
        await _playerDao.resetDailyMissionsStreak(playerId);
      }
    }

    // 3) Marca rollover do dia.
    await _playerDao.markDailyMissionRollover(playerId, at);
  }

  /// Visível pra testes — re-uso da regra "primeira abertura do dia".
  bool _isFirstOpenOfTheDay(int? lastMs, DateTime now) {
    if (lastMs == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    return _dateStr(last) != _dateStr(now);
  }

  /// O status do registro pode estar `pending`/`partial` ainda no
  /// momento de ler ontem (porque o passo 1 pode ter acabado de mudar
  /// pra `partial`/`failed`). Retorna o status efetivo pós-rollover.
  DailyMissionStatus _statusAfterRollover(DailyMission m) {
    if (m.status == DailyMissionStatus.completed) {
      return DailyMissionStatus.completed;
    }
    // Se findByPlayerAndDate foi chamado APÓS o passo 1 fechar, status
    // já vem partial/failed. Mantém.
    return m.status;
  }

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
