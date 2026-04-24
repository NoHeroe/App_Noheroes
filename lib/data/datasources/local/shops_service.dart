import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/player_events.dart';
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
  final AppEventBus _eventBus;
  Future<List<ShopSpec>>? _cacheFuture;

  ShopsService(this._db, this._catalog, this._inventory, this._eventBus);

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

  // Itens visíveis pro jogador nessa loja. Sprint 2.2 pós-teste mudou
  // filosofia: todos os itens aparecem. Gates soft: rank/level/class/faction
  // viram `canInteract=false` + `rejectReasonLabel`. Só `canAppearInShop=false`
  // continua hard-reject (secret/unique/evolving nunca devem aparecer em loja).
  //
  // Exceção: classe 'shadowWeaver' ignora allowedClasses (é híbrido universal).
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

      // Defense-in-depth — ADR 0010. Itens secretos/únicos/evolutivos NUNCA
      // aparecem em loja, mesmo que o JSON coloque. Hard-skip preservado.
      if (!ItemSourcePolicy.canAppearInShop(spec)) continue;

      // Gates SOFT — coletam razão, adicionam item com canInteract=false.
      String? rejectReason;
      if (spec.requiredLevel > player.level) {
        rejectReason = 'Requer nível ${spec.requiredLevel}.';
      } else if (!ItemEquipPolicy.isRankSufficient(
          player.rank, spec.requiredRank)) {
        final r = spec.requiredRank?.name.toUpperCase() ?? '?';
        rejectReason = 'Requer rank $r ou superior.';
      } else if (spec.allowedClasses.isNotEmpty &&
          player.classKey != 'shadowWeaver' &&
          (player.classKey == null ||
              !spec.allowedClasses.contains(player.classKey))) {
        final pt = _formatClassList(spec.allowedClasses);
        rejectReason = 'Apenas para $pt.';
      } else if (spec.allowedFactions.isNotEmpty &&
          (player.factionKey == null ||
              !spec.allowedFactions.contains(player.factionKey))) {
        final pt = spec.allowedFactions.join(', ');
        rejectReason = 'Apenas para facção $pt.';
      }

      final price = entry.priceCoins;
      final gems  = entry.priceGems;
      final canAfford = (price == null || playerCoins >= price) &&
          (gems == null || playerGems >= gems);

      result.add(ShopItemView(
        spec:              spec,
        priceCoins:        price,
        priceGems:         gems,
        canAfford:         canAfford,
        canInteract:       rejectReason == null,
        rejectReasonLabel: rejectReason,
      ));
    }
    return result;
  }

  // Mapa class_id → PT-BR usado na mensagem de reject. Fallback pra key raw
  // quando não reconhecido.
  //
  // NOTA (dívida narrativa Sprint 2.1): items_unified.json usa 4 sub-classes
  // de mago (mage_raw, mage_arcane, mage_runic, mage_dark) em allowedClasses,
  // mas classes.json só tem 'mage' como classe canônica. Conseqüência: mage
  // atual nunca bate com mage_* → esses itens ficam inalcançáveis. Soft-gate
  // Sprint 2.2 expõe visualmente; conserto real (unificar listas) fica
  // pra Sprint 3.x narrativa.
  static const Map<String, String> _classLabelsPt = {
    'warrior':      'Guerreiro',
    'colossus':     'Colosso',
    'monk':         'Monge',
    'rogue':        'Ladino',
    'hunter':       'Caçador',
    'druid':        'Druida',
    'mage':         'Mago',
    'mage_raw':     'Mago Primordial',
    'mage_arcane':  'Mago Arcano',
    'mage_runic':   'Mago Rúnico',
    'mage_dark':    'Mago Sombrio',
    'shadowWeaver': 'Tecelão Sombrio',
  };

  static String _formatClassList(List<String> keys) {
    final pt = keys.map((k) => _classLabelsPt[k] ?? k).toList();
    if (pt.length == 1) return pt.first;
    if (pt.length == 2) return '${pt[0]} e ${pt[1]}';
    return '${pt.sublist(0, pt.length - 1).join(", ")} e ${pt.last}';
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
    // Sprint 2.2 pós-teste: Tecelão Sombrio é híbrido universal — ignora
    // allowedClasses em todos os gates de compra/equip.
    if (spec.allowedClasses.isNotEmpty &&
        player.classKey != 'shadowWeaver' &&
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

    // Sprint 3.1 Bloco 14.5 — fix do débito #3 (ADR 0018): débito de
    // currency + credit de item agora vivem na mesma `db.transaction`.
    // Antes: 2-3 writes independentes; se `addItem` falhasse após
    // `UPDATE players`, jogador perdia gold/gems sem receber item.
    // Agora: rollback total em qualquer exceção, emits pós-commit.
    final int invId;
    try {
      invId = await _db.transaction<int>(() async {
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
        final id = await _inventory.addItem(
          playerId:    playerId,
          itemKey:     itemKey,
          quantity:    1,
          acquiredVia: SourceType.shop,
        );
        if (id < 0) {
          throw StateError('addItem retornou $id (shop=$shopKey item=$itemKey)');
        }
        return id;
      });
    } catch (_) {
      return BuyResult.rejected(BuyRejectReason.dbError);
    }

    // Emits pós-commit — só chega aqui se a transação acima commitou
    // inteira. Listeners (UI, analytics) consomem com a certeza de
    // que débito + credit estão persistidos.
    if (priceCoins != null && priceCoins > 0) {
      _eventBus.publish(GoldSpent(
        playerId: playerId,
        amount: priceCoins,
        source: GoldSink.shop,
      ));
    }
    if (priceGems != null && priceGems > 0) {
      _eventBus.publish(GemsSpent(
        playerId: playerId,
        amount: priceGems,
        source: GemSink.shop,
      ));
    }
    return BuyResult.ok(invId);
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
