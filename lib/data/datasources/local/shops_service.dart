import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../core/utils/item_source_policy.dart';
import '../../../domain/enums/source_type.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/shop_item_view.dart';
import '../../../domain/models/shop_spec.dart';
import '../../database/app_database.dart';
import 'items_catalog_service.dart';
import 'player_inventory_service.dart';

enum BuyRejectReason {
  shopNotFound,
  itemNotInShop,
  itemNotInCatalog,
  shopRejectsPlayerRank,
  shopRejectsPlayerFaction,
  blockedBySourcePolicy,
  levelTooLow,
  rankTooLow,
  classRestricted,
  factionRestricted,
  insufficientCoins,
  insufficientGems,
  noPriceDefined,
  dbError,
}

class BuyResult {
  final bool isOk;
  final int? inventoryId;
  final BuyRejectReason? reason;

  const BuyResult._({required this.isOk, this.inventoryId, this.reason});
  factory BuyResult.ok(int invId) =>
      BuyResult._(isOk: true, inventoryId: invId);
  factory BuyResult.rejected(BuyRejectReason r) =>
      BuyResult._(isOk: false, reason: r);
}

// Orquestra leitura do shops.json + compras. Respeita ADR 0010 via defense-
// in-depth (canAppearInShop) e gates de acesso do jogador.
class ShopsService {
  final AppDatabase _db;
  final ItemsCatalogService _catalog;
  final PlayerInventoryService _inventory;
  Future<List<ShopSpec>>? _cacheFuture;

  ShopsService(this._db, this._catalog, this._inventory);

  Future<List<ShopSpec>> listShops() => _cacheFuture ??= _loadAll();

