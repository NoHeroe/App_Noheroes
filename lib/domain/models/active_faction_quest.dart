/// Sprint 3.1 Bloco 4 — domain model de `active_faction_quests`.
///
/// Ledger semanal: "jogador X, facção Y, recebeu a quest K pra semana
/// Z". Existe separado de `player_mission_progress` pra dois motivos:
///
///   1. UNIQUE `(player_id, faction_id, week_start)` encapsula a
///      atomicidade do assignment semanal — fecha o bug 3 da Sprint 2.3
///      (race condition do assignWeeklyQuest legacy).
///   2. Ciclo de vida distinto: o ledger dura a semana toda; o progresso
///      só existe enquanto a missão está ativa.
///
/// Veja `ActiveFactionQuestsRepository.upsertAtomic` pra detalhes do
/// contrato transacional.
class ActiveFactionQuest {
  final int id;
  final int playerId;
  final String factionId;
  final String missionKey;

  /// yyyy-MM-dd da segunda-feira (âncora do reset semanal).
  final String weekStart;

  final DateTime assignedAt;

  const ActiveFactionQuest({
    required this.id,
    required this.playerId,
    required this.factionId,
    required this.missionKey,
    required this.weekStart,
    required this.assignedAt,
  });

  factory ActiveFactionQuest.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw FormatException("ActiveFactionQuest.id inválido ($id)");
    }
    final playerId = json['player_id'];
    if (playerId is! int) {
      throw FormatException(
          "ActiveFactionQuest.player_id inválido em id=$id");
    }
    final factionId = json['faction_id'];
    if (factionId is! String || factionId.isEmpty) {
      throw FormatException(
          "ActiveFactionQuest.faction_id ausente em id=$id");
    }
    final missionKey = json['mission_key'];
    if (missionKey is! String || missionKey.isEmpty) {
      throw FormatException(
          "ActiveFactionQuest.mission_key ausente em id=$id");
    }
    final weekStart = json['week_start'];
    if (weekStart is! String || weekStart.isEmpty) {
      throw FormatException(
          "ActiveFactionQuest.week_start ausente em id=$id");
    }
    final assignedAt = json['assigned_at'];
    if (assignedAt is! int) {
      throw FormatException(
          "ActiveFactionQuest.assigned_at inválido em id=$id");
    }
    return ActiveFactionQuest(
      id: id,
      playerId: playerId,
      factionId: factionId,
      missionKey: missionKey,
      weekStart: weekStart,
      assignedAt: DateTime.fromMillisecondsSinceEpoch(assignedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'faction_id': factionId,
        'mission_key': missionKey,
        'week_start': weekStart,
        'assigned_at': assignedAt.millisecondsSinceEpoch,
      };
}
