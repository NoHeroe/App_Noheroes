import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../database/app_database.dart';

// Popula recipes_catalog com as ~40 receitas canônicas de assets/data/recipes.json.
// Idempotente via insertOrIgnore — rodar várias vezes não duplica.
// Arrays JSON (materials, unlock_sources) são re-serializados pra string antes
// de persistir, seguindo o padrão de items_catalog_seeder.
class RecipesCatalogSeeder {
  final AppDatabase _db;
  RecipesCatalogSeeder(this._db);

  Future<void> seed() async {
    try {
      final raw = await rootBundle.loadString('assets/data/recipes.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = (data['recipes'] as List).cast<Map<String, dynamic>>();

      var inserted = 0;
      for (final rec in list) {
        final companion = RecipesCatalogTableCompanion.insert(
          key:             rec['key'] as String,
          name:            rec['name'] as String,
          description:     Value(rec['description'] as String? ?? ''),
          type:            rec['type'] as String,
          requiredRank:    Value(rec['required_rank'] as String?),
          requiredLevel:   Value(rec['required_level'] as int? ?? 1),
          requiredStation: Value(rec['required_station'] as String? ?? 'workshop'),
          resultItemKey:   rec['result_item_key'] as String,
          resultQuantity:  Value(rec['result_quantity'] as int? ?? 1),
          materials:       jsonEncode(rec['materials'] ?? const []),
          costCoins:       Value(rec['cost_coins'] as int? ?? 0),
          durationSec:     Value(rec['duration_sec'] as int? ?? 0),
          unlockSources:   jsonEncode(rec['unlock_sources'] ?? const []),
          icon:            Value(rec['icon'] as String?),
        );
        final affected = await _db
            .into(_db.recipesCatalogTable)
            .insert(companion, mode: InsertMode.insertOrIgnore);
        if (affected != 0) inserted++;
      }

      // ignore: avoid_print
      print('[recipes_catalog_seeder] inserted=$inserted / '
          'total_in_file=${list.length} (ignored already-present: '
          '${list.length - inserted})');
    } catch (e) {
      // ignore: avoid_print
      print('[recipes_catalog_seeder] failed: $e');
    }
  }

  // Desbloqueia automaticamente todas as receitas com unlock_sources do tipo
  // 'starter' para o jogador informado. Idempotente — entries já existentes
  // são ignoradas via insertOrIgnore.
  //
  // Chamada:
  // - na criação de um jogador novo (register)
  // - para cada jogador existente dentro da migration 20→21
  Future<int> unlockStarterRecipesFor(int playerId) async {
    try {
      final raw = await rootBundle.loadString('assets/data/recipes.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = (data['recipes'] as List).cast<Map<String, dynamic>>();
      final now = DateTime.now().millisecondsSinceEpoch;

      var unlocked = 0;
      for (final rec in list) {
        final sources = (rec['unlock_sources'] as List?) ?? const [];
        final isStarter = sources.any((s) =>
            s is Map && s['type'] == 'starter');
        if (!isStarter) continue;

        final affected = await _db
            .into(_db.playerRecipesUnlockedTable)
            .insert(
              PlayerRecipesUnlockedTableCompanion.insert(
                playerId:    playerId,
                recipeKey:   rec['key'] as String,
                unlockedAt:  now,
                unlockedVia: 'starter',
              ),
              mode: InsertMode.insertOrIgnore,
            );
        if (affected != 0) unlocked++;
      }
      // ignore: avoid_print
      print('[recipes_catalog_seeder] unlocked $unlocked starter recipes '
          'for player=$playerId');
      return unlocked;
    } catch (e) {
      // ignore: avoid_print
      print('[recipes_catalog_seeder] unlockStarterRecipesFor failed: $e');
      return 0;
    }
  }
}
