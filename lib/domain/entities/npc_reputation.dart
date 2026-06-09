/// Modelo full-online da reputação de um NPC para um jogador (Época 2, ADR-0024).
///
/// Substitui o `NpcReputationTableData` (Drift) como objeto em memória. Mantém
/// a mesma API de getters (camelCase) que a UI já lê (`r.npcId`, `r.reputation`).
///
/// [id] é a PK de linha (bigserial -> int) — NÃO confundir com o jogador.
/// [playerId] é o uuid do jogador (`auth.users.id`), agora `String`.
///
/// `fromMap` lê as chaves snake_case da row do Postgres (PostgREST/Supabase).
class NpcReputation {
  final int id;
  final String playerId;
  final String npcId;
  final int reputation;
  final DateTime? lastGainAt;
  final int dailyGained;

  const NpcReputation({
    required this.id,
    required this.playerId,
    required this.npcId,
    this.reputation = 50,
    this.lastGainAt,
    this.dailyGained = 0,
  });

  static int _int(Object? v, [int fallback = 0]) =>
      v == null ? fallback : (v as num).toInt();

  /// Constrói a partir de uma row do Postgres (chaves snake_case).
  factory NpcReputation.fromMap(Map<String, dynamic> m) => NpcReputation(
        id: _int(m['id']),
        playerId: m['player_id'] as String,
        npcId: m['npc_id'] as String,
        reputation: _int(m['reputation'], 50),
        lastGainAt: m['last_gain_at'] == null
            ? null
            : DateTime.parse(m['last_gain_at'] as String),
        dailyGained: _int(m['daily_gained']),
      );
}
