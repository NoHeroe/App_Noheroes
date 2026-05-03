import 'app_event.dart';

/// Sprint 3.1 Bloco 2 — eventos de seleção de classe e facção.

/// Classe escolhida pelo jogador no nível 5.
///
/// **Hook canônico pra calibração** (Bloco 9): `TutorialManager`
/// (`phase13_mission_calibration`) escuta esse evento pra navegar pra
/// `/mission_calibration`. Também dispara assign das missões diárias de
/// classe pelo `QuestAdmissionService` refatorado (Bloco 7).
class ClassSelected extends AppEvent {
  @override
  final int playerId;
  final String classId;

  ClassSelected({
    required this.playerId,
    required this.classId,
    super.at,
  });

  @override
  String toString() =>
      'ClassSelected(player=$playerId, class=$classId)';
}

/// Jogador entrou numa facção (admissão aprovada em `active_faction_quests`
/// ou migração de `pending:X` pra `X` em `players.faction_type`).
class FactionJoined extends AppEvent {
  @override
  final int playerId;
  final String factionId;

  FactionJoined({
    required this.playerId,
    required this.factionId,
    super.at,
  });

  @override
  String toString() =>
      'FactionJoined(player=$playerId, faction=$factionId)';
}

/// Jogador saiu de uma facção (acessível a partir do nível 7 conforme plano
/// §Admissão). Pode cascatear em `FactionJoined` se troca imediata.
class FactionLeft extends AppEvent {
  @override
  final int playerId;
  final String factionId;

  FactionLeft({
    required this.playerId,
    required this.factionId,
    super.at,
  });

  @override
  String toString() => 'FactionLeft(player=$playerId, faction=$factionId)';
}

/// Sprint 3.4 Sub-Etapa B.2 — admissão eliminatória iniciada pra uma
/// facção (player escolheu em `/faction-selection` e
/// `QuestAdmissionService` criou as missões com sub-tasks no metaJson).
///
/// `attemptCount` reflete `player_faction_membership.admissionAttempts`
/// pra essa facção (1 na primeira tentativa; 2+ após reprovação +
/// retry pós-cooldown). UI da `/faction-selection` mostra esse número
/// no header de dificuldade.
///
/// **Não emitido pra Guilda** — Guilda usa entrada direta (sem
/// admissão eliminatória) por design (Aventureiro nível 1 via
/// `guild_rank` + Facção Guilda nível 2 com entry direta).
class FactionAdmissionStarted extends AppEvent {
  @override
  final int playerId;
  final String factionId;
  final int totalQuests;
  final int attemptCount;

  FactionAdmissionStarted({
    required this.playerId,
    required this.factionId,
    required this.totalQuests,
    required this.attemptCount,
    super.at,
  });

  @override
  String toString() =>
      'FactionAdmissionStarted(player=$playerId, faction=$factionId, '
      'quests=$totalQuests, attempt=$attemptCount)';
}

/// Sprint 3.4 Sub-Etapa B.2 — admissão eliminatória **reprovada**.
///
/// Disparado pelo `FactionAdmissionProgressService` quando:
/// - Sub-task não-monótona (`zero_failed_window`, `zero_category_window`,
///   `exact_daily_count_window`) marca `failed=true` por ultrapassar.
/// - Janela de uma missão expira sem todas as sub-tasks completadas.
///
/// Caller (handler do evento no service) é responsável por:
/// 1. Marcar todas as MissionProgress da admissão como `failed`.
/// 2. Aplicar -10 reputação na facção tentada.
/// 3. Set `lockedUntil = now + 48h` em `player_faction_membership`.
/// 4. Reverter `players.faction_type` pra estado anterior.
class FactionAdmissionRejected extends AppEvent {
  @override
  final int playerId;
  final String factionId;
  final int attemptCount;

  /// Razão canônica da reprovação. Valores:
  /// - `sub_task_failed:<sub_type>` (ex: `sub_task_failed:zero_failed_window`)
  /// - `window_expired:<mission_id>` (ex: `window_expired:ADM_MOON_2`)
  /// - `exact_count_overshoot:<mission_id>` (sub-type
  ///   `exact_daily_count_window` ultrapassou target)
  /// - `dev_panel_force_reject` (atalho de teste)
  final String reason;

  /// Qual missão da sequência falhou (id do catálogo, ex: `ADM_MOON_2`).
  final String missionId;

  FactionAdmissionRejected({
    required this.playerId,
    required this.factionId,
    required this.attemptCount,
    required this.reason,
    required this.missionId,
    super.at,
  });

  @override
  String toString() =>
      'FactionAdmissionRejected(player=$playerId, faction=$factionId, '
      'attempt=$attemptCount, reason=$reason, mission=$missionId)';
}

/// Sprint 3.4 Sub-Etapa B.2 — uma missão da admissão eliminatória
/// (não a admissão inteira) foi completada. Listener de
/// sequenciamento usa pra desbloquear a missão N+1 da sequência.
class FactionAdmissionQuestCompleted extends AppEvent {
  @override
  final int playerId;
  final String factionId;

  /// 1-based. `questIndex == totalQuests` indica que a admissão
  /// inteira foi aprovada (próximo evento canônico:
  /// [FactionAdmissionApproved]).
  final int questIndex;

  final int totalQuests;
  final String missionId;

  FactionAdmissionQuestCompleted({
    required this.playerId,
    required this.factionId,
    required this.questIndex,
    required this.totalQuests,
    required this.missionId,
    super.at,
  });

  @override
  String toString() =>
      'FactionAdmissionQuestCompleted(player=$playerId, faction=$factionId, '
      'mission=$missionId, $questIndex/$totalQuests)';
}

/// Sprint 3.4 Sub-Etapa B.2 — admissão eliminatória **aprovada**
/// (todas as missões completas).
///
/// Caller (handler do evento) deve:
/// 1. Promover `players.faction_type` de `pending:X` pra `X`.
/// 2. Disparar [FactionJoined] em cascata pra preservar
///    retrocompatibilidade com listeners existentes.
class FactionAdmissionApproved extends AppEvent {
  @override
  final int playerId;
  final String factionId;
  final int attemptCount;

  FactionAdmissionApproved({
    required this.playerId,
    required this.factionId,
    required this.attemptCount,
    super.at,
  });

  @override
  String toString() =>
      'FactionAdmissionApproved(player=$playerId, faction=$factionId, '
      'attempt=$attemptCount)';
}

/// Sprint 3.1 Bloco 13b — reputação numa facção mudou (delta aplicado).
///
/// Emitido pelo `FactionReputationService.adjustReputation` após persistir
/// o novo valor. Cobre tanto a facção alvo do delta direto quanto as
/// aliadas/rivais afetadas via propagação (`kFactionAlliances`). `newValue`
/// é clamped 0-100 pelo repo.
class FactionReputationChanged extends AppEvent {
  @override
  final int playerId;
  final String factionId;
  final int newValue;
  final int previousValue;

  FactionReputationChanged({
    required this.playerId,
    required this.factionId,
    required this.newValue,
    required this.previousValue,
    super.at,
  });

  @override
  String toString() =>
      'FactionReputationChanged(player=$playerId, faction=$factionId, '
      '$previousValue→$newValue)';
}
