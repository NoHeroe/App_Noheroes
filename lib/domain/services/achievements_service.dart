import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/daily_mission_events.dart';
import '../../core/events/faction_events.dart';
import '../../core/events/navigation_events.dart';
import '../../core/events/player_events.dart';
import '../../core/events/reward_events.dart';
import '../../core/utils/day_format.dart';
import '../../data/database/daos/player_dao.dart';
import '../../data/services/reward_grant_service.dart';
import '../exceptions/reward_exceptions.dart';
import '../models/achievement_definition.dart';
import '../models/player_daily_mission_stats.dart';
import '../models/player_snapshot.dart';
import '../models/reward_resolved.dart';
import '../repositories/player_achievements_repository.dart';
import 'achievement_trigger_types.dart';
import 'player_screens_visited_service.dart';
import 'reward_resolve_service.dart';

/// Snapshot mínimo de atributos do jogador consumido pelos validators de
/// trigger e pelo resolver. Mantido separado do `PlayerSnapshot` (que é
/// focado em equipamento/combate) porque conquistas pedem contadores
/// distintos — manter os dois isolados evita crescer `PlayerSnapshot`
/// por motivos alheios.
class PlayerFacts {
  final int level;
  final int totalQuestsCompleted;

  /// Sprint 3.3 Etapa 2.1b — streak diário de missões. Lido de
  /// `players.daily_missions_streak`. Usado pelo trigger
  /// `daily_mission_streak`.
  final int dailyMissionsStreak;

  final PlayerSnapshot snapshot;
  const PlayerFacts({
    required this.level,
    required this.totalQuestsCompleted,
    required this.snapshot,
    this.dailyMissionsStreak = 0,
  });
}

/// Callback que resolve `PlayerFacts` pro id dado. Injetado — prod lê do
/// Supabase, testes fornecem stub determinístico.
///
/// Época 2 (ADR-0024): [playerId] virou uuid (String).
typedef PlayerFactsResolver = Future<PlayerFacts> Function(String playerId);

/// Sprint 3.1 Bloco 8 — serviço central das conquistas. Carrega o catálogo
/// JSON em memória, escuta `RewardGranted` no `AppEventBus` e desbloqueia
/// conquistas cujas triggers estejam satisfeitas.
///
/// Época 2 full-online (ADR-0024): leituras de stats/volume diário e do
/// jogador vão direto ao Supabase (`from(...)`) — não há mais DAOs Drift.
/// Operações de unlock/claim continuam via repository (writes simples) e
/// via RPC `grant_achievement_reward` (grant atômico, no `RewardGrantService`).
///
/// ## Contratos
///
/// - **Idempotente**: desbloquear uma key já completada vira noop silencioso
///   (via `PlayerAchievementsRepository.isCompleted`).
/// - **Cascata controlada**: limite duro de 3 níveis.
/// - **Ordem de emissão**: `AchievementUnlocked` publicado APÓS `markCompleted`.
/// - **Re-entry do listener**: idempotência via `isCompleted` torna benigno.
class AchievementsService {
  final PlayerAchievementsRepository _achievementsRepo;
  final RewardResolveService _rewardResolve;
  final RewardGrantService _rewardGrant;
  final AppEventBus _bus;
  final PlayerFactsResolver _resolvePlayerFacts;
  final AssetBundle _assetBundle;

  /// Época 2 (ADR-0024) — client Supabase opcional pros triggers daily
  /// (stats + subtask volume). Quando `null`, qualquer `DailyMissionTrigger`
  /// cai em fail-safe (warn + return false) — preserva backwards-compat de
  /// testes que não constroem o pipeline de stats.
  final SupabaseClient? _client;

  /// Sprint 3.3 Etapa 2.1c-α — PlayerDao opcional pra triggers `event_*`
  /// que precisam ler players (class_type, faction_type, peak_level,
  /// total_gems_spent, etc.). Null em modo degradado de testes legacy.
  final PlayerDao? _playerDao;

  /// Sprint 3.3 Etapa 2.1c-γ — service opcional pro trigger
  /// `event_screen_visited`. Null → fail-safe degradado (warn + return false).
  final PlayerScreensVisitedService? _screensVisitedService;

  /// Path do catálogo — exposto como `static const` pra facilitar override
  /// em teste de load e pra caller inspecionar em debug.
  static const String catalogAssetPath = 'assets/data/achievements.json';

