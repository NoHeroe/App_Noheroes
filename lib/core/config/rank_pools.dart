import '../utils/guild_rank.dart';

/// Sprint 3.1 Bloco 13a — pools de seleção por rank (ADR 0017).
///
/// **Puro**: constantes table-driven + função pura. Zero side-effect.
/// Testável com seed determinística.
///
/// ## Pool cross-rank (ADR 0017 §Pool por rank)
///
/// Distribuição de probabilidade de **seleção de missão/item** por rank
/// do jogador. Colunas = ranks candidatos (E..S), soma = 1.0.
///
/// | Jogador | E    | D    | C    | B    | A    | S    |
/// |---------|------|------|------|------|------|------|
/// | Rank E  | 1.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
/// | Rank D  | 0.25 | 0.70 | 0.05 | 0.00 | 0.00 | 0.00 |
/// | Rank C  | 0.05 | 0.30 | 0.50 | 0.15 | 0.00 | 0.00 |
/// | Rank B  | 0.00 | 0.10 | 0.30 | 0.40 | 0.20 | 0.00 |
/// | Rank A  | 0.00 | 0.00 | 0.05 | 0.30 | 0.50 | 0.15 |
/// | Rank S  | 0.00 | 0.00 | 0.00 | 0.05 | 0.25 | 0.70 |
///
/// Rank baixo **nunca** recebe conteúdo muito acima (evita trivializar
/// curva). Rank alto continua recebendo conteúdo abaixo (utilitário,
/// nostalgia).
class RankPools {
  const RankPools._();

  /// Chaves são o rank do jogador; valores têm 6 doubles na ordem
  /// `[E, D, C, B, A, S]`. Soma garantida 1.0 ± epsilon.
  static const Map<GuildRank, List<double>> distributions = {
    GuildRank.e: [1.00, 0.00, 0.00, 0.00, 0.00, 0.00],
    GuildRank.d: [0.25, 0.70, 0.05, 0.00, 0.00, 0.00],
    GuildRank.c: [0.05, 0.30, 0.50, 0.15, 0.00, 0.00],
    GuildRank.b: [0.00, 0.10, 0.30, 0.40, 0.20, 0.00],
    GuildRank.a: [0.00, 0.00, 0.05, 0.30, 0.50, 0.15],
    GuildRank.s: [0.00, 0.00, 0.00, 0.05, 0.25, 0.70],
  };

  /// Ordem canônica dos ranks em `distributions`. Índice do array.
  static const List<GuildRank> orderedRanks = [
    GuildRank.e,
    GuildRank.d,
    GuildRank.c,
    GuildRank.b,
    GuildRank.a,
    GuildRank.s,
  ];

  /// Filtra [pool] mantendo só entradas cujo rank é **elegível** pro
  /// jogador (probabilidade > 0 na distribuição do rank do jogador).
  ///
  /// Não aplica weighted sampling — apenas corta ranks acima do pool
  /// permitido. Sampling weighted fica a cargo do caller via
  /// `weightFor(playerRank, entryRank)`.
  ///
  /// Usado pra filtrar missões: jogador rank E vê só rank E; rank D
  /// vê E/D/C; rank S vê B/A/S.
  static List<T> filterByRank<T>(
    List<T> pool,
    GuildRank playerRank,
    GuildRank Function(T) rankOf,
  ) {
    final weights = distributions[playerRank]!;
    return pool.where((e) {
      final idx = orderedRanks.indexOf(rankOf(e));
      if (idx < 0) return false;
      return weights[idx] > 0;
    }).toList(growable: false);
  }

  /// Retorna a probabilidade da `entryRank` ser sorteada quando jogador
  /// está em `playerRank`. Usado pra sampling ponderado. `0.0` = não
  /// elegível. Soma sobre todos `orderedRanks` = 1.0.
  static double weightFor(GuildRank playerRank, GuildRank entryRank) {
    final weights = distributions[playerRank]!;
    final idx = orderedRanks.indexOf(entryRank);
    return idx < 0 ? 0.0 : weights[idx];
  }
}
