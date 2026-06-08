import 'dart:convert';

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

    // ── Fase 1: expira faction weekly de SEMANAS PASSADAS ───────────
    // FATIA B4 (Fix gatilho-JOIN) — só expira weeklies cuja janela ISO já
    // fechou (`now >= week_end_ms`). Sem este guard, a weekly criada pelo
    // gatilho de JOIN na semana corrente (lastWeeklyReset ainda null)
    // seria expirada no 1º boot do Santuário e a Fase 2 não conseguiria
    // recriá-la (UNIQUE do ledger + nenhuma progress row ativa pra reusar)
    // → player PERDIA a weekly recém-atribuída. Com o guard, a weekly da
    // semana corrente sobrevive e a Fase 2 a reusa idempotentemente.
    // metaJson sem `week_end_ms` (legacy/'{}') → expira (comportamento
    // pré-B2a preservado).
    final active = await _missionRepo.findActive(playerId);
    int processed = 0;
    for (final mission in active) {
      if (mission.tabOrigin != MissionTabOrigin.faction) continue;
      if (!_isWeeklyWindowClosed(mission, now)) continue;
      await _markExpired(mission);
      processed++;
    }

    // FATIA B4 (Fix Hip.2) — `markWeeklyReset` foi MOVIDO pra DEPOIS da
    // Fase 2, com guard self-healing: o timestamp de 7 dias só é gravado
    // quando o ciclo fecha de fato. Antes, marcava aqui (antes do assign)
    // e travava o player por 7d mesmo quando o assign retornava null
    // (rank gating / catálogo), mascarando o fix e re-travando.

    // ── Fase 2: reassigna faction weekly se factionType válido ─────
    final factionId = _validFactionId(player.factionType);
    if (factionId == null) {
      // ignore: avoid_print
      print('[weekly-reset] factionType="${player.factionType}" não reconhecido — reassign skipado');
      // FATIA B4 (Fix noop-trap) — player SEM facção real: NÃO marca
      // lastWeeklyReset. Marcar aqui (premissa antiga: "entrar na facção
      // dispara o reset por outro caminho") travava por 7d quem entrava
      // numa facção DEPOIS — o boot seguinte caía no noop (<7d) antes de
      // chegar na Fase 2. A premissa era FALSA: nada no JOIN disparava o
      // reset cíclico. Sem marca → re-tenta todo boot; quando o player
      // entra numa facção, o próximo boot atribui (e o gatilho no JOIN
      // atribui na hora). Re-rodar a Fase 1 sem facção é no-op (não há
      // faction weekly ativa pra expirar).
      return WeeklyResetResult(applied: false, processed: processed);
    }

    final rank = _rankOf(player.guildRank);
    // FATIA B2a — baseline de ouro pro sub_task gold_earned_via_quests_window
    // (o validator B1 subtrai esse snapshot do total corrente).
    final progressId = await _assignment.ensureWeeklyFactionQuest(
      playerId: playerId,
      factionKey: factionId,
      playerRank: rank,
      baselineGoldEarned: player.totalGoldEarnedViaQuests,
      now: now,
    );
    // Self-healing: só marca o timestamp se o assign de fato criou a
    // missão. Se `progressId == null` (assign falhou por algum motivo),
    // NÃO marca → re-tenta no próximo boot (destrava quem já travou).
    if (progressId != null) {
      await _playerDao.markWeeklyReset(playerId, now);
    }
    return WeeklyResetResult(
      applied: true,
      processed: processed,
      reassigned: progressId != null,
    );
  }

  /// FATIA B4 (Fix gatilho-JOIN) — true se a janela ISO da weekly já
  /// fechou (`now >= week_end_ms` do metaJson). metaJson sem
  /// `week_end_ms` (legacy/'{}' ou inválido) → true (expira, preserva o
  /// comportamento pré-B2a de varrer faction weekly antigas).
  bool _isWeeklyWindowClosed(MissionProgress mission, DateTime now) {
    try {
      final meta = jsonDecode(mission.metaJson);
      if (meta is Map) {
        final endMs = meta['week_end_ms'];
        if (endMs is int) return now.millisecondsSinceEpoch >= endMs;
      }
    } catch (_) {
      // metaJson inválido → trata como legacy (expira).
    }
    return true;
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
    // Sprint 3.4 Etapa F — Lobo Solitário não é facção real: sem missões
    // de facção. Early-return explícito (silencia warning de "não-listada").
    if (raw == 'lone_wolf') return null;
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
