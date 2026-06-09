import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/crafting_events.dart';
import '../../../core/events/player_events.dart';
import '../../../domain/models/enchant_result.dart';
import '../../../domain/models/enchant_spec.dart';
import '../../../domain/models/player_snapshot.dart';
import 'items_catalog_service.dart';

// Aplica encantamento em item equipável (Época 2 — full-online Supabase,
// ADR-0024).
//
// A atomicidade (EnchantPolicy.canApply + débito de gems + consumo de 1 runa +
// set applied_rune_key) vive agora 100% na RPC Postgres public.apply_enchant(
// p_player, p_inventory_item_id, p_enchant_key, p_confirm_replacement). Qualquer
// RAISE no servidor faz rollback completo.
//
// Soft-gate de substituição: se o item já tem runa e confirmReplacement=false,
// a RPC retorna {applied:false, needs_confirmation:true,
// reason:'alreadyEnchantedSameSlot'} SEM escrever nada -> traduzimos para
// EnchantResult.rejected(alreadyEnchantedSameSlot) pra UI interceptar e
// re-chamar com confirmação.
//
// A RPC só devolve as KEYS das runas (applied/replaced). Pra reconstruir os
// EnchantSpec do EnchantResult (contrato da UI), relemos via
// ItemsCatalogService (runas vivem no items_catalog como type='rune') e
// convertemos com EnchantSpec.fromItemSpec.
class EnchantService {
  final SupabaseClient _client;
  final ItemsCatalogService _items;
  final AppEventBus _eventBus;

  EnchantService(this._client, this._items, this._eventBus);

  // Resolve um item do catálogo e devolve como EnchantSpec. Retorna null se a
  // key for nula/vazia, não existir, OU não for do tipo runa (defensivo).
  Future<EnchantSpec?> _loadRuneSpec(String? key) async {
    if (key == null || key.isEmpty) return null;
    final item = await _items.findByKey(key);
    if (item == null) return null;
    if (item.type.name != 'rune') return null;
    return EnchantSpec.fromItemSpec(item);
  }

  // playerId é o jogador (uuid) -> String. inventoryItemId é PK de linha
  // (bigserial) -> continua int. `player`/`playerGems` não são mais
  // necessários (validação roda no servidor com estado autoritativo); mantidos
  // opcionais pra compat de call-sites.
  Future<EnchantResult> applyEnchantToItem({
    required String playerId,
    required int inventoryItemId,
    required String enchantKey,
    PlayerSnapshot? player,
    int? playerGems,
    bool confirmReplacement = false,
  }) async {
    try {
      final res = await _client.rpc(
        'apply_enchant',
        params: {
          'p_player': playerId,
          'p_inventory_item_id': inventoryItemId,
          'p_enchant_key': enchantKey,
          'p_confirm_replacement': confirmReplacement,
        },
      );

      final map = (res as Map).cast<String, dynamic>();
      final applied = map['applied'] as bool? ?? false;

      // Soft-gate: item já encantado e sem confirmação. UI intercepta.
      if (!applied) {
        return EnchantResult.rejected(
            EnchantRejectReason.alreadyEnchantedSameSlot);
      }

      final itemKey = map['item_key'] as String;
      final runeKey = map['rune_key'] as String;
      final replacedKey = map['replaced_rune_key'] as String?;
      final gemsSpent = (map['gems_spent'] as num?)?.toInt() ?? 0;

      final appliedSpec = await _loadRuneSpec(runeKey);
      final replacedSpec = await _loadRuneSpec(replacedKey);

      // appliedSpec não deveria ser null em sucesso (a RPC já validou type=rune),
      // mas é defensivo: se sumiu do catálogo local, ainda confirmamos o sucesso.
      if (appliedSpec == null) {
        // ignore: avoid_print
        print('[enchant_service] applied rune $runeKey not resolvable locally');
      }

      // Emit pós-sucesso (transação já commitou no servidor).
      // NOTA: eventos ainda usam `int playerId` (ver 'unresolved' do resumo).
      if (gemsSpent > 0) {
        _eventBus.publish(GemsSpent(
          playerId: playerId,
          amount: gemsSpent,
          source: GemSink.enchant,
        ));
      }
      _eventBus.publish(ItemEnchanted(
        playerId: playerId,
        itemKey: itemKey,
        runeKey: runeKey,
      ));

      return EnchantResult.allowed(
        applied: appliedSpec ??
            // fallback minimalista pra não perder o sucesso
            EnchantSpec.fromJson({'key': runeKey, 'name': runeKey}),
        replaced: replacedSpec,
      );
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('[enchant_service] applyEnchantToItem(playerId=$playerId, '
          'inventoryItemId=$inventoryItemId, enchantKey=$enchantKey) '
          'failed: ${e.code} ${e.message}');
      return EnchantResult.rejected(_mapError(e));
    } catch (e) {
      // ignore: avoid_print
      print('[enchant_service] applyEnchantToItem(playerId=$playerId, '
          'inventoryItemId=$inventoryItemId, enchantKey=$enchantKey) '
          'failed: $e');
      return EnchantResult.rejected(EnchantRejectReason.itemNotFound);
    }
  }

  // Traduz o erro da RPC apply_enchant() -> EnchantRejectReason. Discrimina
  // pelo prefixo da mensagem do RAISE (errcode é compartilhado).
  EnchantRejectReason _mapError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('not found / not a rune') ||
        msg.contains('not a rune')) {
      return EnchantRejectReason.enchantNotFound;
    }
    if (msg.contains('inventory item') && msg.contains('not found')) {
      return EnchantRejectReason.itemNotFound;
    }
    if (msg.contains('not in catalog')) {
      return EnchantRejectReason.itemNotFound;
    }
    if (msg.contains('not enchantable') || msg.contains('unenchantable')) {
      return EnchantRejectReason.itemNotEnchantable;
    }
    if (msg.contains('not in inventory')) {
      return EnchantRejectReason.enchantNotInInventory;
    }
    if (msg.contains('rank') && msg.contains('insufficient')) {
      return EnchantRejectReason.rankInsufficient;
    }
    if (msg.contains('class') && msg.contains('restricted')) {
      return EnchantRejectReason.classRestricted;
    }
    if (msg.contains('insufficient gems')) {
      return EnchantRejectReason.insufficientGems;
    }
    return EnchantRejectReason.itemNotFound;
  }

  // GAP de migração: AppEvent.playerId ainda é int; o jogador agora é uuid
  // String. Placeholder via hashCode até a decisão de migrar eventos para
  // String (ver 'unresolved').
}
