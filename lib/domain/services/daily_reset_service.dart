import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/utils/guild_rank.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/player_dao.dart';
import '../enums/mission_tab_origin.dart';
import '../models/mission_progress.dart';
import '../models/player_snapshot.dart';
import '../repositories/mission_repository.dart';
import 'mission_assignment_service.dart';
import 'reward_resolve_service.dart';
import '../../data/services/reward_grant_service.dart';

/// Sumário do reset — caller (sanctuary boot) pode ignorar.
class DailyResetResult {
  final bool applied;
  final int processed;
  final int reassignedDaily;
  final int reassignedClass;
  const DailyResetResult({
    required this.applied,
    this.processed = 0,
    this.reassignedDaily = 0,
    this.reassignedClass = 0,
  });

  const DailyResetResult.noop() : this(applied: false);
}

/// Sprint 3.1 Bloco 13b — boot-check de reset diário.
///
/// Pattern:
///   - `checkAndApply(playerId)` é chamado no boot do sanctuary
///   - Se `now - last_daily_reset < 24h` → noop silencioso
///   - Se `≥ 24h` → processa state + reassigna + `markDailyReset(now)`
///
/// ## Decomposição em 2 fases (evita aninhamento de transação)
///
/// Fase 1 (transação atômica no DailyResetService):
///   1. Lê active daily missions (completedAt IS NULL AND failedAt IS NULL)
///   2. Pra cada: se ≥25% → marca partial (via RewardResolveService +
///      RewardGrantService, que usam sua própria transação interna —
///      ok por serem chamadas fora do `_db.transaction` do Daily) |
///      senão → markFailed(expired) emit MissionFailed
///   3. Sweep expired (`metaJson["deadline_at"] < now`) → markFailed
///   4. `markDailyReset(now)` persistence
///
/// Fase 2 (pós-transação):
///   5. `assignDailyForPlayer` — inserts individuais sem nested tx
///   6. `assignClassDaily` — idem; early-return silencioso se classType
///      é null (Bloco 13b fix)
///
/// **Nota de aninhamento**: `RewardGrantService.grant` abre sua própria
/// `db.transaction` — se chamado dentro do `_db.transaction` do Daily,
/// Drift detecta e usa a outer. Comportamento aceito. Partial reward
/// usa fórmula 0-300% do ADR 0013 (zero código novo no DailyReset).
///
/// Erros logados, nunca propagados — boot não pode falhar por bug aqui.
class DailyResetService {
  final AppDatabase _db;
  final MissionRepository _missionRepo;
  final RewardResolveService _resolver;
  final RewardGrantService _granter;
  final MissionAssignmentService _assignment;
  final PlayerDao _playerDao;
  final AppEventBus _bus;

  /// Threshold partial — missões com progresso ≥ 25% viram partial
  /// com reward proporcional (fórmula 0-300% do ADR 0013). Alinhado
  /// com DESIGN_DOC §8 regras de conclusão.
  static const double kPartialThreshold = 0.25;

  /// Janela em ms. Reset só aplica se `now - last_reset >= kDailyWindowMs`.
  static const int kDailyWindowMs = 24 * 60 * 60 * 1000;

  DailyResetService({
    required AppDatabase db,
    required MissionRepository missionRepo,
    required RewardResolveService resolver,
    required RewardGrantService granter,
    required MissionAssignmentService assignment,
    required PlayerDao playerDao,
    required AppEventBus bus,
  })  : _db = db,
        _missionRepo = missionRepo,
        _resolver = resolver,
        _granter = granter,
        _assignment = assignment,
        _playerDao = playerDao,
        _bus = bus;

  Future<DailyResetResult> checkAndApply(int playerId) async {
    try {
      return await _run(playerId);
    } catch (e) {
      // ignore: avoid_print
      print('[daily-reset] falha silenciosa: $e');
      return const DailyResetResult.noop();
    }
  }

