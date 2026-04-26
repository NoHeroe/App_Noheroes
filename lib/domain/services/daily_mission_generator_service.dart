import 'dart:math';

import '../../core/events/app_event_bus.dart';
import '../../core/events/daily_mission_events.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/daily_missions_dao.dart';
import '../../data/database/daos/player_dao.dart';
import '../enums/mission_category.dart';
import '../models/daily_mission.dart';
import '../models/daily_mission_status.dart';
import '../models/daily_modalidade_pool.dart';
import '../models/daily_sub_task_instance.dart';
import '../models/daily_sub_task_spec.dart';
import 'body_metrics_service.dart';
import 'daily_pool_service.dart';
import 'mission_preferences_service.dart';

/// Sprint 3.2 Etapa 1.2 — geração das 3 missões diárias.
///
/// Distribuição (peso por modalidade no sorteio de cada slot):
///   - primaryFocus (do quiz Bloco 9): 50%
///   - outros 2 pilares: 20% cada
///   - Vitalismo: 10%
///
/// Garante **≥ 2 modalidades distintas** no dia: se os 3 sorteios
/// independentes caem na mesma modalidade, força o 3º slot pra outra
/// (escolhida com pesos relativos das 3 modalidades restantes).
///
/// Filtra sub-tarefas com `escala_por_rank[rank] == 0` no rank do
/// jogador (sub-tarefas tipo "retiro_dia rank E" simplesmente não
/// entram no pool de sorteio).
class DailyMissionGeneratorService {
  final DailyPoolService _pools;
  final BodyMetricsService _bodyMetrics;
  final MissionPreferencesService _prefs;
  final PlayerDao _playerDao;
  final DailyMissionsDao _missionsDao;
  final AppEventBus _bus;
  final Random _random;

  DailyMissionGeneratorService({
    required DailyPoolService pools,
    required BodyMetricsService bodyMetrics,
    required MissionPreferencesService prefs,
    required PlayerDao playerDao,
    required DailyMissionsDao missionsDao,
    required AppEventBus bus,
    Random? random,
  })  : _pools = pools,
        _bodyMetrics = bodyMetrics,
        _prefs = prefs,
        _playerDao = playerDao,
        _missionsDao = missionsDao,
        _bus = bus,
        _random = random ?? Random();

  static const int missionsPerDay = 3;
  static const int subTasksPerMission = 3;

  /// Idempotente — se já existem missões do dia [date] (default hoje)
  /// pro [playerId], retorna elas sem gerar de novo.
  Future<List<DailyMission>> generateForToday(int playerId,
      {DateTime? date}) async {
    final now = date ?? DateTime.now();
    final dateStr = _dateStr(now);

    final existing =
        await _missionsDao.findByPlayerAndDate(playerId, dateStr);
    if (existing.isNotEmpty) return existing;

    await _pools.loadAll();

    final player = await _playerDao.findById(playerId);
    if (player == null) {
      throw StateError('Player $playerId não existe');
    }
    final rank = _normalizeRank(player.guildRank);

    final prefs = await _prefs.findCurrent(playerId);
    final primaryFocus = prefs?.primaryFocus ?? MissionCategory.fisico;

    // Sorteia as 3 modalidades respeitando pesos + ≥2 distintas.
    final modalidades = _drawModalidades(primaryFocus);

    // Garante sub-tarefas únicas cross-missions no dia.
    final usedKeys = <String>{};

    final drafts = <DailyMission>[];
    for (final mod in modalidades) {
      final draft = mod == MissionCategory.vitalismo
          ? _buildVitalismoMission(
              playerId: playerId,
              dateStr: dateStr,
              now: now,
              rank: rank,
              player: player,
              usedKeys: usedKeys,
            )
          : _buildModalidadeMission(
              playerId: playerId,
              dateStr: dateStr,
              now: now,
              modalidade: mod,
              rank: rank,
              player: player,
              usedKeys: usedKeys,
            );
      drafts.add(draft);
    }

    final saved = await _missionsDao.insertAll(drafts);
    for (final m in saved) {
      _bus.publish(DailyMissionGenerated(
        playerId: m.playerId,
        missionId: m.id,
        modalidade: m.modalidade,
      ));
    }
    return saved;
  }

  Future<List<DailyMission>> getTodayMissions(int playerId) async {
    final dateStr = _dateStr(DateTime.now());
    final existing =
        await _missionsDao.findByPlayerAndDate(playerId, dateStr);
    if (existing.isNotEmpty) return existing;
    return generateForToday(playerId);
  }

  Future<DailyMission?> getMissionById(int id) => _missionsDao.findById(id);

  // ─── sorteio de modalidades (50/20/20/10 + ≥2 distintas) ────────────

  List<MissionCategory> _drawModalidades(MissionCategory primary) {
    final weights = _weightsFor(primary);
    final out = [
      _weightedPick(weights),
      _weightedPick(weights),
      _weightedPick(weights),
    ];

    // Forçamento: se as 3 caíram iguais, força a 3ª pra outra
    // modalidade respeitando os pesos relativos das 3 restantes.
    if (out.toSet().length == 1) {
      final remaining = Map<MissionCategory, int>.from(weights)
        ..remove(out.first);
      out[2] = _weightedPick(remaining);
    }
    return out;
  }

