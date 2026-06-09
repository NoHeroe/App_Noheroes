import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/guild_rank.dart';
import '../../../domain/models/guild_ascension_trial.dart';
import 'player_rank_service.dart';

/// Época 2 (full-online — ADR-0024). Leitura/avanço dos trials do ciclo de
/// ascensão da Guilda contra DADOS VIVOS (PostgREST). Operações ATÔMICAS
/// (materializar ciclo, subir rank + evoluir Colar) vivem em RPCs Postgres —
/// `pay`/`ascend` da máquina de estados chamam `ascension_pay`/
/// `ascension_ascend`, que internamente materializam/ascendem. Este service
/// expõe só leituras + avanço single-row (idempotente) do progresso.
class GuildAscensionService {
  final SupabaseClient _client;
  // A.1 — escrita de rank unificada: ascend() delega a PlayerRankService
  // (RPC set_guild_rank: grava canon MAIÚSCULO + evolui o Colar da Guilda).
  final PlayerRankService _rankService;
  GuildAscensionService(this._client, {PlayerRankService? rankService})
      : _rankService = rankService ?? PlayerRankService(_client);

  /// A.1 — normaliza um rank cru pro canon MAIÚSCULO ('E'..'S'). `none`/
  /// vazio é preservado como sentinela (não casa com nenhum ciclo).
  String _canonRank(String raw) {
    final r = raw.trim();
    if (r.isEmpty || r.toLowerCase() == 'none') return 'none';
    return GuildRankSystem.fromString(r).name.toUpperCase();
  }

  // Retorna todas as missões do ciclo atual (rank_from = guildRank)
  Future<List<GuildAscensionTrial>> getMissions(
      String playerId, String currentRank) async {
    final canon = _canonRank(currentRank);
    final rows = await _client
        .from('guild_ascension_progress')
        .select()
        .eq('player_id', playerId)
        .eq('rank_from', canon)
        .order('step', ascending: true);
    return rows.map(GuildAscensionTrial.fromMap).toList();
  }

