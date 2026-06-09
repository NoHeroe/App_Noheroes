import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/vitalism_unique_policy.dart';
import '../../../domain/enums/affinity_tier.dart';

const String lifeVitalismId = 'life';

// Orquestra IO do sistema de Vitalismos Únicos (Época 2 — full-online Supabase,
// ADR-0024). As decisões PURAS continuam em VitalismUniquePolicy, mas os fluxos
// ATÔMICOS (cerimônia do Cristal, ritual do Vazio, PvP roubo/destruição, unlock
// de nó) foram portados para RPCs Postgres e são chamados via client.rpc(...).
// As leituras simples (afinidades, pontos, nós, dormentes) usam .from(...).
//
// playerId é o jogador (auth.users.id, uuid) -> String. PKs compostas usam
// player_id; não há PK de linha int neste domínio.
//
// Ver ADR 0004 (unicidade global do pool de Comuns), 0005 (árvore preservada),
// 0006 (PvP via engine), 0024 (full-online).
class VitalismUniqueService {
  final SupabaseClient _client;

  VitalismUniqueService(this._client);

  // Comuns do catálogo que não estão em posse de NENHUM jogador (unicidade
  // GLOBAL — ADR 0004). Precisa enxergar afinidades alheias, o que a RLS por
  // jogador esconderia; por isso vai via RPC SECURITY DEFINER.
  Future<List<String>> availableCommonVitalismsInPool() async {
    final res = await _client.rpc('available_common_vitalisms_in_pool');
    if (res == null) return const [];
    return (res as List).cast<String>();
  }

  // Cerimônia do Cristal. Atômica (checa posse + sorteia do pool global +
  // insere) -> RPC awake_from_crystal. No-op se já tem afinidade ou pool vazio.
  Future<void> awakeFromCrystal(String playerId) async {
    await _client.rpc('awake_from_crystal', params: {'p_player': playerId});
  }

  // Stub de PvP — chamado pela engine externa com o resultado do duelo. A
  // decisão de roubar-vs-destruir, a transferência e a possível destruição são
  // atômicas e multi-jogador -> RPC steal_affinities (que delega internamente
  // pra destroy_affinities_grant_life quando o winner é Vitalista da Vida).
  Future<void> stealAllAffinitiesFromLoser({
    required String winnerId,
    required String loserId,
  }) async {
    await _client.rpc('steal_affinities', params: {
      'p_winner': winnerId,
      'p_loser': loserId,
    });
  }

  // Vitalista da Vida destrói afinidades do derrotado e ganha pontos. Atômico
  // (read-modify-write multi-tabela) -> RPC destroy_affinities_grant_life.
  Future<void> destroyAffinitiesAndGrantLifePoints({
    required String vitalistaVidaId,
    required String loserId,
  }) async {
    await _client.rpc('destroy_affinities_grant_life', params: {
      'p_vitalista_vida': vitalistaVidaId,
      'p_loser': loserId,
    });
  }

  Future<bool> isVitalistaDaVida(String playerId) async {
    final row = await _client
        .from('player_vitalism_affinities')
        .select('vitalism_id')
        .eq('player_id', playerId)
        .eq('vitalism_id', lifeVitalismId)
        .maybeSingle();
    return row != null;
  }

  // Pode realizar o ritual do Vazio se tem 3+ Raros e ainda não tem Vida.
  // Leitura + decisão pura local (a validação canônica do sacrifício específico
  // vive na RPC perform_life_ritual; aqui é só o gate de elegibilidade da UI).
  Future<bool> canPerformLifeRitual(String playerId) async {
    final owned = await _affinitiesWithTiersOf(playerId);
    final alreadyHasLife = owned.any((e) => e.id == lifeVitalismId);
    final tiers = owned.map((e) => e.tier).toList();
    return VitalismUniquePolicy.canPerformLifeRitual(
      currentAffinities: tiers,
      alreadyHasLife: alreadyHasLife,
    );
  }

  // Executa o ritual do Vazio. Validação do sacrifício + conversão de TODAS as
  // afinidades em pontos da Vida + zeragem + insert da Vida + log são atômicos
  // -> RPC perform_life_ritual. Retorna os pontos convertidos, ou null se
  // rejeitado (validação falhou) — espelha o Future<int?> original.
  Future<int?> performLifeRitual(
    String playerId,
    List<String> sacrificedRareIds,
  ) async {
    final res = await _client.rpc('perform_life_ritual', params: {
      'p_player': playerId,
      'p_sacrificed_rare_ids': sacrificedRareIds,
    });
    return (res as num?)?.toInt();
  }

  // ── internos ───────────────────────────────────────────────────────────────

  Future<List<String>> _affinityIdsOf(String playerId) async {
    final rows = await _client
        .from('player_vitalism_affinities')
        .select('vitalism_id')
        .eq('player_id', playerId);
    return rows.map((r) => r['vitalism_id'] as String).toList();
  }

  // Público: afinidades do jogador com dados do catálogo (nome, carrier, tier, tema).
  Future<List<OwnedAffinity>> ownedAffinitiesOf(String playerId) =>
      _affinitiesWithTiersOf(playerId);

