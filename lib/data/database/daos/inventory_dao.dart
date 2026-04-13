import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/items_table.dart';
import '../tables/inventory_table.dart';
import '../tables/shop_items_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [ItemsTable, InventoryTable, ShopItemsTable])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  // Busca inventário completo do jogador
  Future<List<InventoryWithItem>> getInventory(int playerId) async {
    final inv = await (select(inventoryTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();

    final result = <InventoryWithItem>[];
    for (final entry in inv) {
      final item = await (select(itemsTable)
            ..where((t) => t.id.equals(entry.itemId)))
          .getSingleOrNull();
      if (item != null) {
        result.add(InventoryWithItem(entry: entry, item: item));
      }
    }
    return result;
  }

  // Busca itens da loja disponíveis para o nível
  Future<List<ShopWithItem>> getShopItems(int playerLevel) async {
    final shopItems = await (select(shopItemsTable)
          ..where((t) => t.isAvailable.equals(true))
          ..where((t) => t.requiredLevel.isSmallerOrEqualValue(playerLevel)))
        .get();

    final result = <ShopWithItem>[];
    for (final shop in shopItems) {
      final item = await (select(itemsTable)
            ..where((t) => t.id.equals(shop.itemId)))
          .getSingleOrNull();
      if (item != null) {
        result.add(ShopWithItem(shop: shop, item: item));
      }
    }
    return result;
  }

  // Compra item
  Future<String?> buyItem({
    required int playerId,
    required int itemId,
    required int price,
    required int playerGold,
    required String currency,
  }) async {
    if (currency == 'gold' && playerGold < price) {
      return 'Ouro insuficiente.';
    }

    // Verifica se já tem no inventário (não stackable)
    final item = await (select(itemsTable)
          ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
    if (item == null) return 'Item não encontrado.';

    if (item.isStackable) {
      // Stackable: incrementa quantidade
      final existing = await (select(inventoryTable)
            ..where((t) => t.playerId.equals(playerId))
            ..where((t) => t.itemId.equals(itemId)))
          .getSingleOrNull();

      if (existing != null) {
        await (update(inventoryTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(InventoryTableCompanion(
                quantity: Value(existing.quantity + 1)));
      } else {
        await into(inventoryTable).insert(InventoryTableCompanion(
          playerId: Value(playerId),
          itemId: Value(itemId),
        ));
      }
    } else {
      await into(inventoryTable).insert(InventoryTableCompanion(
        playerId: Value(playerId),
        itemId: Value(itemId),
      ));
    }

    return null; // sucesso
  }

  // Equipa item
  Future<void> equipItem(int inventoryId, String slot) async {
    // Desequipa item anterior no mesmo slot
    await (update(inventoryTable)
          ..where((t) => t.equippedSlot.equals(slot)))
        .write(const InventoryTableCompanion(
      isEquipped: Value(false),
      equippedSlot: Value(null),
    ));

    await (update(inventoryTable)
          ..where((t) => t.id.equals(inventoryId)))
        .write(InventoryTableCompanion(
      isEquipped: const Value(true),
      equippedSlot: Value(slot),
    ));
  }

  // Remove item
  Future<void> removeItem(int inventoryId) {
    return (delete(inventoryTable)
          ..where((t) => t.id.equals(inventoryId)))
        .go();
  }
}

class InventoryWithItem {
  final InventoryTableData entry;
  final ItemsTableData item;
  InventoryWithItem({required this.entry, required this.item});
}

class ShopWithItem {
  final ShopItemsTableData shop;
  final ItemsTableData item;
  ShopWithItem({required this.shop, required this.item});
}
