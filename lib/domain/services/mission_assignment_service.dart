import 'dart:convert';
import 'dart:math';

import '../../core/config/rank_pools.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/utils/guild_rank.dart';
import '../../data/datasources/local/mission_catalogs_service.dart';
import '../enums/mission_modality.dart';
import '../enums/mission_tab_origin.dart';
import '../models/mission_progress.dart';
import '../models/reward_declared.dart';
import '../repositories/active_faction_quests_repository.dart';
import '../repositories/mission_repository.dart';

/// Sprint 3.1 Bloco 13a — assignment pool-based (ADR 0017 + DESIGN_DOC §8).
///
/// Orquestra criação de `MissionProgress` a partir dos catálogos estáticos
/// (`MissionCatalogsService`), aplicando:
///
///   - **Rank gating** (ADR 0017): pool cross-rank via `RankPools.filterByRank`.
///   - **Sampling**: `Random` injetável pra testes determinísticos.
///
/// Emite `MissionStarted` pós-commit de cada MissionProgress criado —
/// o evento do Bloco 2 é suficiente (sem criar `MissionAssigned` novo
/// conforme decisão CEO).
///
/// Schema 37 (reescrita das diárias): o assign de **diárias legacy**
/// (`assignDailyForPlayer`, baseado em `MissionPreferences`) foi removido
/// — as diárias agora são geradas pelo `DailyMissionGeneratorService`
/// (modelo fixo). Restam **missões de classe** (`assignClassDaily`) e
/// **facção semanal** (`ensureWeeklyFactionQuest`).
class MissionAssignmentService {
  final MissionRepository _missionRepo;
  final MissionCatalogsService _catalogs;
  final ActiveFactionQuestsRepository _factionRepo;
  final AppEventBus _bus;
  final Random _random;

  MissionAssignmentService({
    required MissionRepository missionRepo,
    required MissionCatalogsService catalogs,
    required ActiveFactionQuestsRepository factionRepo,
    required AppEventBus bus,
    Random? random,
  })  : _missionRepo = missionRepo,
        _catalogs = catalogs,
        _factionRepo = factionRepo,
        _bus = bus,
        _random = random ?? Random();

  /// Quantidade fixa de missões de classe por dia.
  static const int kClassPerDay = 3;

  /// Assigna [kClassPerDay] missões de classe pro jogador. Filtra pool
  /// por `class_key` + rank. Retorna ids criadas.
  ///
  /// Bloco 13b — `classKey` nullable: se `null` ou vazio, early-return
  /// silencioso `const []`. Jogador sem classe escolhida (pré-phase5
  /// ou Rogue guest) não recebe class missions. DailyResetService
  /// chama com `player.classType` direto sem precisar validar.
  Future<List<int>> assignClassDaily({
    required int playerId,
    required String? classKey,
    required GuildRank playerRank,
  }) async {
    if (classKey == null || classKey.isEmpty) return const [];
    final pool = await _catalogs.loadClass(classKey);
    if (pool.isEmpty) return const [];
    final filtered = RankPools.filterByRank<Map<String, dynamic>>(
      pool,
      playerRank,
      (e) => _rankOf(e),
    );
    if (filtered.isEmpty) return const [];
    final picked = _sampleN(filtered, kClassPerDay);
    return _persistAndEmit(playerId, picked, MissionTabOrigin.classTab);
  }

  /// Garante 1 missão de facção semanal pro par (jogador, facção).
  /// Atomic upsert via `ActiveFactionQuestsRepository` (fecha bug 3
  /// Sprint 2.3). Retorna progressId criado/recuperado, ou `null` se
  /// pool vazio.
  Future<int?> ensureWeeklyFactionQuest({
    required int playerId,
    required String factionKey,
    required GuildRank playerRank,
    DateTime? now,
  }) async {
    final pool = await _catalogs.loadFactionWeekly(factionKey);
    if (pool.isEmpty) return null;
    final filtered = RankPools.filterByRank<Map<String, dynamic>>(
      pool,
      playerRank,
      (e) => _rankOf(e),
    );
    if (filtered.isEmpty) return null;
    final picked = _sampleN(filtered, 1).first;
    final weekStart = _weekStartIso(now ?? DateTime.now());

    final seedJson = _toProgressSeed(picked, MissionTabOrigin.faction);
    final result = await _factionRepo.upsertAtomic(
      playerId: playerId,
      factionId: factionKey,
      missionKey: picked['key'] as String,
      weekStart: weekStart,
      progressSeedJson: seedJson,
    );
    _bus.publish(MissionStarted(
      missionKey: picked['key'] as String,
      playerId: playerId,
      modality: _modalityOf(picked).storage,
      tabOrigin: MissionTabOrigin.faction.storage,
    ));
    return result.progressId;
  }