  /// Limite duro de profundidade da cascata (conta em níveis encadeados).
  static const int maxCascadeDepth = 3;

  final Map<String, AchievementDefinition> _catalog = {};

  /// Cache pré-filtrado dos achievements com trigger daily. Filtra
  /// `disabled=true`.
  List<AchievementDefinition> _dailyAchievements = const [];

  /// Cache pré-filtrado dos achievements com trigger event_* (não-daily).
  List<AchievementDefinition> _eventAchievements = const [];

  /// Cache pré-filtrado dos achievements com trigger MetaTrigger /
  /// ThresholdStatTrigger / EventCountTrigger. Filtra `disabled=true`.
  List<AchievementDefinition> _metaLikeAchievements = const [];

  bool _loaded = false;
  Future<void>? _loadingFuture;

  AchievementsService({
    required PlayerAchievementsRepository achievementsRepo,
    required RewardResolveService rewardResolve,
    required RewardGrantService rewardGrant,
    required AppEventBus bus,
    required PlayerFactsResolver resolvePlayerFacts,
    SupabaseClient? client,
    PlayerDao? playerDao,
    PlayerScreensVisitedService? screensVisitedService,
    AssetBundle? assetBundle,
  })  : _achievementsRepo = achievementsRepo,
        _rewardResolve = rewardResolve,
        _rewardGrant = rewardGrant,
        _bus = bus,
        _resolvePlayerFacts = resolvePlayerFacts,
        _client = client,
        _playerDao = playerDao,
        _screensVisitedService = screensVisitedService,
        _assetBundle = assetBundle ?? rootBundle;

