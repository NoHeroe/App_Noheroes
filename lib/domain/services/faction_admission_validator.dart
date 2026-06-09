import 'package:supabase_flutter/supabase_flutter.dart';

import 'faction_admission_sub_task_types.dart';

/// Sprint 3.4 Etapa B (Sub-Etapa B.1) — descreve UMA sub-task de uma
/// missão de admissão.
///
/// Construída pelo `QuestAdmissionService` (Sub-Etapa B.2) ao
/// desbloquear a missão e persistida em `metaJson` da
/// `MissionProgress`. Validator consome desta estrutura.
class FactionAdmissionSubTask {
  /// Sub-type canônico (ver `FactionAdmissionSubTaskTypes.all`).
  final String subType;

  /// Threshold pra completar.
  final int target;

  /// Timestamp ms epoch — janela móvel começa aqui (= momento em que
  /// a missão de admissão foi desbloqueada). Sub-types `*_window`
  /// usam pra filtrar `completed_at >= windowStartMs`.
  final int windowStartMs;

  /// Rank do player capturado no momento de unlock (D2 do plan-first).
  /// Só usado por sub-types que respeitam snapshot rank
  /// (`params.respect_snapshot_rank == true`).
  final String? snapshotRank;

  /// Params específicos do sub-type:
  /// - `modalidade`: filter pra `daily_count_window` /
  ///   `zero_category_window`
  /// - `respect_snapshot_rank`: bool, opcional
  /// - `baseline_gold_via_quests`: snapshot pra `gold_earned_via_quests`
  ///   (caller passa no momento de unlock)
  final Map<String, dynamic>? params;

  /// Whether sub-task already achieved (set quando validator detecta
  /// completion; persistir em metaJson é responsabilidade do caller —
  /// validator é stateless).
  final bool completed;

  /// Sprint 3.4 Sub-Etapa B.2 hotfix — texto legível pra UI
  /// (ex: "Completar 5 missões mentais em 48h"). Vem do catálogo
  /// `faction_admission_quests_v2.json` campo `label`. Nullable pra
  /// compatibilidade com testes/legacy que constroem sub-tasks
  /// programaticamente sem label. UI usa fallback `subType` cru com
  /// prefixo `[bug:]` quando label é null.
  final String? label;

  const FactionAdmissionSubTask({
    required this.subType,
    required this.target,
    required this.windowStartMs,
    this.snapshotRank,
    this.params,
    this.completed = false,
    this.label,
  });

  Map<String, dynamic> toJson() => {
        'sub_type': subType,
        'target': target,
        'window_start_ms': windowStartMs,
        if (snapshotRank != null) 'snapshot_rank': snapshotRank,
        if (params != null) 'params': params,
        if (completed) 'completed': true,
        if (label != null) 'label': label,
      };

  factory FactionAdmissionSubTask.fromJson(Map<String, dynamic> json) {
    final subType = json['sub_type'];
    if (subType is! String ||
        !FactionAdmissionSubTaskTypes.all.contains(subType)) {
      throw FormatException(
          "FactionAdmissionSubTask.sub_type inválido: $subType");
    }
    final target = json['target'];
    if (target is! int) {
      throw const FormatException("FactionAdmissionSubTask.target ausente");
    }
    final windowStartMs = json['window_start_ms'];
    if (windowStartMs is! int) {
      throw const FormatException(
          "FactionAdmissionSubTask.window_start_ms ausente");
    }
    return FactionAdmissionSubTask(
      subType: subType,
      target: target,
      windowStartMs: windowStartMs,
      snapshotRank: json['snapshot_rank'] as String?,
      params: (json['params'] as Map?)?.cast<String, dynamic>(),
      completed: json['completed'] == true,
      label: json['label'] as String?,
    );
  }
}

/// Resultado de [FactionAdmissionValidator.evaluate]: estado final da
/// sub-task após query no DB.
class SubTaskEvaluation {
  /// Valor atual do contador (depende do sub-type).
  final int current;

  /// Threshold (= `subTask.target`).
  final int target;

