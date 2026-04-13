// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dao.dart';

// ignore_for_file: type=lint
mixin _$InventoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ItemsTableTable get itemsTable => attachedDatabase.itemsTable;
  $InventoryTableTable get inventoryTable => attachedDatabase.inventoryTable;
  $ShopItemsTableTable get shopItemsTable => attachedDatabase.shopItemsTable;
  InventoryDaoManager get managers => InventoryDaoManager(this);
}

class InventoryDaoManager {
  final _$InventoryDaoMixin _db;
  InventoryDaoManager(this._db);
  $$ItemsTableTableTableManager get itemsTable =>
      $$ItemsTableTableTableManager(_db.attachedDatabase, _db.itemsTable);
  $$InventoryTableTableTableManager get inventoryTable =>
      $$InventoryTableTableTableManager(
          _db.attachedDatabase, _db.inventoryTable);
  $$ShopItemsTableTableTableManager get shopItemsTable =>
      $$ShopItemsTableTableTableManager(
          _db.attachedDatabase, _db.shopItemsTable);
}
