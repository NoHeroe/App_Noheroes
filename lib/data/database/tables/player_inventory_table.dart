import 'package:drift/drift.dart';

// Instâncias de itens que cada jogador possui. FK lógica: item_key → items_catalog.key.
// Introduzida no Sprint 2.1 — substitui a antiga `inventory` que será aposentada.
class PlayerInventoryTable extends Table {
  @override
  String get tableName => 'player_inventory';

  IntColumn  get id          => integer().autoIncrement()();
  IntColumn  get playerId    => integer()();
  TextColumn get itemKey     => text()();
  IntColumn  get quantity    => integer().withDefault(const Constant(1))();

  // Nullable — só preenche pra itens com durability_max.
  IntColumn  get durabilityCurrent => integer().nullable()();

  IntColumn  get acquiredAt  => integer()(); // millis since epoch

  // shop / loot / craft / quest / achievement / starter / purchase / pvp_drop ...
  TextColumn get acquiredVia => text()();

  // Nullable — só preenche pra itens is_unique + is_evolving (ex.: 'stage_E' do Colar).
  TextColumn get evolutionStage => text().nullable()();

  BoolColumn get isEquipped => boolean().withDefault(const Constant(false))();

  // Sprint 2.3 — encantamento. Null até o jogador aplicar runa/seiva.
  // Substituir runa faz a anterior ser perdida (decisão Sprint 2.3).
  // sapChargesRemaining: carga inicial ao aplicar; decay pra Sprint 2.4.
  TextColumn get appliedRuneKey => text().nullable()();
  TextColumn get appliedSapKey => text().nullable()();
  IntColumn get sapChargesRemaining => integer().nullable()();
}
