/// Economia de cartas (criar / desencantar / aprimorar) — camada Dart.
///
/// Server-authoritative: tudo passa pelas RPCs Supabase definidas em
/// `20260611150000_card_economy_rpcs.sql` + o snapshot `cg_card_info`
/// (`20260611160000`). O cliente nunca decide custo/affordability — só lê o
/// snapshot e dispara a ação. Ver ADR-0027.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';

/// Resultado simples de uma ação de economia.
class CgResult {
  final bool ok;
  final String? reason;
  final Map<String, dynamic> raw;
  const CgResult(this.ok, this.reason, this.raw);
  factory CgResult.fromRpc(Object? res) {
    final map = (res as Map).cast<String, dynamic>();
    return CgResult(map['ok'] == true, map['reason'] as String?, map);
  }
}

class CardEconomyService {
  CardEconomyService(this._client);
  final SupabaseClient _client;

  /// Snapshot de economia da carta (posse, custos, saldos, flags `can`).
  Future<Map<String, dynamic>> cardInfo(String playerId, String cardId) async {
    final res = await _client.rpc('cg_card_info',
        params: {'p_player': playerId, 'p_card_id': cardId});
    return (res as Map).cast<String, dynamic>();
  }

  Future<CgResult> create(String playerId, String cardId) async =>
      CgResult.fromRpc(await _client.rpc('cg_create_card',
          params: {'p_player': playerId, 'p_card_id': cardId}));

  Future<CgResult> disenchant(String playerId, String cardId) async =>
      CgResult.fromRpc(await _client.rpc('cg_disenchant_card',
          params: {'p_player': playerId, 'p_card_id': cardId}));

  Future<CgResult> upgrade(String playerId, String cardId) async =>
      CgResult.fromRpc(await _client.rpc('cg_upgrade_card',
          params: {'p_player': playerId, 'p_card_id': cardId}));
}

final cardEconomyServiceProvider = Provider<CardEconomyService>(
    (ref) => CardEconomyService(ref.watch(supabaseClientProvider)));

/// Níveis de aprimoramento das cartas possuídas (`card_id` → level). Vazio sem
/// login. Usado pra injetar o nível no loadout da partida (escala de stats) e
/// exibir nível na Coleção.
final cardLevelsProvider = FutureProvider<Map<String, int>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return const <String, int>{};
  final rows = await ref
      .read(supabaseClientProvider)
      .from('player_cards')
      .select('card_id, level');
  final list = (rows as List).cast<Map<String, dynamic>>();
  return {
    for (final r in list)
      (r['card_id'] as String): ((r['level'] as int?) ?? 1),
  };
});

/// Mensagem PT-BR para cada `reason` das RPCs de economia.
String cgReasonLabel(String? reason) {
  switch (reason) {
    case 'locked_level':
      return 'Nível de jogador insuficiente.';
    case 'insufficient_resources':
    case 'insufficient':
      return 'Recursos insuficientes.';
    case 'not_craftable':
      return 'Esta carta não pode ser criada.';
    case 'not_disenchantable':
      return 'Esta carta não pode ser desencantada.';
    case 'not_owned':
      return 'Você não possui esta carta.';
    case 'max_level':
      return 'Carta já está no nível máximo.';
    case 'unknown_card':
      return 'Carta desconhecida.';
    default:
      return 'Não foi possível concluir a ação.';
  }
}
