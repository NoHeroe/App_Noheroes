import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/enums/source_type.dart';
import '../../../domain/models/recipe_spec.dart';
import 'recipes_catalog_service.dart';

// Gestão de receitas desbloqueadas por jogador (Época 2 — full-online
// Supabase, ADR-0024). Desbloqueio é idempotente via upsert ignoreDuplicates
// (player_recipes_unlocked tem PK composta player_id+recipe_key). playerId é o
// jogador (uuid) -> String.
class PlayerRecipesService {
  final SupabaseClient _client;
  final RecipesCatalogService _catalog;

  PlayerRecipesService(this._client, this._catalog);

  Future<List<RecipeSpec>> listUnlockedOf(String playerId) async {
    final rows = await _client
        .from('player_recipes_unlocked')
        .select('recipe_key')
        .eq('player_id', playerId);
    if (rows.isEmpty) return const [];

    final out = <RecipeSpec>[];
    for (final row in rows) {
      final spec = await _catalog.findByKey(row['recipe_key'] as String);
      if (spec == null) continue; // receita sumida do catálogo — defensivo
      out.add(spec);
    }
    return out;
  }

  Future<bool> isUnlocked(String playerId, String recipeKey) async {
    final row = await _client
        .from('player_recipes_unlocked')
        .select('recipe_key')
        .eq('player_id', playerId)
        .eq('recipe_key', recipeKey)
        .maybeSingle();
    return row != null;
  }

  Future<void> unlock({
    required String playerId,
    required String recipeKey,
    required SourceType via,
  }) async {
    // insertOrIgnore -> upsert com ignoreDuplicates (on conflict do nothing).
    await _client.from('player_recipes_unlocked').upsert(
      {
        'player_id': playerId,
        'recipe_key': recipeKey,
        'unlocked_at': DateTime.now().millisecondsSinceEpoch,
        'unlocked_via': via.name,
      },
      ignoreDuplicates: true,
    );
  }
}
