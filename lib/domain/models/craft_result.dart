// Razões canônicas pelas quais um craft pode ser rejeitado.
// Usado tanto pela política pura (craft_policy) quanto pelo service
// de crafting que devolve ao UI.
enum CraftRejectReason {
  recipeNotUnlocked,
  recipeNotFound,
  rankTooLow,
  levelTooLow,
  stationMismatch,
  notEnoughMaterials,
  notEnoughCoins,
  itemNotInCatalog,
  inventoryFull, // reservado — sem implementação por enquanto
  dbError,
}

class CraftResult {
  final bool isOk;
  final CraftRejectReason? reason;
  // Preenchidos apenas em sucesso.
  final int? inventoryId;
  final int? quantity;

  const CraftResult._({
    required this.isOk,
    this.reason,
    this.inventoryId,
    this.quantity,
  });

  factory CraftResult.ok({
    required int inventoryId,
    required int quantity,
  }) =>
      CraftResult._(isOk: true, inventoryId: inventoryId, quantity: quantity);

  factory CraftResult.failed(CraftRejectReason r) =>
      CraftResult._(isOk: false, reason: r);
}
