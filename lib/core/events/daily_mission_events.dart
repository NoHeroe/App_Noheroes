import '../../domain/enums/mission_category.dart';
import 'app_event.dart';

/// Sprint 3.2 Etapa 1.2 — eventos do fluxo de missões diárias.
///
/// Achievements baseados em diárias virão na Etapa 1.4 — por enquanto
/// estes eventos não são consumidos por `AchievementsService`, só
/// servem pra debug/observabilidade interna.

/// Emitido pelo [DailyMissionGeneratorService] após persistir as 3
/// missões do dia. Um evento por missão (3 eventos por geração).
class DailyMissionGenerated extends AppEvent {
  @override
  final int playerId;
  final int missionId;
  final MissionCategory modalidade;

  DailyMissionGenerated({
    required this.playerId,
    required this.missionId,
    required this.modalidade,
  });

  @override
  String toString() =>
      'DailyMissionGenerated(player=$playerId, mission=$missionId, '
      '${modalidade.storage})';
}

/// Emitido pelo [DailyMissionProgressService] em cada `incrementSubTask`
/// que NÃO completou a missão. Quando a missão fecha, vem
/// [DailyMissionCompleted] no lugar.
class DailyMissionProgressed extends AppEvent {
  @override
  final int playerId;
  final int missionId;
  final String subTaskKey;
  final int novoProgresso;

  DailyMissionProgressed({
    required this.playerId,
    required this.missionId,
    required this.subTaskKey,
    required this.novoProgresso,
  });

  @override
  String toString() =>
      'DailyMissionProgressed(player=$playerId, mission=$missionId, '
      'sub=$subTaskKey, progresso=$novoProgresso)';
}

/// Emitido quando uma missão diária fecha — seja 100% (`fullCompleted`)
/// ou parcial pelo rollover (`partial`). Reward já foi creditada antes
/// do evento subir.
class DailyMissionCompleted extends AppEvent {
  @override
  final int playerId;
  final int missionId;
  final MissionCategory modalidade;

  /// `true` quando todas as 3 sub-tarefas atingiram a meta. Mutuamente
  /// exclusivo com [partial].
  final bool fullCompleted;

  /// `true` quando o rollover fechou com 1-2 sub-tarefas completas
  /// (reward × (subs/3) × 0.5).
  final bool partial;

  /// Sprint 3.3 Etapa 2.1c-β — `true` quando o rollover detectou modo
  /// automático ativo + 100% em todas as sub-tarefas e fechou via
  /// `applyAutoCompleted`. Confirmações manuais e parciais sempre
  /// `false`. Default `false` (backwards-compat com 4 emissores
  /// existentes em progress + rollover services).
  final bool wasAutoConfirmed;

  /// Sprint 3.4 Etapa B (Sub-Etapa B.1) — gold creditado por esta
  /// daily, **após** SOULSLIKE multipliers + categoria + streak bonus.
  /// Default `0` pra backwards-compat com listeners pré-3.4.
  ///
  /// Consumido pelo `QuestRewardStatsService` pra incrementar
  /// `players.total_gold_earned_via_quests`. Daily missions atualizam
  /// `players.gold` via SQL direto sem disparar `RewardGranted` —
  /// carregar gold no evento foi a forma mais cirúrgica de cobrir
  /// dailies sem refatorar o flow inteiro.
  final int goldEarned;

  DailyMissionCompleted({
    required this.playerId,
    required this.missionId,
    required this.modalidade,
    required this.fullCompleted,
    required this.partial,
    this.wasAutoConfirmed = false,
    this.goldEarned = 0,
  });

  @override
  String toString() =>
      'DailyMissionCompleted(player=$playerId, mission=$missionId, '
      '${modalidade.storage}, full=$fullCompleted, partial=$partial, '
      'auto=$wasAutoConfirmed, gold=$goldEarned)';
}

/// Emitido pelo rollover quando a missão fecha com 0 sub-tarefas — sem
/// reward.
class DailyMissionFailed extends AppEvent {
  @override
  final int playerId;
  final int missionId;
  final String reason;

  DailyMissionFailed({
    required this.playerId,
    required this.missionId,
    required this.reason,
  });

  @override
  String toString() =>
      'DailyMissionFailed(player=$playerId, mission=$missionId, $reason)';
}

/// Sprint 3.3 Etapa 2.1b — evento de coordenação interna entre
/// `DailyMissionStatsService` (writer) e `AchievementsService` (reader)
/// pra resolver race condition na escuta dos eventos terminais.
///
/// **Não é evento de domínio público** — não esperar mais consumidores
/// fora desse pipeline. Stats publica APÓS persistir as mudanças no DB,
/// garantindo que qualquer reader veja o estado novo.
///
/// Se outra feature precisar reagir a mudanças de stats no futuro, pode
/// se subscrever sem refactor.
class DailyStatsUpdated extends AppEvent {
  @override
  final int playerId;

  /// `'completed'` | `'failed'` | `'generated'`. Usado pra log/debug; o
  /// `AchievementsService` ignora o valor e itera todos os achievements
  /// daily (mesmo evento dispara checks de qualquer trigger).
  final String eventType;

  DailyStatsUpdated({
    required this.playerId,
    required this.eventType,
  });

  @override
  String toString() =>
      'DailyStatsUpdated(player=$playerId, $eventType)';
}
