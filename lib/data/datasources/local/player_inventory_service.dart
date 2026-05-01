import 'package:drift/drift.dart';
import '../../../domain/enums/source_type.dart';
import '../../../domain/models/inventory_entry_with_spec.dart';
import '../../database/app_database.dart';
import 'items_catalog_service.dart';

// Orquestra player_inventory + catálogo. Respeita stack_max ao empilhar.
// Stubs de craft/forge/enchant permanecem pra Sprints 2.2/2.3.
//
// TODO: teste de integração em sprint futura (requer Drift in-memory).
// A lógica de decisão está coberta pelas políticas puras do Bloco 3.
class PlayerInventoryService {
  final AppDatabase _db;
  final ItemsCatalogService _catalog;

  PlayerInventoryService(this._db, this._catalog);

  Future<List<InventoryEntryWithSpec>> listOf(int playerId) async {
    final rows = await (_db.select(_db.playerInventoryTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    if (rows.isEmpty) return const [];

    final out = <InventoryEntryWithSpec>[];
    for (final row in rows) {
      final spec = await _catalog.findByKey(row.itemKey);
      if (spec == null) continue; // item sumido do catálogo — ignora defensivo
      out.add(InventoryEntryWithSpec(entry: row, spec: spec));
    }
    return out;
  }

  // Adiciona item respeitando stack_max. Se stackable, tenta empilhar em entry
  // não-equipada existente; se sobrar, cria nova (possivelmente várias).
  // Retorna o id da última entry criada/atualizada. -1 se o item não existir no catálogo.
  Future<int> addItem({
    required int playerId,
    required String itemKey,
    int quantity = 1,
    required SourceType acquiredVia,
    String? evolutionStage,
  }) async {
    if (quantity <= 0) return -1;
    final spec = await _catalog.findByKey(itemKey);
    if (spec == null) {
      // Sprint 3.3 Etapa 2.2 hotfix — log explícito ao invés de falhar
      // silencioso. Causa típica: catálogo desatualizado (item novo no
      // JSON mas self-heal não rodou ou falhou). Conquistas com items
      // (ex: CHEST_DEFEATED em tiers *_falha) caem aqui se o seed do
      // items_unified.json não cobriu este item.
      // ignore: avoid_print
      print('[inventory] addItem: item key "$itemKey" não existe no '
          'items_catalog (player=$playerId, qty=$quantity, '
          'via=${acquiredVia.name}). Verificar self-heal de '
          'items_unified.json.');
      return -1;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    var remaining = quantity;
    var lastId = -1;

    if (spec.isStackable) {
      // Preenche entries existentes não-equipadas primeiro.
      final existing = await (_db.select(_db.playerInventoryTable)
            ..where((t) =>
                t.playerId.equals(playerId) &
                t.itemKey.equals(itemKey) &
                t.isEquipped.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

      for (final row in existing) {
        if (remaining <= 0) break;
        final available = spec.stackMax - row.quantity;
        if (available <= 0) continue;
        final toAdd = available >= remaining ? remaining : available;
        await (_db.update(_db.playerInventoryTable)
              ..where((t) => t.id.equals(row.id)))
            .write(PlayerInventoryTableCompanion(
          quantity: Value(row.quantity + toAdd),
        ));
        lastId = row.id;
        remaining -= toAdd;
      }
    }

    // Cria novas entries pra quantidade restante.
    while (remaining > 0) {
      final chunk = spec.isStackable && remaining > spec.stackMax
          ? spec.stackMax
          : remaining;
      final id = await _db.into(_db.playerInventoryTable).insert(
            PlayerInventoryTableCompanion.insert(
              playerId:     playerId,
              itemKey:      itemKey,
              acquiredAt:   now,
              acquiredVia:  acquiredVia.name,
              quantity:     Value(chunk),
              evolutionStage: Value(evolutionStage),
              durabilityCurrent: Value(spec.durabilityMax),
            ),
          );
      lastId = id;
      remaining -= chunk;
    }

    return lastId;
  }

  // Remove quantity de uma entry. Rejeita se equipada. Retorna true se algo saiu.
  Future<bool> removeItem({required int inventoryId, int quantity = 1}) async {
    if (quantity <= 0) return false;
    final row = await (_db.select(_db.playerInventoryTable)
          ..where((t) => t.id.equals(inventoryId)))
        .getSingleOrNull();
    if (row == null) return false;
    if (row.isEquipped) return false; // caller precisa desequipar antes
    if (row.quantity <= quantity) {
      await (_db.delete(_db.playerInventoryTable)
            ..where((t) => t.id.equals(inventoryId)))
          .go();
    } else {
      await (_db.update(_db.playerInventoryTable)
            ..where((t) => t.id.equals(inventoryId)))
          .write(PlayerInventoryTableCompanion(
        quantity: Value(row.quantity - quantity),
      ));
    }
    return true;
  }

  // Consome 1 unidade de um item is_consumable. Não aplica effects nesta sprint
  // (engine de effects é Fase 4 — caller é responsável).
  Future<bool> consumeItem(int inventoryId) async {
    final row = await (_db.select(_db.playerInventoryTable)
          ..where((t) => t.id.equals(inventoryId)))
        .getSingleOrNull();
    if (row == null) return false;
    final spec = await _catalog.findByKey(row.itemKey);
    if (spec == null || !spec.isConsumable) return false;

    if (row.quantity <= 1) {
      await (_db.delete(_db.playerInventoryTable)
            ..where((t) => t.id.equals(inventoryId)))
          .go();
    } else {
      await (_db.update(_db.playerInventoryTable)
            ..where((t) => t.id.equals(inventoryId)))
          .write(PlayerInventoryTableCompanion(
        quantity: Value(row.quantity - 1),
      ));
    }
    // TODO: aplicar effects do consumível (Fase 4 — engine de effects).
    return true;
  }

  // Dev Panel — remove TODOS os itens + equipamentos do jogador. Destrutivo.
  Future<void> resetInventoryFor(int playerId) async {
    await (_db.delete(_db.playerEquipmentTable)
          ..where((t) => t.playerId.equals(playerId)))
        .go();
    await (_db.delete(_db.playerInventoryTable)
          ..where((t) => t.playerId.equals(playerId)))
        .go();
  }

  // Sprint 2.3 fix (D.2) — APIs equivalentes às antigas PlayerEnchantsService,
  // agora que runas vivem no player_inventory como items normais.

  // Verifica se o jogador tem pelo menos 1 unidade (qualquer stack, qualquer
  // equipagem) do item informado.
  Future<bool> hasItem(int playerId, String itemKey) async {
    final rows = await (_db.select(_db.playerInventoryTable)
          ..where((t) =>
              t.playerId.equals(playerId) & t.itemKey.equals(itemKey)))
        .get();
    return rows.any((r) => r.quantity > 0);
  }

  // Consome 1 unidade por chave de item (não por inventoryId). Pega a
  // primeira entry não-equipada. Se quantity cai a zero, DELETE a row.
  // Throw StateError se o player não tem nenhuma entry — caller usa pra
  // forçar rollback em transações atômicas (ex: EnchantService).
  Future<void> consumeOneByKey({
    required int playerId,
    required String itemKey,
  }) async {
    final row = await (_db.select(_db.playerInventoryTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.itemKey.equals(itemKey) &
              t.isEquipped.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null || row.quantity <= 0) {
      throw StateError(
          'Tentou consumir item $itemKey do player $playerId, '
          'mas não tem em inventário (não-equipado).');
    }
    if (row.quantity == 1) {
      await (_db.delete(_db.playerInventoryTable)
            ..where((t) => t.id.equals(row.id)))
          .go();
    } else {
      await (_db.update(_db.playerInventoryTable)
            ..where((t) => t.id.equals(row.id)))
          .write(PlayerInventoryTableCompanion(
        quantity: Value(row.quantity - 1),
      ));
    }
  }
}
