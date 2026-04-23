import '../../core/config/faction_alliances.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/utils/guild_rank.dart';
import '../../data/database/daos/player_dao.dart';
import '../enums/mission_tab_origin.dart';
import '../models/mission_progress.dart';
import '../repositories/mission_repository.dart';
import 'mission_assignment_service.dart';

class WeeklyResetResult {
  final bool applied;
  final int processed;
  final bool reassigned;
  const WeeklyResetResult({
    required this.applied,
    this.processed = 0,
    this.reassigned = false,
  });

  const WeeklyResetResult.noop() : this(applied: false);
}

/// Sprint 3.1 Bloco 13b — boot-check de reset semanal.
///
/// Análogo ao `DailyResetService`, janela 7 dias. Processa faction
/// weekly missions ativas (tabOrigin == faction) + reassigna via
/// `ensureWeeklyFactionQuest` **só** se `players.faction_type` bate com
/// [kKnownFactions] (D5): valores `null`, `none`, `pending:X` ou strings
/// não-listadas → log warning + skip silencioso.
///
/// Missões partial no weekly NÃO aplicam fórmula 0-300% (missões de
/// facção são marcadas ou como completed pelo próprio jogador durante
/// a semana, ou falham inteiras quando a semana vira). Decisão: só
/// markFailed(expired) pra missões ativas. Partial = mesmo pattern do
/// Daily se a 2ª decisão de produto mudar no futuro.
///
/// Erros logados, nunca propagados.
class WeeklyResetService {
  final MissionRepository _missionRepo;
  final MissionAssignmentService _assignment;
  final PlayerDao _playerDao;
  final AppEventBus _bus;

  /// Janela 7 dias em ms.
  static const int kWeeklyWindowMs = 7 * 24 * 60 * 60 * 1000;

  WeeklyResetService({
    required MissionRepository missionRepo,
    required MissionAssignmentService assignment,
    required PlayerDao playerDao,
    required AppEventBus bus,
  })  : _missionRepo = missionRepo,
        _assignment = assignment,
        _playerDao = playerDao,
        _bus = bus;

  Future<WeeklyResetResult> checkAndApply(int playerId) async {
    try {
      return await _run(playerId);
    } catch (e) {
      // ignore: avoid_print
      print('[weekly-reset] falha silenciosa: $e');
      return const WeeklyResetResult.noop();
    }
  }

  Future<WeeklyResetResult> _run(int playerId) async {
    final player = await _playerDao.findById(playerId);
    if (player == null) return const WeeklyResetResult.noop();

    final now = DateTime.now();
    final lastMs = player.lastWeeklyReset;
    if (lastMs != null && (now.millisecondsSinceEpoch - lastMs) < kWeeklyWindowMs) {
      return const WeeklyResetResult.noop();
    }

    // ── Fase 1: processa faction weekly ativas ──────────────────────
    final active = await _missionRepo.findActive(playerId);
    int processed = 0;
    for (final mission in active) {
      if (mission.tabOrigin != MissionTabOrigin.faction) continue;
      await _markExpired(mission);
      processed++;
    }

    await _playerDao.markWeeklyReset(playerId, now);

    // ── Fase 2: reassigna faction weekly se factionType válido ─────
    final factionId = _validFactionId(player.factionType);
    if (factionId == null) {
      // ignore: avoid_print
      print('[weekly-reset] factionType="${player.factionType}" não reconhecido — reassign skipado');
      return WeeklyResetResult(applied: true, processed: processed);
    }

    final rank = _rankOf(player.guildRank);
    final progressId = await _assignment.ensureWeeklyFactionQuest(
      playerId: playerId,
      factionKey: factionId,
      playerRank: rank,
      now: now,
    );
    return WeeklyResetResult(
      applied: true,
      processed: processed,
      reassigned: progressId != null,
    );
  }

  Future<void> _markExpired(MissionProgress mission) async {
    await _missionRepo.markFailed(mission.id, at: DateTime.now());
    _bus.publish(MissionFailed(
      missionKey: mission.missionKey,
      playerId: mission.playerId,
      reason: MissionFailureReason.expired,
    ));
  }

  /// D5 — valida `factionType` contra [kKnownFactions]. Retorna null se
  /// `null`, vazio, `none`, `pending:X` ou string não-listada.
  String? _validFactionId(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'none') return null;
    if (raw.startsWith('pending:')) return null;
    if (!kKnownFactions.contains(raw)) return null;
    return raw;
  }

  GuildRank _rankOf(String guildRankColumn) {
    final raw = guildRankColumn.toLowerCase();
    return GuildRank.values.firstWhere(
      (r) => r.name == raw,
      orElse: () => GuildRank.e,
    );
  }
}
