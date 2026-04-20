import 'package:drift/drift.dart';

// Slots de equipamento ativos do jogador. Referência ao inventory_id da instância
// equipada. PK composta (player_id, slot) — 1 item por slot.
//
// Slots canônicos: main_hand / off_hand / head / chest / legs / feet / hands /
// shoulders / waist / ring / necklace / relic
class PlayerEquipmentTable extends Table {
  @override
  String get tableName => 'player_equipment';

  IntColumn  get playerId    => integer()();
  TextColumn get slot        => text()();
  IntColumn  get inventoryId => integer()();

  @override
  Set<Column> get primaryKey => {playerId, slot};
}
