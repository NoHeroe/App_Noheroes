import 'package:drift/drift.dart';

// Catálogo imutável de receitas — seed via recipes_catalog_seeder (Bloco 2).
// Sprint 2.2. Complementa items_catalog com regras de criação.
class RecipesCatalogTable extends Table {
  @override
  String get tableName => 'recipes_catalog';

  TextColumn get key => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();

  // 'craft' (workshop) | 'forge' (bigorna)
  TextColumn get type => text()();

  // Rank mínimo do jogador: null | 'E'..'S'
  TextColumn get requiredRank => text().nullable()();

  IntColumn get requiredLevel => integer().withDefault(const Constant(1))();

  // Gate do local: 'workshop' | 'forge' | 'anvil' ...
  TextColumn get requiredStation =>
      text().withDefault(const Constant('workshop'))();

  // FK lógica → items_catalog.key
  TextColumn get resultItemKey => text()();
  IntColumn get resultQuantity => integer().withDefault(const Constant(1))();

  // JSON array: [{item_key, quantity}, ...]
  TextColumn get materials => text()();

  IntColumn get costCoins => integer().withDefault(const Constant(0))();
  IntColumn get durationSec => integer().withDefault(const Constant(0))();

  // JSON array: [{type: 'starter'|'quest'|...}, ...]
  TextColumn get unlockSources => text()();

  TextColumn get icon => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
