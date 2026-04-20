import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../database/app_database.dart';

// Popula items_catalog com os itens canônicos de assets/data/items_unified.json.
// Idempotente via insertOrIgnore — rodar várias vezes não duplica.
// Campos JSON (arrays e objects) são re-serializados pra string antes de persistir.
//
// Sprint 2.2 pós-teste: aplicado parser tolerante int/double (_intOrNull) nos
// 5 casts de int. Bug regressão idêntico ao já corrigido em ItemSpec.fromJson
// no Sprint 2.1 (ba36ebc) — o write-path havia ficado pra trás.
//
// Loop com try/catch por item: 1 entry com schema quebrado não aborta o
// catálogo inteiro (antes, o try/catch envolvia o loop e 1 crash perdia N).
class ItemsCatalogSeeder {
  final AppDatabase _db;
  ItemsCatalogSeeder(this._db);

  Future<void> seed() async {
    final List<Map<String, dynamic>> list;
    try {
      final raw = await rootBundle
          .loadString('assets/data/items_unified.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      list = (data['items'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // ignore: avoid_print
      print('[items_catalog_seeder] failed at asset load: $e');
      return;
    }

    var inserted = 0;
    var failed = 0;
    for (final item in list) {
      try {
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
          requiredLevel:   Value(_intOrNull(item['required_level']) ?? 1),
          allowedClasses:  Value(jsonEncode(item['allowed_classes'] ?? const [])),
          allowedFactions: Value(jsonEncode(item['allowed_factions'] ?? const [])),
          stats:   Value(jsonEncode(item['stats'] ?? const {})),
          effects: Value(jsonEncode(item['effects'] ?? const {})),
          sources: Value(jsonEncode(item['sources'] ?? const [])),
          shopPriceCoins: Value(_intOrNull(item['shop_price_coins'])),
          shopPriceGems:  Value(_intOrNull(item['shop_price_gems'])),
          stackMax:       Value(_intOrNull(item['stack_max']) ?? 1),
          durabilityMax:  Value(_intOrNull(item['durability_max'])),
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
      } catch (e) {
        // ignore: avoid_print
        print('[items_catalog_seeder] FAILED item=${item['key']}: $e');
        failed++;
      }
    }

    // ignore: avoid_print
    print('[items_catalog_seeder] inserted=$inserted failed=$failed '
        'total_in_file=${list.length}');
  }
}

// Tolerante a int/double — JSON writers podem emitir 25.0 onde queremos 25.
// Mesmo helper que ItemSpec.fromJson usa no read-path (Sprint 2.1 ba36ebc).
// Duplicado aqui pra evitar dependência cruzada domain → data.
int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
