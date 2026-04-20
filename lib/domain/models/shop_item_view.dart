import 'item_spec.dart';

// View-model que a loja expõe pra UI: spec do item + preço da entry + flag
// se o jogador pode pagar. Gates (level/rank/classe/facção) já foram aplicados
// — itens que falham nos gates não viram ShopItemView.
class ShopItemView {
  final ItemSpec spec;
  final int? priceCoins;
  final int? priceGems;
  final bool canAfford;

  const ShopItemView({
    required this.spec,
    required this.priceCoins,
    required this.priceGems,
    required this.canAfford,
  });
}