  /// `true` se a sub-task atinge a condição de sucesso.
  final bool achieved;

  /// `true` se a sub-task **falhou irrecuperavelmente** (ex.:
  /// `zero_failed_window` viu uma falha; `exact_daily_count_window`
  /// passou do target). Diferenciar de "ainda não atingida":
  /// achieved=false sem failed=true significa "still in progress".
  final bool failed;

  const SubTaskEvaluation({
    required this.current,
    required this.target,
    required this.achieved,
    this.failed = false,
  });
}

/// Sprint 3.4 Etapa B (Sub-Etapa B.1) — validador de sub-tasks de
/// admissão de facção.
///
/// Época 2 (ADR-0024) — full-online Supabase. Service paralelo ao
/// `AchievementsService`. As queries de contagem viram leituras
/// PostgREST com `.count()`; os dois agregados GROUP BY/HAVING
/// (`full_perfect_day_window`, `no_partial_day_window`) viram RPCs
/// (`count_full_perfect_days`, `count_no_partial_days`). Leituras de
/// `players` (streak/gold/rank) via `.from('players')`.
///
/// Validator é **stateless** — não persiste progresso. Caller
/// (Sub-Etapa B.2) re-encoda `metaJson` da missão com o estado novo
/// quando a sub-task transita pra `completed=true` ou `failed=true`.
class FactionAdmissionValidator {
  final SupabaseClient _client;

  FactionAdmissionValidator(this._client);

  /// Upper-bound "infinito" pros agregados RPC, que exigem [win_start,
  /// win_end]. A admissão só tem lower-bound (janela móvel desde unlock),
  /// então passamos um teto bem acima de qualquer timestamp real.
  static const int _farFutureMs = 1 << 62;

  /// Avalia a sub-task contra o estado atual do DB. Retorna
  /// [SubTaskEvaluation] indicando current/target/achieved/failed.
  ///
  /// Sprint 3.4 Etapa C hotfix #1 — `expired` indica que a janela
  /// terminou. Afeta sub-types **não-monotônicos** (`zero_failed_window`,
  /// `zero_category_window`, `no_partial_day_window`): durante a janela
  /// aberta retornam `pending` (achieved=false) mesmo com count=0;
  /// somente na expiração viram `achieved=true` (sucesso confirmado).
  /// Sub-types monotônicos (count crescente) ignoram `expired`.
  Future<SubTaskEvaluation> evaluate({
    required String playerId,
    required FactionAdmissionSubTask subTask,
    bool expired = false,
  }) async {
    switch (subTask.subType) {
      case FactionAdmissionSubTaskTypes.modalityCountWindow:
        return _evalModalityCountWindow(playerId, subTask);
      case FactionAdmissionSubTaskTypes.zeroFailedWindow:
        return _evalZeroFailedWindow(playerId, subTask, expired: expired);
      case FactionAdmissionSubTaskTypes.fullPerfectDayWindow:
        return _evalFullPerfectDayWindow(playerId, subTask);
      case FactionAdmissionSubTaskTypes.individualCompletedWindow:
        return _evalIndividualCompletedWindow(playerId, subTask);
      case FactionAdmissionSubTaskTypes.diaryEntryWindow:
        return _evalDiaryEntryWindow(playerId, subTask);
      case FactionAdmissionSubTaskTypes.zeroCategoryWindow:
        return _evalZeroCategoryWindow(playerId, subTask, expired: expired);
      case FactionAdmissionSubTaskTypes.streakMinimum:
        return _evalStreakMinimum(playerId, subTask);
      case FactionAdmissionSubTaskTypes.goldEarnedViaQuestsWindow:
        return _evalGoldEarnedViaQuestsWindow(playerId, subTask);
      case FactionAdmissionSubTaskTypes.goldBalanceThreshold:
        return _evalGoldBalanceThreshold(playerId, subTask);
      case FactionAdmissionSubTaskTypes.noPartialDayWindow:
        return _evalNoPartialDayWindow(playerId, subTask);
      case FactionAdmissionSubTaskTypes.exactDailyCountWindow:
        return _evalExactDailyCountWindow(playerId, subTask);
      default:
        // Defesa final — construtor já valida via
        // FactionAdmissionSubTaskTypes.all.
        throw StateError('sub-type não mapeado: ${subTask.subType}');
    }
  }

