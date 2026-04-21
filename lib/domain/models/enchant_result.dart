import 'enchant_spec.dart';

// Razões canônicas pelas quais um encantamento pode ser rejeitado.
// Ordem determinística — EnchantPolicy.canApply retorna a primeira que falha.
enum EnchantRejectReason {
  itemNotFound,
  enchantNotFound,
  enchantNotInInventory,
  itemNotEnchantable,       // material, consumable, Colar da Guilda
  rankInsufficient,          // runa D em item E
  alreadyEnchantedSameSlot,  // soft — UI pergunta substituição
  insufficientGems,
  classRestricted,           // runa com allowedClasses não bate (exceção shadowWeaver)
}

class EnchantResult {
  final bool allowed;
  final EnchantRejectReason? reason;
  final EnchantSpec? appliedEnchant;
  final EnchantSpec? replacedEnchant; // se substituiu outro

  const EnchantResult._({
    required this.allowed,
    this.reason,
    this.appliedEnchant,
    this.replacedEnchant,
  });

  factory EnchantResult.allowed({
    required EnchantSpec applied,
    EnchantSpec? replaced,
  }) => EnchantResult._(
        allowed: true,
        appliedEnchant: applied,
        replacedEnchant: replaced,
      );

  factory EnchantResult.rejected(EnchantRejectReason r) => EnchantResult._(
        allowed: false,
        reason: r,
      );
}
