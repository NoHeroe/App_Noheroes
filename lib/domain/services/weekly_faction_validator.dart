import 'package:supabase_flutter/supabase_flutter.dart';

import 'faction_admission_validator.dart' show SubTaskEvaluation;

/// FATIA B1 — strings canônicas dos sub-types do motor SEMANAL de
/// facção. Espelham os sub-types acumulativos da admissão, **sem** o
/// prefixo `admission_` (são tipos do motor semanal; mapeiam pras
/// mesmas primitivas SQL).
///
/// Diferenças vs admissão:
/// - **Acumulativo**: `achieved = current >= target` sempre. Nunca
///   `failed`, nunca `expired`-gating.
/// - **Janela limitada**: `[weekStartMs, weekEndMs)` — o progresso NÃO
///   vaza pra semana seguinte (admissão só tem lower-bound).
///
/// Os 3 eliminatórios da admissão (`zero_failed`, `zero_category`,
/// `exact_daily_count`) NÃO existem aqui — não são acumulativos.
abstract class WeeklyFactionSubTaskTypes {
  WeeklyFactionSubTaskTypes._();

  /// "N missões de modalidade X na semana" (sem `params.modalidade` =
  /// qualquer modalidade). Conta `daily_missions` com status
  /// completed/partial.
  static const String modalityCountWindow = 'modality_count_window';

  /// "Streak de N+ dias" — snapshot de `players.daily_missions_streak`
  /// (sem janela).
  static const String streakMinimum = 'streak_minimum';

  /// "Acumular X+ ouro via quests na semana" —
  /// `players.total_gold_earned_via_quests - baseline` (baseline gravado
  /// no assign via `params.baseline_gold_via_quests`).
  static const String goldEarnedViaQuestsWindow =
      'gold_earned_via_quests_window';

  /// "Ter X+ gold no inventário em algum momento da semana" — snapshot
  /// de `players.gold`.
  static const String goldBalanceThreshold = 'gold_balance_threshold';

  /// "N+ missões individuais completadas na semana".
  static const String individualCompletedWindow =
      'individual_completed_window';

  /// "N+ entradas de diário na semana".
  static const String diaryEntryWindow = 'diary_entry_window';

  /// "N dias com 100% das dailies (3/3 completed) na semana".
  static const String fullPerfectDayWindow = 'full_perfect_day_window';

  /// "N dias sem partial completion na semana".
  static const String noPartialDayWindow = 'no_partial_day_window';

  /// FATIA B1 — sub-type NOVO (não existe na admissão). Conta itens
  /// forjados/encantados via contador incremental em metaJson — NÃO
  /// querya o DB. O listener (B2) incrementa `current` a cada
  /// `ItemCrafted`/`ItemEnchanted`. Aqui só comparamos `current` ao
  /// target.
  static const String equipmentImproved = 'equipment_improved';

  static const Set<String> all = {
    modalityCountWindow,
    streakMinimum,
    goldEarnedViaQuestsWindow,
    goldBalanceThreshold,
    individualCompletedWindow,
    diaryEntryWindow,
    fullPerfectDayWindow,
    noPartialDayWindow,
    equipmentImproved,
  };
}

/// FATIA B1 — uma sub-task do motor semanal. Construída a partir do
/// catálogo `missions_faction_weekly.json` (B1) e re-hidratada do
/// `metaJson` da `MissionProgress` pelo listener semanal (B2).
class WeeklyFactionSubTask {
  /// Sub-type canônico (ver [WeeklyFactionSubTaskTypes.all]).
  final String subType;

  /// Threshold pra completar.
  final int target;

  /// Params específicos do sub-type:
  /// - `modalidade`: filtro pra `modality_count_window`.
  /// - `baseline_gold_via_quests`: snapshot pra
  ///   `gold_earned_via_quests_window` (gravado no assign — B2).
  final Map<String, dynamic>? params;

  /// Texto legível pra UI (vem do catálogo).
  final String? label;

  /// Contador corrente — usado APENAS por `equipment_improved` (que não
  /// querya o DB). Alimentado pelo listener (B2) em metaJson. Para os
  /// sub-types de janela, é ignorado (o validator calcula `current`
  /// direto do banco).
  final int current;

  /// Whether a sub-task já foi marcada como completa (persistido em
  /// metaJson pelo listener). O validator não usa — quem decide é o
  /// caller —, mas faz parte do roundtrip JSON.
  final bool completed;

