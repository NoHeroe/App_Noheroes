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

/// Schema 37 (reescrita das diárias) — geração das 3 missões diárias.
///
/// **Modelo fixo, igual pra todos os jogadores:** 1 missão de cada pilar
/// — [MissionCategory.fisico], [MissionCategory.mental],
/// [MissionCategory.espiritual] — por dia. Sem questionário de ajuste,
/// sem `primaryFocus`, sem Vitalismo diário.
///
/// Cada missão tira 1 sub-categoria rotativa do pool da modalidade e
/// monta [subTasksPerMission] sub-tarefas, escaladas por rank via
/// `escala_por_rank` (filtra sub-tarefas com escala 0 no rank do
/// jogador). Recompensa por rank vive no `DailyMissionProgressService`.
///
/// **BUG 1 (geração concorrente gerava 6/9):** `generateForToday` usa
/// um **single-flight guard** por `(playerId, dateStr)` — chamadas
/// concorrentes aguardam a MESMA Future em vez de cada uma rodar o
/// check-and-insert (TOCTOU). Combinado com o guard idempotente
/// `findByPlayerAndDate`, o resultado é exatamente 3, nunca 9.
class DailyMissionGeneratorService {
  final DailyPoolService _pools;
  final BodyMetricsService _bodyMetrics;
  final PlayerDao _playerDao;
  final DailyMissionsDao _missionsDao;
  final AppEventBus _bus;
  final Random _random;

  DailyMissionGeneratorService({
    required DailyPoolService pools,
    required BodyMetricsService bodyMetrics,
    required PlayerDao playerDao,
    required DailyMissionsDao missionsDao,
    required AppEventBus bus,
    Random? random,
  })  : _pools = pools,
        _bodyMetrics = bodyMetrics,
        _playerDao = playerDao,
        _missionsDao = missionsDao,
        _bus = bus,
        _random = random ?? Random();

  static const int missionsPerDay = 3;
  static const int subTasksPerMission = 3;

  /// Modalidades fixas do dia: 1 de cada pilar, sempre nesta ordem.
  /// Vitalismo NÃO entra nas diárias (modelo schema 37).
  static const List<MissionCategory> fixedModalidades = [
    MissionCategory.fisico,
    MissionCategory.mental,
    MissionCategory.espiritual,
  ];

  /// Single-flight: gerações em curso por `(playerId, dateStr)`. Garante
  /// que builds concorrentes da /quests (BUG 1) compartilhem a mesma
  /// Future em vez de cada um gerar e inserir 3 (= 6/9 duplicadas).
  final Map<String, Future<List<DailyMission>>> _inFlight = {};

  /// Idempotente — se já existem missões do dia [date] (default hoje)
  /// pro [playerId], retorna elas sem gerar de novo.
  ///
  /// Se [force] for `true` e já existirem missões do dia, elas são
  /// apagadas antes de gerar 3 novas. Usado pelo dev tool "Resetar
  /// missões diárias de hoje" — não usar em prod path.
  Future<List<DailyMission>> generateForToday(int playerId,
      {DateTime? date, bool force = false}) {
    final now = date ?? DateTime.now();
    final dateStr = _dateStr(now);
    final flightKey = '$playerId|$dateStr';

    // Se já há uma geração em curso pra (player, dia), aguarda a mesma
    // Future. O check-and-set é atômico (Dart single-thread, sem await
    // entre o get e o put).
    final inFlight = _inFlight[flightKey];
    if (inFlight != null) return inFlight;

    final future = _generate(playerId, now, dateStr, force);
    _inFlight[flightKey] = future;
    // Limpa o registro ao terminar (sucesso ou erro) sem alterar o
    // retorno do caller.
    future.whenComplete(() {
      if (identical(_inFlight[flightKey], future)) {
        _inFlight.remove(flightKey);
      }
    });
    return future;
  }

  Future<List<DailyMission>> _generate(
      int playerId, DateTime now, String dateStr, bool force) async {
    final existing =
        await _missionsDao.findByPlayerAndDate(playerId, dateStr);
    if (existing.isNotEmpty) {
      if (!force) return existing;
      await _missionsDao.deleteByPlayerAndDate(playerId, dateStr);
    }

    await _pools.loadAll();

    final player = await _playerDao.findById(playerId);
    if (player == null) {
      throw StateError('Player $playerId não existe');
    }
    final rank = _normalizeRank(player.guildRank);

    // Garante sub-tarefas únicas cross-missions no dia.
    final usedKeys = <String>{};
    // Hotfix Etapa 1.3.A — dedup de títulos cross-missions também.
    final usedTitulos = <String>{};

    final drafts = <DailyMission>[];
    for (final mod in fixedModalidades) {
      drafts.add(_buildModalidadeMission(
        playerId: playerId,
        dateStr: dateStr,
        now: now,
        modalidade: mod,
        rank: rank,
        player: player,
        usedKeys: usedKeys,
        usedTitulos: usedTitulos,
      ));
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

  // ─── construção da missão (mono-modalidade) ──────────────────────────

  DailyMission _buildModalidadeMission({
    required int playerId,
    required String dateStr,
    required DateTime now,
    required MissionCategory modalidade,
    required String rank,
    required PlayersTableData player,
    required Set<String> usedKeys,
    required Set<String> usedTitulos,
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
            usedTitulos: usedTitulos,
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
      usedTitulos: usedTitulos,
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
    required Set<String> usedTitulos,
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

    final titulo = _pickTitulo(
        pool.titulosPorSubcategoria[subCategoria]!, usedTitulos);
    usedTitulos.add(titulo);
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

  // ─── helpers ────────────────────────────────────────────────────────

  /// Sorteia um título do pool, evitando os já usados em outras missões
  /// do mesmo dia. Pior caso (improvável dados os pools 8/sub-cat): se
  /// 100% dos candidatos foram usados, cai pra sorteio sobre o pool
  /// inteiro como fallback.
  String _pickTitulo(List<String> pool, Set<String> usedTitulos) {
    final candidatos = pool.where((t) => !usedTitulos.contains(t)).toList();
    if (candidatos.isEmpty) {
      return pool[_random.nextInt(pool.length)];
    }
    return candidatos[_random.nextInt(candidatos.length)];
  }

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