  // B.2 — cache do catálogo parseado (rootBundle). O catálogo continua
  // client-side (asset) pra a VIEW/gates; o servidor tem um espelho IMMUTABLE
  // (_ascension_cycle) usado pelas RPCs atômicas.
  List<Map<String, dynamic>>? _cyclesCache;
  Future<List<Map<String, dynamic>>> _loadCycles() async {
    if (_cyclesCache != null) return _cyclesCache!;
    final raw = await rootBundle.loadString('assets/data/guild_ascension.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _cyclesCache =
        (json['ascension'] as List).cast<Map<String, dynamic>>();
  }

  /// B.2 — config tipada do ciclo (gates/fee/janela/cooldown/reward) pro
  /// rank canon. Null se rank S / sem ciclo.
  Future<AscensionCycleConfig?> loadCycleConfig(String rankCanon) async {
    final canon = _canonRank(rankCanon);
    final cycles = await _loadCycles();
    final cycle = cycles.firstWhere(
      (c) => c['rank_from'] == canon,
      orElse: () => const <String, dynamic>{},
    );
    if (cycle.isEmpty) return null;
    return AscensionCycleConfig.fromJson(cycle);
  }

  /// A.2 — avalia a missão de menor `step` incompleta do ciclo via DADOS
  /// VIVOS (sem `ctx`): grava `progress` e marca `completed` ao bater o
  /// target. Retorna true se completou. Single-row update (read-modify-write
  /// de UMA row) → PostgREST direto. NÃO ascende e NÃO incrementa
  /// total_quests_completed.
  Future<bool> checkCurrentMission(
      String playerId, String currentRank) async {
    final canon = _canonRank(currentRank);
    final missions = await getMissions(playerId, canon);
    final current = missions
        .where((m) => !m.completed)
        .fold<GuildAscensionTrial?>(null, (acc, m) {
      if (acc == null) return m;
      return m.step < acc.step ? m : acc;
    });
    if (current == null) return false;

    // B.3 — janela do ciclo (se houver state com janela). Ausente = lifetime.
    final st = await _client
        .from('guild_ascension_state')
        .select('window_started_ms, window_deadline_ms')
        .eq('player_id', playerId)
        .eq('rank_from', canon)
        .maybeSingle();
    final params =
        jsonDecode(current.checkParamsJson) as Map<String, dynamic>;
    final progress = await _calcProgress(
      current.checkType,
      params,
      playerId,
      windowStartMs: (st?['window_started_ms'] as num?)?.toInt(),
      windowDeadlineMs: (st?['window_deadline_ms'] as num?)?.toInt(),
    );

    if (progress >= current.progressTarget) {
      await _client.from('guild_ascension_progress').update({
        'completed': true,
        'progress': current.progressTarget,
      }).eq('id', current.id);
      return true;
    }

    if (progress != current.progress) {
      await _client
          .from('guild_ascension_progress')
          .update({'progress': progress}).eq('id', current.id);
    }
    return false;
  }

  // Verifica se todas missões do ciclo estão completas → pode subir o rank.
  Future<bool> canAscend(String playerId, String currentRank) async {
    final missions = await getMissions(playerId, currentRank);
    if (missions.isEmpty) return false;
    return missions.every((m) => m.completed);
  }

  /// A.1 — sobe o rank (canon → next) + evolui o Colar. Multi-write atômico
  /// delegado a `set_guild_rank` (via PlayerRankService). NOTA: no fluxo
  /// full-online o ascend ATÔMICO completo (reward + rank + status) é a RPC
  /// `ascension_ascend`; este método é mantido como helper de rank puro
  /// (guard canAscend + cálculo do próximo) pra paridade com o legado.
  Future<String?> ascend(String playerId, String currentRank) async {
    final canon = _canonRank(currentRank);
    if (canon == 'none') return null;
    if (!await canAscend(playerId, canon)) return null;
    final next = GuildRankSystem.next(GuildRankSystem.fromString(canon));
    if (next == null) return null; // já é S
    await _rankService.setRank(playerId, next);
    return next.name.toUpperCase();
  }

  /// A.2 — mapeia a `category` do catálogo (inglês) pra grafia REAL da
  /// `daily_missions.modalidade` (PT-BR).
  static const Map<String, String> _categoryToModalidade = {
    'physical': 'fisico',
    'mental': 'mental',
    'spiritual': 'espiritual',
  };

  /// B.3 — UNIÃO de missões completadas (daily_missions + player_mission_
  /// progress), com janela opcional `[startMs, deadlineMs)`. Sem janela =
  /// lifetime. Duas COUNTs read-only via PostgREST (count exato no head).
  Future<int> countMissionsCompleted(String playerId,
      {int? startMs, int? deadlineMs}) async {
    final windowed = startMs != null && deadlineMs != null;

    var dailyQ = _client
        .from('daily_missions')
        .select()
        .eq('player_id', playerId)
        .not('completed_at', 'is', null)
        .eq('status', 'completed');
    if (windowed) {
      dailyQ = dailyQ
          .gte('completed_at', startMs)
          .lt('completed_at', deadlineMs);
    }
    final dailyRes = await dailyQ.count(CountOption.exact);

    var pmpQ = _client
        .from('player_mission_progress')
        .select()
        .eq('player_id', playerId)
        .not('completed_at', 'is', null);
    if (windowed) {
      pmpQ = pmpQ.gte('completed_at', startMs).lt('completed_at', deadlineMs);
    }
    final pmpRes = await pmpQ.count(CountOption.exact);

    return dailyRes.count + pmpRes.count;
  }

  /// Progresso contra DADOS VIVOS por check_type. "Completada" =
  /// `status = 'completed'` (partial NÃO conta).
  Future<int> _calcProgress(
      String checkType, Map<String, dynamic> params, String playerId,
      {int? windowStartMs, int? windowDeadlineMs}) async {
    switch (checkType) {
      case 'complete_any_total':
        final count = params['count'] as int;
        final found = await countMissionsCompleted(playerId,
            startMs: windowStartMs, deadlineMs: windowDeadlineMs);
        return found.clamp(0, count);

      case 'complete_category_total':
        final count = params['count'] as int;
        final cat = params['category'] as String;
        final modalidade = _categoryToModalidade[cat];
        if (modalidade == null) return 0;
        // Categoria só existe em daily_missions.modalidade (pmp não tem pilar).
        var q = _client
            .from('daily_missions')
            .select()
            .eq('player_id', playerId)
            .not('completed_at', 'is', null)
            .eq('status', 'completed')
            .eq('modalidade', modalidade);
        if (windowStartMs != null && windowDeadlineMs != null) {
          q = q
              .gte('completed_at', windowStartMs)
              .lt('completed_at', windowDeadlineMs);
        }
        final res = await q.count(CountOption.exact);
        return res.count.clamp(0, count);

      case 'streak_days':
        final days = params['days'] as int;
        final row = await _client
            .from('players')
            .select('streak_days')
            .eq('id', playerId)
            .maybeSingle();
        final streak = (row?['streak_days'] as num?)?.toInt() ?? 0;
        return streak.clamp(0, days);

      case 'achievements_count':
        final count = params['count'] as int;
        final res = await _client
            .from('player_achievements_completed')
            .select()
            .eq('player_id', playerId)
            .count(CountOption.exact);
        return res.count.clamp(0, count);

      case 'diary_total_words':
        final words = params['words'] as int;
        // SUM de palavras (LENGTH - LENGTH(replace ' ') + 1) não é expressável
        // em PostgREST puro → agrega no cliente lendo o conteúdo das entradas.
        final rows = await _client
            .from('diary_entries')
            .select('content')
            .eq('player_id', playerId);
        var found = 0;
        for (final r in rows) {
          final content = (r['content'] as String?) ?? '';
          final spaces = content.length - content.replaceAll(' ', '').length;
          found += spaces + 1;
        }
        return found.clamp(0, words);

      default:
        return 0;
    }
  }
}

/// B.2 — config tipada de um ciclo de ascensão (lida do guild_ascension.json).
class AscensionCycleConfig {
  final String rankFrom;
  final String rankTo;
  final int minLevel;
  final int missionsCompleted;
  final int goldEarnedLifetime;
  final int cardWins;
  final int feeBase;
  final int windowHours;
  final int cooldownHours;
  final int rewardXp;
  final int rewardGold;
  final int rewardInsignias;
  final List<Map<String, dynamic>> trials;