  // ─── implementações por sub-type ──────────────────────────────────

  /// Conta atividades por **pilar** (modalidade) na janela. Hoje
  /// aterriza apenas em `daily_missions`. Filtra por modalidade se
  /// `params.modalidade != null`. Filtra por rank se
  /// `params.respect_snapshot_rank == true`.
  Future<SubTaskEvaluation> _evalModalityCountWindow(
      String playerId, FactionAdmissionSubTask sub) async {
    final modalidade = sub.params?['modalidade'] as String?;
    final respectRank = sub.params?['respect_snapshot_rank'] == true &&
        sub.snapshotRank != null;

    if (respectRank) {
      final guildRank = await _readGuildRank(playerId);
      if (guildRank == null || !_rankAtLeast(guildRank, sub.snapshotRank!)) {
        return SubTaskEvaluation(
            current: 0, target: sub.target, achieved: false);
      }
    }

    var q = _client
        .from('daily_missions')
        .select()
        .eq('player_id', playerId)
        .not('completed_at', 'is', null)
        .gte('completed_at', sub.windowStartMs)
        .inFilter('status', const ['completed', 'partial']);
    if (modalidade != null) {
      q = q.eq('modalidade', modalidade);
    }
    final count = await q.count(CountOption.exact);
    final c = count.count;
    return SubTaskEvaluation(
      current: c,
      target: sub.target,
      achieved: c >= sub.target,
    );
  }

