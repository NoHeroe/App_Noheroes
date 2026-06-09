import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/player_events.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../core/utils/item_source_policy.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/shop_item_view.dart';
import '../../../domain/models/shop_spec.dart';
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
  insufficientInsignias,
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

// Orquestra leitura do shops.json (asset) + compras (Supabase, Época 2 —
// ADR-0024). Respeita ADR 0010 via defense-in-depth (canAppearInShop) e gates
// de acesso do jogador. A transação de compra (débito de moeda + credit do
// item, atômica) vive na RPC shop_buy_item.
class ShopsService {
  final SupabaseClient _client;
  final ItemsCatalogService _catalog;
  final PlayerInventoryService _inventory;
  final AppEventBus _eventBus;
  Future<List<ShopSpec>>? _cacheFuture;

  ShopsService(this._client, this._catalog, this._inventory, this._eventBus);

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

  // Itens visíveis pro jogador nessa loja. Gates soft: rank/level/class/faction
  // viram `canInteract=false` + `rejectReasonLabel`. Só `canAppearInShop=false`
  // continua hard-reject (secret/unique/evolving nunca devem aparecer em loja).
  //
  // Exceção: classe 'shadowWeaver' ignora allowedClasses (é híbrido universal).
  Future<List<ShopItemView>> itemsOf({
    required String shopKey,
    required PlayerSnapshot player,
    required int playerCoins,
    required int playerGems,
    int playerInsignias = 0,
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
      final insignias = entry.priceInsignias;
      final canAfford = (price == null || playerCoins >= price) &&
          (gems == null || playerGems >= gems) &&
          (insignias == null || playerInsignias >= insignias);

      result.add(ShopItemView(
        spec:              spec,
        priceCoins:        price,
        priceGems:         gems,
        priceInsignias:    insignias,
        canAfford:         canAfford,
        canInteract:       rejectReason == null,
        rejectReasonLabel: rejectReason,
      ));
    }
    return result;
  }

  // Mapa class_id → PT-BR usado na mensagem de reject. Fallback pra key raw
  // quando não reconhecido.
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
    required String playerId,
    required PlayerSnapshot player,
    required int playerCoins,
    required int playerGems,
    int playerInsignias = 0,
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
    // Tecelão Sombrio é híbrido universal — ignora allowedClasses nos gates.
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
    final priceInsignias = entry.priceInsignias;
    if (priceCoins == null && priceGems == null && priceInsignias == null) {
      return BuyResult.rejected(BuyRejectReason.noPriceDefined);
    }
    if (priceCoins != null && playerCoins < priceCoins) {
      return BuyResult.rejected(BuyRejectReason.insufficientCoins);
    }
    if (priceGems != null && playerGems < priceGems) {
      return BuyResult.rejected(BuyRejectReason.insufficientGems);
    }
    if (priceInsignias != null && playerInsignias < priceInsignias) {
      return BuyResult.rejected(BuyRejectReason.insufficientInsignias);
    }

    // Transação atômica (débito de gold/gems/insignias + credit do item via
    // inventory_add_item) -> RPC shop_buy_item. Espelha a antiga
    // db.transaction (Sprint 3.1 Bloco 14.5): rollback total em qualquer
    // exceção. A RPC valida saldo defensivamente e levanta em falha.
    final int invId;
    try {
      final res = await _client.rpc('shop_buy_item', params: {
        'p_player': playerId,
        'p_shop_key': shopKey,
        'p_item_key': itemKey,
        'p_coins': priceCoins,
        'p_gems': priceGems,
        'p_insignias': priceInsignias,
      });
      final id = _asInt(res) ?? -1;
      if (id < 0) {
        return BuyResult.rejected(BuyRejectReason.dbError);
      }
      invId = id;
    } catch (_) {
      return BuyResult.rejected(BuyRejectReason.dbError);
    }

    // Emits pós-commit — só chega aqui se a RPC commitou inteira.
    // NOTA: GoldSpent/GemsSpent ainda usam `int playerId` (camada de eventos
    // não-migrada). Bridge via _eventPlayerId(uuid)->int, mesmo padrão da
    // EnchantService já migrada (ver 'unresolved'). Listeners (analytics,
    // quests "gaste X ouro") seguem recebendo o sinal.
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

  // Bridge uuid String -> int pra eventos legacy (mesmo padrão da
  // EnchantService já migrada). Ver 'unresolved' do resumo de migração.

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

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
