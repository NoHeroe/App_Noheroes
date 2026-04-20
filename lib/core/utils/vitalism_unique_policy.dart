import 'dart:math';
import '../../domain/enums/affinity_tier.dart';

// Políticas puras do sistema de Vitalismos Únicos.
// Nenhuma dependência de banco — IO fica no VitalismUniqueService.
// Ver ADR 0005, 0006, 0007.
class VitalismUniquePolicy {
  VitalismUniquePolicy._();

  // Soma dos pontos de vida correspondentes a uma lista de afinidades.
  // Usada no ritual do Vazio (converte TODAS as afinidades em posse — opção B)
  // e em PvP pós-Vida (destrói afinidades do derrotado, converte em pontos).
  static int calculateLifePointsFromAffinities(List<AffinityTier> affinities) {
    return affinities.fold(0, (sum, t) => sum + t.lifeRitualPoints);
  }

  // Se o matador é Vitalista da Vida, o comportamento do PvP muda:
  // em vez de roubar as afinidades do derrotado, destrói e ganha pontos.
  static bool shouldDestroyInsteadOfSteal({
    required bool winnerIsVitalistaDaVida,
  }) =>
      winnerIsVitalistaDaVida;

  // Pré-condição do ritual do Vazio: 3+ raros em posse e ainda não tem Vida.
  static bool canPerformLifeRitual({
    required List<AffinityTier> currentAffinities,
    required bool alreadyHasLife,
  }) {
    if (alreadyHasLife) return false;
    final rareCount =
        currentAffinities.where((t) => t == AffinityTier.rare).length;
    return rareCount >= 3;
  }

  // Valida que os 3 ids sacrificados:
  //  1. são exatamente 3
  //  2. são todos distintos
  //  3. estão em posse do jogador
  //  4. são todos do tier raro
  static bool validateLifeRitualSacrifices({
    required List<String> sacrificedIds,
    required Map<String, AffinityTier> ownedByTier,
  }) {
    if (sacrificedIds.length != 3) return false;
    if (sacrificedIds.toSet().length != 3) return false;
    for (final id in sacrificedIds) {
      final tier = ownedByTier[id];
      if (tier != AffinityTier.rare) return false;
    }
    return true;
  }

  // Sorteio puro a partir do pool. Retorna null se vazio.
  // RNG explícito pra ser testável de forma determinística.
  static String? pickRandomFromPool(List<String> pool, Random rng) {
    if (pool.isEmpty) return null;
    return pool[rng.nextInt(pool.length)];
  }
}