  Future<List<ShopSpec>> _loadAll() async {
    final raw = await rootBundle.loadString('assets/data/shops.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final list = (data['shops'] as List).cast<Map<String, dynamic>>();
    return List<ShopSpec>.unmodifiable(list.map(ShopSpec.fromJson));
  }

  Future<ShopSpec?> findByKey(String key) async {
    final all = await listShops();
    for (final s in all) {
      if (s.key == key) return s;
    }
    return null;
  }

  // Lojas onde o jogador pode entrar (filtra por accepted_ranks/factions).
  Future<List<ShopSpec>> listShopsAvailableTo(PlayerSnapshot player) async {
    final all = await listShops();
    return all.where((s) => _canPlayerEnterShop(s, player)).toList();
  }

  // Itens visíveis pro jogador nessa loja. Aplica: canAppearInShop defensivo,
  // gates item-level, e marca canAfford.
  Future<List<ShopItemView>> itemsOf({
    required String shopKey,
    required PlayerSnapshot player,
    required int playerCoins,
    required int playerGems,
  }) async {
    final shop = await findByKey(shopKey);
    if (shop == null) return const [];
    if (!_canPlayerEnterShop(shop, player)) return const [];

    final result = <ShopItemView>[];
    for (final entry in shop.items) {
      final spec = await _catalog.findByKey(entry.itemKey);
      if (spec == null) continue;

      // Defense-in-depth — ADR 0010.
      if (!ItemSourcePolicy.canAppearInShop(spec)) continue;

      // Gates item-level.
      if (spec.requiredLevel > player.level) continue;
      if (!ItemEquipPolicy.isRankSufficient(player.rank, spec.requiredRank)) {
        continue;
      }
      if (spec.allowedClasses.isNotEmpty &&
          (player.classKey == null ||
              !spec.allowedClasses.contains(player.classKey))) {
        continue;
      }
      if (spec.allowedFactions.isNotEmpty &&
          (player.factionKey == null ||
              !spec.allowedFactions.contains(player.factionKey))) {
        continue;
      }

      final price = entry.priceCoins;
      final gems  = entry.priceGems;
      final canAfford = (price == null || playerCoins >= price) &&
          (gems == null || playerGems >= gems);

      result.add(ShopItemView(
        spec:       spec,
        priceCoins: price,
        priceGems:  gems,
        canAfford:  canAfford,
      ));
    }
    return result;
  }

  Future<BuyResult> buyItem({
    required String shopKey,
    required String itemKey,
    required int playerId,
    required PlayerSnapshot player,
    required int playerCoins,
    required int playerGems,
  }) async {
    final shop = await findByKey(shopKey);
    if (shop == null) return BuyResult.rejected(BuyRejectReason.shopNotFound);

    if (!_canPlayerEnterShop(shop, player)) {
      return BuyResult.rejected(
        player.factionKey == null && shop.acceptedFactions.isNotEmpty
            ? BuyRejectReason.shopRejectsPlayerFaction
            : BuyRejectReason.shopRejectsPlayerRank,
      );
    }

    final entry = shop.items.firstWhere(
      (e) => e.itemKey == itemKey,
      orElse: () => const ShopItemEntry(itemKey: ''),
    );
    if (entry.itemKey.isEmpty) {
      return BuyResult.rejected(BuyRejectReason.itemNotInShop);
    }

    final spec = await _catalog.findByKey(itemKey);
    if (spec == null) {
      return BuyResult.rejected(BuyRejectReason.itemNotInCatalog);
    }
    if (!ItemSourcePolicy.canAppearInShop(spec)) {
      return BuyResult.rejected(BuyRejectReason.blockedBySourcePolicy);
    }

    // Gates.
    if (spec.requiredLevel > player.level) {
      return BuyResult.rejected(BuyRejectReason.levelTooLow);
    }
    if (!ItemEquipPolicy.isRankSufficient(player.rank, spec.requiredRank)) {
      return BuyResult.rejected(BuyRejectReason.rankTooLow);
    }
    if (spec.allowedClasses.isNotEmpty &&
        (player.classKey == null ||
            !spec.allowedClasses.contains(player.classKey))) {
      return BuyResult.rejected(BuyRejectReason.classRestricted);
    }
    if (spec.allowedFactions.isNotEmpty &&
        (player.factionKey == null ||
            !spec.allowedFactions.contains(player.factionKey))) {
      return BuyResult.rejected(BuyRejectReason.factionRestricted);
    }

    // Preço.
    final priceCoins = entry.priceCoins;
    final priceGems  = entry.priceGems;
    if (priceCoins == null && priceGems == null) {
      return BuyResult.rejected(BuyRejectReason.noPriceDefined);
    }
    if (priceCoins != null && playerCoins < priceCoins) {
      return BuyResult.rejected(BuyRejectReason.insufficientCoins);
    }
    if (priceGems != null && playerGems < priceGems) {
      return BuyResult.rejected(BuyRejectReason.insufficientGems);
    }

    // Debita e entrega.
    try {
      if (priceCoins != null) {
        await (_db.update(_db.playersTable)
              ..where((t) => t.id.equals(playerId)))
            .write(PlayersTableCompanion(
          gold: Value(playerCoins - priceCoins),
        ));
      }
      if (priceGems != null) {
        await (_db.update(_db.playersTable)
              ..where((t) => t.id.equals(playerId)))
            .write(PlayersTableCompanion(
          gems: Value(playerGems - priceGems),
        ));
      }

      final invId = await _inventory.addItem(
        playerId:    playerId,
        itemKey:     itemKey,
        quantity:    1,
        acquiredVia: SourceType.shop,
      );
      if (invId < 0) return BuyResult.rejected(BuyRejectReason.dbError);
      return BuyResult.ok(invId);
    } catch (_) {
      return BuyResult.rejected(BuyRejectReason.dbError);
    }
  }

  bool _canPlayerEnterShop(ShopSpec shop, PlayerSnapshot player) {
    if (shop.acceptedRanks.isNotEmpty) {
      if (player.rank == null) return false;
      final rankStr = player.rank!.name.toUpperCase();
      if (!shop.acceptedRanks.contains(rankStr)) return false;
    }
    if (shop.acceptedFactions.isNotEmpty) {
      if (player.factionKey == null) return false;
      if (!shop.acceptedFactions.contains(player.factionKey)) return false;
    }
    return true;
  }
}