  Map<MissionCategory, int> _weightsFor(MissionCategory primary) {
    final w = <MissionCategory, int>{
      MissionCategory.fisico: 20,
      MissionCategory.mental: 20,
      MissionCategory.espiritual: 20,
      MissionCategory.vitalismo: 10,
    };
    if (primary == MissionCategory.vitalismo) {
      // Edge case: primaryFocus = vitalismo. Aumenta peso do vitalismo
      // pra 50, mantém 20/20/10 no resto (mas só temos 3 outros).
      // Distribuição final: vit 50, fisico 20, mental 20, espiritual 10.
      // Mantém soma 100. (Caelum + Etapa 1.1 mostra Vitalismo é raro:
      // se virou primaryFocus, aumenta presença mas não vira maioria.)
      w[MissionCategory.vitalismo] = 50;
      w[MissionCategory.espiritual] = 10;
    } else {
      w[primary] = 50;
    }
    return w;
  }

  MissionCategory _weightedPick(Map<MissionCategory, int> weights) {
    final total = weights.values.fold<int>(0, (a, b) => a + b);
    var r = _random.nextInt(total);
    for (final entry in weights.entries) {
      r -= entry.value;
      if (r < 0) return entry.key;
    }
    return weights.keys.last; // fallback (não deveria acontecer)
  }

  // ─── construção da missão (mono-modalidade) ──────────────────────────

  DailyMission _buildModalidadeMission({
    required int playerId,
    required String dateStr,
    required DateTime now,
    required MissionCategory modalidade,
    required String rank,
    required PlayersTableData player,
    required Set<String> usedKeys,
  }) {
    final pool = _pools.poolFor(modalidade) as DailyModalidadePool;
    final subCat = _pickSubcategoria(pool.pesosSubcategoria);

    final candidatas = pool.subTarefas
        .where((s) => s.subCategoria == subCat)
        .where((s) => !usedKeys.contains(s.key))
        .where((s) => _resolveScale(s, rank, player) > 0)
        .toList();

    if (candidatas.length < subTasksPerMission) {
      // Defesa: se a sub-cat sorteada não tem 3 elegíveis (sub-tarefas
      // já usadas em outras missões + filtro escala 0), tenta outra
      // sub-cat dentro da mesma modalidade.
      for (final entry in pool.titulosPorSubcategoria.keys) {
        if (entry == subCat) continue;
        final alt = pool.subTarefas
            .where((s) => s.subCategoria == entry)
            .where((s) => !usedKeys.contains(s.key))
            .where((s) => _resolveScale(s, rank, player) > 0)
            .toList();
        if (alt.length >= subTasksPerMission) {
          return _assembleMono(
            playerId: playerId,
            dateStr: dateStr,
            now: now,
            modalidade: modalidade,
            subCategoria: entry,
            pool: pool,
            candidatas: alt,
            rank: rank,
            player: player,
            usedKeys: usedKeys,
          );
        }
      }
      throw StateError(
          'Sem sub-tarefas elegíveis pra ${modalidade.storage} no rank $rank '
          '(usadas=${usedKeys.length})');
    }

    return _assembleMono(
      playerId: playerId,
      dateStr: dateStr,
      now: now,
      modalidade: modalidade,
      subCategoria: subCat,
      pool: pool,
      candidatas: candidatas,
      rank: rank,
      player: player,
      usedKeys: usedKeys,
    );
  }

  DailyMission _assembleMono({
    required int playerId,
    required String dateStr,
    required DateTime now,
    required MissionCategory modalidade,
    required String subCategoria,
    required DailyModalidadePool pool,
    required List<DailySubTaskSpec> candidatas,
    required String rank,
    required PlayersTableData player,
    required Set<String> usedKeys,
  }) {
    final shuffled = List<DailySubTaskSpec>.from(candidatas)..shuffle(_random);
    final picked = shuffled.take(subTasksPerMission).toList();
    for (final s in picked) {
      usedKeys.add(s.key);
    }

    final subInsts = picked
        .map((s) => DailySubTaskInstance(
              subTaskKey: s.key,
              nomeVisivel: s.nomeVisivel,
              escalaAlvo: _resolveScale(s, rank, player),
              unidade: s.unidade,
              tipoUnidade: s.tipoUnidade,
            ))
        .toList();

    final titulos = pool.titulosPorSubcategoria[subCategoria]!;
    final titulo = titulos[_random.nextInt(titulos.length)];
    final quote = pool.quotes[_random.nextInt(pool.quotes.length)];

    return DailyMission(
      id: 0,
      playerId: playerId,
      data: dateStr,
      modalidade: modalidade,
      subCategoria: subCategoria,
      tituloKey: titulo,
      tituloResolvido: titulo,
      quoteResolvida: quote,
      subTarefas: subInsts,
      status: DailyMissionStatus.pending,
      createdAt: now,
      completedAt: null,
      rewardClaimed: false,
    );
  }

