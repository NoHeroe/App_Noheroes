import '../../core/utils/guild_rank.dart';
import '../entities/player.dart';

// Value object leve usado pelas políticas de equipamento. Antes era construído
// a partir do PlayersTableData (Drift); no full-online (ADR-0024) vem da row
// `players` do Postgres (fromMap) ou do modelo de domínio Player (fromPlayer).
class PlayerSnapshot {
  final int level;
  final GuildRank? rank;
  final String? classKey;
  final String? factionKey;

  const PlayerSnapshot({
    required this.level,
    this.rank,
    this.classKey,
    this.factionKey,
  });

  // Constrói a partir de uma row `players` do Postgres (chaves snake_case).
  // O rank vem de `guild_rank` (TEXT: 'none' | 'E'..'S').
  factory PlayerSnapshot.fromMap(Map<String, dynamic> m) => PlayerSnapshot(
        level: (m['level'] as num?)?.toInt() ?? 1,
        rank: _parseRank(m['guild_rank'] as String?),
        classKey: m['class_type'] as String?,
        factionKey: m['faction_type'] as String?,
      );

  // Constrói a partir do modelo de domínio Player (full-online).
  factory PlayerSnapshot.fromPlayer(Player p) => PlayerSnapshot(
        level: p.level,
        rank: _parseRank(p.guildRank),
        classKey: p.classType,
        factionKey: p.factionType,
      );

  static GuildRank? _parseRank(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw.toUpperCase()) {
      case 'E':
        return GuildRank.e;
      case 'D':
        return GuildRank.d;
      case 'C':
        return GuildRank.c;
      case 'B':
        return GuildRank.b;
      case 'A':
        return GuildRank.a;
      case 'S':
        return GuildRank.s;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerSnapshot &&
          level == other.level &&
          rank == other.rank &&
          classKey == other.classKey &&
          factionKey == other.factionKey);

  @override
  int get hashCode => Object.hash(level, rank, classKey, factionKey);
}
