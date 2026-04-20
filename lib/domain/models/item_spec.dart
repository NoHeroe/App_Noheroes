import 'dart:convert';
import '../../core/utils/guild_rank.dart';
import '../../data/database/app_database.dart';
import '../enums/equipment_slot.dart';
import '../enums/item_rarity.dart';
import '../enums/item_type.dart';
import '../enums/source_type.dart';

// Representação imutável de um item do catálogo. Construída via fromJson
// (formato do asset JSON) ou fromRow (linha Drift — delega pra fromJson
// parseando os campos-string como JSON).
class ItemSpec {
  final String key;
  final String name;
  final String description;
  final ItemType type;
  final String? subtype;
  final EquipmentSlot? slot;
  final GuildRank? rank;
  final GuildRank? requiredRank;
  final ItemRarity rarity;
  final bool isSecret;
  final bool isUnique;
  final bool isDarkItem;
  final bool isEvolving;
  final int requiredLevel;
  final List<String> allowedClasses;
  final List<String> allowedFactions;
  final Map<String, num> stats;
  final Map<String, dynamic> effects;
  final List<SourceSpec> sources;
  final int? shopPriceCoins;
  final int? shopPriceGems;
  final int stackMax;
  final int? durabilityMax;
  final String? durabilityBreaksTo;
  final bool isStackable;
  final bool isConsumable;
  final bool isEquippable;
  final bool isTradable;
  final bool isSellable;
  final bool bindOnPickup;
  final String? craftRecipeId;
  final String? forgeRecipeId;
  final bool enchantAllowed;
  final String? sombrioContentId;
  final Map<String, EvolutionStage>? evolutionStages;
  final String image;
  final String? icon;

  const ItemSpec._({
    required this.key,
    required this.name,
    required this.description,
    required this.type,
    required this.subtype,
    required this.slot,
    required this.rank,
    required this.requiredRank,
    required this.rarity,
    required this.isSecret,
    required this.isUnique,
    required this.isDarkItem,
    required this.isEvolving,
    required this.requiredLevel,
    required this.allowedClasses,
    required this.allowedFactions,
    required this.stats,
    required this.effects,
    required this.sources,
    required this.shopPriceCoins,
    required this.shopPriceGems,
    required this.stackMax,
    required this.durabilityMax,
    required this.durabilityBreaksTo,
    required this.isStackable,
    required this.isConsumable,
    required this.isEquippable,
    required this.isTradable,
    required this.isSellable,
    required this.bindOnPickup,
    required this.craftRecipeId,
    required this.forgeRecipeId,
    required this.enchantAllowed,
    required this.sombrioContentId,
    required this.evolutionStages,
    required this.image,
    required this.icon,
  });

  // Formato do asset JSON (snake_case). fromRow delega aqui após parsear os
  // campos JSON-string do banco.
  factory ItemSpec.fromJson(Map<String, dynamic> json) {
    final statsRaw = (json['stats'] as Map?) ?? const {};
    final stats = <String, num>{
      for (final e in statsRaw.entries)
        if (e.value is num) '${e.key}': e.value as num,
    };
    final sourcesRaw = (json['sources'] as List?) ?? const [];
    final sources = [
      for (final s in sourcesRaw)
        if (s is Map<String, dynamic>) SourceSpec.fromJson(s),
    ];
    final stagesRaw = json['evolution_stages'];
    final evolutionStages = stagesRaw == null
        ? null
        : <String, EvolutionStage>{
            for (final e in (stagesRaw as Map).entries)
              '${e.key}':
                  EvolutionStage.fromJson(e.value as Map<String, dynamic>),
          };

    return ItemSpec._(
      key:          json['key'] as String,
      name:         json['name'] as String,
      description:  json['description'] as String? ?? '',
      type: ItemTypeParser.fromString(json['type'] as String?) ?? ItemType.misc,
      subtype:      json['subtype'] as String?,
      slot:         EquipmentSlotParser.fromString(json['slot'] as String?),
      rank:         _parseRank(json['rank'] as String?),
      requiredRank: _parseRank(json['required_rank'] as String?),
      rarity: ItemRarityParser.fromString(json['rarity'] as String?) ??
          ItemRarity.common,
      isSecret:    json['is_secret'] as bool? ?? false,
      isUnique:    json['is_unique'] as bool? ?? false,
      isDarkItem:  json['is_dark_item'] as bool? ?? false,
      isEvolving:  json['is_evolving'] as bool? ?? false,
      requiredLevel: _intOrNull(json['required_level']) ?? 1,
      allowedClasses:
          ((json['allowed_classes'] as List?) ?? const []).cast<String>(),
      allowedFactions:
          ((json['allowed_factions'] as List?) ?? const []).cast<String>(),
      stats:   stats,
      effects: Map<String, dynamic>.from((json['effects'] as Map?) ?? const {}),
      sources: sources,
      shopPriceCoins:     _intOrNull(json['shop_price_coins']),
      shopPriceGems:      _intOrNull(json['shop_price_gems']),
      stackMax:           _intOrNull(json['stack_max']) ?? 1,
      durabilityMax:      _intOrNull(json['durability_max']),
      durabilityBreaksTo: json['durability_breaks_to'] as String?,
      isStackable:   json['is_stackable'] as bool? ?? false,
      isConsumable:  json['is_consumable'] as bool? ?? false,
      isEquippable:  json['is_equippable'] as bool? ?? false,
      isTradable:    json['is_tradable'] as bool? ?? true,
      isSellable:    json['is_sellable'] as bool? ?? true,
      bindOnPickup:  json['bind_on_pickup'] as bool? ?? false,
      craftRecipeId: json['craft_recipe_id'] as String?,
      forgeRecipeId: json['forge_recipe_id'] as String?,
      enchantAllowed:   json['enchant_allowed'] as bool? ?? true,
      sombrioContentId: json['sombrio_content_id'] as String?,
      evolutionStages:  evolutionStages,
      image: json['image'] as String? ?? '',
      icon:  json['icon'] as String?,
    );
  }