  Future<DailyResetResult> _run(int playerId) async {
    final player = await _playerDao.findById(playerId);
    if (player == null) return const DailyResetResult.noop();

    final now = DateTime.now();
    final lastMs = player.lastDailyReset;
    if (lastMs != null && (now.millisecondsSinceEpoch - lastMs) < kDailyWindowMs) {
      return const DailyResetResult.noop();
    }

    // ── Fase 1: processa state existente ────────────────────────────
    final active = await _missionRepo.findActive(playerId);
    int processed = 0;
    for (final mission in active) {
      if (mission.tabOrigin == MissionTabOrigin.daily) {
        await _processDaily(mission);
        processed++;
      }
      // Sweep expired aplica a QUALQUER modalidade (individual, mixed, etc.)
      // que tenha deadline_at definido.
      final deadline = _deadlineOf(mission);
      if (deadline != null && deadline.isBefore(now)) {
        // Se já processou como partial acima, pulou — senão marca failed.
        final updated = await _missionRepo.findById(mission.id);
        if (updated?.completedAt == null && updated?.failedAt == null) {
          await _markExpired(mission);
          processed++;
        }
      }
    }

    await _playerDao.markDailyReset(playerId, now);

    // ── Fase 2: reassign ────────────────────────────────────────────
    final rank = _rankOf(player.guildRank);
    final newDaily = await _assignment.assignDailyForPlayer(
      playerId: playerId,
      playerRank: rank,
    );
    final newClass = await _assignment.assignClassDaily(
      playerId: playerId,
      classKey: player.classType,
      playerRank: rank,
    );

    return DailyResetResult(
      applied: true,
      processed: processed,
      reassignedDaily: newDaily.length,
      reassignedClass: newClass.length,
    );
  }

  Future<void> _processDaily(MissionProgress mission) async {
    final pct = mission.targetValue == 0
        ? 0.0
        : mission.currentValue / mission.targetValue;
    if (pct >= kPartialThreshold) {
      await _markPartial(mission, pct);
    } else {
      await _markExpired(mission);
    }
  }

  Future<void> _markPartial(MissionProgress mission, double pct) async {
    final progressPct = (pct * 100).clamp(0, 100).round();
    final snapshot = PlayerSnapshot(
      level: 1, // partial usa reward proporcional; level não afeta
      rank: mission.rank,
    );
    try {
      final resolved = await _resolver.resolve(
        mission.reward,
        snapshot,
        progressPct: progressPct,
      );
      await _granter.grant(
        missionProgressId: mission.id,
        playerId: mission.playerId,
        resolved: resolved,
      );
      // Marker pra UI diferenciar partial (Bloco 14+ pode mostrar badge).
      await _updateMetaPartial(mission);
      _bus.publish(MissionPartial(
        missionKey: mission.missionKey,
        playerId: mission.playerId,
        progressPct: progressPct,
        rewardResolvedJson: resolved.toJsonString(),
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[daily-reset] partial grant falhou pra ${mission.missionKey}: $e');
    }
  }

  Future<void> _markExpired(MissionProgress mission) async {
    await _missionRepo.markFailed(mission.id, at: DateTime.now());
    _bus.publish(MissionFailed(
      missionKey: mission.missionKey,
      playerId: mission.playerId,
      reason: MissionFailureReason.expired,
    ));
  }

  /// Adiciona `{"partial": true}` ao metaJson da missão. Não sobrescreve
  /// chaves existentes.
  Future<void> _updateMetaPartial(MissionProgress mission) async {
    try {
      final raw = mission.metaJson;
      final meta = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
      meta['partial'] = true;
      await _db.customUpdate(
        'UPDATE player_mission_progress SET meta_json = ? WHERE id = ?',
        variables: [Variable.withString(jsonEncode(meta)), Variable.withInt(mission.id)],
        updates: {_db.playerMissionProgressTable},
      );
    } catch (_) {
      // metaJson corrompida é edge irrecuperável; ignora partial marker.
    }
  }

  DateTime? _deadlineOf(MissionProgress mission) {
    try {
      final raw = mission.metaJson;
      if (raw.isEmpty) return null;
      final meta = jsonDecode(raw);
      if (meta is! Map<String, dynamic>) return null;
      final ms = meta['deadline_at'];
      if (ms is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  GuildRank _rankOf(String guildRankColumn) {
    final raw = guildRankColumn.toLowerCase();
    return GuildRank.values.firstWhere(
      (r) => r.name == raw,
      orElse: () => GuildRank.e,
    );
  }
}
