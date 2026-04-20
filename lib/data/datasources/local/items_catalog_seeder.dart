import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../database/app_database.dart';

// Popula items_catalog com os 181 itens canônicos do assets/data/items_unified.json.
// Idempotente via insertOrIgnore — rodar várias vezes não duplica.
// Campos JSON (arrays e objects) são re-serializados pra string antes de persistir.
class ItemsCatalogSeeder {
  final AppDatabase _db;
  ItemsCatalogSeeder(this._db);

  Future<void> seed() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/items_unified.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = (data['items'] as List).cast<Map<String, dynamic>>();

      var inserted = 0;
      for (final item in list) {
        final companion = ItemsCatalogTableCompanion.insert(
          key:          item['key'] as String,
          name:         item['name'] as String,
          description:  Value(item['description'] as String? ?? ''),
          type:         item['type'] as String,
          subtype:      Value(item['subtype'] as String?),
          slot:         Value(item['slot'] as String?),
          rank:         Value(item['rank'] as String?),
          requiredRank: Value(item['required_rank'] as String?),
          rarity:       Value(item['rarity'] as String? ?? 'common'),
          isSecret:     Value(item['is_secret'] as bool? ?? false),
          isUnique:     Value(item['is_unique'] as bool? ?? false),
          isDarkItem:   Value(item['is_dark_item'] as bool? ?? false),
          isEvolving:   Value(item['is_evolving'] as bool? ?? false),
          requiredLevel:   Value(item['required_level'] as int? ?? 1),
          allowedClasses:  Value(jsonEncode(item['allowed_classes'] ?? const [])),
          allowedFactions: Value(jsonEncode(item['allowed_factions'] ?? const [])),
          stats:   Value(jsonEncode(item['stats'] ?? const {})),
          effects: Value(jsonEncode(item['effects'] ?? const {})),
          sources: Value(jsonEncode(item['sources'] ?? const [])),
          shopPriceCoins: Value(item['shop_price_coins'] as int?),
          shopPriceGems:  Value(item['shop_price_gems'] as int?),
          stackMax:       Value(item['stack_max'] as int? ?? 1),
          durabilityMax:  Value(item['durability_max'] as int?),
          durabilityBreaksTo: Value(item['durability_breaks_to'] as String?),
          isStackable:    Value(item['is_stackable'] as bool? ?? false),
          isConsumable:   Value(item['is_consumable'] as bool? ?? false),
          isEquippable:   Value(item['is_equippable'] as bool? ?? false),
          isTradable:     Value(item['is_tradable'] as bool? ?? true),
          isSellable:     Value(item['is_sellable'] as bool? ?? true),
          bindOnPickup:   Value(item['bind_on_pickup'] as bool? ?? false),
          craftRecipeId:  Value(item['craft_recipe_id'] as String?),
          forgeRecipeId:  Value(item['forge_recipe_id'] as String?),
          enchantAllowed: Value(item['enchant_allowed'] as bool? ?? true),
          sombrioContentId: Value(item['sombrio_content_id'] as String?),
          evolutionStages: item['evolution_stages'] == null
              ? const Value(null)
              : Value(jsonEncode(item['evolution_stages'])),
          image: Value(item['image'] as String? ?? ''),
          icon:  Value(item['icon'] as String?),
        );
        final affected = await _db
            .into(_db.itemsCatalogTable)
            .insert(companion, mode: InsertMode.insertOrIgnore);
        if (affected != 0) inserted++;
      }

      // ignore: avoid_print
      print('[items_catalog_seeder] inserted=$inserted / '
          'total_in_file=${list.length} (ignored already-present: '
          '${list.length - inserted})');
    } catch (e) {
      // ignore: avoid_print
      print('[items_catalog_seeder] failed: $e');
      // Fallback silencioso — padrão dos outros seeders do projeto.
    }
  }
}