  // ─── construção Vitalismo (1 sub-tarefa por pilar) ───────────────────

  DailyMission _buildVitalismoMission({
    required int playerId,
    required String dateStr,
    required DateTime now,
    required String rank,
    required PlayersTableData player,
    required Set<String> usedKeys,
  }) {
    final vitPool = _pools.vitalismoPool();
    final pesosPorPilar = vitPool.pesosSubcategoriaPorPilar;

    final fis = _pickVitalismoSubTask(
        pilar: 'fisico',
        category: MissionCategory.fisico,
        pesos: pesosPorPilar['fisico']!,
        rank: rank,
        player: player,
        usedKeys: usedKeys);
    final men = _pickVitalismoSubTask(
        pilar: 'mental',
        category: MissionCategory.mental,
        pesos: pesosPorPilar['mental']!,
        rank: rank,
        player: player,
        usedKeys: usedKeys);
    final esp = _pickVitalismoSubTask(
        pilar: 'espiritual',
        category: MissionCategory.espiritual,
        pesos: pesosPorPilar['espiritual']!,
        rank: rank,
        player: player,
        usedKeys: usedKeys);

    final subInsts = [fis, men, esp];
    final titulo = vitPool.titulos[_random.nextInt(vitPool.titulos.length)];
    final quote = vitPool.quotes[_random.nextInt(vitPool.quotes.length)];

    return DailyMission(
      id: 0,
      playerId: playerId,
      data: dateStr,
      modalidade: MissionCategory.vitalismo,
      subCategoria: null,
      tituloKey: titulo,
      tituloResolvido: titulo,
      quoteResolvida: quote,
      subTarefas: subInsts,
      status: DailyMissionStatus.pending,
      createdAt: now,
      completedAt: null,
      rewardClaimed: false,
    );
  }

  DailySubTaskInstance _pickVitalismoSubTask({
    required String pilar,
    required MissionCategory category,
    required Map<String, double> pesos,
    required String rank,
    required PlayersTableData player,
    required Set<String> usedKeys,
  }) {
    final pool = _pools.poolFor(category) as DailyModalidadePool;
    // Tenta sub-categorias em ordem de peso decrescente até achar uma
    // com sub-tarefa elegível.
    final subCats = pesos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sorteio ponderado da sub-categoria.
    final subCat = _pickSubcategoriaDouble(pesos);

    DailySubTaskSpec? spec = _firstEligible(
        pool, subCat, rank, player, usedKeys);
    if (spec == null) {
      // Fallback: tenta outras sub-cats do mesmo pilar.
      for (final entry in subCats) {
        if (entry.key == subCat) continue;
        spec = _firstEligible(pool, entry.key, rank, player, usedKeys);
        if (spec != null) break;
      }
    }
    if (spec == null) {
      throw StateError(
          'Vitalismo: sem sub-tarefa elegível em $pilar (rank=$rank, '
          'usadas=${usedKeys.length})');
    }
    usedKeys.add(spec.key);
    return DailySubTaskInstance(
      subTaskKey: spec.key,
      nomeVisivel: spec.nomeVisivel,
      escalaAlvo: _resolveScale(spec, rank, player),
      unidade: spec.unidade,
      tipoUnidade: spec.tipoUnidade,
      subPilar: pilar,
    );
  }

  DailySubTaskSpec? _firstEligible(DailyModalidadePool pool, String subCat,
      String rank, PlayersTableData player, Set<String> usedKeys) {
    final candidatas = pool.subTarefas
        .where((s) => s.subCategoria == subCat)
        .where((s) => !usedKeys.contains(s.key))
        .where((s) => _resolveScale(s, rank, player) > 0)
        .toList();
    if (candidatas.isEmpty) return null;
    candidatas.shuffle(_random);
    return candidatas.first;
  }

  // ─── helpers ────────────────────────────────────────────────────────

  String _pickSubcategoria(Map<String, double> pesos) =>
      _pickSubcategoriaDouble(pesos);

  String _pickSubcategoriaDouble(Map<String, double> pesos) {
    final total = pesos.values.fold<double>(0, (a, b) => a + b);
    var r = _random.nextDouble() * total;
    for (final entry in pesos.entries) {
      r -= entry.value;
      if (r <= 0) return entry.key;
    }
    return pesos.keys.last;
  }

  int _resolveScale(
          DailySubTaskSpec spec, String rank, PlayersTableData player) =>
      _pools.resolveScale(
          spec: spec,
          rank: rank,
          bodyMetrics: _bodyMetrics,
          player: player);

  /// Player.guildRank vem como `'E'..'S'` (uppercase) ou `'none'` pra
  /// pré-Guilda. `'none'` cai pra rank E (jogador novo).
  String _normalizeRank(String raw) {
    if (raw == 'none' || raw.isEmpty) return 'E';
    return raw.toUpperCase();
  }

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
