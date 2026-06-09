import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/npc_reputation.dart';

enum NpcRepLevel { hostile, distrustful, neutral, ally, loyal, devout }

/// Serviço full-online de reputação de NPCs (Época 2, ADR-0024).
///
/// Escritas de gameplay (add/lose) delegam às RPCs Postgres `add_npc_reputation`
/// / `lose_npc_reputation`, que encapsulam o get-or-create + reset diário +
/// clamps atomicamente no servidor. Leituras usam PostgREST direto.
class NpcReputationService {
  final SupabaseClient _client;

  NpcReputationService(this._client);

  static NpcRepLevel levelFromValue(int value) {
    if (value <= 20) return NpcRepLevel.hostile;
    if (value <= 40) return NpcRepLevel.distrustful;
    if (value <= 60) return NpcRepLevel.neutral;
    if (value <= 75) return NpcRepLevel.ally;
    if (value <= 90) return NpcRepLevel.loyal;
    return NpcRepLevel.devout;
  }

  static String labelFromLevel(NpcRepLevel level) => switch (level) {
        NpcRepLevel.hostile     => 'Hostil',
        NpcRepLevel.distrustful => 'Desconfiado',
        NpcRepLevel.neutral     => 'Neutro',
        NpcRepLevel.ally        => 'Aliado',
        NpcRepLevel.loyal       => 'Leal',
        NpcRepLevel.devout      => 'Devoto',
      };

  static String levelKey(NpcRepLevel level) => switch (level) {
        NpcRepLevel.hostile     => 'hostile',
        NpcRepLevel.distrustful => 'distrustful',
        NpcRepLevel.neutral     => 'neutral',
        NpcRepLevel.ally        => 'ally',
        NpcRepLevel.loyal       => 'loyal',
        NpcRepLevel.devout      => 'devout',
      };

  /// get-or-create da linha de reputação. As RPCs já fazem isto no servidor;
  /// aqui replicamos só pro caminho de leitura ([get]) garantir uma linha.
  Future<NpcReputation> _ensure(String playerId, String npcId) async {
    final existing = await _client
        .from('npc_reputation')
        .select()
        .eq('player_id', playerId)
        .eq('npc_id', npcId)
        .maybeSingle();
    if (existing != null) {
      return NpcReputation.fromMap(existing);
    }
    final inserted = await _client
        .from('npc_reputation')
        .insert({'player_id': playerId, 'npc_id': npcId})
        .select()
        .single();
    return NpcReputation.fromMap(inserted);
  }

  Future<NpcReputation> get(String playerId, String npcId) =>
      _ensure(playerId, npcId);

  Future<List<NpcReputation>> getAll(String playerId) async {
    final rows = await _client
        .from('npc_reputation')
        .select()
        .eq('player_id', playerId);
    return rows.map((r) => NpcReputation.fromMap(r)).toList();
  }

  /// Adiciona reputação respeitando limite diário de +20.
  /// Delega à RPC `add_npc_reputation` (get-or-create + reset diário + clamp
  /// atômicos no servidor). Retorna a quantidade efetivamente aplicada.
  Future<int> addReputation(String playerId, String npcId, int amount) async {
    final result = await _client.rpc('add_npc_reputation', params: {
      'p_player': playerId,
      'p_npc_id': npcId,
      'p_amount': amount,
    });
    return (result as num?)?.toInt() ?? 0;
  }

  /// Subtrai reputação com clamp 0..100. Delega à RPC `lose_npc_reputation`.
  Future<void> loseReputation(
      String playerId, String npcId, int amount) async {
    await _client.rpc('lose_npc_reputation', params: {
      'p_player': playerId,
      'p_npc_id': npcId,
      'p_amount': amount,
    });
  }
}
