import '../../data/database/app_database.dart';

/// Sprint 3.3 Etapa 2.1a — read-only mirror imutável de uma row da
/// tabela `player_daily_subtask_volume`.
class PlayerDailySubtaskVolume {
  final int playerId;
  final String subTaskKey;
  final int totalUnits;
  final DateTime updatedAt;

  const PlayerDailySubtaskVolume({
    required this.playerId,
    required this.subTaskKey,
    required this.totalUnits,
    required this.updatedAt,
  });

  factory PlayerDailySubtaskVolume.fromRow(
      PlayerDailySubtaskVolumeData row) {
    return PlayerDailySubtaskVolume(
      playerId: row.playerId,
      subTaskKey: row.subTaskKey,
      totalUnits: row.totalUnits,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
