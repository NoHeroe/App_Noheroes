/// Sistema de Rank da Guilda de Aventureiros
/// Rank separado do nível do personagem — reflete reputação e comprometimento
/// E (Iniciante) → D → C → B → A → S (Lendário)
enum GuildRank { e, d, c, b, a, s }

class GuildRankSystem {
  // Thresholds: [xpTotal, missõesConcluídas] para atingir cada rank
  static const _thresholds = {
    GuildRank.e: (xp: 0,      quests: 0),
    GuildRank.d: (xp: 500,    quests: 10),
    GuildRank.c: (xp: 2000,   quests: 30),
    GuildRank.b: (xp: 6000,   quests: 75),
    GuildRank.a: (xp: 15000,  quests: 150),
    GuildRank.s: (xp: 40000,  quests: 300),
  };

  // Multiplicadores de recompensa por rank
  static const _multipliers = {
    GuildRank.e: 1.0,
    GuildRank.d: 1.2,
    GuildRank.c: 1.5,
    GuildRank.b: 2.0,
    GuildRank.a: 2.8,
    GuildRank.s: 4.0,
  };

  /// Calcula o rank atual com base em XP total e missões concluídas
  static GuildRank calcRank({
    required int totalXp,
    required int totalQuests,
  }) {
    GuildRank current = GuildRank.e;
    for (final rank in GuildRank.values.reversed) {
      final t = _thresholds[rank]!;
      if (totalXp >= t.xp && totalQuests >= t.quests) {
        current = rank;
        break;
      }
    }
    return current;
  }

  /// Converte string salva no banco ('e', 'd'...) para enum
  static GuildRank fromString(String value) {
    return GuildRank.values.firstWhere(
      (r) => r.name == value.toLowerCase(),
      orElse: () => GuildRank.e,
    );
  }

  /// Adapta XP de recompensa com multiplicador do rank
  static int adaptXp(int baseXp, GuildRank rank) =>
      (baseXp * (_multipliers[rank] ?? 1.0)).round();

  /// Adapta ouro de recompensa com multiplicador do rank
  static int adaptGold(int baseGold, GuildRank rank) =>
      (baseGold * (_multipliers[rank] ?? 1.0)).round();

  /// Retorna o multiplicador atual
  static double multiplier(GuildRank rank) => _multipliers[rank] ?? 1.0;

  /// Rótulo legível do rank
  static String label(GuildRank rank) => switch (rank) {
        GuildRank.e => 'Rank E',
        GuildRank.d => 'Rank D',
        GuildRank.c => 'Rank C',
        GuildRank.b => 'Rank B',
        GuildRank.a => 'Rank A',
        GuildRank.s => 'Rank S',
      };

  /// Próximo rank (null se já é S)
  static GuildRank? next(GuildRank rank) {
    final idx = GuildRank.values.indexOf(rank);
    if (idx >= GuildRank.values.length - 1) return null;
    return GuildRank.values[idx + 1];
  }

  /// Todos os ranks disponíveis
  static List<GuildRank> availableRanks() => GuildRank.values.toList();

  /// Progresso em % até o próximo rank (0.0–1.0)
  static double progressToNext({
    required int totalXp,
    required int totalQuests,
    required GuildRank current,
  }) {
    final nextRank = next(current);
    if (nextRank == null) return 1.0;

    final curT = _thresholds[current]!;
    final nextT = _thresholds[nextRank]!;

    final xpProgress = nextT.xp > curT.xp
        ? (totalXp - curT.xp) / (nextT.xp - curT.xp)
        : 1.0;
    final questProgress = nextT.quests > curT.quests
        ? (totalQuests - curT.quests) / (nextT.quests - curT.quests)
        : 1.0;

    return ((xpProgress + questProgress) / 2).clamp(0.0, 1.0);
  }
}
