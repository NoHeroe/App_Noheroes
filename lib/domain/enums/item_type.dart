// Ver ADR 0008 — 16 tipos canônicos. Tipos no JSON usam snake_case
// (`dark_item`), enum Dart usa camelCase (`darkItem`). fromString mapeia.
enum ItemType {
  weapon,
  armor,
  accessory,
  shield,
  tome,
  relic,
  consumable,
  material,
  chest,
  key,
  title,
  cosmetic,
  lore,
  currency,
  darkItem,
  misc,
}

extension ItemTypeExt on ItemType {
  String get label => switch (this) {
    ItemType.weapon     => 'Arma',
    ItemType.armor      => 'Armadura',
    ItemType.accessory  => 'Acessório',
    ItemType.shield     => 'Escudo',
    ItemType.tome       => 'Tomo',
    ItemType.relic      => 'Relíquia',
    ItemType.consumable => 'Consumível',
    ItemType.material   => 'Material',
    ItemType.chest      => 'Baú',
    ItemType.key        => 'Chave',
    ItemType.title      => 'Título',
    ItemType.cosmetic   => 'Cosmético',
    ItemType.lore       => 'Lore',
    ItemType.currency   => 'Moeda',
    ItemType.darkItem   => 'Item Sombrio',
    ItemType.misc       => 'Misc',
  };
}

class ItemTypeParser {
  ItemTypeParser._();

  static const Map<String, ItemType> _byString = {
    'weapon':     ItemType.weapon,
    'armor':      ItemType.armor,
    'accessory':  ItemType.accessory,
    'shield':     ItemType.shield,
    'tome':       ItemType.tome,
    'relic':      ItemType.relic,
    'consumable': ItemType.consumable,
    'material':   ItemType.material,
    'chest':      ItemType.chest,
    'key':        ItemType.key,
    'title':      ItemType.title,
    'cosmetic':   ItemType.cosmetic,
    'lore':       ItemType.lore,
    'currency':   ItemType.currency,
    'dark_item':  ItemType.darkItem,
    'darkItem':   ItemType.darkItem,
    'misc':       ItemType.misc,
  };

  static ItemType? fromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return _byString[raw.toLowerCase()];
  }
}
