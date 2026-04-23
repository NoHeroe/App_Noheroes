import '../../core/utils/guild_rank.dart';

/// Sprint 3.1 Bloco 10a.2 — custo de apagar uma missão individual
/// repetível (ADR 0014 §Família Individual + DESIGN_DOC §4 linha 160).
///
/// O custo é debitado do jogador via `IndividualDeleteService` (dentro
/// de transação Drift atômica) antes de marcar a missão como falhada
/// com `MissionFailureReason.deletedByUser`.
///
/// ## Valores PLACEHOLDER — TODO(bloco11)
///
/// DESIGN_DOC declara "gemas + ouro (valor alto)" sem especificar
/// valores exatos. A tabela abaixo é **placeholder conservador** por
/// rank, escalando geometricamente (2x por step E→S) pra alinhar com o
/// princípio soulslike.
///
/// **Bloco 11** (criação de individuais + form completo) reavalia após
/// ver a fórmula de reward concreta — se refazer custa 200g/1s e delete
/// custa 50g/20g, desalinha a narrativa de "alto custo". Registrado em
/// Sprint_Missoes_Sessao1_Progresso.md (débitos 15.5).
///
/// Tabela atual:
///
/// | Rank | Gold | Gems |
/// |------|------|------|
/// | E    | 50   | 20   |
/// | D    | 100  | 40   |
/// | C    | 200  | 80   |
/// | B    | 400  | 160  |
/// | A    | 800  | 320  |
/// | S    | 1600 | 640  |
class IndividualDeleteCost {
  final int gold;
  final int gems;

  const IndividualDeleteCost({required this.gold, required this.gems});

  /// Mapeia `rank` → custo. Exposta como função pura pro `IndividualDeleteService`
  /// e testes.
  static IndividualDeleteCost forRank(GuildRank rank) {
    switch (rank) {
      case GuildRank.e:
        return const IndividualDeleteCost(gold: 50, gems: 20);
      case GuildRank.d:
        return const IndividualDeleteCost(gold: 100, gems: 40);
      case GuildRank.c:
        return const IndividualDeleteCost(gold: 200, gems: 80);
      case GuildRank.b:
        return const IndividualDeleteCost(gold: 400, gems: 160);
      case GuildRank.a:
        return const IndividualDeleteCost(gold: 800, gems: 320);
      case GuildRank.s:
        return const IndividualDeleteCost(gold: 1600, gems: 640);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndividualDeleteCost &&
          gold == other.gold &&
          gems == other.gems);

  @override
  int get hashCode => Object.hash(gold, gems);

  @override
  String toString() => 'IndividualDeleteCost(gold=$gold, gems=$gems)';
}