  factory ItemSpec.fromRow(ItemsCatalogTableData row) {
    return ItemSpec.fromJson({
      'key': row.key,
      'name': row.name,
      'description': row.description,
      'type': row.type,
      'subtype': row.subtype,
      'slot': row.slot,
      'rank': row.rank,
      'required_rank': row.requiredRank,
      'rarity': row.rarity,
      'is_secret':   row.isSecret,
      'is_unique':   row.isUnique,
      'is_dark_item': row.isDarkItem,
      'is_evolving': row.isEvolving,
      'required_level':   row.requiredLevel,
      'allowed_classes':  jsonDecode(row.allowedClasses),
      'allowed_factions': jsonDecode(row.allowedFactions),
      'stats':   jsonDecode(row.stats),
      'effects': jsonDecode(row.effects),
      'sources': jsonDecode(row.sources),
      'shop_price_coins':     row.shopPriceCoins,
      'shop_price_gems':      row.shopPriceGems,
      'stack_max':            row.stackMax,
      'durability_max':       row.durabilityMax,
      'durability_breaks_to': row.durabilityBreaksTo,
      'is_stackable':  row.isStackable,
      'is_consumable': row.isConsumable,
      'is_equippable': row.isEquippable,
      'is_tradable':   row.isTradable,
      'is_sellable':   row.isSellable,
      'bind_on_pickup': row.bindOnPickup,
      'craft_recipe_id': row.craftRecipeId,
      'forge_recipe_id': row.forgeRecipeId,
      'enchant_allowed':    row.enchantAllowed,
      'sombrio_content_id': row.sombrioContentId,
      'evolution_stages':
          row.evolutionStages == null ? null : jsonDecode(row.evolutionStages!),
      'image': row.image,
      'icon':  row.icon,
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ItemSpec && other.key == key);

  @override
  int get hashCode => key.hashCode;
}

class SourceSpec {
  final SourceType? type; // null quando fonte é unknown (forward-compat)
  final String? rawType;  // valor bruto preservado pra debug
  final Map<String, dynamic> params;

  const SourceSpec({
    required this.type,
    required this.rawType,
    required this.params,
  });

  factory SourceSpec.fromJson(Map<String, dynamic> json) {
    final raw = json['type'] as String?;
    final parsed = SourceTypeParser.fromString(raw);
    final params = <String, dynamic>{
      for (final e in json.entries)
        if (e.key != 'type') e.key: e.value,
    };
    return SourceSpec(type: parsed, rawType: raw, params: params);
  }
}

class EvolutionStage {
  final String description;
  final Map<String, num> stats;

  const EvolutionStage({required this.description, required this.stats});

  factory EvolutionStage.fromJson(Map<String, dynamic> json) {
    final statsRaw = (json['stats'] as Map?) ?? const {};
    return EvolutionStage(
      description: json['description'] as String? ?? '',
      stats: <String, num>{
        for (final e in statsRaw.entries)
          if (e.value is num) '${e.key}': e.value as num,
      },
    );
  }
}

// Tolerante a int/double — JSON writers podem emitir 15.0 onde queremos 15.
// Sem isso, `as int?` explode em todo o catálogo pela 1ª string "double".
int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

GuildRank? _parseRank(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  switch (raw.toUpperCase()) {
    case 'E': return GuildRank.e;
    case 'D': return GuildRank.d;
    case 'C': return GuildRank.c;
    case 'B': return GuildRank.b;
    case 'A': return GuildRank.a;
    case 'S': return GuildRank.s;
  }
  return null;
}
