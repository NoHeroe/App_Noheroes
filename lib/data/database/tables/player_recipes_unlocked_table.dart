import 'package:drift/drift.dart';

// Receitas que cada jogador conhece. FK lógica: recipe_key → recipes_catalog.key.
// Sprint 2.2.
class PlayerRecipesUnlockedTable extends Table {
  @override
  String get tableName => 'player_recipes_unlocked';

  IntColumn  get playerId    => integer()();
  TextColumn get recipeKey   => text()();
  IntColumn  get unlockedAt  => integer()(); // millis since epoch
  TextColumn get unlockedVia => text()();    // starter|quest|drop|achievement|npc

  @override
  Set<Column> get primaryKey => {playerId, recipeKey};
}
