import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/faction_alliances.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/utils/guild_rank.dart';
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
/// Época 2 (ADR-0024) — full-online Supabase. Análogo ao
/// `DailyResetService`, janela 7 dias. Processa faction weekly missions
/// ativas (tabOrigin == faction) + reassigna via
/// `ensureWeeklyFactionQuest` **só** se `players.faction_type` bate com
/// [kKnownFactions] (D5). O state do player (`last_weekly_reset`,
/// `faction_type`, `guild_rank`, `total_gold_earned_via_quests`) é lido
/// e marcado direto em `players` via PostgREST — `markWeeklyReset` é um
/// single-write `update`.
///
/// Missões partial no weekly NÃO aplicam fórmula 0-300%. Só
/// markFailed(expired) pra missões ativas.
///
/// Erros logados, nunca propagados.
class WeeklyResetService {
  final MissionRepository _missionRepo;
  final MissionAssignmentService _assignment;
  final SupabaseClient _client;
  final AppEventBus _bus;

  /// Janela 7 dias em ms.
  static const int kWeeklyWindowMs = 7 * 24 * 60 * 60 * 1000;

  WeeklyResetService({
    required MissionRepository missionRepo,
    required MissionAssignmentService assignment,
    required SupabaseClient client,
    required AppEventBus bus,
  })  : _missionRepo = missionRepo,
        _assignment = assignment,
        _client = client,
        _bus = bus;

  Future<WeeklyResetResult> checkAndApply(String playerId) async {
    try {
      return await _run(playerId);
    } catch (e) {
      // ignore: avoid_print
      print('[weekly-reset] falha silenciosa: $e');
      return const WeeklyResetResult.noop();
    }
  }

  Future<WeeklyResetResult> _run(String playerId) async {
    final player = await _client
        .from('players')
        .select(
            'faction_type, guild_rank, total_gold_earned_via_quests, last_weekly_reset')
        .eq('id', playerId)
        .maybeSingle();
    if (player == null) return const WeeklyResetResult.noop();

    final now = DateTime.now();
    final lastMs = (player['last_weekly_reset'] as num?)?.toInt();
    if (lastMs != null &&
        (now.millisecondsSinceEpoch - lastMs) < kWeeklyWindowMs) {
      return const WeeklyResetResult.noop();
    }

    // ── Fase 1: expira faction weekly de SEMANAS PASSADAS ───────────
    // FATIA B4 (Fix gatilho-JOIN) — só expira weeklies cuja janela ISO já
    // fechou (`now >= week_end_ms`). metaJson sem `week_end_ms`
    // (legacy/'{}') → expira (comportamento pré-B2a preservado).
    final active = await _missionRepo.findActive(playerId);
    int processed = 0;
    for (final mission in active) {
      if (mission.tabOrigin != MissionTabOrigin.faction) continue;
      if (!_isWeeklyWindowClosed(mission, now)) continue;
      await _markExpired(mission);
      processed++;
    }

    // FATIA B4 (Fix Hip.2) — `markWeeklyReset` é gravado DEPOIS da Fase 2,
    // com guard self-healing: o timestamp só é gravado quando o ciclo
    // fecha de fato.

    // ── Fase 2: reassigna faction weekly se factionType válido ─────
    final factionType = player['faction_type'] as String?;
    final factionId = _validFactionId(factionType);
    if (factionId == null) {
      // ignore: avoid_print
      print('[weekly-reset] factionType="$factionType" não reconhecido — reassign skipado');
      // FATIA B4 (Fix noop-trap) — player SEM facção real: NÃO marca
      // lastWeeklyReset.
      return WeeklyResetResult(applied: false, processed: processed);
    }

    final rank = _rankOf((player['guild_rank'] as String?) ?? 'none');
    // FATIA B2a — baseline de ouro pro sub_task gold_earned_via_quests_window.
    final baselineGold =
        (player['total_gold_earned_via_quests'] as num?)?.toInt() ?? 0;
    final progressId = await _assignment.ensureWeeklyFactionQuest(
      playerId: playerId,
      factionKey: factionId,
      playerRank: rank,
      baselineGoldEarned: baselineGold,
      now: now,
    );
    // Self-healing: só marca o timestamp se o assign de fato criou a
    // missão.
    if (progressId != null) {
      await _markWeeklyReset(playerId, now);
    }
    return WeeklyResetResult(
      applied: true,
      processed: processed,
      reassigned: progressId != null,
    );
  }

  /// Single-write de `players.last_weekly_reset` (ms epoch).
  Future<void> _markWeeklyReset(String playerId, DateTime at) async {
    await _client.from('players').update(
        {'last_weekly_reset': at.millisecondsSinceEpoch}).eq('id', playerId);
  }

  /// FATIA B4 (Fix gatilho-JOIN) — true se a janela ISO da weekly já
  /// fechou (`now >= week_end_ms` do metaJson). metaJson sem
  /// `week_end_ms` (legacy/'{}' ou inválido) → true (expira).
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
    // Sprint 3.4 Etapa F — Lobo Solitário não é facção real.
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
