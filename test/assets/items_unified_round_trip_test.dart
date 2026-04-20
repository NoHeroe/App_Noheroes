import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/models/item_spec.dart';

// Simula o caminho real do runtime:
//   JSON asset → seeder encoda campos como string → banco guarda →
//   ItemSpec.fromRow decodifica strings → fromJson usa o Map resultante.
// Se algum item quebra nesse pipeline, é aqui que pega.
void main() {
  test('round-trip seeder → fromRow → fromJson em TODOS os 181 itens', () {
    final raw = File('assets/data/items_unified.json').readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    final failures = <String>[];

    for (final item in items) {
      // Simula o que o seeder grava no banco: arrays/objects viram JSON strings.
      final reEncodedJson = <String, dynamic>{
        'key':          item['key'],
        'name':         item['name'],
        'description':  item['description'] ?? '',
        'type':         item['type'],
        'subtype':      item['subtype'],
        'slot':         item['slot'],
        'rank':         item['rank'],
        'required_rank': item['required_rank'],
        'rarity':       item['rarity'] ?? 'common',
        'is_secret':    item['is_secret'] ?? false,
        'is_unique':    item['is_unique'] ?? false,
        'is_dark_item': item['is_dark_item'] ?? false,
        'is_evolving':  item['is_evolving'] ?? false,
        'required_level': item['required_level'] ?? 1,
        // Round-trip: o banco armazena como JSON string; fromRow faz jsonDecode.
        'allowed_classes':  jsonDecode(jsonEncode(item['allowed_classes'] ?? const [])),
        'allowed_factions': jsonDecode(jsonEncode(item['allowed_factions'] ?? const [])),
        'stats':   jsonDecode(jsonEncode(item['stats'] ?? const {})),
        'effects': jsonDecode(jsonEncode(item['effects'] ?? const {})),
        'sources': jsonDecode(jsonEncode(item['sources'] ?? const [])),
        'shop_price_coins':  item['shop_price_coins'],
        'shop_price_gems':   item['shop_price_gems'],
        'stack_max':         item['stack_max'] ?? 1,
        'durability_max':    item['durability_max'],
        'durability_breaks_to': item['durability_breaks_to'],
        'is_stackable':   item['is_stackable'] ?? false,
        'is_consumable':  item['is_consumable'] ?? false,
        'is_equippable':  item['is_equippable'] ?? false,
        'is_tradable':    item['is_tradable'] ?? true,
        'is_sellable':    item['is_sellable'] ?? true,
        'bind_on_pickup': item['bind_on_pickup'] ?? false,
        'craft_recipe_id': item['craft_recipe_id'],
        'forge_recipe_id': item['forge_recipe_id'],
        'enchant_allowed': item['enchant_allowed'] ?? true,
        'sombrio_content_id': item['sombrio_content_id'],
        'evolution_stages': item['evolution_stages'] == null
            ? null
            : jsonDecode(jsonEncode(item['evolution_stages'])),
        'image': item['image'] ?? '',
        'icon':  item['icon'],
      };

      try {
        ItemSpec.fromJson(reEncodedJson);
      } catch (e, st) {
        failures.add('${item['key']}: $e\n$st');
      }
    }

    expect(failures, isEmpty,
        reason: 'items que falharam no round-trip:\n${failures.join("\n\n")}');
  });
}
