import '../../core/utils/guild_rank.dart';

/// Sprint 3.1 Bloco 3 — codec de rank com contratos estritos pra parsing
/// de JSON/catálogos.
///
/// ## Reuse-first
///
/// Não cria um `MissionRank` novo. O projeto já tem dois enums de rank:
///
/// - `GuildRank` (`lib/core/utils/guild_rank.dart`) — **canônico**,
///   consumido por `items_catalog_service`, `recipes_catalog_service`,
///   `player_rank_service`, `guild_ascension_service`.
/// - `HabitRank` (`lib/domain/enums/habit_rank.dart`) — orphan pós Bloco 1,
///   só consumido por `lib/domain/entities/habit.dart` (que por sua vez
///   não tem consumer). Dead code — Fase 5 limpa.
///
/// Missões reusam `GuildRank`, que tem os mesmos 6 valores (E, D, C, B,
/// A, S) já usados em catálogos de items/recipes. Alinhamento perfeito
/// com rank gating do ADR 0017 (pool determinado por rank do jogador).
///
/// ## Por que este arquivo existe
///
/// `GuildRankSystem.fromString(String)` existente **retorna `GuildRank.e`
/// como fallback silencioso** em caso de valor inválido — comportamento
/// útil pra 4 services que já dependem dele, mas **inseguro** pra parsing
/// de JSON novo (um typo no catálogo viraria rank E sem aviso).
///
/// Este codec expõe a API alternativa acordada no Bloco 3:
///
/// - [fromString] tolerante: retorna `null` em caso de valor inválido.
/// - [fromStorage] estrito: lança [FormatException] com mensagem
///   `"Invalid GuildRank '<value>'"`.
///
/// `GuildRankSystem` continua intacto — nenhum caller existente é afetado.
class RankCodec {
  const RankCodec._();

  /// String canônica ('e', 'd', ..., 's') — mesmo formato usado em
  /// `players.guild_rank` e nos JSONs de catálogo.
  static String storage(GuildRank rank) => rank.name;

  /// Label legível em PT-BR (ex: 'Rank E').
  static String display(GuildRank rank) => GuildRankSystem.label(rank);

  /// Tolerante — retorna `null` se [value] não for um rank canônico.
  ///
  /// Use em *checks* defensivos. Para parsing de JSON que precisa falhar
  /// rápido no campo ofensivo, use [fromStorage].
  static GuildRank? fromString(String value) {
    for (final r in GuildRank.values) {
      if (r.name == value) return r;
    }
    return null;
  }

  /// Estrito — lança [FormatException] com mensagem
  /// `"Invalid GuildRank '<value>'"` se [value] for inválido.
  static GuildRank fromStorage(String value) {
    final r = fromString(value);
    if (r == null) {
      throw FormatException("Invalid GuildRank '$value'");
    }
    return r;
  }
}
