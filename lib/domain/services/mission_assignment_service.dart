import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/rank_pools.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/utils/guild_rank.dart';
import '../../data/datasources/local/mission_catalogs_service.dart';
import '../enums/mission_modality.dart';
import '../enums/mission_tab_origin.dart';
import '../enums/rank_codec.dart';
import '../models/reward_declared.dart';
import 'weekly_faction_validator.dart' show WeeklyFactionSubTaskTypes;

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
  final SupabaseClient _client;
  final MissionCatalogsService _catalogs;
  final AppEventBus _bus;
  final Random _random;

  MissionAssignmentService({
    required SupabaseClient client,
    required MissionCatalogsService catalogs,
    required AppEventBus bus,
    Random? random,
  })  : _client = client,
        _catalogs = catalogs,
        _bus = bus,
        _random = random ?? Random();

  /// Quantidade fixa de missões de classe por dia.
  static const int kClassPerDay = 3;

  /// FATIA B4 — curva de reward da semanal de facção por **guild-rank**
  /// do jogador (balance — tunável). `goldTargetMult` escala o target
  /// BASE (rank E) das sub-tasks `gold_earned_via_quests_window`.
  /// Insígnias entram fixas no pipeline (Fatia A); xp/gold ainda passam
  /// pelo SOULSLIKE no grant.
  static const Map<GuildRank,
      ({int insignias, int xp, int gold, double goldTargetMult})>
      _weeklyRewardByRank = {
    GuildRank.e: (insignias: 15, xp: 100, gold: 50, goldTargetMult: 1.0),
    GuildRank.d: (insignias: 22, xp: 150, gold: 75, goldTargetMult: 1.3),
    GuildRank.c: (insignias: 32, xp: 225, gold: 125, goldTargetMult: 1.8),
    GuildRank.b: (insignias: 45, xp: 325, gold: 200, goldTargetMult: 2.5),
    GuildRank.a: (insignias: 60, xp: 450, gold: 300, goldTargetMult: 3.5),
    GuildRank.s: (insignias: 80, xp: 650, gold: 450, goldTargetMult: 5.0),
  };

  /// Assigna [kClassPerDay] missões de classe pro jogador. Filtra pool
  /// por `class_key` + rank. Retorna ids criadas.
  ///
  /// Bloco 13b — `classKey` nullable: se `null` ou vazio, early-return
  /// silencioso `const []`. Jogador sem classe escolhida (pré-phase5
  /// ou Rogue guest) não recebe class missions. DailyResetService
  /// chama com `player.classType` direto sem precisar validar.
  Future<List<int>> assignClassDaily({
    required String playerId,
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
  ///
  /// FATIA B2a — catálogo per-facção com `sub_tasks[]` (motor acumulativo
  /// B1). Monta o `metaJson` RICO espelhando a admissão: `faction_id`,
  /// `mission_id`, `week_start_ms`/`week_end_ms` (semana ISO segunda
  /// 00:00 → +7d), `sub_tasks[]` (cada uma com `current:0`/`completed:
  /// false`), e um snapshot de `reward` (xp/gold/insignias/items) que a
  /// Fatia C lê pra pagar fração ≥50% na expiração.
  ///
  /// [baselineGoldEarned] = `players.total_gold_earned_via_quests` no
  /// momento do assign — gravado em `params.baseline_gold_via_quests` das
  /// sub-tasks `gold_earned_via_quests_window` (o validator B1 subtrai
  /// esse baseline). O caller (`WeeklyResetService`) injeta; default 0
  /// pra testes/callers sem o snapshot.
  Future<int?> ensureWeeklyFactionQuest({
    required String playerId,
    required String factionKey,
    required GuildRank playerRank,
    int baselineGoldEarned = 0,
    DateTime? now,
  }) async {
    final pool = await _catalogs.loadFactionWeekly(factionKey);
    if (pool.isEmpty) return null;
    // FATIA B4 — SEM rank gating: a semanal é 1 missão temática por
    // facção (pool de 5 variantes), não um pool tier-gated. Um pool de
    // poucas missões é incompatível com a banda de `RankPools` (Rank E
    // só aceitava rank `e`, que o catálogo não tem → assign nunca
    // gerava). Todo membro recebe em qualquer guild-rank; o `_sampleN`
    // ainda dá variedade entre as 5. (NÃO mexer em RankPools —
    // class/daily continuam usando.)
    final picked = _sampleN(pool, 1).first;
    final nowDt = now ?? DateTime.now();
    final weekStart = _weekStartIso(nowDt);
    final missionId = picked['id'] as String;

    final seedJson = _toWeeklyProgressSeed(
      picked,
      factionKey: factionKey,
      missionId: missionId,
      nowDt: nowDt,
      playerRank: playerRank,
      baselineGoldEarned: baselineGoldEarned,
    );
    // Upsert atômico+idempotente (ledger active_faction_quests + row de
    // progresso) delegado à RPC assign_weekly_faction_quest. O seed já vem
    // no shape esperado pela RPC (modality/tab_origin/rank/target_value/
    // reward_json/meta_json). NÃO reimplementamos a atomicidade no cliente.
    final result = await _client.rpc('assign_weekly_faction_quest', params: {
      'p_player': playerId,
      'p_faction_id': factionKey,
      'p_mission_key': missionId,
      'p_week_start': weekStart,
      'p_seed': seedJson,
    });
    final map = (result as Map).cast<String, dynamic>();
    final progressId = (map['progress_id'] as num?)?.toInt();

    _bus.publish(MissionStarted(
      missionKey: missionId,
      playerId: playerId,
      modality: MissionModality.internal.storage,
      tabOrigin: MissionTabOrigin.faction.storage,
    ));
    return progressId;
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
    String playerId,
    List<Map<String, dynamic>> picked,
    MissionTabOrigin tab,
  ) async {
    final ids = <int>[];
    for (final entry in picked) {
      final row = _toInsertRow(playerId, entry, tab);
      // Insert simples (single-row, sem atomicidade multi-tabela) — não há
      // RPC dedicada pra class daily; persiste direto via PostgREST e lê o
      // id (bigserial) de volta.
      final inserted = await _client
          .from('player_mission_progress')
          .insert(row)
          .select('id')
          .single();
      final id = (inserted['id'] as num).toInt();
      ids.add(id);
      _bus.publish(MissionStarted(
        missionKey: row['mission_key'] as String,
        playerId: playerId,
        modality: row['modality'] as String,
        tabOrigin: row['tab_origin'] as String,
      ));
    }
    return ids;
  }

  /// Monta a row (snake_case) de `player_mission_progress` pra insert
  /// direto. `id` é omitido (bigserial). `started_at`/`completed_at`/
  /// `failed_at` são bigint ms-epoch no schema.
  Map<String, dynamic> _toInsertRow(
    String playerId,
    Map<String, dynamic> entry,
    MissionTabOrigin tab,
  ) {
    final rewardJson = entry['reward'] as Map<String, dynamic>?;
    final reward = rewardJson == null
        ? const RewardDeclared()
        : RewardDeclared.fromJson(rewardJson);
    return {
      'player_id': playerId,
      'mission_key': entry['key'] as String,
      'modality': _modalityOf(entry).storage,
      'tab_origin': tab.storage,
      'rank': RankCodec.storage(_rankOf(entry)),
      'target_value': entry['target_value'] as int? ?? 1,
      'current_value': 0,
      'reward_json': reward.toJsonString(),
      'started_at': DateTime.now().millisecondsSinceEpoch,
      'reward_claimed': false,
      'meta_json': _buildMetaJson(entry),
    };
  }

  /// FATIA B2a — materializa `progress_seed_json` pro
  /// `ActiveFactionQuestsRepository` a partir de uma missão semanal do
  /// catálogo per-facção (com `sub_tasks[]`/`reward`). O repo usa esse
  /// map pra criar a row `player_mission_progress` dentro da mesma
  /// transação.
  ///
  /// - `modality` = `internal` (igual à admissão — sem `internal_event`;
  ///   o progresso flui pelo listener semanal da B2b, não pelas
  ///   strategies).
  /// - `target_value` = nº de sub-tasks (header N/M na UI).
  /// - `reward_json` = reward declarada da missão (xp/gold/insignias/
  ///   items — insígnias suportadas pela Fatia A).
  /// - `meta_json` = estado RICO (sub_tasks + janela semanal + snapshot
  ///   da reward).
  Map<String, dynamic> _toWeeklyProgressSeed(
    Map<String, dynamic> entry, {
    required String factionKey,
    required String missionId,
    required DateTime nowDt,
    required GuildRank playerRank,
    required int baselineGoldEarned,
  }) {
    // FATIA B4 — reward vem da CURVA por guild-rank (não do JSON).
    final curve = _weeklyRewardByRank[playerRank] ?? _weeklyRewardByRank[GuildRank.e]!;
    final rewardMap = <String, dynamic>{
      'xp': curve.xp,
      'gold': curve.gold,
      'insignias': curve.insignias,
    };
    // `rank` = guild-rank do player (flavor/display no badge do card).
    final rankLower = playerRank.name;

    final weekStartMs = _weekStartMs(nowDt);
    final weekEndMs = weekStartMs + _kWeekMs;

    final catalogSubs =
        (entry['sub_tasks'] as List?)?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    final subTasks = [
      for (final s in catalogSubs)
        _buildWeeklySubTask(s, baselineGoldEarned, curve.goldTargetMult),
    ];

    final meta = <String, dynamic>{
      'faction_id': factionKey,
      'mission_id': missionId,
      'title': entry['title'],
      'description': entry['description'],
      'rank': rankLower,
      'week_start_ms': weekStartMs,
      'week_end_ms': weekEndMs,
      'sub_tasks': subTasks,
      // Snapshot da reward — a Fatia C lê daqui pra pagar fração ≥50%.
      'reward': rewardMap,
    };

    // reward_json espelha a reward da curva (RewardDeclared aceita
    // insignias via Fatia A). Não dispara grant sozinho: missão weekly é
    // internal sem `internal_event`, então nada avança currentValue — o
    // pagamento é responsabilidade do listener/expiração (B2b/Fatia C).
    final rewardDeclared = RewardDeclared.fromJson(rewardMap);

    return {
      'mission_key': missionId,
      'modality': MissionModality.internal.storage,
      'tab_origin': MissionTabOrigin.faction.storage,
      'rank': rankLower,
      'target_value': subTasks.length,
      'reward_json': rewardDeclared.toJsonString(),
      'meta_json': jsonEncode(meta),
    };
  }

  /// FATIA B2a/B4 — converte uma sub-task do catálogo no shape persistido
  /// em metaJson (`current:0`/`completed:false`).
  ///
  /// Pra `gold_earned_via_quests_window`:
  ///  - injeta `params.baseline_gold_via_quests` (o validator B1 subtrai);
  ///  - escala o target BASE (rank E do catálogo) por [goldTargetMult] da
  ///    curva e reconstrói o label com o valor já escalado.
  Map<String, dynamic> _buildWeeklySubTask(
      Map<String, dynamic> s, int baselineGoldEarned, double goldTargetMult) {
    final subType = s['sub_type'] as String;
    final catalogParams =
        (s['params'] as Map?)?.cast<String, dynamic>();
    final params = <String, dynamic>{if (catalogParams != null) ...catalogParams};
    var target = (s['target'] as int?) ?? 0;
    var label = s['label'] as String?;

    if (subType == WeeklyFactionSubTaskTypes.goldEarnedViaQuestsWindow) {
      params['baseline_gold_via_quests'] = baselineGoldEarned;
      target = (target * goldTargetMult).round();
      label = '$target ouro ganho via quests na semana';
    }

    return <String, dynamic>{
      'sub_type': subType,
      'target': target,
      if (params.isNotEmpty) 'params': params,
      'label': label,
      'current': 0,
      'completed': false,
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

  /// FATIA B2a — janela de 7 dias em ms (segunda 00:00 → próxima segunda).
  static const int _kWeekMs = 7 * 24 * 60 * 60 * 1000;

  /// FATIA B2a — timestamp ms da segunda-feira 00:00 da semana de [now]
  /// (hora local). Fronteira de semana = a mesma do `_weekStartIso`
  /// (Monday-based), mas zerada na meia-noite e em epoch ms. Usado em
  /// `week_start_ms`/`week_end_ms` do metaJson (consumido pelo
  /// `WeeklyFactionValidator` da B1).
  int _weekStartMs(DateTime now) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final midnight = DateTime(monday.year, monday.month, monday.day);
    return midnight.millisecondsSinceEpoch;
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
