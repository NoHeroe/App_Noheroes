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

  DailyMissionCompleted({
    required this.playerId,
    required this.missionId,
    required this.modalidade,
    required this.fullCompleted,
    required this.partial,
  });

  @override
  String toString() =>
      'DailyMissionCompleted(player=$playerId, mission=$missionId, '
      '${modalidade.storage}, full=$fullCompleted, partial=$partial)';
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
