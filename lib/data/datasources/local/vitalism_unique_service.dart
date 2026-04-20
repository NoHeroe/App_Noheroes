import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../../core/utils/vitalism_unique_policy.dart';
import '../../../domain/enums/affinity_tier.dart';

const String lifeVitalismId = 'life';

// Orquestra IO do sistema de Vitalismos Únicos. Decisões puras vivem em
// VitalismUniquePolicy — este service só lê/escreve banco.
//
// Ver ADR 0004 (unicidade local), 0005 (árvore do jogador), 0006 (PvP via engine).
//
// TODO: teste de integração em sprint futura (requer infra de Drift in-memory
// que o projeto ainda não possui). A lógica de decisão está coberta em
// test/core/utils/vitalism_unique_policy_test.dart.
class VitalismUniqueService {
  final AppDatabase _db;
  final Random _rng;

  VitalismUniqueService(this._db, {Random? rng}) : _rng = rng ?? Random();

  // Comuns do catálogo que não estão em posse de nenhum jogador local.
  Future<List<String>> availableCommonVitalismsInPool() async {
    final ocupados = await _db.select(_db.playerVitalismAffinitiesTable).get();
    final ocupadosIds = ocupados.map((r) => r.vitalismId).toSet();
    final comuns = await (_db.select(_db.vitalismUniqueCatalogTable)
          ..where((t) => t.tier.equals('common')))
        .get();
    return comuns
        .where((c) => !ocupadosIds.contains(c.id))
        .map((c) => c.id)
        .toList();
  }

