import 'package:drift/drift.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/crafting_events.dart';
import '../../../core/events/player_events.dart';
import '../../../core/utils/craft_policy.dart';
import '../../../domain/enums/recipe_type.dart';
import '../../../domain/enums/source_type.dart';
import '../../../domain/models/craft_result.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../database/app_database.dart';
import '../../database/daos/player_dao.dart';
import 'items_catalog_service.dart';
import 'player_inventory_service.dart';
import 'player_recipes_service.dart';
import 'recipes_catalog_service.dart';

// Orquestra crafting atômico: valida pela CraftPolicy, debita materiais e
// coins, cria item no inventário. Tudo dentro de uma transação Drift — falha
// em qualquer step → rollback completo.
class CraftingService {
  final AppDatabase _db;
  final RecipesCatalogService _recipes;
  final PlayerRecipesService _playerRecipes;
  final ItemsCatalogService _items;
  final PlayerInventoryService _inventory;
  final PlayerDao _playerDao;
  final AppEventBus _eventBus;

  CraftingService(
    this._db,
    this._recipes,
    this._playerRecipes,
    this._items,
    this._inventory,
    this._playerDao,
    this._eventBus,
  );

  Future<CraftResult> craft({
    required int playerId,
    required String recipeKey,
    int quantity = 1,
    required PlayerSnapshot player,
  }) async {
    if (quantity <= 0) return CraftResult.failed(CraftRejectReason.dbError);

    // Sprint 3.1 Bloco 7a — capturado dentro da transação pra emit pós-commit.
    // Se o transaction rolar exception, o catch retorna failed e estes
    // ficam 0/'' — nenhum evento é publicado.
    var capturedCost = 0;
    var capturedItemKey = '';
    var capturedRecipeType = RecipeType.craft;

    try {
      final result = await _db.transaction<CraftResult>(() async {
        // 1. Receita existe?
        final recipe = await _recipes.findByKey(recipeKey);
        if (recipe == null) {
          return CraftResult.failed(CraftRejectReason.recipeNotFound);
        }

        // 2. Receita desbloqueada?
        final unlocked = await _playerRecipes.isUnlocked(playerId, recipeKey);
        if (!unlocked) {
          return CraftResult.failed(CraftRejectReason.recipeNotUnlocked);
        }

        // 3. Materiais atuais do jogador (só os relevantes pra esta receita).
        final neededKeys = recipe.materials.map((m) => m.itemKey).toSet();
        final currentMaterials = <String, int>{};
        if (neededKeys.isNotEmpty) {
          final rows = await (_db.select(_db.playerInventoryTable)
                ..where((t) =>
                    t.playerId.equals(playerId) &
                    t.itemKey.isIn(neededKeys) &
                    t.isEquipped.equals(false)))
              .get();
          for (final row in rows) {
            currentMaterials[row.itemKey] =
                (currentMaterials[row.itemKey] ?? 0) + row.quantity;
          }
        }

        // 4. Coins atuais.
        final playerRow = await _playerDao.findById(playerId);
        if (playerRow == null) {
          return CraftResult.failed(CraftRejectReason.dbError);
        }
        final currentCoins = playerRow.gold;

        // 5. Política pura decide se pode craftar [quantity] vezes.
        //    Escalamos materials e coins pela quantidade (batelada).
        final totalMats = CraftPolicy.calculateMaterialsNeeded(
            recipe, quantity);
        final totalCost = recipe.costCoins * quantity;
        final reason = CraftPolicy.canCraft(
          recipe: recipe,
          player: player,
          recipeUnlocked: true,
          // Passamos os totals como "requisito" via receita — a política
          // compara currentMaterials contra recipe.materials × 1. Pra N>1
          // validamos manualmente aqui.
          currentMaterials: currentMaterials,
          currentCoins: currentCoins,
        );
        if (reason != null) return CraftResult.failed(reason);

        // Validação extra pra quantity > 1: a policy só checa 1 unidade.
        if (quantity > 1) {
          for (final entry in totalMats.entries) {
            if ((currentMaterials[entry.key] ?? 0) < entry.value) {
              return CraftResult.failed(
                  CraftRejectReason.notEnoughMaterials);
            }
          }
          if (currentCoins < totalCost) {
            return CraftResult.failed(CraftRejectReason.notEnoughCoins);
          }
        }

        // 6. Item resultado existe no catálogo (defensivo).
        final resultSpec = await _items.findByKey(recipe.resultItemKey);
        if (resultSpec == null) {
          return CraftResult.failed(CraftRejectReason.itemNotInCatalog);
        }

        // 7. Debita materiais. _inventory.removeItem opera por inventoryId;
        //    iteramos entries unequipadas do item_key até zerar a quantidade.
        //    Dívida: player_inventory_service não expõe removeByKey — adapto
        //    aqui pra não refatorar (Regra 5). Candidato a helper futuro.
        for (final entry in totalMats.entries) {
          final ok = await _debitMaterial(playerId, entry.key, entry.value);
          if (!ok) {
            // Defensivo — se chegou aqui, a policy aprovou mas o debito falhou.
            // throw força rollback da transação.
            throw StateError(
                'debit ${entry.key} failed — concurrent modification?');
          }
        }

        // 8. Debita coins (atomicamente via SQL pra não ter read-modify-write
        //    com potencial race dentro da transação).
        if (totalCost > 0) {
          await _db.customUpdate(
            'UPDATE players SET gold = gold - ? WHERE id = ?',
            variables: [
              Variable.withInt(totalCost),
              Variable.withInt(playerId),
            ],
            updates: {_db.playersTable},
          );
        }
        capturedCost = totalCost;
        capturedItemKey = recipe.resultItemKey;
        capturedRecipeType = recipe.type;

        // 9. Adiciona item resultado no inventário.
        final acquiredVia = recipe.type == RecipeType.forge
            ? SourceType.forge
            : SourceType.craft;
        final producedQty = recipe.resultQuantity * quantity;
        final invId = await _inventory.addItem(
          playerId:    playerId,
          itemKey:     recipe.resultItemKey,
          quantity:    producedQty,
          acquiredVia: acquiredVia,
        );
        if (invId < 0) {
          throw StateError(
              'addItem(${recipe.resultItemKey}) retornou $invId — rollback');
        }

        return CraftResult.ok(inventoryId: invId, quantity: producedQty);
      });

      // Sprint 3.1 Bloco 7a — emit FORA da transação. Só publica se:
      //   - result.isOk (transação commitou sucesso, não short-circuit com
      //     CraftResult.failed de dentro da lambda)
      // ItemCrafted: sempre emitido em sucesso.
      // GoldSpent: só quando cost > 0 (receitas grátis existem).
      if (result.isOk) {
        if (capturedCost > 0) {
          _eventBus.publish(GoldSpent(
            playerId: playerId,
            amount: capturedCost,
            source: capturedRecipeType == RecipeType.forge
                ? GoldSink.forge
                : 'craft',
          ));
        }
        _eventBus.publish(ItemCrafted(
          playerId: playerId,
          itemKey: capturedItemKey,
          recipeKey: recipeKey,
        ));
      }
      return result;
    } catch (e) {
      // Rollback ocorreu — captured vars ficam zeradas / vazias.
      // Eventos NÃO são emitidos (garantido porque o emit vive depois
      // do try, só executa se não propagou exception).
      // ignore: avoid_print
      print('[crafting_service] craft($recipeKey ×$quantity) failed: $e');
      return CraftResult.failed(CraftRejectReason.dbError);
    }
  }

  // Debita [qty] unidades de [itemKey] do inventário do jogador iterando
  // entries não-equipadas em ordem de id ascendente. Usa _inventory.removeItem
  // por entry (respeita signature existente). Retorna false se não conseguir
  // completar o débito (→ caller deve forçar rollback).
  Future<bool> _debitMaterial(
      int playerId, String itemKey, int qty) async {
    if (qty <= 0) return true;
    final entries = await (_db.select(_db.playerInventoryTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.itemKey.equals(itemKey) &
              t.isEquipped.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();

    var remaining = qty;
    for (final row in entries) {
      if (remaining <= 0) break;
      final take = row.quantity <= remaining ? row.quantity : remaining;
      final ok = await _inventory.removeItem(
          inventoryId: row.id, quantity: take);
      if (!ok) return false;
      remaining -= take;
    }
    return remaining == 0;
  }
}
