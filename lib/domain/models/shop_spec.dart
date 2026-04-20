// Especificação imutável de uma loja — carregada de assets/data/shops.json.
class ShopSpec {
  final String key;
  final String name;
  final String description;
  final String npcId;
  final String region;
  final String type; // 'general' / 'faction' / 'guild'
  final List<String> acceptedFactions;
  final List<String> acceptedRanks; // ['E', 'D', ...]
  final List<ShopItemEntry> items;

  const ShopSpec({
    required this.key,
    required this.name,
    required this.description,
    required this.npcId,
    required this.region,
    required this.type,
    required this.acceptedFactions,
    required this.acceptedRanks,
    required this.items,
  });

  factory ShopSpec.fromJson(Map<String, dynamic> json) {
    return ShopSpec(
      key:         json['key'] as String,
      name:        json['name'] as String,
      description: json['description'] as String? ?? '',
      npcId:       json['npc_id'] as String? ?? '',
      region:      json['region'] as String? ?? '',
      type:        json['type'] as String? ?? 'general',
      acceptedFactions: ((json['accepts_factions'] as List?) ?? const [])
          .cast<String>(),
      acceptedRanks: ((json['accepts_ranks'] as List?) ?? const [])
          .cast<String>(),
      items: ((json['items'] as List?) ?? const [])
          .map((e) => ShopItemEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

// Entry de um item dentro de uma loja — a loja define o preço específico.
class ShopItemEntry {
  final String itemKey;
  final int? priceCoins;
  final int? priceGems;

  const ShopItemEntry({
    required this.itemKey,
    this.priceCoins,
    this.priceGems,
  });

  factory ShopItemEntry.fromJson(Map<String, dynamic> json) {
    return ShopItemEntry(
      itemKey:    json['key'] as String,
      priceCoins: _intOrNull(json['price_coins']),
      priceGems:  _intOrNull(json['price_gems']),
    );
  }
}

// Tolerante a int/double — ver nota em item_spec.dart.
int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
