import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/enums/equipment_slot.dart';
import '../../../domain/enums/item_type.dart';
import '../../../domain/models/inventory_entry_with_spec.dart';
import '../../../domain/models/player_inventory_entry.dart';
import '../../../domain/models/player_snapshot.dart';
import 'items_catalog_service.dart';

// Gerencia os 12 slots de equipamento ativos (Supabase, Época 2 — ADR-0024).
// Os gates de ItemEquipPolicy.canEquipItem (nível/rank/classe/atributos) são
// avaliados aqui no cliente com o PlayerSnapshot; a escrita atômica (desequipar
// ocupante + upsert + marcar is_equipped) vive na RPC equipment_equip.
//
// Retorna EquipResult (retorno explícito facilita UI/snackbars).
class PlayerEquipmentService {
  final SupabaseClient _client;
  final ItemsCatalogService _catalog;

  PlayerEquipmentService(this._client, this._catalog);

  Future<EquipResult> equip({
    required String playerId,
    required int inventoryId,
    required PlayerSnapshot player,
  }) async {
    final entryRow = await _client
        .from('player_inventory')
        .select()
        .eq('id', inventoryId)
        .maybeSingle();
    if (entryRow == null) {
      return const EquipResult.rejected(RejectReason.notEquippable);
    }
    final entry = PlayerInventoryEntry.fromMap(entryRow);
    if (entry.playerId != playerId) {
      return const EquipResult.rejected(RejectReason.notEquippable);
    }

    final spec = await _catalog.findByKey(entry.itemKey);
    if (spec == null || spec.slot == null) {
      return const EquipResult.rejected(RejectReason.notEquippable);
    }

    final check = ItemEquipPolicy.canEquipItem(item: spec, player: player);
    if (!check.isOk) return check;

    // Escrita atômica (desequipa ocupante do slot + upsert + is_equipped=true).
    await _client.rpc('equipment_equip', params: {
      'p_player': playerId,
      'p_inventory_id': inventoryId,
    });

    return const EquipResult.ok();
  }

  Future<void> unequip({
    required String playerId,
    required EquipmentSlot slot,
  }) async {
    await _client.rpc('equipment_unequip', params: {
      'p_player': playerId,
      'p_slot': slot.dbValue,
    });
  }

  Future<List<InventoryEntryWithSpec>> equippedItemsOf(String playerId) async {
    final slots = await _client
        .from('player_equipment')
        .select('inventory_id')
        .eq('player_id', playerId);
    final slotList = (slots as List).cast<Map<String, dynamic>>();
    if (slotList.isEmpty) return const [];

    final out = <InventoryEntryWithSpec>[];
    for (final s in slotList) {
      final invId = _asInt(s['inventory_id']);
      if (invId == null) continue;
      final invRow = await _client
          .from('player_inventory')
          .select()
          .eq('id', invId)
          .maybeSingle();
      if (invRow == null) continue;
      final inv = PlayerInventoryEntry.fromMap(invRow);
      final spec = await _catalog.findByKey(inv.itemKey);
      if (spec == null) continue;
      out.add(InventoryEntryWithSpec(entry: inv, spec: spec));
    }
    return out;
  }

  Future<Map<String, num>> aggregatedStatsOf(String playerId) async {
    final equipped = await equippedItemsOf(playerId);
    // Respeita evolution_stage pra items is_evolving (ex.: Colar da Guilda).
    final agg = ItemEquipPolicy.aggregateStatsFromEquippedEntries(equipped);

    // Sprint 2.3 Bloco 7.3 — soma efeitos das runas aplicadas em itens
    // equipados. Policy permanece pura (síncrona); aqui é async porque
    // depende do catálogo. Seivas ficam fora até Sprint 2.4 ativar cargas.
    for (final e in equipped) {
      final runeKey = e.entry.appliedRuneKey;
      if (runeKey == null) continue;
      final rune = await _catalog.findByKey(runeKey);
      if (rune == null || rune.type != ItemType.rune) continue;
      rune.effects.forEach((k, v) {
        if (v is num) {
          agg[k] = (agg[k] ?? 0) + v;
        }
      });
    }

    return agg;
  }
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
