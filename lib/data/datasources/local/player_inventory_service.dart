import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/enums/source_type.dart';
import '../../../domain/models/inventory_entry_with_spec.dart';
import '../../../domain/models/player_inventory_entry.dart';
import 'items_catalog_service.dart';

// Orquestra player_inventory + catálogo (Supabase, Época 2 — ADR-0024).
// Respeita stack_max ao empilhar (lógica atômica vive na RPC inventory_add_item).
//
// TODO: teste de integração em sprint futura.
// A lógica de decisão está coberta pelas políticas puras do Bloco 3.
class PlayerInventoryService {
  final SupabaseClient _client;
  final ItemsCatalogService _catalog;

  PlayerInventoryService(this._client, this._catalog);

  Future<List<InventoryEntryWithSpec>> listOf(String playerId) async {
    final rows = await _client
        .from('player_inventory')
        .select()
        .eq('player_id', playerId);
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return const [];

    final out = <InventoryEntryWithSpec>[];
    for (final row in list) {
      final entry = PlayerInventoryEntry.fromMap(row);
      final spec = await _catalog.findByKey(entry.itemKey);
      if (spec == null) continue; // item sumido do catálogo — ignora defensivo
      out.add(InventoryEntryWithSpec(entry: entry, spec: spec));
    }
    return out;
  }

  // Adiciona item respeitando stack_max. Operação multi-write atômica
  // (stacking + inserts) -> RPC inventory_add_item. Retorna o id da última
  // entry criada/atualizada. -1 se quantity<=0 ou item ausente do catálogo.
  Future<int> addItem({
    required String playerId,
    required String itemKey,
    int quantity = 1,
    required SourceType acquiredVia,
    String? evolutionStage,
  }) async {
    if (quantity <= 0) return -1;

    final res = await _client.rpc('inventory_add_item', params: {
      'p_player': playerId,
      'p_item_key': itemKey,
      'p_quantity': quantity,
      'p_acquired_via': acquiredVia.name,
      'p_evolution_stage': evolutionStage,
    });
    final id = _asInt(res) ?? -1;
    if (id < 0) {
      // Causa típica: catálogo desatualizado (item novo no servidor mas
      // este cliente não recarregou) ou key inexistente no items_catalog.
      // ignore: avoid_print
      print('[inventory] addItem: item key "$itemKey" não existe no '
          'items_catalog (player=$playerId, qty=$quantity, '
          'via=${acquiredVia.name}).');
    }
    return id;
  }

  // Remove quantity de uma entry. Rejeita se equipada. Retorna true se algo saiu.
  // Read-modify-write client-side (sem RPC dedicada).
  Future<bool> removeItem({required int inventoryId, int quantity = 1}) async {
    if (quantity <= 0) return false;
    final row = await _client
        .from('player_inventory')
        .select()
        .eq('id', inventoryId)
        .maybeSingle();
    if (row == null) return false;
    final entry = PlayerInventoryEntry.fromMap(row);
    if (entry.isEquipped) return false; // caller precisa desequipar antes
    if (entry.quantity <= quantity) {
      await _client.from('player_inventory').delete().eq('id', inventoryId);
    } else {
      await _client
          .from('player_inventory')
          .update({'quantity': entry.quantity - quantity})
          .eq('id', inventoryId);
    }
    return true;
  }

  // Consome 1 unidade de um item is_consumable. Não aplica effects nesta sprint
  // (engine de effects é Fase 4 — caller é responsável).
  Future<bool> consumeItem(int inventoryId) async {
    final row = await _client
        .from('player_inventory')
        .select()
        .eq('id', inventoryId)
        .maybeSingle();
    if (row == null) return false;
    final entry = PlayerInventoryEntry.fromMap(row);
    final spec = await _catalog.findByKey(entry.itemKey);
    if (spec == null || !spec.isConsumable) return false;

    if (entry.quantity <= 1) {
      await _client.from('player_inventory').delete().eq('id', inventoryId);
    } else {
      await _client
          .from('player_inventory')
          .update({'quantity': entry.quantity - 1})
          .eq('id', inventoryId);
    }
    // TODO: aplicar effects do consumível (Fase 4 — engine de effects).
    return true;
  }

  // Dev Panel — remove TODOS os itens + equipamentos do jogador. Destrutivo.
  // Multi-delete atômico -> RPC inventory_reset.
  Future<void> resetInventoryFor(String playerId) async {
    await _client.rpc('inventory_reset', params: {'p_player': playerId});
  }

  // Sprint 2.3 fix (D.2) — APIs equivalentes às antigas PlayerEnchantsService,
  // agora que runas vivem no player_inventory como items normais.

  // Verifica se o jogador tem pelo menos 1 unidade (qualquer stack, qualquer
  // equipagem) do item informado.
  Future<bool> hasItem(String playerId, String itemKey) async {
    final rows = await _client
        .from('player_inventory')
        .select('quantity')
        .eq('player_id', playerId)
        .eq('item_key', itemKey);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .any((r) => (_asInt(r['quantity']) ?? 0) > 0);
  }

  // Consome 1 unidade por chave de item (não por inventoryId). Pega a
  // primeira entry não-equipada. Se quantity cai a zero, DELETE a row.
  // Throw StateError se o player não tem nenhuma entry — caller usa pra
  // forçar rollback (ex: EnchantService).
  Future<void> consumeOneByKey({
    required String playerId,
    required String itemKey,
  }) async {
    final row = await _client
        .from('player_inventory')
        .select()
        .eq('player_id', playerId)
        .eq('item_key', itemKey)
        .eq('is_equipped', false)
        .order('id', ascending: true)
        .limit(1)
        .maybeSingle();
    if (row == null) {
      throw StateError(
          'Tentou consumir item $itemKey do player $playerId, '
          'mas não tem em inventário (não-equipado).');
    }
    final entry = PlayerInventoryEntry.fromMap(row);
    if (entry.quantity <= 0) {
      throw StateError(
          'Tentou consumir item $itemKey do player $playerId, '
          'mas não tem em inventário (não-equipado).');
    }
    if (entry.quantity == 1) {
      await _client.from('player_inventory').delete().eq('id', entry.id);
    } else {
      await _client
          .from('player_inventory')
          .update({'quantity': entry.quantity - 1})
          .eq('id', entry.id);
    }
  }
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
