import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/crafting_events.dart';
import '../../../core/events/player_events.dart';
import '../../../domain/enums/recipe_type.dart';
import '../../../domain/models/craft_result.dart';
import '../../../domain/models/player_snapshot.dart';

// Orquestra crafting (Época 2 — full-online Supabase, ADR-0024).
//
// A atomicidade (validação CraftPolicy + débito de materiais/gold + criação do
// item) vive agora 100% na RPC Postgres public.craft(p_player, p_recipe_key,
// p_quantity) — espelho fiel do antigo CraftingService.craft + CraftPolicy.
// Qualquer RAISE no servidor faz rollback completo da transação.
//
// O cliente apenas: chama a RPC, traduz o erro Postgres -> CraftRejectReason,
// e (em sucesso) publica os eventos client-side a partir dos deltas retornados.
class CraftingService {
  final SupabaseClient _client;
  final AppEventBus _eventBus;

  CraftingService(this._client, this._eventBus);

  // playerId é o jogador (uuid) -> String. `player` (PlayerSnapshot) não é mais
  // necessário — toda a validação (rank/level/materiais/gold) roda no servidor
  // com o estado autoritativo. Mantido opcional pra compat de call-sites.
  Future<CraftResult> craft({
    required String playerId,
    required String recipeKey,
    int quantity = 1,
    PlayerSnapshot? player,
  }) async {
    if (quantity <= 0) return CraftResult.failed(CraftRejectReason.dbError);

    try {
      final res = await _client.rpc(
        'craft',
        params: {
          'p_player': playerId,
          'p_recipe_key': recipeKey,
          'p_quantity': quantity,
        },
      );

      final map = (res as Map).cast<String, dynamic>();
      final invId = (map['inventory_id'] as num).toInt();
      final producedQty = (map['quantity'] as num).toInt();
      final goldSpent = (map['gold_spent'] as num?)?.toInt() ?? 0;
      final itemKey = map['item_key'] as String;
      final recipeType =
          RecipeTypeX.fromString(map['recipe_type'] as String?) ??
              RecipeType.craft;

      // Emit pós-sucesso (a transação já commitou no servidor).
      // GoldSpent só quando cost > 0 (receitas grátis existem).
      // NOTA: eventos ainda usam `int playerId` (ver 'unresolved' do resumo).
      if (goldSpent > 0) {
        _eventBus.publish(GoldSpent(
          playerId: playerId,
          amount: goldSpent,
          source: recipeType == RecipeType.forge ? GoldSink.forge : 'craft',
        ));
      }
      _eventBus.publish(ItemCrafted(
        playerId: playerId,
        itemKey: itemKey,
        recipeKey: recipeKey,
      ));

      return CraftResult.ok(inventoryId: invId, quantity: producedQty);
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('[crafting_service] craft($recipeKey x$quantity) failed: '
          '${e.code} ${e.message}');
      return CraftResult.failed(_mapError(e));
    } catch (e) {
      // ignore: avoid_print
      print('[crafting_service] craft($recipeKey x$quantity) failed: $e');
      return CraftResult.failed(CraftRejectReason.dbError);
    }
  }

  // Traduz o erro da RPC craft() -> CraftRejectReason. A RPC sinaliza a causa
  // via mensagem (errcode é compartilhado entre razões distintas), então
  // discriminamos pelo prefixo da mensagem do RAISE.
  CraftRejectReason _mapError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('not found')) return CraftRejectReason.recipeNotFound;
    if (msg.contains('not unlocked')) {
      return CraftRejectReason.recipeNotUnlocked;
    }
    if (msg.contains('rank too low')) return CraftRejectReason.rankTooLow;
    if (msg.contains('level too low')) return CraftRejectReason.levelTooLow;
    if (msg.contains('not enough materials')) {
      return CraftRejectReason.notEnoughMaterials;
    }
    if (msg.contains('not enough coins')) {
      return CraftRejectReason.notEnoughCoins;
    }
    if (msg.contains('not in catalog')) {
      return CraftRejectReason.itemNotInCatalog;
    }
    return CraftRejectReason.dbError;
  }

  // GAP de migração: AppEvent.playerId ainda é int; o jogador agora é uuid
  // String. Sem um campo int estável, derivamos um placeholder pelo hashCode
  // pra manter o EventBus funcional até a decisão de migrar os eventos para
  // String (ver 'unresolved'). NÃO é o id real — só preserva igualdade/filtro
  // por ocorrência dentro de uma sessão.
}
