import 'package:drift/drift.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/enums/equipment_slot.dart';
import '../../../domain/models/inventory_entry_with_spec.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../database/app_database.dart';
import 'items_catalog_service.dart';

// Gerencia os 12 slots de equipamento ativos. Valida via ItemEquipPolicy
// antes de equipar; desequipa automaticamente o ocupante atual se houver.
//
// Retorna EquipResult (spec original do Sprint_2.1 pediu Future<void>; retorno
// explícito facilita UI/snackbars no Bloco 5).
//
// TODO: teste de integração em sprint futura (requer Drift in-memory).
class PlayerEquipmentService {
  final AppDatabase _db;
  final ItemsCatalogService _catalog;

  PlayerEquipmentService(this._db, this._catalog);

  Future<EquipResult> equip({
    required int playerId,
    required int inventoryId,
    required PlayerSnapshot player,
  }) async {
    final entry = await (_db.select(_db.playerInventoryTable)
          ..where((t) => t.id.equals(inventoryId)))
        .getSingleOrNull();
    if (entry == null) {
      return const EquipResult.rejected(RejectReason.notEquippable);
    }
    if (entry.playerId != playerId) {
      return const EquipResult.rejected(RejectReason.notEquippable);
    }

    final spec = await _catalog.findByKey(entry.itemKey);
    if (spec == null || spec.slot == null) {
      return const EquipResult.rejected(RejectReason.notEquippable);
    }

    final check = ItemEquipPolicy.canEquipItem(item: spec, player: player);
    if (!check.isOk) return check;

    final slot = spec.slot!;

    // Desequipa o atual ocupante do slot (se houver).
    final occupant = await (_db.select(_db.playerEquipmentTable)
          ..where((t) =>
              t.playerId.equals(playerId) & t.slot.equals(slot.dbValue)))
        .getSingleOrNull();
    if (occupant != null) {
      await (_db.update(_db.playerInventoryTable)
            ..where((t) => t.id.equals(occupant.inventoryId)))
          .write(const PlayerInventoryTableCompanion(
        isEquipped: Value(false),
      ));
      await (_db.delete(_db.playerEquipmentTable)
            ..where((t) =>
                t.playerId.equals(playerId) & t.slot.equals(slot.dbValue)))
          .go();
    }

    await _db.into(_db.playerEquipmentTable).insert(
          PlayerEquipmentTableCompanion.insert(
            playerId:    playerId,
            slot:        slot.dbValue,
            inventoryId: inventoryId,
          ),
          mode: InsertMode.insertOrReplace,
        );

    await (_db.update(_db.playerInventoryTable)
          ..where((t) => t.id.equals(inventoryId)))
        .write(const PlayerInventoryTableCompanion(
      isEquipped: Value(true),
    ));

    return const EquipResult.ok();
  }

  Future<void> unequip({
    required int playerId,
    required EquipmentSlot slot,
  }) async {
    final row = await (_db.select(_db.playerEquipmentTable)
          ..where((t) =>
              t.playerId.equals(playerId) & t.slot.equals(slot.dbValue)))
        .getSingleOrNull();
    if (row == null) return;

    await (_db.update(_db.playerInventoryTable)
          ..where((t) => t.id.equals(row.inventoryId)))
        .write(const PlayerInventoryTableCompanion(
      isEquipped: Value(false),
    ));
    await (_db.delete(_db.playerEquipmentTable)
          ..where((t) =>
              t.playerId.equals(playerId) & t.slot.equals(slot.dbValue)))
        .go();
  }

  Future<List<InventoryEntryWithSpec>> equippedItemsOf(int playerId) async {
    final slots = await (_db.select(_db.playerEquipmentTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    if (slots.isEmpty) return const [];

    final out = <InventoryEntryWithSpec>[];
    for (final s in slots) {
      final inv = await (_db.select(_db.playerInventoryTable)
            ..where((t) => t.id.equals(s.inventoryId)))
          .getSingleOrNull();
      if (inv == null) continue;
      final spec = await _catalog.findByKey(inv.itemKey);
      if (spec == null) continue;
      out.add(InventoryEntryWithSpec(entry: inv, spec: spec));
    }
    return out;
  }

  Future<Map<String, num>> aggregatedStatsOf(int playerId) async {
    final equipped = await equippedItemsOf(playerId);
    // Respeita evolution_stage pra items is_evolving (ex.: Colar da Guilda).
    return ItemEquipPolicy.aggregateStatsFromEquippedEntries(equipped);
  }
}