  /// "0 falhas na janela". Falha (count > 0) é IRRECUPERÁVEL na
  /// janela — marcamos `failed=true` pra caller resetar admissão.
  Future<SubTaskEvaluation> _evalZeroFailedWindow(
      String playerId, FactionAdmissionSubTask sub,
      {bool expired = false}) async {
    final res = await _client
        .from('daily_missions')
        .select()
        .eq('player_id', playerId)
        .eq('status', 'failed')
        .gte('completed_at', sub.windowStartMs)
        .count(CountOption.exact);
    final count = res.count;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: expired && count == 0,
      failed: count > 0,
    );
  }

  /// "Existir um dia onde TODAS as 3 dailies do player foram
  /// `completed`". Janela aplica. Agregado GROUP BY/HAVING → RPC.
  Future<SubTaskEvaluation> _evalFullPerfectDayWindow(
      String playerId, FactionAdmissionSubTask sub) async {
    final daysCount = await _client.rpc('count_full_perfect_days', params: {
      'p_player': playerId,
      'p_win_start': sub.windowStartMs,
      'p_win_end': _farFutureMs,
    });
    final count = (daysCount as num?)?.toInt() ?? 0;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  /// "1+ missão individual completada na janela".
  Future<SubTaskEvaluation> _evalIndividualCompletedWindow(
      String playerId, FactionAdmissionSubTask sub) async {
    final res = await _client
        .from('player_mission_progress')
        .select()
        .eq('player_id', playerId)
        .eq('modality', 'individual')
        .not('completed_at', 'is', null)
        .gte('completed_at', sub.windowStartMs)
        .count(CountOption.exact);
    final count = res.count;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  /// "1+ entrada de diário escrita na janela". `diary_entries.entry_date`
  /// é unix seconds (Drift legacy) — convertemos `windowStartMs / 1000`.
  Future<SubTaskEvaluation> _evalDiaryEntryWindow(
      String playerId, FactionAdmissionSubTask sub) async {
    final res = await _client
        .from('diary_entries')
        .select()
        .eq('player_id', playerId)
        .gte('entry_date', sub.windowStartMs ~/ 1000)
        .count(CountOption.exact);
    final count = res.count;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  /// "0 missões de modalidade X completadas na janela" (Trindade
  /// "Jejum"). Falha = qualquer completion da modalidade no período.
  Future<SubTaskEvaluation> _evalZeroCategoryWindow(
      String playerId, FactionAdmissionSubTask sub,
      {bool expired = false}) async {
    final modalidade = sub.params?['modalidade'] as String?;
    if (modalidade == null) {
      throw const FormatException(
          "zeroCategoryWindow exige params.modalidade");
    }
    final res = await _client
        .from('daily_missions')
        .select()
        .eq('player_id', playerId)
        .eq('modalidade', modalidade)
        .eq('status', 'completed')
        .gte('completed_at', sub.windowStartMs)
        .count(CountOption.exact);
    final count = res.count;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: expired && count == 0,
      failed: count > 0,
    );
  }

  /// "Streak de N+ dias". Snapshot do `players.daily_missions_streak`
  /// corrente — sem janela.
  Future<SubTaskEvaluation> _evalStreakMinimum(
      String playerId, FactionAdmissionSubTask sub) async {
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

  /// Delta de `total_gold_earned_via_quests` desde o baseline
  /// capturado no unlock.
  Future<SubTaskEvaluation> _evalGoldEarnedViaQuestsWindow(
      String playerId, FactionAdmissionSubTask sub) async {
    final baseline = (sub.params?['baseline_gold_via_quests'] as int?) ?? 0;
    final row = await _client
        .from('players')
        .select('total_gold_earned_via_quests')
        .eq('id', playerId)
        .maybeSingle();
    final total =
        (row?['total_gold_earned_via_quests'] as num?)?.toInt() ?? 0;
    final current = total - baseline;
    return SubTaskEvaluation(
      current: current.clamp(0, 1 << 30),
      target: sub.target,
      achieved: current >= sub.target,
    );
  }

  /// "100+ gold no inventário em algum momento da janela". Validador
  /// olha `players.gold` corrente.
  Future<SubTaskEvaluation> _evalGoldBalanceThreshold(
      String playerId, FactionAdmissionSubTask sub) async {
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

  /// "1+ dia sem partial completion". Agregado GROUP BY/HAVING → RPC.
  Future<SubTaskEvaluation> _evalNoPartialDayWindow(
      String playerId, FactionAdmissionSubTask sub) async {
    final daysCount = await _client.rpc('count_no_partial_days', params: {
      'p_player': playerId,
      'p_win_start': sub.windowStartMs,
      'p_win_end': _farFutureMs,
    });
    final count = (daysCount as num?)?.toInt() ?? 0;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  /// "EXATAMENTE N dailies na janela". Não-monótono — se passar do
  /// target, marca `failed=true` (Renegado "Caminho Próprio").
  Future<SubTaskEvaluation> _evalExactDailyCountWindow(
      String playerId, FactionAdmissionSubTask sub) async {
    final res = await _client
        .from('daily_missions')
        .select()
        .eq('player_id', playerId)
        .not('completed_at', 'is', null)
        .gte('completed_at', sub.windowStartMs)
        .inFilter('status', const ['completed', 'partial'])
        .count(CountOption.exact);
    final count = res.count;
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count == sub.target,
      failed: count > sub.target,
    );
  }

  // ─── helpers ──────────────────────────────────────────────────────

  Future<String?> _readGuildRank(String playerId) async {
    final row = await _client
        .from('players')
        .select('guild_rank')
        .eq('id', playerId)
        .maybeSingle();
    if (row == null) return null;
    return (row['guild_rank'] as String?) ?? 'none';
  }

  /// Rank order: none < e < d < c < b < a < s. Aceita case
  /// indiferentemente.
  static const Map<String, int> _rankOrder = {
    'none': 0,
    'e': 1,
    'd': 2,
    'c': 3,
    'b': 4,
    'a': 5,
    's': 6,
  };

  /// `current` rank atende o piso `required`?
  bool _rankAtLeast(String current, String required) {
    final c = _rankOrder[current.toLowerCase()] ?? 0;
    final r = _rankOrder[required.toLowerCase()] ?? 0;
    return c >= r;
  }
}