  const AscensionCycleConfig({
    required this.rankFrom,
    required this.rankTo,
    required this.minLevel,
    required this.missionsCompleted,
    required this.goldEarnedLifetime,
    required this.cardWins,
    required this.feeBase,
    required this.windowHours,
    required this.cooldownHours,
    required this.rewardXp,
    required this.rewardGold,
    required this.rewardInsignias,
    required this.trials,
  });

  factory AscensionCycleConfig.fromJson(Map<String, dynamic> c) {
    final req = (c['unlock_requirements'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final rw = (c['reward'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return AscensionCycleConfig(
      rankFrom: c['rank_from'] as String,
      rankTo: c['rank_to'] as String,
      minLevel: (req['min_level'] as int?) ?? 0,
      missionsCompleted: (req['missions_completed'] as int?) ?? 0,
      goldEarnedLifetime: (req['gold_earned_lifetime'] as int?) ?? 0,
      cardWins: (req['card_wins'] as int?) ?? 0,
      feeBase: (c['fee_base'] as int?) ?? 0,
      windowHours: (c['window_hours'] as int?) ?? 0,
      cooldownHours: (c['cooldown_hours'] as int?) ?? 4,
      rewardXp: (rw['xp'] as int?) ?? 0,
      rewardGold: (rw['gold'] as int?) ?? 0,
      rewardInsignias: (rw['insignias'] as int?) ?? 0,
      trials: (c['trials'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[],
    );
  }
}