  const WeeklyFactionSubTask({
    required this.subType,
    required this.target,
    this.params,
    this.label,
    this.current = 0,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'sub_type': subType,
        'target': target,
        if (params != null) 'params': params,
        if (label != null) 'label': label,
        'current': current,
        if (completed) 'completed': true,
      };

  factory WeeklyFactionSubTask.fromJson(Map<String, dynamic> json) {
    final subType = json['sub_type'];
    if (subType is! String ||
        !WeeklyFactionSubTaskTypes.all.contains(subType)) {
      throw FormatException(
          "WeeklyFactionSubTask.sub_type inválido: $subType");
    }
    final target = json['target'];
    if (target is! int) {
      throw const FormatException("WeeklyFactionSubTask.target ausente");
    }
    return WeeklyFactionSubTask(
      subType: subType,
      target: target,
      params: (json['params'] as Map?)?.cast<String, dynamic>(),
      label: json['label'] as String?,
      current: (json['current'] as int?) ?? 0,
      completed: json['completed'] == true,
    );
  }
}

/// FATIA B1 — validador acumulativo do motor SEMANAL de facção.
///
/// Época 2 (ADR-0024) — full-online Supabase. Stateless (igual ao
/// `FactionAdmissionValidator`): consulta o DB via PostgREST/RPC e
/// retorna [SubTaskEvaluation] sem persistir. O caller (listener B2)
/// re-encoda o metaJson da missão quando a sub-task vira `completed`.
///
/// `achieved = current >= target` **sempre** — sem `failed`, sem
/// `expired`-gating. A janela é **limitada** a `[weekStartMs, weekEndMs)`.
class WeeklyFactionValidator {
  final SupabaseClient _client;

  WeeklyFactionValidator(this._client);

  /// Avalia a sub-task contra o estado do DB dentro da janela semanal.
  Future<SubTaskEvaluation> evaluate({
    required String playerId,
    required WeeklyFactionSubTask subTask,
    required int weekStartMs,
    required int weekEndMs,
  }) async {
    switch (subTask.subType) {
      case WeeklyFactionSubTaskTypes.modalityCountWindow:
        return _modalityCountWindow(playerId, subTask, weekStartMs, weekEndMs);
      case WeeklyFactionSubTaskTypes.streakMinimum:
        return _streakMinimum(playerId, subTask);
      case WeeklyFactionSubTaskTypes.goldEarnedViaQuestsWindow:
        return _goldEarnedViaQuests(playerId, subTask);
      case WeeklyFactionSubTaskTypes.goldBalanceThreshold:
        return _goldBalanceThreshold(playerId, subTask);
      case WeeklyFactionSubTaskTypes.individualCompletedWindow:
        return _individualCompleted(playerId, subTask, weekStartMs, weekEndMs);
      case WeeklyFactionSubTaskTypes.diaryEntryWindow:
        return _diaryEntry(playerId, subTask, weekStartMs, weekEndMs);
      case WeeklyFactionSubTaskTypes.fullPerfectDayWindow:
        return _fullPerfectDay(playerId, subTask, weekStartMs, weekEndMs);
      case WeeklyFactionSubTaskTypes.noPartialDayWindow:
        return _noPartialDay(playerId, subTask, weekStartMs, weekEndMs);
      case WeeklyFactionSubTaskTypes.equipmentImproved:
        return _equipmentImproved(subTask);
      default:
        throw StateError('sub-type não mapeado: ${subTask.subType}');
    }
  }

  // ─── implementações por sub-type ──────────────────────────────────
  //
  // ESPELHO de FactionAdmissionValidator — a diferença estrutural é o
  // **upper-bound** `completed_at < weekEndMs` (admissão só tem
  // lower-bound) e a semântica sempre acumulativa.

