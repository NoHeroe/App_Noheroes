import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/guild_rank.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/enums/recipe_type.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/recipe_spec.dart';

// Leitura do recipes_catalog (Época 2 — full-online Supabase, ADR-0024).
// Catálogo é imutável após seed → cache em memória na primeira chamada, mesmo
// pattern do ItemsCatalogService. Rows vêm como Map<String,dynamic> do
// PostgREST e são construídas via RecipeSpec.fromMap.
class RecipesCatalogService {
  final SupabaseClient _client;
  Future<List<RecipeSpec>>? _cacheFuture;

  RecipesCatalogService(this._client);

  Future<List<RecipeSpec>> findAll() => _cacheFuture ??= _loadAll();

  Future<List<RecipeSpec>> _loadAll() async {
    final rows = await _client.from('recipes_catalog').select();
    return List<RecipeSpec>.unmodifiable(
      rows.map((r) => RecipeSpec.fromMap(r)),
    );
  }

  Future<RecipeSpec?> findByKey(String key) async {
    final all = await findAll();
    for (final s in all) {
      if (s.key == key) return s;
    }
    return null;
  }

  Future<List<RecipeSpec>> findByType(RecipeType type) async {
    final all = await findAll();
    return all.where((s) => s.type == type).toList(growable: false);
  }

  Future<List<RecipeSpec>> findByRank(GuildRank rank) async {
    final all = await findAll();
    return all.where((s) => s.requiredRank == rank).toList(growable: false);
  }

  // Receitas com gate de rank+level compatível com o jogador.
  // NÃO filtra por unlock — a UI cruza com PlayerRecipesService.listUnlockedOf
  // ou isUnlocked pra saber o que realmente está liberado.
  Future<List<RecipeSpec>> findAvailableFor(PlayerSnapshot player) async {
    final all = await findAll();
    return all.where((r) {
      if (!ItemEquipPolicy.isRankSufficient(player.rank, r.requiredRank)) {
        return false;
      }
      if (player.level < r.requiredLevel) return false;
      return true;
    }).toList(growable: false);
  }
}