  // Afinidades "dormentes" — o jogador já teve (tem linhas em player_vitalism_trees)
  // mas no momento não está em posse (não está em player_vitalism_affinities).
  // ADR 0005: árvore preservada mesmo após perder posse.
  Future<List<OwnedAffinity>> dormantAffinitiesOf(String playerId) async {
    final treeRows = await _client
        .from('player_vitalism_trees')
        .select('vitalism_id')
        .eq('player_id', playerId);
    final hasTreeIds =
        treeRows.map((r) => r['vitalism_id'] as String).toSet();
    if (hasTreeIds.isEmpty) return const [];

    final activeIds = (await _affinityIdsOf(playerId)).toSet();
    final dormantIds = hasTreeIds.difference(activeIds);
    if (dormantIds.isEmpty) return const [];

    final catalog = await _client
        .from('vitalism_unique_catalog')
        .select('id, name, carrier_name, tier, theme_description');
    final byId = {for (final c in catalog) c['id'] as String: c};
    final out = <OwnedAffinity>[];
    for (final id in dormantIds) {
      final c = byId[id];
      if (c == null) continue;
      final tier = parseAffinityTier(c['tier'] as String?);
      if (tier == null) continue;
      out.add(OwnedAffinity(
        id: id,
        name: c['name'] as String,
        carrierName: c['carrier_name'] as String,
        tier: tier,
        themeDescription: c['theme_description'] as String,
      ));
    }
    return out;
  }

  Future<LifeVitalismPoints?> lifePointsOf(String playerId) async {
    final row = await _client
        .from('life_vitalism_points')
        .select()
        .eq('player_id', playerId)
        .maybeSingle();
    return row == null ? null : LifeVitalismPoints.fromMap(row);
  }

  // Nós registrados da árvore do jogador pra uma afinidade.
  Future<List<VitalismTreeNode>> treeNodesOf(
    String playerId,
    String vitalismId,
  ) async {
    final rows = await _client
        .from('player_vitalism_trees')
        .select()
        .eq('player_id', playerId)
        .eq('vitalism_id', vitalismId);
    return rows.map((r) => VitalismTreeNode.fromMap(r)).toList();
  }

  // Desbloqueia um nó da árvore do jogador. Atômico (checa posse + checa estado
  // do nó + upsert) -> RPC unlock_tree_node. Retorna false se a afinidade não
  // está ativa ou o nó já estava desbloqueado. Caller checa requisito de nível.
  Future<bool> unlockTreeNode({
    required String playerId,
    required String vitalismId,
    required String nodeId,
  }) async {
    final res = await _client.rpc('unlock_tree_node', params: {
      'p_player': playerId,
      'p_vitalism_id': vitalismId,
      'p_node_id': nodeId,
    });
    return (res as bool?) ?? false;
  }

  // JOIN manual afinidade → catálogo.
  Future<List<OwnedAffinity>> _affinitiesWithTiersOf(String playerId) async {
    final affinities = await _client
        .from('player_vitalism_affinities')
        .select('vitalism_id')
        .eq('player_id', playerId);
    if (affinities.isEmpty) return const [];
    final catalog = await _client
        .from('vitalism_unique_catalog')
        .select('id, name, carrier_name, tier, theme_description');
    final byId = {for (final c in catalog) c['id'] as String: c};
    final out = <OwnedAffinity>[];
    for (final a in affinities) {
      final c = byId[a['vitalism_id'] as String];
      if (c == null) continue;
      final tier = parseAffinityTier(c['tier'] as String?);
      if (tier == null) continue;
      out.add(OwnedAffinity(
        id: a['vitalism_id'] as String,
        name: c['name'] as String,
        carrierName: c['carrier_name'] as String,
        tier: tier,
        themeDescription: c['theme_description'] as String,
      ));
    }
    return out;
  }
}

class OwnedAffinity {
  final String id;
  final String name;
  final String carrierName;
  final AffinityTier tier;
  final String themeDescription;

  const OwnedAffinity({
    required this.id,
    required this.name,
    required this.carrierName,
    required this.tier,
    required this.themeDescription,
  });
}

// Substitui o Drift LifeVitalismPointsTableData. Row de life_vitalism_points.
class LifeVitalismPoints {
  final String playerId;
  final int totalPoints;
  final String sourceLog; // JSON array (text)

  const LifeVitalismPoints({
    required this.playerId,
    required this.totalPoints,
    required this.sourceLog,
  });

  factory LifeVitalismPoints.fromMap(Map<String, dynamic> m) =>
      LifeVitalismPoints(
        playerId: m['player_id'] as String,
        totalPoints: (m['total_points'] as num?)?.toInt() ?? 0,
        sourceLog: (m['source_log'] as String?) ?? '[]',
      );
}

// Substitui o Drift PlayerVitalismTreesTableData. Row de player_vitalism_trees.
class VitalismTreeNode {
  final String playerId;
  final String vitalismId;
  final String nodeId;
  final bool unlocked;
  final int? unlockedAt;

  const VitalismTreeNode({
    required this.playerId,
    required this.vitalismId,
    required this.nodeId,
    required this.unlocked,
    this.unlockedAt,
  });

  factory VitalismTreeNode.fromMap(Map<String, dynamic> m) => VitalismTreeNode(
        playerId: m['player_id'] as String,
        vitalismId: m['vitalism_id'] as String,
        nodeId: m['node_id'] as String,
        unlocked: (m['unlocked'] as bool?) ?? false,
        unlockedAt: (m['unlocked_at'] as num?)?.toInt(),
      );
}
