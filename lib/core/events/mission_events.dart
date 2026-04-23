import 'app_event.dart';

/// Sprint 3.1 Bloco 2 — eventos do domínio Missões.
///
/// Emissão é responsabilidade do `MissionProgressService` (Bloco 6) e dos
/// services refatorados no Bloco 7. Nesta sprint nenhum emissor ainda
/// conecta ao bus — os eventos existem pra fixar o contrato.
///
/// Termo oficial: **Mission** (DESIGN_DOC §2 — `Quest` é apenas alias em
/// código legacy).

/// Missão foi criada / assignada e está aguardando progresso.
///
/// Disparado no momento em que a entrada nasce em `player_mission_progress`.
class MissionStarted extends AppEvent {
  final String missionKey;
  @override
  final int playerId;

  /// `internal` | `real` | `individual` | `mista` (ADR 0014).
  final String modality;

  /// `daily` | `class` | `faction` | `extras` | `admission`.
  final String tabOrigin;

  MissionStarted({
    required this.missionKey,
    required this.playerId,
    required this.modality,
    required this.tabOrigin,
    super.at,
  });

  @override
  String toString() =>
      'MissionStarted($missionKey, player=$playerId, modality=$modality, tab=$tabOrigin)';
}

/// Progresso da missão avançou. Emite um por incremento efetivo — agregação
/// fica a cargo de quem consome (UI normalmente debouncia pra animação).
class MissionProgressed extends AppEvent {
  final String missionKey;
  @override
  final int playerId;
  final int currentValue;
  final int targetValue;

  MissionProgressed({
    required this.missionKey,
    required this.playerId,
    required this.currentValue,
    required this.targetValue,
    super.at,
  });

  @override
  String toString() =>
      'MissionProgressed($missionKey, player=$playerId, $currentValue/$targetValue)';
}

/// Missão atingiu 100% (ou faixa total na família Real). Reward já foi
/// resolvida mas pode ou não ter sido grantada — `RewardGranted` é evento
/// separado, disparado pelo `RewardGrantService` (Bloco 5).
class MissionCompleted extends AppEvent {
  final String missionKey;
  @override
  final int playerId;

  /// JSON da reward resolvida (após SOULSLIKE + rank resolver). Mantido como
  /// string pra evitar acoplar o evento ao tipo `RewardResolved` (Bloco 5).
  final String rewardResolvedJson;

  MissionCompleted({
    required this.missionKey,
    required this.playerId,
    required this.rewardResolvedJson,
    super.at,
  });

  @override
  String toString() =>
      'MissionCompleted($missionKey, player=$playerId)';
}

/// Missão Diária concluída em faixa parcial (25–99%), conforme fórmula
/// 0-300% do ADR 0013 §4. Famílias Classe/Facção/Admissão **não emitem**
/// parcial (parcial = falha silenciosa nelas).
class MissionPartial extends AppEvent {
  final String missionKey;
  @override
  final int playerId;

  /// Percentual final (25..299 inclusive — 300% é limite superior; 100 é
  /// exatamente total e usa [MissionCompleted]).
  final int progressPct;

  final String rewardResolvedJson;

  MissionPartial({
    required this.missionKey,
    required this.playerId,
    required this.progressPct,
    required this.rewardResolvedJson,
    super.at,
  });

  @override
  String toString() =>
      'MissionPartial($missionKey, player=$playerId, $progressPct%)';
}

/// Motivos canônicos de falha de missão. Enum em String pra evitar import
/// recíproco entre events e domain/enums (Bloco 3).
class MissionFailureReason {
  static const expired = 'expired'; // reset diário/semanal bateu sem conclusão
  static const abandoned = 'abandoned'; // jogador desistiu via UI (0%)
  static const below25pct = 'below_25pct'; // tentou confirmar com <25%

  /// Sprint 3.1 Bloco 10a.2 — jogador pagou pra deletar individual
  /// repetível. Semanticamente: falha custosa que debita currency
  /// (gold+gems por rank) em vez de subir sombra. Histórico do Bloco 12
  /// discrimina visualmente: badge "Apagada" vs "Expirou"/"Desistiu".
  /// Reusar `failedAt` em vez de criar coluna `deleted_at` porque
  /// é solução final, não workaround — ver decisão D2 do plan-first.
  static const deletedByUser = 'deleted_by_user';
}

/// Missão falhou. `reason` usa os valores canônicos de [MissionFailureReason].
class MissionFailed extends AppEvent {
  final String missionKey;
  @override
  final int playerId;
  final String reason;

  MissionFailed({
    required this.missionKey,
    required this.playerId,
    required this.reason,
    super.at,
  });

  @override
  String toString() =>
      'MissionFailed($missionKey, player=$playerId, reason=$reason)';
}

/// Sprint 3.1 Bloco 11a — missão **individual** foi criada pelo jogador
/// (via form de criação). Emitido pelo `IndividualCreationService`
/// pós-commit. Hoje sem listeners — deixa o hook preparado pra
/// `AchievementsService` cascatear (ex: "Primeira missão individual
/// criada") ou assignment de Bloco 14 reagir.
///
/// `categoria` é `String` (storage) pra evitar import recíproco com
/// `domain/enums` — listeners parseiam via `MissionCategoryCodec`.
class IndividualCreated extends AppEvent {
  @override
  final int playerId;
  final int missionProgressId;
  final String missionKey;
  final String categoria;

  IndividualCreated({
    required this.playerId,
    required this.missionProgressId,
    required this.missionKey,
    required this.categoria,
    super.at,
  });

  @override
  String toString() =>
      'IndividualCreated(player=$playerId, key=$missionKey, cat=$categoria)';
}

/// Preferências do jogador mudaram (primeira calibração, refazer, ou update
/// programático). `MissionAssignmentService` do Bloco 14 escuta pra
/// recalcular pools.
class MissionPreferencesChanged extends AppEvent {
  @override
  final int playerId;

  MissionPreferencesChanged({required this.playerId, super.at});

  @override
  String toString() => 'MissionPreferencesChanged(player=$playerId)';
}
