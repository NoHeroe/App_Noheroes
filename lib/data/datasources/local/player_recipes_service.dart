import 'package:drift/drift.dart';
import '../../../domain/enums/source_type.dart';
import '../../../domain/models/recipe_spec.dart';
import '../../database/app_database.dart';
import 'recipes_catalog_service.dart';

// Gestão de receitas desbloqueadas por jogador. Desbloqueio é idempotente
// via insertOrIgnore (player_recipes_unlocked tem PK composta).
class PlayerRecipesService {
  final AppDatabase _db;
  final RecipesCatalogService _catalog;

  PlayerRecipesService(this._db, this._catalog);

  Future<List<RecipeSpec>> listUnlockedOf(int playerId) async {
    final rows = await (_db.select(_db.playerRecipesUnlockedTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    if (rows.isEmpty) return const [];

    final out = <RecipeSpec>[];
    for (final row in rows) {
      final spec = await _catalog.findByKey(row.recipeKey);
      if (spec == null) continue; // receita sumida do catálogo — defensivo
      out.add(spec);
    }
    return out;
  }

  Future<bool> isUnlocked(int playerId, String recipeKey) async {
    final row = await (_db.select(_db.playerRecipesUnlockedTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.recipeKey.equals(recipeKey)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> unlock({
    required int playerId,
    required String recipeKey,
    required SourceType via,
  }) async {
    await _db.into(_db.playerRecipesUnlockedTable).insert(
          PlayerRecipesUnlockedTableCompanion.insert(
            playerId:    playerId,
            recipeKey:   recipeKey,
            unlockedAt:  DateTime.now().millisecondsSinceEpoch,
            unlockedVia: via.name,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
