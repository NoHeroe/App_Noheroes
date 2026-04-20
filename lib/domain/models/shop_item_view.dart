import 'item_spec.dart';

// View-model que a loja expõe pra UI: spec do item + preço da entry + flags
// de estado.
//
// Sprint 2.2 pós-teste: filosofia mudou — itens incompatíveis com o jogador
// **continuam aparecendo** na loja, mas com `canInteract=false` e
// `rejectReasonLabel` preenchido. UI mostra cinza + popup ao tocar.
// Transparência > magia (consistente com Colar da Guilda).
//
// - canInteract: gates hard (rank/level/class/faction). false → botão cinza,
//   tap abre dialog explicando o motivo.
// - canAfford: gate de preço. Separado de canInteract porque é transitório
//   (jogador pode farmar ouro).
// - rejectReasonLabel: mensagem em PT-BR pronta pra UI quando !canInteract.
class ShopItemView {
  final ItemSpec spec;
  final int? priceCoins;
  final int? priceGems;
  final bool canAfford;
  final bool canInteract;
  final String? rejectReasonLabel;

  const ShopItemView({
    required this.spec,
    required this.priceCoins,
    required this.priceGems,
    required this.canAfford,
    this.canInteract = true,
    this.rejectReasonLabel,
  });
}
