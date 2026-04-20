import 'package:flutter/material.dart';

// ADR 0008 — 7 raridades canônicas, ordem crescente.
// Cores de Material.Colors padrão (sem criar tema novo).
enum ItemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
  divine,
}

extension ItemRarityExt on ItemRarity {
  String get label => switch (this) {
    ItemRarity.common    => 'Comum',
    ItemRarity.uncommon  => 'Incomum',
    ItemRarity.rare      => 'Rara',
    ItemRarity.epic      => 'Épica',
    ItemRarity.legendary => 'Lendária',
    ItemRarity.mythic    => 'Mítica',
    ItemRarity.divine    => 'Divina',
  };

  Color get color => switch (this) {
    ItemRarity.common    => Colors.grey,
    ItemRarity.uncommon  => Colors.green,
    ItemRarity.rare      => Colors.blue,
    ItemRarity.epic      => Colors.purple,
    ItemRarity.legendary => Colors.orange,
    ItemRarity.mythic    => Colors.red,
    ItemRarity.divine    => Colors.amber,
  };
}

class ItemRarityParser {
  ItemRarityParser._();

  static const Map<String, ItemRarity> _byString = {
    'common':    ItemRarity.common,
    'uncommon':  ItemRarity.uncommon,
    'rare':      ItemRarity.rare,
    'epic':      ItemRarity.epic,
    'legendary': ItemRarity.legendary,
    'mythic':    ItemRarity.mythic,
    'divine':    ItemRarity.divine,
  };

  static ItemRarity? fromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return _byString[raw.toLowerCase()];
  }
}
