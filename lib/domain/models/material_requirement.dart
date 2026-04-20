// Par (itemKey, quantity) de um ingrediente exigido por uma receita.
class MaterialRequirement {
  final String itemKey;
  final int quantity;

  const MaterialRequirement({
    required this.itemKey,
    required this.quantity,
  });

  factory MaterialRequirement.fromJson(Map<String, dynamic> json) {
    return MaterialRequirement(
      itemKey: json['item_key'] as String,
      quantity: _intOrNull(json['quantity']) ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialRequirement &&
          other.itemKey == itemKey &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(itemKey, quantity);
}

// Tolerante a int/double — idêntico ao helper em ItemSpec pela mesma razão
// (JSON writers podem emitir 2.0 onde queremos 2).
int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