  // ─── helpers privados ──────────────────────────────────────────────

  /// Sampling sem reposição. Respeita `weightFor` do ADR 0017 se forem
  /// ranks heterogêneos — pro MVP simplificamos pra shuffle uniforme
  /// (weighted por rank seria overkill dentro de pool já filtrado).
  List<Map<String, dynamic>> _sampleN(
    List<Map<String, dynamic>> pool,
    int n,
  ) {
    if (pool.length <= n) return List.from(pool);
    final copy = List<Map<String, dynamic>>.from(pool);
    copy.shuffle(_random);
    return copy.take(n).toList(growable: false);
  }

  Future<List<int>> _persistAndEmit(
    int playerId,
    List<Map<String, dynamic>> picked,
    MissionTabOrigin tab,
  ) async {
    final ids = <int>[];
    for (final entry in picked) {
      final mp = _toMissionProgress(playerId, entry, tab);
      final id = await _missionRepo.insert(mp);
      ids.add(id);
      _bus.publish(MissionStarted(
        missionKey: mp.missionKey,
        playerId: playerId,
        modality: mp.modality.storage,
        tabOrigin: mp.tabOrigin.storage,
      ));
    }
    return ids;
  }

  MissionProgress _toMissionProgress(
    int playerId,
    Map<String, dynamic> entry,
    MissionTabOrigin tab,
  ) {
    final rewardJson = entry['reward'] as Map<String, dynamic>?;
    return MissionProgress(
      id: 0,
      playerId: playerId,
      missionKey: entry['key'] as String,
      modality: _modalityOf(entry),
      tabOrigin: tab,
      rank: _rankOf(entry),
      targetValue: entry['target_value'] as int? ?? 1,
      currentValue: 0,
      reward: rewardJson == null
          ? const RewardDeclared()
          : RewardDeclared.fromJson(rewardJson),
      startedAt: DateTime.now(),
      rewardClaimed: false,
      metaJson: _buildMetaJson(entry),
    );
  }

  /// Materializa `progress_seed_json` pro `ActiveFactionQuestsRepository`.
  /// O repo usa esse map pra criar a row `player_mission_progress`
  /// dentro da mesma transação.
  Map<String, dynamic> _toProgressSeed(
      Map<String, dynamic> entry, MissionTabOrigin tab) {
    final rewardJson = entry['reward'] as Map<String, dynamic>? ?? {};
    return {
      'mission_key': entry['key'],
      'modality': _modalityOf(entry).storage,
      'tab_origin': tab.storage,
      'rank': _rankOf(entry).name,
      'target_value': entry['target_value'] ?? 1,
      'reward_json': jsonEncode(rewardJson),
      'meta_json': _buildMetaJson(entry),
    };
  }

  String _buildMetaJson(Map<String, dynamic> entry) {
    // Mantém category pra filtros do QuestsScreenNotifier (Bloco 10a.1).
    final meta = <String, dynamic>{};
    final cat = entry['category'];
    if (cat is String) meta['category'] = cat;
    return jsonEncode(meta);
  }

  GuildRank _rankOf(Map<String, dynamic> entry) {
    final raw = (entry['rank'] as String?)?.toLowerCase() ?? 'e';
    return GuildRank.values.firstWhere(
      (r) => r.name == raw,
      orElse: () => GuildRank.e,
    );
  }

  MissionModality _modalityOf(Map<String, dynamic> entry) {
    final raw = entry['modality'] as String? ?? 'real';
    return MissionModalityCodec.fromStorage(raw);
  }

  /// Semana ISO no formato `YYYY-Www` (ex: `2026-W17`). Usado como
  /// `week_start` do `active_faction_quests` — batch Daily/Weekly
  /// Reset (Bloco 13b) varre expirados.
  String _weekStartIso(DateTime now) {
    // Monday-based week. Dart's weekday: 1=Monday..7=Sunday.
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final isoYear = monday.year;
    final jan4 = DateTime(isoYear, 1, 4);
    final firstMon =
        jan4.subtract(Duration(days: jan4.weekday - 1));
    final weekNum =
        ((monday.difference(firstMon).inDays) ~/ 7) + 1;
    return '$isoYear-W${weekNum.toString().padLeft(2, '0')}';
  }
}
