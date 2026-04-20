import '../../../core/utils/guild_rank.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/enums/recipe_type.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/recipe_spec.dart';
import '../../database/app_database.dart';

// Leitura do recipes_catalog. Catálogo é imutável após seed → cache em memória
// na primeira chamada, mesmo pattern do ItemsCatalogService.
class RecipesCatalogService {
  final AppDatabase _db;
  Future<List<RecipeSpec>>? _cacheFuture;

  RecipesCatalogService(this._db);

  Future<List<RecipeSpec>> findAll() => _cacheFuture ??= _loadAll();

  Future<List<RecipeSpec>> _loadAll() async {
    final rows = await _db.select(_db.recipesCatalogTable).get();
    return List<RecipeSpec>.unmodifiable(rows.map(RecipeSpec.fromRow));
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