  /// Lê o catálogo em memória (idempotente). Race-free via Future guardada.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loadingFuture ??= _doLoad();
    await _loadingFuture;
  }

  Future<void> _doLoad() async {
    String raw;
    try {
      raw = await _assetBundle.loadString(catalogAssetPath);
    } catch (_) {
      _loaded = true;
      // ignore: avoid_print
      print('[achievements] catálogo $catalogAssetPath ausente — service '
          'fica em no-op até Bloco 14 popular');
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException("achievements.json: raiz não é objeto");
    }
    final tierDefsRaw = decoded['tier_definitions'];
    final Map<String, Map<String, dynamic>> tierDefs = {};
    if (tierDefsRaw is Map<String, dynamic>) {
      for (final e in tierDefsRaw.entries) {
        if (e.value is Map<String, dynamic>) {
          tierDefs[e.key] = e.value as Map<String, dynamic>;
        }
      }
    }
    final list = decoded['achievements'];
    if (list is! List) {
      throw const FormatException(
          "achievements.json: campo 'achievements' deve ser lista");
    }
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException(
            "achievements.json: entrada da lista não é objeto");
      }
      final processed = _resolveTier(entry, tierDefs);
      final def = AchievementDefinition.fromJson(processed);
      if (_catalog.containsKey(def.key)) {
        throw FormatException(
            "achievements.json: key duplicada '${def.key}'");
      }
      _catalog[def.key] = def;
    }
    _dailyAchievements = _catalog.values
        .where((d) => d.trigger is DailyMissionTrigger && !d.disabled)
        .toList(growable: false);
    _eventAchievements = _catalog.values
        .where((d) => d.trigger is EventTrigger && !d.disabled)
        .toList(growable: false);
    _metaLikeAchievements = _catalog.values
        .where((d) =>
            !d.disabled &&
            (d.trigger is MetaTrigger ||
                d.trigger is ThresholdStatTrigger ||
                d.trigger is EventCountTrigger))
        .toList(growable: false);
    _loaded = true;
  }

  /// Sprint 3.3 Etapa 2.2 — converte um entry do catálogo no formato com
  /// `reward_tier` (string ref) ou `reward_tier_custom` (inline). Idempotente.
  Map<String, dynamic> _resolveTier(
    Map<String, dynamic> entry,
    Map<String, Map<String, dynamic>> tierDefs,
  ) {
    if (entry.containsKey('reward')) return entry;
    Map<String, dynamic>? tierMap;
    if (entry.containsKey('reward_tier_custom')) {
      final raw = entry['reward_tier_custom'];
      if (raw is! Map<String, dynamic>) {
        throw FormatException(
            "reward_tier_custom deve ser objeto em '${entry['key']}'");
      }
      tierMap = raw;
    } else if (entry.containsKey('reward_tier')) {
      final tierName = entry['reward_tier'];
      if (tierName is! String) {
        throw FormatException(
            "reward_tier deve ser string em '${entry['key']}'");
      }
      tierMap = tierDefs[tierName];
      if (tierMap == null) {
        throw FormatException(
            "reward_tier '$tierName' não encontrado em tier_definitions "
            "(em '${entry['key']}')");
      }
    }
    if (tierMap == null) return entry;

    final items = <Map<String, dynamic>>[];
    final bausSecretos = (tierMap['baus_secretos'] as int?) ?? 0;
    if (bausSecretos > 0) {
      items.add({
        'key': 'CHEST_SECRET',
        'quantity': bausSecretos,
        'chance_pct': 100,
      });
    }
    final bausDerrotado = (tierMap['baus_derrotado'] as int?) ?? 0;
    if (bausDerrotado > 0) {
      items.add({
        'key': 'CHEST_DEFEATED',
        'quantity': bausDerrotado,
        'chance_pct': 100,
      });
    }
    final reward = <String, dynamic>{
      'xp': (tierMap['xp'] as int?) ?? 0,
      'gold': (tierMap['gold'] as int?) ?? 0,
      'gems': (tierMap['gems'] as int?) ?? 0,
      if (items.isNotEmpty) 'items': items,
    };

    return {...entry, 'reward': reward};
  }

  /// Carrega catálogo e assina o listener de `RewardGranted`. Retorna a
  /// subscription — caller deve cancelar em dispose.
  Future<StreamSubscription<RewardGranted>> attach() async {
    await ensureLoaded();
    return _bus.on<RewardGranted>().listen(_handleRewardGranted);
  }

  /// Sprint 3.3 Etapa 2.1b — assina o listener de `DailyStatsUpdated`.
  Future<List<StreamSubscription>> attachDailyListeners() async {
    await ensureLoaded();
    return [
      _bus.on<DailyStatsUpdated>().listen(_onDailyStatsUpdated),
    ];
  }

  /// Sprint 3.3 Etapa 2.2 hotfix — assina listeners de `AchievementUnlocked`
  /// e `LevelUp` pros triggers meta/threshold/event_count.
  Future<List<StreamSubscription>> attachMetaLikeListeners() async {
    await ensureLoaded();
    return [
      _bus
          .on<AchievementUnlocked>()
          .listen((e) => _checkMetaLikeTriggers(e.playerId)),
      _bus.on<LevelUp>().listen((e) => _checkMetaLikeTriggers(e.playerId)),
    ];
  }

  /// Sprint 3.3 Etapa 2.1c-α — assina os listeners pros triggers `event_*`.
  Future<List<StreamSubscription>> attachEventListeners() async {
    await ensureLoaded();
    return [
      _bus.on<ClassSelected>().listen((e) => _checkEventTriggers(e.playerId)),
      _bus.on<FactionJoined>().listen((e) => _checkEventTriggers(e.playerId)),
      _bus
          .on<AttributePointSpent>()
          .listen((e) => _checkEventTriggers(e.playerId)),
      _bus.on<BodyMetricsUpdated>().listen(
          (e) => _checkEventTriggers(e.playerId, bodyMetricsEvent: e)),
      _bus
          .on<CurrencyStatsUpdated>()
          .listen((e) => _checkEventTriggers(e.playerId)),
      _bus.on<ScreenVisited>().listen((e) => _checkEventTriggers(e.playerId)),
    ];
  }

  /// Acessor pra inspeção em testes / debug. Não mutável.
  Map<String, AchievementDefinition> get catalog =>
      Map.unmodifiable(_catalog);

  // ─── handler + cascata ─────────────────────────────────────────────

  Future<void> _onDailyStatsUpdated(DailyStatsUpdated evt) async {
    await ensureLoaded();
    if (_dailyAchievements.isEmpty) return;
    for (final def in _dailyAchievements) {
      await _tryUnlock(evt.playerId, def.key, depth: 0);
    }
  }

  Future<void> _checkMetaLikeTriggers(String playerId) async {
    await ensureLoaded();
    if (_metaLikeAchievements.isEmpty) return;
    for (final def in _metaLikeAchievements) {
      await _tryUnlock(playerId, def.key, depth: 0);
    }
  }

  Future<void> _checkEventTriggers(
    String playerId, {
    BodyMetricsUpdated? bodyMetricsEvent,
  }) async {
    await ensureLoaded();
    if (_eventAchievements.isEmpty) return;
    for (final def in _eventAchievements) {
      await _tryUnlock(playerId, def.key,
          depth: 0, bodyMetricsEvent: bodyMetricsEvent);
    }
  }

  Future<void> _handleRewardGranted(RewardGranted evt) async {
    // Eventos gerados pelo próprio grantAchievement não entram no fluxo de
    // cascata pelo listener — a cascata já foi processada síncronamente.
    if (evt.fromAchievementCascade) return;

    await ensureLoaded();

    final RewardResolved resolved;
    try {
      resolved = RewardResolved.fromJsonString(evt.rewardResolvedJson);
    } catch (e) {
      // ignore: avoid_print
      print('[achievements] falha desserializando RewardGranted payload: $e');
      return;
    }
    for (final key in resolved.achievementsToCheck) {
      await _tryUnlock(evt.playerId, key, depth: 0);
    }
  }

  /// Tentativa de desbloqueio com controle de idempotência, trigger e
  /// cascata. Ver docstring da classe pro fluxo canônico.
  Future<void> _tryUnlock(
    String playerId,
    String key, {
    required int depth,
    BodyMetricsUpdated? bodyMetricsEvent,
  }) async {
    if (depth >= maxCascadeDepth) {
      // ignore: avoid_print
      print('[achievements] cascade depth limit atingido em "$key" '
          '(depth=$depth, max=$maxCascadeDepth) — skip');
      return;
    }
    if (await _achievementsRepo.isCompleted(playerId, key)) {
      return;
    }
    final def = _catalog[key];
    if (def == null) {
      // ignore: avoid_print
      print('[achievements] key "$key" referenciada em '
          'achievements_to_check não existe no catálogo — skip');
      return;
    }
    if (def.disabled) {
      return;
    }
    if (!await _validateTrigger(playerId, def,
        bodyMetricsEvent: bodyMetricsEvent)) {
      return;
    }

    // Sprint 3.3 Etapa Final-A — coleta manual: unlock só marca completed
    // e publica AchievementUnlocked. Grant da reward é de [claimReward].
    // Ver ADR-0020-coleta-manual-recompensas-conquistas.
    await _achievementsRepo.markCompleted(
      playerId,
      key,
      at: DateTime.now(),
    );
    _bus.publish(
        AchievementUnlocked(playerId: playerId, achievementKey: key));
  }

  /// Sprint 3.3 Etapa Final-A — coleta manual de recompensa de conquista.
  ///
  /// Race condition tolerada: 2 calls concorrentes na mesma key — o 2º
  /// recebe [AchievementRewardAlreadyGrantedException] do grant e retorna
  /// false silenciosamente.
  Future<bool> claimReward(String playerId, String key) async {
    await ensureLoaded();
    final def = _catalog[key];
    if (def == null) return false;
    if (def.disabled) return false;
    if (!await _achievementsRepo.isCompleted(playerId, key)) return false;
    if (await _achievementsRepo.isRewardClaimed(playerId, key)) {
      return false;
    }
    if (def.reward == null) {
      await _achievementsRepo.markRewardClaimed(playerId, key);
      return true;
    }
    final facts = await _resolvePlayerFacts(playerId);
    final resolved =
        await _rewardResolve.resolve(def.reward!, facts.snapshot);
    try {
      await _rewardGrant.grantAchievement(
        playerId: playerId,
        achievementKey: key,
        resolved: resolved,
      );
      return true;
    } on AchievementRewardAlreadyGrantedException {
      return false;
    }
  }

  // ─── validators de trigger ─────────────────────────────────────────

  Future<bool> _validateTrigger(
    String playerId,
    AchievementDefinition def, {
    BodyMetricsUpdated? bodyMetricsEvent,
  }) async {
    final trigger = def.trigger;
    switch (trigger) {
      case EventCountTrigger(eventName: final name, count: final c):
        switch (name) {
          case 'MissionCompleted':
            final facts = await _resolvePlayerFacts(playerId);
            return facts.totalQuestsCompleted >= c;
          case 'AchievementUnlocked':
            final n = await _achievementsRepo.countCompleted(playerId);
            return n >= c;
          default:
            // ignore: avoid_print
            print('[achievements] event_count com event "$name" não '
                'suportado no MVP — trigger de "${def.key}" fica false '
                '(Bloco 14 expande)');
            return false;
        }
      case ThresholdStatTrigger(stat: final s, value: final v):
        if (s != 'level') {
          // ignore: avoid_print
          print('[achievements] threshold_stat com stat "$s" não '
              'suportado no MVP — trigger de "${def.key}" fica false '
              '(Bloco 14 expande)');
          return false;
        }
        final facts = await _resolvePlayerFacts(playerId);
        return facts.level >= v;
      case MetaTrigger(targetCount: final n):
        final current = await _achievementsRepo.countCompleted(playerId);
        return current >= n;
      case DailyMissionTrigger():
        return _validateDailyTrigger(playerId, def, trigger);
      case EventTrigger():
        return _validateEventTrigger(
            playerId, def, trigger, bodyMetricsEvent);
      case UnknownAchievementTrigger(rawType: final t):
        // ignore: avoid_print
        print('[achievements] trigger type "$t" não reconhecido em '
            '"${def.key}" — skip (Bloco 14 expande)');
        return false;
    }
  }

  // ─── leitura de stats/volume diário (Supabase, Época 2) ─────────────

  /// Lê a row de `player_daily_mission_stats` do jogador. Retorna `null`
  /// se não existe (sem auto-create: validação de trigger é read-only e
  /// row ausente vira zeros via [_emptyStats]). Substitui o antigo
  /// `PlayerDailyMissionStatsDao.findOrCreate` (que criava em escrita —
  /// desnecessário num caminho de leitura).
  Future<PlayerDailyMissionStats> _readStats(String playerId) async {
    final row = await _client!
        .from('player_daily_mission_stats')
        .select()
        .eq('player_id', playerId)
        .maybeSingle();
    if (row == null) return _emptyStats(playerId);
    return PlayerDailyMissionStats.fromMap(row);
  }

  /// Stats default (todos zeros) pra jogador sem row ainda — espelha o
  /// estado recém-criado do `findOrCreate` legacy.
  PlayerDailyMissionStats _emptyStats(String playerId) =>
      PlayerDailyMissionStats(
        playerId: playerId,
        totalCompleted: 0,
        totalFailed: 0,
        totalPartial: 0,
        totalPerfect: 0,
        totalSuperPerfect: 0,
        totalGenerated: 0,
        totalConfirmed: 0,
        bestStreak: 0,
        daysWithoutFailing: 0,
        bestDaysWithoutFailing: 0,
        consecutiveFailsCount: 0,
        maxConsecutiveFails: 0,
        consecutiveActiveDays: 0,
        bestConsecutiveActiveDays: 0,
        totalSubTasksCompleted: 0,
        totalSubTasksOvershoot: 0,
        totalConfirmedBefore8AM: 0,
        totalConfirmedAfter10PM: 0,
        totalConfirmedOnWeekend: 0,
        daysOfWeekCompletedBitmask: 0,
        totalZeroProgressConfirms: 0,
        totalDaysAllPilars: 0,
        totalSpeedrunCompletions: 0,
        totalAutoConfirmCompletions: 0,
        totalZeroProgressManualConfirms: 0,
        dailyTodayCount: 0,
        lastTodayCountDate: null,
        firstCompletedAt: null,
        lastCompletedAt: null,
        lastPilarBalanceDay: null,
        lastActiveDay: null,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Volume de uma sub-task específica. 0 se não há row.
  Future<int> _readSubtaskVolume(String playerId, String subTaskKey) async {
    final row = await _client!
        .from('player_daily_subtask_volume')
        .select('total_units')
        .eq('player_id', playerId)
        .eq('sub_task_key', subTaskKey)
        .maybeSingle();
    if (row == null) return 0;
    return (row['total_units'] as num?)?.toInt() ?? 0;
  }

  /// Soma de `total_units` de todas as sub-tasks do jogador. 0 se nenhuma.
  Future<int> _readSubtaskTotalVolume(String playerId) async {
    final rows = await _client!
        .from('player_daily_subtask_volume')
        .select('total_units')
        .eq('player_id', playerId);
    var total = 0;
    for (final r in rows) {
      total += (r['total_units'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  // ─── validators de daily trigger (Sprint 3.3 Etapa 2.1b) ───────────

  Future<bool> _validateDailyTrigger(
    String playerId,
    AchievementDefinition def,
    DailyMissionTrigger trigger,
  ) async {
    if (_client == null &&
        trigger.subType != AchievementTriggerTypes.dailyMissionStreak) {
      // Triggers que dependem de stats precisam do client. Streak é único
      // que lê de PlayerFacts (players.daily_missions_streak).
      // ignore: avoid_print
      print('[achievements] daily trigger "${trigger.subType}" em '
          '"${def.key}" requer client Supabase — skip (modo degradado)');
      return false;
    }

    switch (trigger.subType) {
      case AchievementTriggerTypes.dailyMissionCount:
        final stats = await _readStats(playerId);
        return stats.totalCompleted >= trigger.target;

      case AchievementTriggerTypes.dailyMissionFailedCount:
        final stats = await _readStats(playerId);
        return stats.totalFailed >= trigger.target;

      case AchievementTriggerTypes.dailyMissionPartialCount:
        final stats = await _readStats(playerId);
        return stats.totalPartial >= trigger.target;

      case AchievementTriggerTypes.dailyMissionStreak:
        final facts = await _resolvePlayerFacts(playerId);
        return facts.dailyMissionsStreak >= trigger.target;

      case AchievementTriggerTypes.dailyMissionBestStreak:
        final stats = await _readStats(playerId);
        return stats.bestStreak >= trigger.target;

      case AchievementTriggerTypes.dailyMissionPerfectCount:
        final stats = await _readStats(playerId);
        return stats.totalPerfect >= trigger.target;

      case AchievementTriggerTypes.dailyMissionSuperPerfectCount:
        final stats = await _readStats(playerId);
        return stats.totalSuperPerfect >= trigger.target;

      case AchievementTriggerTypes.dailyNoFailStreak:
        final stats = await _readStats(playerId);
        final useBest = trigger.params?['use_best'] == true;
        final value = useBest
            ? stats.bestDaysWithoutFailing
            : stats.daysWithoutFailing;
        return value >= trigger.target;

      case AchievementTriggerTypes.dailySubtaskVolume:
        final key = trigger.params?['sub_task_key'];
        if (key is! String || key.isEmpty) {
          // ignore: avoid_print
          print('[achievements] daily_subtask_volume em "${def.key}" '
              'sem params.sub_task_key — fail-safe');
          return false;
        }
        final volume = await _readSubtaskVolume(playerId, key);
        return volume >= trigger.target;

      case AchievementTriggerTypes.dailySubtaskTotalVolume:
        final total = await _readSubtaskTotalVolume(playerId);
        return total >= trigger.target;

      case AchievementTriggerTypes.dailyConfirmedTimeWindow:
        final stats = await _readStats(playerId);
        final window = trigger.params?['window'];
        switch (window) {
          case 'before_8am':
            return stats.totalConfirmedBefore8AM >= trigger.target;
          case 'after_10pm':
            return stats.totalConfirmedAfter10PM >= trigger.target;
          default:
            // ignore: avoid_print
            print('[achievements] daily_confirmed_time_window em '
                '"${def.key}" com window inválido ($window) — fail-safe');
            return false;
        }

      case AchievementTriggerTypes.dailyConfirmedOnWeekend:
        final stats = await _readStats(playerId);
        return stats.totalConfirmedOnWeekend >= trigger.target;

      case AchievementTriggerTypes.dailyPilarBalance:
        final stats = await _readStats(playerId);
        return stats.totalDaysAllPilars >= trigger.target;

      case AchievementTriggerTypes.dailyConsecutiveDaysActive:
        final stats = await _readStats(playerId);
        final useBest = trigger.params?['use_best'] == true;
        final value = useBest
            ? stats.bestConsecutiveActiveDays
            : stats.consecutiveActiveDays;
        return value >= trigger.target;

      case AchievementTriggerTypes.dailySpeedrun:
        final stats = await _readStats(playerId);
        return stats.totalSpeedrunCompletions >= trigger.target;

      case AchievementTriggerTypes.dailyAutoConfirmCount:
        final stats = await _readStats(playerId);
        return stats.totalAutoConfirmCompletions >= trigger.target;

      case AchievementTriggerTypes.dailyZeroProgressManualCount:
        final stats = await _readStats(playerId);
        return stats.totalZeroProgressManualConfirms >= trigger.target;

      case AchievementTriggerTypes.dailyTodayCount:
        // STALE GUARD: contador é tocado pós-completion. Se a data não é
        // hoje (device local), o valor é de ontem — rejeita.
        final stats = await _readStats(playerId);
        final today = formatDay(DateTime.now());
        if (stats.lastTodayCountDate != today) {
          return false;
        }
        return stats.dailyTodayCount >= trigger.target;

      default:
        // ignore: avoid_print
        print('[achievements] daily subType "${trigger.subType}" em '
            '"${def.key}" sem mapeamento — fail-safe');
        return false;
    }
  }

  // ─── validators de event trigger (Sprint 3.3 Etapa 2.1c-α) ─────────

  Future<bool> _validateEventTrigger(
    String playerId,
    AchievementDefinition def,
    EventTrigger trigger,
    BodyMetricsUpdated? bodyMetricsEvent,
  ) async {
    final playerDao = _playerDao;
    if (playerDao == null) {
      // ignore: avoid_print
      print('[achievements] event trigger "${trigger.subType}" em '
          '"${def.key}" requer playerDao — skip (modo degradado)');
      return false;
    }

    switch (trigger.subType) {
      case AchievementTriggerTypes.eventClassSelected:
        final expectedClass = trigger.param<String>('class_key');
        final player = await playerDao.findById(playerId);
        if (player == null) return false;
        if (expectedClass == null) {
          return player.classType != null && player.classType!.isNotEmpty;
        }
        return player.classType == expectedClass;

      case AchievementTriggerTypes.eventFactionJoined:
        final expectedFaction = trigger.param<String>('faction_id');
        final player = await playerDao.findById(playerId);
        if (player == null) return false;
        final ft = player.factionType;
        if (ft == null ||
            ft.isEmpty ||
            ft.startsWith('pending:') ||
            ft == 'lone_wolf') {
          return false;
        }
        if (expectedFaction == null) {
          return true;
        }
        return ft == expectedFaction;

      case AchievementTriggerTypes.eventAttributePointSpent:
        final player = await playerDao.findById(playerId);
        if (player == null) return false;
        return player.totalAttributePointsSpent >= trigger.target;

      case AchievementTriggerTypes.eventBodyMetricsUpdated:
        final player = await playerDao.findById(playerId);
        if (player == null) return false;
        final calibrated =
            player.weightKg != null && player.heightCm != null;
        if (!calibrated) return false;
        final mustBeFirstTime =
            trigger.param<bool>('must_be_first_time') ?? false;
        if (mustBeFirstTime) {
          return bodyMetricsEvent?.isFirstTime ?? false;
        }
        return true;

      case AchievementTriggerTypes.eventGemsSpentTotal:
        final player = await playerDao.findById(playerId);
        if (player == null) return false;
        return player.totalGemsSpent >= trigger.target;

      case AchievementTriggerTypes.eventScreenVisited:
        final svc = _screensVisitedService;
        if (svc == null) {
          // ignore: avoid_print
          print('[achievements] event_screen_visited em "${def.key}" '
              'requer screensVisitedService — skip (modo degradado)');
          return false;
        }
        final expectedKey = trigger.param<String>('screen_key');
        if (expectedKey == null) {
          return await svc.visitedCount(playerId) >= trigger.target;
        }
        return await svc.hasVisited(playerId, expectedKey);

      default:
        // ignore: avoid_print
        print('[achievements] event subType "${trigger.subType}" em '
            '"${def.key}" sem mapeamento — fail-safe');
        return false;
    }
  }

  /// Read-only acessor pro cache pré-filtrado de daily triggers.
  List<AchievementDefinition> get dailyAchievements =>
      List.unmodifiable(_dailyAchievements);

  /// Read-only acessor pro cache pré-filtrado dos event_* triggers.
  List<AchievementDefinition> get eventAchievements =>
      List.unmodifiable(_eventAchievements);

  /// Read-only acessor pro cache de meta/threshold_stat/event_count.
  List<AchievementDefinition> get metaLikeAchievements =>
      List.unmodifiable(_metaLikeAchievements);

  /// Read-only — leitura direta de stats pra testes/inspeção. `null` se não
  /// há client configurado.
  Future<PlayerDailyMissionStats?> debugReadStats(String playerId) async {
    if (_client == null) return null;
    return _readStats(playerId);
  }
}
