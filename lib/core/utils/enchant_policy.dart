import '../../domain/enums/item_type.dart';
import '../../domain/models/enchant_result.dart';
import '../../domain/models/enchant_spec.dart';
import '../../domain/models/item_spec.dart';
import '../../domain/models/player_snapshot.dart';
import 'item_equip_policy.dart';

// Política pura de encantamento — sem IO, sem banco. Recebe tudo como
// parâmetro e retorna EnchantResult. Espelha ItemEquipPolicy / CraftPolicy
// (Sprint 2.1/2.2): ordem de validação determinística, primeira rejeição
// retornada.
//
// alreadyEnchantedSameSlot é um soft-gate: a UI intercepta, pergunta se o
// jogador quer substituir, e em caso afirmativo re-chama canApply passando
// currentRuneOnItem: null. O service então preenche replacedEnchant ao
// materializar a transação. Policy segue puro.
class EnchantPolicy {
  EnchantPolicy._();

  static const Set<ItemType> _enchantableTypes = {
    ItemType.weapon,
    ItemType.armor,
    ItemType.shield,
    ItemType.accessory,
  };

  // Keys de itens que nunca aceitam encantamento — sagrados / únicos com
  // escrita bloqueada narrativamente.
  static const Set<String> _unenchantableItemKeys = {
    'COLLAR_GUILD',
  };

  // Determina se aplicar `enchant` em `item` é permitido.
  // Ordem:
  //   1. itemNotEnchantable     (tipo não equipável / key bloqueada)
  //   2. enchantNotInInventory  (jogador não possui a runa)
  //   3. rankInsufficient       (rank do item < rank requerido da runa)
  //   4. classRestricted        (allowed_classes da runa não inclui player)
  //   5. insufficientGems       (custo em gemas)
  //   6. alreadyEnchantedSameSlot (soft — UI trata)
  static EnchantResult canApply({
    required EnchantSpec enchant,
    required ItemSpec item,
    required PlayerSnapshot player,
    required int playerGems,
    required bool enchantInInventory,
    EnchantSpec? currentRuneOnItem,
  }) {
    if (!_enchantableTypes.contains(item.type)) {
      return EnchantResult.rejected(EnchantRejectReason.itemNotEnchantable);
    }
    if (_unenchantableItemKeys.contains(item.key)) {
      return EnchantResult.rejected(EnchantRejectReason.itemNotEnchantable);
    }

    if (!enchantInInventory) {
      return EnchantResult.rejected(EnchantRejectReason.enchantNotInInventory);
    }

    if (!ItemEquipPolicy.isRankSufficient(
        item.requiredRank, enchant.requiredRank)) {
      return EnchantResult.rejected(EnchantRejectReason.rankInsufficient);
    }

    // Tecelão Sombrio é híbrido universal — ignora allowed_classes (mesma
    // exceção aplicada em ItemEquipPolicy.canEquipItem pós-Sprint 2.2).
    if (enchant.allowedClasses.isNotEmpty &&
        player.classKey != 'shadowWeaver' &&
        (player.classKey == null ||
            !enchant.allowedClasses.contains(player.classKey))) {
      return EnchantResult.rejected(EnchantRejectReason.classRestricted);
    }

    final cost = enchant.costGems ?? 0;
    if (playerGems < cost) {
      return EnchantResult.rejected(EnchantRejectReason.insufficientGems);
    }

    if (currentRuneOnItem != null) {
      return EnchantResult.rejected(
          EnchantRejectReason.alreadyEnchantedSameSlot);
    }

    return EnchantResult.allowed(applied: enchant);
  }
}
