/// Sprint 3.3 Etapa 2.1a — read-only mirror imutável de uma row da
/// tabela `player_daily_subtask_volume`.
///
/// Época 2 (ADR-0024): `playerId` virou uuid (String); `fromRow` (Drift)
/// substituído por [PlayerDailySubtaskVolume.fromMap] (row snake_case).
class PlayerDailySubtaskVolume {
  final String playerId;
  final String subTaskKey;
  final int totalUnits;
  final DateTime updatedAt;

  const PlayerDailySubtaskVolume({
    required this.playerId,
    required this.subTaskKey,
    required this.totalUnits,
    required this.updatedAt,
  });

  factory PlayerDailySubtaskVolume.fromMap(Map<String, dynamic> m) =>
      PlayerDailySubtaskVolume(
        playerId: m['player_id'] as String,
        subTaskKey: m['sub_task_key'] as String,
        totalUnits: (m['total_units'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (m['updated_at'] as num?)?.toInt() ?? 0),
      );
}
