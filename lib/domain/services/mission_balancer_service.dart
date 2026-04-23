import '../../core/utils/guild_rank.dart';
import '../balance/individual_creation_balance.dart';
import '../balance/soulslike_balance.dart';
import '../enums/intensity.dart';
import '../enums/mission_category.dart';
import '../models/reward_declared.dart';

/// Sprint 3.1 Bloco 11a — calcula reward de missão individual criada
/// pelo jogador (ADR 0014 §Família Individual + Sprint_Missoes Bloco 11).
///
/// **Puro**: função sem side-effects. Entrada `BalancerInput`, saída
/// `RewardDeclared`. Testável sem mocks.
///
/// ## Fórmula (Sprint_Missoes Bloco 11, linha 343-348)
///
/// ```
/// base_xp   = intensity × 30 × categoryMult
/// base_gold = intensity × 20 × categoryMult
/// final_xp   = base_xp   × SOULSLIKE.xpMultiplier   × repetivelPenalty
/// final_gold = base_gold × SOULSLIKE.goldMultiplier × repetivelPenalty
/// ```
///
/// Onde:
///   - `intensity` ∈ {1, 2, 3} conforme `Intensity.light|medium|heavy`
///     (ADR 0014 — Intensity.adaptive fora do escopo de criação)
///   - `categoryMult` do `SoulslikeBalance.categoryMultipliers` (1.0
///     físico, 1.1 mental, 1.2 espiritual, 1.15 vitalismo)
///   - SOULSLIKE multipliers: xp 0.4, gold 0.35 (ADR 0013)
///   - `repetivelPenalty = 0.7` quando `isRepetivel=true`, senão 1.0
///     (desincentivo a oversupply — placeholder, TODO bloco 15.5)
///
/// ## Rank herdado
///
/// O jogador **não escolhe** rank da missão individual. Service recebe
/// `rank` do caller (que lê do `players.guild_rank` atual). Bloco atual
/// não usa `rank` na fórmula — fica reservado pro Bloco 14 (assignment)
/// caso decida ajustar itens/bonus por rank. Passa intacto.
///
/// ## Output
///
/// Retorna `RewardDeclared` com xp + gold calculados. Gems/seivas/items
/// ficam 0 (missão individual padrão não gera — reservado pra futuro).
class MissionBalancerService {
  const MissionBalancerService();

  RewardDeclared calculate(BalancerInput input) {
    final intensityMult = _intensityToMult(input.intensity);
    if (intensityMult <= 0) {
      throw ArgumentError.value(
        input.intensity,
        'intensity',
        'Intensity.adaptive não é criável — usa light/medium/heavy',
      );
    }
    final catMult =
        SoulslikeBalance.categoryMultipliers[input.categoria.storage] ?? 1.0;
    final repPenalty = input.isRepetivel
        ? IndividualCreationBalance.kRepetivelPenalty
        : 1.0;

    final baseXp = intensityMult * 30 * catMult;
    final baseGold = intensityMult * 20 * catMult;

    final finalXp =
        (baseXp * SoulslikeBalance.xpMultiplier * repPenalty).round();
    final finalGold =
        (baseGold * SoulslikeBalance.goldMultiplier * repPenalty).round();

    return RewardDeclared(xp: finalXp, gold: finalGold);
  }

  int _intensityToMult(Intensity i) {
    switch (i) {
      case Intensity.light:
        return IndividualCreationBalance.intensityMultiplierLight;
      case Intensity.medium:
        return IndividualCreationBalance.intensityMultiplierMedium;
      case Intensity.heavy:
        return IndividualCreationBalance.intensityMultiplierHeavy;
      case Intensity.adaptive:
        return 0; // inválido — calculate() lança
    }
  }
}

/// Entrada do balancer. Imutável.
class BalancerInput {
  final MissionCategory categoria;
  final Intensity intensity;
  final GuildRank rank;
  final bool isRepetivel;

  const BalancerInput({
    required this.categoria,
    required this.intensity,
    required this.rank,
    required this.isRepetivel,
  });
}
