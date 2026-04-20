import '../../core/utils/guild_rank.dart';

// Value object leve construído no call-site a partir do PlayersTableData.
// Usado pelas políticas de equipamento pra evitar dependência direta do Drift.
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
