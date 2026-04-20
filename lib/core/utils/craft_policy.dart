import '../../domain/models/craft_result.dart';
import '../../domain/models/player_snapshot.dart';
import '../../domain/models/recipe_spec.dart';
import 'item_equip_policy.dart';

// Políticas puras de crafting — sem IO, sem banco.
// Espelha o contrato de ItemEquipPolicy: funções estáticas, ordem de validação
// determinística, retorno de primeira rejeição.
class CraftPolicy {
  CraftPolicy._();

  // Valida se uma receita pode ser crafteada. Retorna null quando ok,
  // ou a razão da rejeição.
  //
  // Ordem (importa — testes dependem):
  //   1. recipeNotUnlocked
  //   2. rankTooLow
  //   3. levelTooLow
  //   4. notEnoughMaterials
  //   5. notEnoughCoins
  //
  // stationMismatch não é validado aqui — fica pra Sprint 4.1 (travel/stations
  // físicas). Por ora, todas as receitas passam no gate de station.
  static CraftRejectReason? canCraft({
    required RecipeSpec recipe,
    required PlayerSnapshot player,
    required bool recipeUnlocked,
    required Map<String, int> currentMaterials,
    required int currentCoins,
  }) {
    if (!recipeUnlocked) return CraftRejectReason.recipeNotUnlocked;

    if (!ItemEquipPolicy.isRankSufficient(player.rank, recipe.requiredRank)) {
      return CraftRejectReason.rankTooLow;
    }

    if (player.level < recipe.requiredLevel) {
      return CraftRejectReason.levelTooLow;
    }

    for (final m in recipe.materials) {
      final have = currentMaterials[m.itemKey] ?? 0;
      if (have < m.quantity) return CraftRejectReason.notEnoughMaterials;
    }

    if (currentCoins < recipe.costCoins) {
      return CraftRejectReason.notEnoughCoins;
    }

    return null;
  }

  // Soma total de materiais pra craftar [quantity] vezes a receita.
  // Usado pelo UI pra exibir total "x4 × 2 = 8 iron_ingot" em crafts de
  // lote, e pelo service pra decidir quanto consumir.
  //
  // quantity <= 0 retorna mapa vazio (defensivo).
  static Map<String, int> calculateMaterialsNeeded(
    RecipeSpec recipe,
    int quantity,
  ) {
    if (quantity <= 0) return const {};
    final out = <String, int>{};
    for (final m in recipe.materials) {
      out[m.itemKey] = (out[m.itemKey] ?? 0) + m.quantity * quantity;
    }
    return out;
  }
}
