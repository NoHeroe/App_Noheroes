import 'package:drift/drift.dart' show Variable;

import '../../data/database/app_database.dart';
import '../../data/database/daos/player_dao.dart';
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
/// Service paralelo ao `AchievementsService` — NÃO reusado porque os
/// triggers de conquista são all-time monotônicos e admissão precisa
/// de **janela móvel desde unlock**.
///
/// ## Uso
///
/// ```dart
/// final validator = FactionAdmissionValidator(db);
/// final eval = await validator.evaluate(playerId: 1, subTask: subTask);
/// if (eval.achieved) { ... }
/// if (eval.failed) { ... reset cooldown ... }
/// ```
///
/// Validator é **stateless** — não persiste progresso. Caller
/// (Sub-Etapa B.2) re-encoda `metaJson` da missão com o estado novo
/// quando a sub-task transita pra `completed=true` ou `failed=true`.
class FactionAdmissionValidator {
  final AppDatabase _db;

  FactionAdmissionValidator(this._db);

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
    required int playerId,
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

  /// Sprint 3.4 Sub-Etapa B.2 hotfix #2 — renomeado de
  /// `_evalDailyCountWindow`. Conta atividades por **pilar** (modalidade)
  /// na janela. Hoje aterriza apenas em `daily_missions` (cap por
  /// throughput de 3 dailies/dia). Sprint futura expande UNION com
  /// `player_mission_progress` (individuais/classe/extras) quando D1
  /// for endereçada (ver dívidas_pos_sprint_3.4.md).
  ///
  /// Filtra por modalidade se `params.modalidade != null`. Filtra por
  /// rank se `params.respect_snapshot_rank == true` (verifica
  /// `player.guildRank` corrente >= `snapshotRank`).
  Future<SubTaskEvaluation> _evalModalityCountWindow(
      int playerId, FactionAdmissionSubTask sub) async {
    final modalidade = sub.params?['modalidade'] as String?;
    final respectRank =
        sub.params?['respect_snapshot_rank'] == true && sub.snapshotRank != null;

    if (respectRank) {
      // Snapshot rank check: descarta sub-task se player rank atual
      // < snapshot. Decisão D2: snapshot foi capturado no unlock; se
      // player desceu rank por algum motivo (não acontece no MVP),
      // sub-task simplesmente fica não-validável.
      final player = await PlayerDao(_db).findById(playerId);
      if (player == null ||
          !_rankAtLeast(player.guildRank, sub.snapshotRank!)) {
        return SubTaskEvaluation(
            current: 0, target: sub.target, achieved: false);
      }
    }

    final whereClauses = <String>[
      'player_id = ?',
      'completed_at IS NOT NULL',
      'completed_at >= ?',
      "status IN ('completed', 'partial')",
    ];
    final variables = <Variable>[
      Variable.withInt(playerId),
      Variable.withInt(sub.windowStartMs),
    ];

    if (modalidade != null) {
      whereClauses.add('modalidade = ?');
      variables.add(Variable.withString(modalidade));
    }

    final rows = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM daily_missions '
      'WHERE ${whereClauses.join(' AND ')}',
      variables: variables,
    ).get();
    final count = rows.first.read<int>('c');
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  /// "0 falhas na janela". Falha (count > 0) é IRRECUPERÁVEL na
  /// janela — marcamos `failed=true` pra caller resetar admissão.
  Future<SubTaskEvaluation> _evalZeroFailedWindow(
      int playerId, FactionAdmissionSubTask sub,
      {bool expired = false}) async {
    final rows = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM daily_missions "
      "WHERE player_id = ? AND status = 'failed' "
      "AND completed_at >= ?",
      variables: [
        Variable.withInt(playerId),
        Variable.withInt(sub.windowStartMs),
      ],
    ).get();
    final count = rows.first.read<int>('c');
    // Sprint 3.4 Etapa C hotfix #1 — não-monotônico. Durante janela
    // aberta com count=0: pending (não pode declarar sucesso porque
    // ainda pode falhar). Só vira `achieved=true` quando janela expira
    // sem falhas (`expired=true && count==0`). Falha continua
    // irrecuperável: `count > 0` → failed sempre.
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: expired && count == 0,
      failed: count > 0,
    );
  }

  /// "Existir um dia onde TODAS as 3 dailies do player foram
  /// `completed`". Janela aplica.
  Future<SubTaskEvaluation> _evalFullPerfectDayWindow(
      int playerId, FactionAdmissionSubTask sub) async {
    // Para cada `data` de daily na janela: contar quantas tem status
    // != 'completed'. Se algum dia tem 3 completed e 0 não-completed,
    // achievement.
    final rows = await _db.customSelect(
      "SELECT data, "
      " SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS done, "
      " COUNT(*) AS total "
      "FROM daily_missions "
      "WHERE player_id = ? AND completed_at >= ? "
      "GROUP BY data "
      "HAVING done = 3 AND total = 3",
      variables: [
        Variable.withInt(playerId),
        Variable.withInt(sub.windowStartMs),
      ],
    ).get();
    final daysCount = rows.length;
    return SubTaskEvaluation(
      current: daysCount,
      target: sub.target,
      achieved: daysCount >= sub.target,
    );
  }

  /// "1+ missão individual completada na janela".
  Future<SubTaskEvaluation> _evalIndividualCompletedWindow(
      int playerId, FactionAdmissionSubTask sub) async {
    final rows = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM player_mission_progress "
      "WHERE player_id = ? AND modality = 'individual' "
      "AND completed_at IS NOT NULL "
      "AND completed_at >= ?",
      variables: [
        Variable.withInt(playerId),
        Variable.withInt(sub.windowStartMs),
      ],
    ).get();
    final count = rows.first.read<int>('c');
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  /// "1+ entrada de diário escrita na janela". Usa
  /// `diary_entries.entry_date` (DateTimeColumn, Drift padrão = unix
  /// seconds). Convertemos `windowStartMs / 1000`.
  Future<SubTaskEvaluation> _evalDiaryEntryWindow(
      int playerId, FactionAdmissionSubTask sub) async {
    final rows = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM diary_entries "
      "WHERE player_id = ? AND entry_date >= ?",
      variables: [
        Variable.withInt(playerId),
        Variable.withInt(sub.windowStartMs ~/ 1000),
      ],
    ).get();
    final count = rows.first.read<int>('c');
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count >= sub.target,
    );
  }

  /// "0 missões de modalidade X completadas na janela" (Trindade
  /// "Jejum"). Falha = qualquer completion da modalidade no período.
  Future<SubTaskEvaluation> _evalZeroCategoryWindow(
      int playerId, FactionAdmissionSubTask sub,
      {bool expired = false}) async {
    final modalidade = sub.params?['modalidade'] as String?;
    if (modalidade == null) {
      throw const FormatException(
          "zeroCategoryWindow exige params.modalidade");
    }
    final rows = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM daily_missions "
      "WHERE player_id = ? AND modalidade = ? "
      "AND status = 'completed' AND completed_at >= ?",
      variables: [
        Variable.withInt(playerId),
        Variable.withString(modalidade),
        Variable.withInt(sub.windowStartMs),
      ],
    ).get();
    final count = rows.first.read<int>('c');
    // Sprint 3.4 Etapa C hotfix #1 — não-monotônico (mesma família que
    // zero_failed_window). Durante janela aberta com count=0: pending.
    // Só vira `achieved=true` na expiração da janela sem completar
    // missões da categoria proibida.
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
      int playerId, FactionAdmissionSubTask sub) async {
    final player = await PlayerDao(_db).findById(playerId);
    final streak = player?.dailyMissionsStreak ?? 0;
    return SubTaskEvaluation(
      current: streak,
      target: sub.target,
      achieved: streak >= sub.target,
    );
  }

  /// Delta de `total_gold_earned_via_quests` desde o baseline
  /// capturado no unlock.
  Future<SubTaskEvaluation> _evalGoldEarnedViaQuestsWindow(
      int playerId, FactionAdmissionSubTask sub) async {
    final baseline =
        (sub.params?['baseline_gold_via_quests'] as int?) ?? 0;
    final player = await PlayerDao(_db).findById(playerId);
    final current = (player?.totalGoldEarnedViaQuests ?? 0) - baseline;
    return SubTaskEvaluation(
      current: current.clamp(0, 1 << 30),
      target: sub.target,
      achieved: current >= sub.target,
    );
  }

  /// "100+ gold no inventário em algum momento da janela". Validador
  /// olha `players.gold` corrente — caller é responsável por
  /// re-evaluar a cada evento terminal e marcar `completed=true`
  /// quando atingiu (já marcado nunca volta).
  Future<SubTaskEvaluation> _evalGoldBalanceThreshold(
      int playerId, FactionAdmissionSubTask sub) async {
    final player = await PlayerDao(_db).findById(playerId);
    final gold = player?.gold ?? 0;
    return SubTaskEvaluation(
      current: gold,
      target: sub.target,
      achieved: gold >= sub.target,
    );
  }

  /// "1+ dia sem partial completion" — existir um dia onde TODAS as 3
  /// dailies foram `completed` E nenhuma foi `partial` ou `failed`.
  /// Equivalente conceitual a `fullPerfectDayWindow` mas verifica
  /// também a ausência de `partial`.
  Future<SubTaskEvaluation> _evalNoPartialDayWindow(
      int playerId, FactionAdmissionSubTask sub) async {
    final rows = await _db.customSelect(
      "SELECT data, "
      " SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS done, "
      " SUM(CASE WHEN status = 'partial' THEN 1 ELSE 0 END) AS partials, "
      " COUNT(*) AS total "
      "FROM daily_missions "
      "WHERE player_id = ? AND completed_at >= ? "
      "GROUP BY data "
      "HAVING done = total AND partials = 0 AND total >= 1",
      variables: [
        Variable.withInt(playerId),
        Variable.withInt(sub.windowStartMs),
      ],
    ).get();
    return SubTaskEvaluation(
      current: rows.length,
      target: sub.target,
      achieved: rows.length >= sub.target,
    );
  }

  /// "EXATAMENTE N dailies na janela". Não-monótono — se passar do
  /// target, marca `failed=true` (Renegado "Caminho Próprio").
  Future<SubTaskEvaluation> _evalExactDailyCountWindow(
      int playerId, FactionAdmissionSubTask sub) async {
    final rows = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM daily_missions "
      "WHERE player_id = ? "
      "AND completed_at IS NOT NULL "
      "AND completed_at >= ? "
      "AND status IN ('completed', 'partial')",
      variables: [
        Variable.withInt(playerId),
        Variable.withInt(sub.windowStartMs),
      ],
    ).get();
    final count = rows.first.read<int>('c');
    return SubTaskEvaluation(
      current: count,
      target: sub.target,
      achieved: count == sub.target,
      failed: count > sub.target,
    );
  }

  // ─── helpers ──────────────────────────────────────────────────────

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
