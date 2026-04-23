import 'package:drift/drift.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/crafting_events.dart';
import '../../../core/events/player_events.dart';
import '../../../core/utils/enchant_policy.dart';
import '../../../domain/models/enchant_result.dart';
import '../../../domain/models/enchant_spec.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../database/app_database.dart';
import 'items_catalog_service.dart';
import 'player_inventory_service.dart';

// Aplica encantamento em item equipável do inventário. Transação atômica
// espelhando CraftingService (Sprint 2.2):
//   - Policy pura valida antes da escrita
//   - _db.transaction<T> envolve debit + consume + update
//   - Qualquer throw interno desfaz TODAS as mudanças
//
// Sprint 2.3 fix (D.2): runas agora vivem no items_catalog como ItemType.rune.
// Service lê via ItemsCatalogService + converte ItemSpec → EnchantSpec via
// EnchantSpec.fromItemSpec. Consumo usa PlayerInventoryService.consumeOneByKey
// (substitui o antigo PlayerEnchantsService.consumeOne).
//
// Soft-gate de substituição: se item já tem runa e confirmReplacement=false,
// retorna alreadyEnchantedSameSlot pra UI interceptar. Com confirmação, a
// policy é re-consultada com currentRuneOnItem=null (simula slot vazio) e,
// se aprovada, a runa anterior é perdida implicitamente (não volta pro
// inventário — decisão Sprint 2.3).
class EnchantService {
  final AppDatabase _db;
  final ItemsCatalogService _items;
  final PlayerInventoryService _playerInventory;
  final AppEventBus _eventBus;

  EnchantService(
      this._db, this._items, this._playerInventory, this._eventBus);

  // Resolve um item do catálogo e devolve como EnchantSpec. Retorna null
  // se a key não existe OU o item não é do tipo runa (defensivo — protege
  // contra chamadas com key arbitrária).
  Future<EnchantSpec?> _loadRuneSpec(String key) async {
    final item = await _items.findByKey(key);
    if (item == null) return null;
    // Enquanto seivas não chegam (Sprint 2.4), aceita só type: rune.
    // Usar .name evita import de ItemType só pra comparação.
    if (item.type.name != 'rune') return null;
    return EnchantSpec.fromItemSpec(item);
  }

  // `player` + `playerGems` vêm do call-site (UI ou service orquestrador) —
  // mesmo contrato de CraftingService.craft. Evita dependência de PlayerDao
  // aqui e mantém service focado na orquestração atômica.
  Future<EnchantResult> applyEnchantToItem({
    required int playerId,
    required int inventoryItemId,
    required String enchantKey,
    required PlayerSnapshot player,
    required int playerGems,
    bool confirmReplacement = false,
  }) async {
    // 1. Spec da runa.
    final enchant = await _loadRuneSpec(enchantKey);
    if (enchant == null) {
      return EnchantResult.rejected(EnchantRejectReason.enchantNotFound);
    }

    // 2. Row do item no inventário do jogador.
    final invRow = await (_db.select(_db.playerInventoryTable)
          ..where((t) =>
              t.id.equals(inventoryItemId) &
              t.playerId.equals(playerId)))
        .getSingleOrNull();
    if (invRow == null) {
      return EnchantResult.rejected(EnchantRejectReason.itemNotFound);
    }

    // 3. Spec do item alvo.
    final itemSpec = await _items.findByKey(invRow.itemKey);
    if (itemSpec == null) {
      return EnchantResult.rejected(EnchantRejectReason.itemNotFound);
    }

    // 4. Jogador possui a runa? (runa é item consumível no player_inventory).
    final hasEnchant =
        await _playerInventory.hasItem(playerId, enchantKey);

    // 5. Runa atualmente aplicada (se houver).
    EnchantSpec? currentRune;
    if (invRow.appliedRuneKey != null) {
      currentRune = await _loadRuneSpec(invRow.appliedRuneKey!);
    }

    // 6. Policy valida.
    var check = EnchantPolicy.canApply(
      enchant: enchant,
      item: itemSpec,
      player: player,
      playerGems: playerGems,
      enchantInInventory: hasEnchant,
      currentRuneOnItem: currentRune,
    );

    // 7. Soft-gate de substituição.
    if (!check.allowed &&
        check.reason == EnchantRejectReason.alreadyEnchantedSameSlot) {
      if (!confirmReplacement) {
        return check; // UI intercepta, pergunta, re-chama com confirmação
      }
      // Re-valida como se slot estivesse vazio. Se outro gate falhar,
      // retorna essa nova razão.
      check = EnchantPolicy.canApply(
        enchant: enchant,
        item: itemSpec,
        player: player,
        playerGems: playerGems,
        enchantInInventory: hasEnchant,
        currentRuneOnItem: null,
      );
      if (!check.allowed) return check;
    } else if (!check.allowed) {
      return check;
    }

    // 8. Transação atômica — debit gems + consume runa + set applied_rune_key.
    // Sprint 3.1 Bloco 7a — vars capturadas dentro da transação pra emit
    // pós-commit. Rollback deixa as vars originais (0/'') e o publish
    // vive fora do try; não alcançado se exception propagar.
    var capturedCost = 0;
    var capturedTargetItemKey = '';
    try {
      final result = await _db.transaction<EnchantResult>(() async {
        final cost = enchant.costGems ?? 0;
        if (cost > 0) {
          await _db.customUpdate(
            'UPDATE players SET gems = gems - ? WHERE id = ?',
            variables: [
              Variable.withInt(cost),
              Variable.withInt(playerId),
            ],
            updates: {_db.playersTable},
          );
        }

        // Consome 1 unidade da runa no inventário do jogador (item_key).
        // StateError aqui força rollback da transação.
        await _playerInventory.consumeOneByKey(
          playerId: playerId,
          itemKey: enchantKey,
        );

        // Grava runa aplicada no item. Runa anterior (currentRune) é perdida
        // implicitamente — decisão Sprint 2.3: substituir = perder anterior.
        await (_db.update(_db.playerInventoryTable)
              ..where((t) => t.id.equals(inventoryItemId)))
            .write(PlayerInventoryTableCompanion(
          appliedRuneKey: Value(enchantKey),
        ));

        capturedCost = cost;
        capturedTargetItemKey = invRow.itemKey;

        return EnchantResult.allowed(
          applied: enchant,
          replaced: currentRune,
        );
      });

      // Emit pós-commit.
      if (result.allowed) {
        if (capturedCost > 0) {
          _eventBus.publish(GemsSpent(
            playerId: playerId,
            amount: capturedCost,
            source: GemSink.enchant,
          ));
        }
        _eventBus.publish(ItemEnchanted(
          playerId: playerId,
          itemKey: capturedTargetItemKey,
          runeKey: enchantKey,
        ));
      }
      return result;
    } catch (e) {
      // ignore: avoid_print
      print('[enchant_service] applyEnchantToItem(playerId=$playerId, '
          'inventoryItemId=$inventoryItemId, enchantKey=$enchantKey) '
          'failed: $e');
      // Falha de DB → mesmo padrão de CraftingService (reusa reason
      // itemNotFound pra não introduzir dbError no enum nesta sprint).
      return EnchantResult.rejected(EnchantRejectReason.itemNotFound);
    }
  }
}
