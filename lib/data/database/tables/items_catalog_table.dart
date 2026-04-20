import 'package:drift/drift.dart';

// Catálogo imutável de itens — seed via JSON (assets/data/items_unified.json).
// Schema canônico do Sprint 2.1. Ver ADR 0008 (flags independentes).
class ItemsCatalogTable extends Table {
  @override
  String get tableName => 'items_catalog';

  TextColumn get key => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();

  // weapon / armor / accessory / shield / tome / relic / consumable /
  // material / chest / key / title / cosmetic / lore / currency / dark_item / misc
  TextColumn get type => text()();
  TextColumn get subtype => text().nullable()();
  TextColumn get slot => text().nullable()();

  // Rank da Guilda — E/D/C/B/A/S ou null
  TextColumn get rank => text().nullable()();
  TextColumn get requiredRank => text().nullable()();

  // common / uncommon / rare / epic / legendary / mythic / divine
  TextColumn get rarity => text().withDefault(const Constant('common'))();

  // Flags booleanas ortogonais (ADR 0008)
  BoolColumn get isSecret    => boolean().withDefault(const Constant(false))();
  BoolColumn get isUnique    => boolean().withDefault(const Constant(false))();
  BoolColumn get isDarkItem  => boolean().withDefault(const Constant(false))();
  BoolColumn get isEvolving  => boolean().withDefault(const Constant(false))();

  IntColumn get requiredLevel => integer().withDefault(const Constant(1))();

  // Arrays JSON — parseados em ItemSpec.fromRow no Bloco 3.
  TextColumn get allowedClasses  => text().withDefault(const Constant('[]'))();
  TextColumn get allowedFactions => text().withDefault(const Constant('[]'))();

  // Objetos JSON livres.
  TextColumn get stats   => text().withDefault(const Constant('{}'))();
  TextColumn get effects => text().withDefault(const Constant('{}'))();

  // Array de objetos {type, ...params} — ADR 0010.
  TextColumn get sources => text().withDefault(const Constant('[]'))();

  IntColumn get shopPriceCoins => integer().nullable()();
  IntColumn get shopPriceGems  => integer().nullable()();

  IntColumn get stackMax => integer().withDefault(const Constant(1))();

  IntColumn get durabilityMax       => integer().nullable()();
  TextColumn get durabilityBreaksTo => text().nullable()();

  BoolColumn get isStackable   => boolean().withDefault(const Constant(false))();
  BoolColumn get isConsumable  => boolean().withDefault(const Constant(false))();
  BoolColumn get isEquippable  => boolean().withDefault(const Constant(false))();
  BoolColumn get isTradable    => boolean().withDefault(const Constant(true))();
  BoolColumn get isSellable    => boolean().withDefault(const Constant(true))();
  BoolColumn get bindOnPickup  => boolean().withDefault(const Constant(false))();

  TextColumn get craftRecipeId => text().nullable()();
  TextColumn get forgeRecipeId => text().nullable()();
  BoolColumn get enchantAllowed => boolean().withDefault(const Constant(true))();

  TextColumn get sombrioContentId => text().nullable()();

  // JSON — só preenchido quando is_evolving = true.
  TextColumn get evolutionStages => text().nullable()();

  TextColumn get image => text().withDefault(const Constant(''))();
  TextColumn get icon  => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
