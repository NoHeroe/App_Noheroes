import 'app_event.dart';

/// Sprint 3.1 Bloco 2 — eventos de forja/encantamento.
///
/// Consumidos principalmente por strategies internal (Bloco 6) em quests
/// tipo "forje 3 itens", "encante 10 itens" e por conquistas (Bloco 8).
/// Emissão fica pra Bloco 7 (refactor CraftingService + EnchantService).

class ItemCrafted extends AppEvent {
  final int playerId;
  final String itemKey;
  final String recipeKey;

  ItemCrafted({
    required this.playerId,
    required this.itemKey,
    required this.recipeKey,
    super.at,
  });

  @override
  String toString() =>
      'ItemCrafted(player=$playerId, item=$itemKey, recipe=$recipeKey)';
}

class ItemEnchanted extends AppEvent {
  final int playerId;

  /// Key do item base que recebeu a runa.
  final String itemKey;

  /// Key da runa aplicada (formato items_catalog, ex: `RUNE_FIRE_E`).
  final String runeKey;

  ItemEnchanted({
    required this.playerId,
    required this.itemKey,
    required this.runeKey,
    super.at,
  });

  @override
  String toString() =>
      'ItemEnchanted(player=$playerId, item=$itemKey, rune=$runeKey)';
}