  Future<SubTaskEvaluation> _modalityCountWindow(String playerId,
      WeeklyFactionSubTask sub, int weekStartMs, int weekEndMs) async {
    final modalidade = sub.params?['modalidade'] as String?;
    var q = _client
        .from('daily_missions')
        .select()
        .eq('player_id', playerId)
        .not('completed_at', 'is', null)
        .gte('completed_at', weekStartMs)
        .lt('completed_at', weekEndMs)
        .inFilter('status', const ['completed', 'partial']);
    if (modalidade != null) {
      q = q.eq('modalidade', modalidade);
    }
    final res = await q.count(CountOption.exact);
    final count = res.count;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  Future<SubTaskEvaluation> _streakMinimum(
      String playerId, WeeklyFactionSubTask sub) async {
    final row = await _client
        .from('players')
        .select('daily_missions_streak')
        .eq('id', playerId)
        .maybeSingle();
    final streak = (row?['daily_missions_streak'] as num?)?.toInt() ?? 0;
    return SubTaskEvaluation(
      current: streak,
      target: sub.target,
      achieved: streak >= sub.target,
    );
  }

  Future<SubTaskEvaluation> _goldEarnedViaQuests(
      String playerId, WeeklyFactionSubTask sub) async {
    final baseline = (sub.params?['baseline_gold_via_quests'] as int?) ?? 0;
    final row = await _client
        .from('players')
        .select('total_gold_earned_via_quests')
        .eq('id', playerId)
        .maybeSingle();
    final total =
        (row?['total_gold_earned_via_quests'] as num?)?.toInt() ?? 0;
    final current = total - baseline;
    final clamped = current.clamp(0, 1 << 30);
    return SubTaskEvaluation(
      current: clamped,
      target: sub.target,
      achieved: clamped >= sub.target,
    );
  }

  Future<SubTaskEvaluation> _goldBalanceThreshold(
      String playerId, WeeklyFactionSubTask sub) async {
    final row = await _client
        .from('players')
        .select('gold')
        .eq('id', playerId)
        .maybeSingle();
    final gold = (row?['gold'] as num?)?.toInt() ?? 0;
    return SubTaskEvaluation(
      current: gold,
      target: sub.target,
      achieved: gold >= sub.target,
    );
  }

  Future<SubTaskEvaluation> _individualCompleted(String playerId,
      WeeklyFactionSubTask sub, int weekStartMs, int weekEndMs) async {
    final res = await _client
        .from('player_mission_progress')
        .select()
        .eq('player_id', playerId)
        .eq('modality', 'individual')
        .not('completed_at', 'is', null)
        .gte('completed_at', weekStartMs)
        .lt('completed_at', weekEndMs)
        .count(CountOption.exact);
    final count = res.count;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  Future<SubTaskEvaluation> _diaryEntry(String playerId,
      WeeklyFactionSubTask sub, int weekStartMs, int weekEndMs) async {
    // diary_entries.entry_date é unix SECONDS (Drift legacy) — converte
    // os bounds de ms pra segundos.
    final res = await _client
        .from('diary_entries')
        .select()
        .eq('player_id', playerId)
        .gte('entry_date', weekStartMs ~/ 1000)
        .lt('entry_date', weekEndMs ~/ 1000)
        .count(CountOption.exact);
    final count = res.count;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  Future<SubTaskEvaluation> _fullPerfectDay(String playerId,
      WeeklyFactionSubTask sub, int weekStartMs, int weekEndMs) async {
    // RPC usa created_at e bounds inclusivos [start, end]; passamos
    // weekEndMs-1 pra aproximar o upper-bound exclusivo do Dart.
    final daysCount = await _client.rpc('count_full_perfect_days', params: {
      'p_player': playerId,
      'p_win_start': weekStartMs,
      'p_win_end': weekEndMs - 1,
    });
    final count = (daysCount as num?)?.toInt() ?? 0;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  Future<SubTaskEvaluation> _noPartialDay(String playerId,
      WeeklyFactionSubTask sub, int weekStartMs, int weekEndMs) async {
    final daysCount = await _client.rpc('count_no_partial_days', params: {
      'p_player': playerId,
      'p_win_start': weekStartMs,
      'p_win_end': weekEndMs - 1,
    });
    final count = (daysCount as num?)?.toInt() ?? 0;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  /// FATIA B1 — `equipment_improved` NÃO querya o DB. Lê o contador
  /// `current` do próprio subTask (alimentado pelo listener em B2 via
  /// metaJson a cada `ItemCrafted`/`ItemEnchanted`).
  SubTaskEvaluation _equipmentImproved(WeeklyFactionSubTask sub) {
    return SubTaskEvaluation(
      current: sub.current,
      target: sub.target,
      achieved: sub.current >= sub.target,
    );
  }
}