  // Cerimônia do Cristal. Só pode rodar se o jogador ainda não tem afinidade.
  // Se o pool local de Comuns estiver vazio, o jogador desperta sem afinidade.
  Future<void> awakeFromCrystal(int playerId) async {
    final existentes = await _affinityIdsOf(playerId);
    if (existentes.isNotEmpty) return;

    final pool = await availableCommonVitalismsInPool();
    final sorteado = VitalismUniquePolicy.pickRandomFromPool(pool, _rng);
    if (sorteado == null) return;

    await _db.into(_db.playerVitalismAffinitiesTable).insert(
          PlayerVitalismAffinitiesTableCompanion.insert(
            playerId:    playerId,
            vitalismId:  sorteado,
            acquiredAt:  DateTime.now().millisecondsSinceEpoch,
            acquiredVia: 'crystal',
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  // Stub de PvP — chamado pela engine externa com o resultado do duelo.
  // Se o matador é Vitalista da Vida, delega pra destroyAffinitiesAndGrantLifePoints.
  Future<void> stealAllAffinitiesFromLoser({
    required int winnerId,
    required int loserId,
  }) async {
    final winnerIsVida = await isVitalistaDaVida(winnerId);
    if (VitalismUniquePolicy.shouldDestroyInsteadOfSteal(
        winnerIsVitalistaDaVida: winnerIsVida)) {
      await destroyAffinitiesAndGrantLifePoints(
        vitalistaVidaId: winnerId,
        loserId: loserId,
      );
      return;
    }

    final loserAffinities = await _affinityIdsOf(loserId);
    if (loserAffinities.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Transferência: remove do loser, insere pro winner com via pvp_steal.
    // Árvore do loser (player_vitalism_trees) NÃO é tocada — preservada por ADR 0005.
    // Árvore do winner começa vazia pra cada afinidade nova (inserts só em unlock).
    for (final id in loserAffinities) {
      await _db.into(_db.playerVitalismAffinitiesTable).insert(
            PlayerVitalismAffinitiesTableCompanion.insert(
              playerId:    winnerId,
              vitalismId:  id,
              acquiredAt:  now,
              acquiredVia: 'pvp_steal',
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await (_db.delete(_db.playerVitalismAffinitiesTable)
          ..where((t) => t.playerId.equals(loserId)))
        .go();
  }

  // Vitalista da Vida destrói afinidades do derrotado e ganha pontos.
  Future<void> destroyAffinitiesAndGrantLifePoints({
    required int vitalistaVidaId,
    required int loserId,
  }) async {
    final loserWithTiers = await _affinitiesWithTiersOf(loserId);
    if (loserWithTiers.isEmpty) return;

    final tiers = loserWithTiers.map((e) => e.tier).toList();
    final gained = VitalismUniquePolicy.calculateLifePointsFromAffinities(tiers);

    await (_db.delete(_db.playerVitalismAffinitiesTable)
          ..where((t) => t.playerId.equals(loserId)))
        .go();

    await _addLifePoints(
      vitalistaVidaId,
      gained,
      source: 'pvp_destroy',
      extra: {
        'loser_id': loserId,
        'destroyed': loserWithTiers.map((e) => e.id).toList(),
      },
    );
  }

  Future<bool> isVitalistaDaVida(int playerId) async {
    final row = await (_db.select(_db.playerVitalismAffinitiesTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.vitalismId.equals(lifeVitalismId)))
        .getSingleOrNull();
    return row != null;
  }

  // Pode realizar o ritual do Vazio se tem 3+ Raros e ainda não tem Vida.
  Future<bool> canPerformLifeRitual(int playerId) async {
    final owned = await _affinitiesWithTiersOf(playerId);
    final alreadyHasLife = owned.any((e) => e.id == lifeVitalismId);
    final tiers = owned.map((e) => e.tier).toList();
    return VitalismUniquePolicy.canPerformLifeRitual(
      currentAffinities: tiers,
      alreadyHasLife: alreadyHasLife,
    );
  }

  // Executa o ritual: sacrifica 3 raros escolhidos, converte TODAS as afinidades
  // em posse em pontos da Vida (opção B), zera afinidades, adiciona Vida.
  // Retorna os pontos convertidos, ou null se rejeitado (validação falhou).
  Future<int?> performLifeRitual(
    int playerId,
    List<String> sacrificedRareIds,
  ) async {
    final owned = await _affinitiesWithTiersOf(playerId);
    final ownedByTier = {for (final e in owned) e.id: e.tier};

    if (!VitalismUniquePolicy.validateLifeRitualSacrifices(
      sacrificedIds: sacrificedRareIds,
      ownedByTier: ownedByTier,
    )) {
      return null;
    }
    if (ownedByTier.containsKey(lifeVitalismId)) return null;

    final allTiers = owned.map((e) => e.tier).toList();
    final points = VitalismUniquePolicy.calculateLifePointsFromAffinities(allTiers);
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.delete(_db.playerVitalismAffinitiesTable)
          ..where((t) => t.playerId.equals(playerId)))
        .go();

    await _db.into(_db.playerVitalismAffinitiesTable).insert(
          PlayerVitalismAffinitiesTableCompanion.insert(
            playerId:    playerId,
            vitalismId:  lifeVitalismId,
            acquiredAt:  now,
            acquiredVia: 'life_ritual',
          ),
          mode: InsertMode.insertOrIgnore,
        );

    await _addLifePoints(
      playerId,
      points,
      source: 'life_ritual',
      extra: {
        'sacrificed': sacrificedRareIds,
        'converted': owned.map((e) => e.id).toList(),
      },
    );

    return points;
  }

  // ── internos ───────────────────────────────────────────────────────────────

  Future<List<String>> _affinityIdsOf(int playerId) async {
    final rows = await (_db.select(_db.playerVitalismAffinitiesTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    return rows.map((r) => r.vitalismId).toList();
  }

  // Público: afinidades do jogador com dados do catálogo (nome, carrier, tier, tema).
  Future<List<OwnedAffinity>> ownedAffinitiesOf(int playerId) =>
      _affinitiesWithTiersOf(playerId);

  // Afinidades "dormentes" — o jogador já teve (tem linhas em player_vitalism_trees)
  // mas no momento não está em posse (não está em player_vitalism_affinities).
  // ADR 0005: árvore preservada mesmo após perder posse.
  // Sprint 1.2: retorna vazio pra todo jogador, já que ainda não há caminho
  // pra desbloquear nós. Vira populado quando Bloco 7 / PvP real entrarem.
  Future<List<OwnedAffinity>> dormantAffinitiesOf(int playerId) async {
    final treeRows = await (_db.select(_db.playerVitalismTreesTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    final hasTreeIds = treeRows.map((r) => r.vitalismId).toSet();
    if (hasTreeIds.isEmpty) return const [];

    final activeIds = (await _affinityIdsOf(playerId)).toSet();
    final dormantIds = hasTreeIds.difference(activeIds);
    if (dormantIds.isEmpty) return const [];

    final catalog = await _db.select(_db.vitalismUniqueCatalogTable).get();
    final byId = {for (final c in catalog) c.id: c};
    final out = <OwnedAffinity>[];
    for (final id in dormantIds) {
      final c = byId[id];
      if (c == null) continue;
      final tier = parseAffinityTier(c.tier);
      if (tier == null) continue;
      out.add(OwnedAffinity(
        id: id,
        name: c.name,
        carrierName: c.carrierName,
        tier: tier,
        themeDescription: c.themeDescription,
      ));
    }
    return out;
  }

  Future<LifeVitalismPointsTableData?> lifePointsOf(int playerId) {
    return (_db.select(_db.lifeVitalismPointsTable)
          ..where((t) => t.playerId.equals(playerId)))
        .getSingleOrNull();
  }

  // Nós registrados da árvore do jogador pra uma afinidade.
  Future<List<PlayerVitalismTreesTableData>> treeNodesOf(
    int playerId,
    String vitalismId,
  ) {
    return (_db.select(_db.playerVitalismTreesTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.vitalismId.equals(vitalismId)))
        .get();
  }

  // Desbloqueia um nó da árvore do jogador. Retorna false se:
  //  - afinidade não está ativa (não pode evoluir árvore dormente),
  //  - nó já estava desbloqueado.
  // Caller é responsável por checar requisito de nível.
  Future<bool> unlockTreeNode({
    required int playerId,
    required String vitalismId,
    required String nodeId,
  }) async {
    final active = await _affinityIdsOf(playerId);
    if (!active.contains(vitalismId)) return false;

    final existing = await (_db.select(_db.playerVitalismTreesTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.vitalismId.equals(vitalismId) &
              t.nodeId.equals(nodeId)))
        .getSingleOrNull();
    if (existing != null && existing.unlocked) return false;

    await _db.into(_db.playerVitalismTreesTable).insert(
          PlayerVitalismTreesTableCompanion.insert(
            playerId:   playerId,
            vitalismId: vitalismId,
            nodeId:     nodeId,
            unlocked:   const Value(true),
            unlockedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrReplace,
        );
    return true;
  }

  // JOIN manual afinidade → catálogo.
  Future<List<OwnedAffinity>> _affinitiesWithTiersOf(int playerId) async {
    final affinities = await (_db.select(_db.playerVitalismAffinitiesTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    if (affinities.isEmpty) return const [];
    final catalog = await _db.select(_db.vitalismUniqueCatalogTable).get();
    final byId = {for (final c in catalog) c.id: c};
    final out = <OwnedAffinity>[];
    for (final a in affinities) {
      final c = byId[a.vitalismId];
      if (c == null) continue;
      final tier = parseAffinityTier(c.tier);
      if (tier == null) continue;
      out.add(OwnedAffinity(
        id: a.vitalismId,
        name: c.name,
        carrierName: c.carrierName,
        tier: tier,
        themeDescription: c.themeDescription,
      ));
    }
    return out;
  }

  Future<void> _addLifePoints(
    int playerId,
    int delta, {
    required String source,
    Map<String, dynamic> extra = const {},
  }) async {
    final current = await (_db.select(_db.lifeVitalismPointsTable)
          ..where((t) => t.playerId.equals(playerId)))
        .getSingleOrNull();

    final entry = {
      'at': DateTime.now().millisecondsSinceEpoch,
      'delta': delta,
      'source': source,
      ...extra,
    };

    if (current == null) {
      await _db.into(_db.lifeVitalismPointsTable).insert(
            LifeVitalismPointsTableCompanion.insert(
              playerId: Value(playerId),
              totalPoints: Value(delta),
              sourceLog: Value(jsonEncode([entry])),
            ),
          );
      return;
    }

    final log = (jsonDecode(current.sourceLog) as List).cast<dynamic>();
    log.add(entry);

    await (_db.update(_db.lifeVitalismPointsTable)
          ..where((t) => t.playerId.equals(playerId)))
        .write(LifeVitalismPointsTableCompanion(
      totalPoints: Value(current.totalPoints + delta),
      sourceLog:   Value(jsonEncode(log)),
    ));
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
