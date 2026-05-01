import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/events/app_event_bus.dart';
import '../../core/events/daily_mission_events.dart';
import '../../core/events/faction_events.dart';
import '../../core/events/navigation_events.dart';
import '../../core/events/player_events.dart';
import '../../core/events/reward_events.dart';
import '../../core/utils/day_format.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/player_dao.dart';
import '../../data/database/daos/player_daily_mission_stats_dao.dart';
import '../../data/database/daos/player_daily_subtask_volume_dao.dart';
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
/// `AppDatabase`, testes fornecem stub determinístico.
typedef PlayerFactsResolver = Future<PlayerFacts> Function(int playerId);

/// Sprint 3.1 Bloco 8 — serviço central das conquistas. Carrega o catálogo
/// JSON em memória, escuta `RewardGranted` no `AppEventBus` e desbloqueia
/// conquistas cujas triggers estejam satisfeitas.
///
/// ## Contratos
///
/// - **Idempotente**: desbloquear uma key já completada vira noop silencioso
///   (via `PlayerAchievementsRepository.isCompleted`).
/// - **Cascata controlada**: `reward.achievementsToCheck` das próprias
///   conquistas é processado síncronamente com `depth+1`. Limite dura de 3
///   níveis; atingiu → log warning e skip (fail-safe, nunca lança).
/// - **Ordem de emissão**: `AchievementUnlocked` é publicado APÓS o grant
///   da reward (quando houver), espelhando o pattern `commit-then-publish`
///   do `RewardGrantService` (Bloco 5). Se reward é `null`, o evento é
///   publicado logo após `markCompleted`.
/// - **Re-entry do listener**: o próprio `grantAchievement` emite
///   `RewardGranted`, que volta pro handler. A idempotência via
///   `isCompleted` torna esse ciclo benigno (noop em ~1 check), então
///   não aplicamos flags de supressão.
///
/// ## Triggers suportados no MVP (Bloco 8)
///
/// | Tipo             | Resolve contra                                     |
/// |------------------|----------------------------------------------------|
/// | `event_count`    | `MissionCompleted` → `total_quests_completed`      |
/// |                  | `AchievementUnlocked` → `countCompleted()`         |
/// | `threshold_stat` | `stat: level` → `players.level`                    |
/// | `meta`           | `countCompleted() >= target_count`                 |
///
/// Qualquer outro par (`event_count` com event desconhecido, `threshold_stat`
/// com stat != `level`, trigger `sequence`, etc.) cai em **fail-safe**:
/// retorna `false` + log warn. Bloco 14 expande mapeamentos.
///
/// ## Lifecycle
///
/// ```dart
/// final service = AchievementsService(...);
/// final sub = await service.attach();  // carrega + subscreve
/// // ...
/// await sub.cancel();
/// ```
class AchievementsService {
  final PlayerAchievementsRepository _achievementsRepo;
  final RewardResolveService _rewardResolve;
  final RewardGrantService _rewardGrant;
  final AppEventBus _bus;
  final PlayerFactsResolver _resolvePlayerFacts;
  final AssetBundle _assetBundle;

  /// Sprint 3.3 Etapa 2.1b — DAOs opcionais pros 15 triggers daily.
  /// Quando `null`, qualquer `DailyMissionTrigger` cai em fail-safe
  /// (warn + return false) — preserva backwards-compat de testes que
  /// não constroem o pipeline de stats.
  final PlayerDailyMissionStatsDao? _statsDao;
  final PlayerDailySubtaskVolumeDao? _volumeDao;

  /// Sprint 3.3 Etapa 2.1c-α — PlayerDao opcional pra triggers
  /// `event_*` que precisam ler players (class_type, faction_type,
  /// peak_level, total_gems_spent, etc.). Null em modo degradado
  /// de testes legacy.
  final PlayerDao? _playerDao;

  /// Sprint 3.3 Etapa 2.1c-γ — service opcional pro trigger
  /// `event_screen_visited` (lê telas visitadas via CSV em
  /// `players.screens_visited_keys`). Null → fail-safe degradado
  /// (warn + return false).
  final PlayerScreensVisitedService? _screensVisitedService;

  /// Path do catálogo — exposto como `static const` pra facilitar override
  /// em teste de load e pra caller inspecionar em debug.
  static const String catalogAssetPath = 'assets/data/achievements.json';

  /// Limite duro de profundidade da cascata (conta em níveis encadeados).
  /// Depth 0 = unlock direto do `RewardGranted` externo; 1 = 1º nested;
  /// 2 = 2º nested; >=3 = log warn + skip.
  static const int maxCascadeDepth = 3;

  final Map<String, AchievementDefinition> _catalog = {};

  /// Cache pré-filtrado dos achievements com trigger daily — evita varrer
  /// o catálogo inteiro a cada `DailyStatsUpdated`. Populado em `_doLoad`.
  /// Filtra `disabled=true` (Sprint 3.3 Etapa 2.1c-α).
  List<AchievementDefinition> _dailyAchievements = const [];

  /// Sprint 3.3 Etapa 2.1c-α — cache pré-filtrado dos achievements com
  /// trigger event_* (não-daily). Filtra `disabled=true`.
  List<AchievementDefinition> _eventAchievements = const [];

  bool _loaded = false;
  Future<void>? _loadingFuture;

  AchievementsService({
    required PlayerAchievementsRepository achievementsRepo,
    required RewardResolveService rewardResolve,
    required RewardGrantService rewardGrant,
    required AppEventBus bus,
    required PlayerFactsResolver resolvePlayerFacts,
    PlayerDailyMissionStatsDao? statsDao,
    PlayerDailySubtaskVolumeDao? volumeDao,
    PlayerDao? playerDao,
    PlayerScreensVisitedService? screensVisitedService,
    AssetBundle? assetBundle,
  })  : _achievementsRepo = achievementsRepo,
        _rewardResolve = rewardResolve,
        _rewardGrant = rewardGrant,
        _bus = bus,
        _resolvePlayerFacts = resolvePlayerFacts,
        _statsDao = statsDao,
        _volumeDao = volumeDao,
        _playerDao = playerDao,
        _screensVisitedService = screensVisitedService,
        _assetBundle = assetBundle ?? rootBundle;

  /// Lê o catálogo em memória (idempotente). Chamado explicitamente pelo
  /// caller em startup ou lazy no primeiro evento. Re-chamar é noop.
  ///
  /// Em catálogo malformado lança `FormatException` — Bloco 8 assume que
  /// o arquivo ou é válido ou é ausente; ausência de asset deixa o service
  /// com `_catalog` vazio (handler fica noop sem ruído).
  ///
  /// ## Race-free (Hotfix v0.29.1)
  ///
  /// Dois callers concorrentes (provider inicializa via `attach()` em
  /// fire-and-forget + tela `/achievements` chama ao montar) podiam
  /// entrar ambos no corpo antes de `_loaded=true`, preenchendo
  /// `_catalog` duas vezes e estourando "key duplicada" no 2º loop.
  /// Guardamos a Future da carga em andamento e fazemos callers
  /// subsequentes awaitarem a mesma — uma só execução do loop.
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
      // Asset não empacotado / não existe. Deixa _loaded=true + catálogo
      // vazio pro handler virar noop em vez de tentar carregar a cada
      // evento.
      _loaded = true;
      // ignore: avoid_print
      print('[achievements] catálogo $catalogAssetPath ausente — service '
          'fica em no-op até Bloco 14 popular');
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          "achievements.json: raiz não é objeto");
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
      final def = AchievementDefinition.fromJson(entry);
      if (_catalog.containsKey(def.key)) {
        throw FormatException(
            "achievements.json: key duplicada '${def.key}'");
      }
      _catalog[def.key] = def;
    }
    // Sprint 3.3 Etapa 2.1b — cache pré-filtrado de daily triggers.
    // Sprint 3.3 Etapa 2.1c-α — também filtra `disabled=true`.
    _dailyAchievements = _catalog.values
        .where((d) => d.trigger is DailyMissionTrigger && !d.disabled)
        .toList(growable: false);
    // Sprint 3.3 Etapa 2.1c-α — cache pré-filtrado de event_* triggers.
    _eventAchievements = _catalog.values
        .where((d) => d.trigger is EventTrigger && !d.disabled)
        .toList(growable: false);
    _loaded = true;
  }

  /// Carrega catálogo e assina o listener de `RewardGranted`. Retorna a
  /// subscription — caller deve cancelar em dispose (provider faz isso
  /// via `ref.onDispose`).
  Future<StreamSubscription<RewardGranted>> attach() async {
    await ensureLoaded();
    return _bus.on<RewardGranted>().listen(_handleRewardGranted);
  }

  /// Sprint 3.3 Etapa 2.1b — assina o listener de `DailyStatsUpdated`,
  /// evento publicado pelo `DailyMissionStatsService` APÓS commit das
  /// stats. Retorna lista de subscriptions — caller deve cancelar todas
  /// em dispose. Hoje há só 1 (o evento agrega completed/failed/generated)
  /// mas devolve lista pra facilitar adição futura sem mudar contrato.
  Future<List<StreamSubscription>> attachDailyListeners() async {
    await ensureLoaded();
    return [
      _bus.on<DailyStatsUpdated>().listen(_onDailyStatsUpdated),
    ];
  }

  /// Sprint 3.3 Etapa 2.1c-α — assina os 5 listeners pros triggers
  /// `event_*`:
  ///   - [ClassSelected] → `event_class_selected`
  ///   - [FactionJoined] → `event_faction_joined`
  ///   - [AttributePointSpent] → `event_attribute_point_spent`
  ///   - [BodyMetricsUpdated] → `event_body_metrics_updated`
  ///   - [CurrencyStatsUpdated] → `event_gems_spent_total` (escuta o
  ///     evento de coordenação publicado pelo `PlayerCurrencyStatsService`
  ///     pós-commit, NÃO o `GemsSpent` cru — evita race condition)
  ///
  /// Cada handler delega ao mesmo método interno [_checkEventTriggers]
  /// que itera o cache `_eventAchievements` e tenta unlock.
  Future<List<StreamSubscription>> attachEventListeners() async {
    await ensureLoaded();
    return [
      _bus.on<ClassSelected>().listen(
          (e) => _checkEventTriggers(e.playerId)),
      _bus.on<FactionJoined>().listen(
          (e) => _checkEventTriggers(e.playerId)),
      _bus.on<AttributePointSpent>().listen(
          (e) => _checkEventTriggers(e.playerId)),
      _bus.on<BodyMetricsUpdated>().listen(
          (e) => _checkEventTriggers(e.playerId, bodyMetricsEvent: e)),
      _bus.on<CurrencyStatsUpdated>().listen(
          (e) => _checkEventTriggers(e.playerId)),
      // Sprint 3.3 Etapa 2.1c-γ — escuta SEMPRE (isFirstVisit true OU
      // false). Conquista pode ter sido adicionada após a 1ª visita;
      // a 2ª visita é a primeira chance de unlock.
      _bus.on<ScreenVisited>().listen(
          (e) => _checkEventTriggers(e.playerId)),
    ];
  }

  /// Acessor pra inspeção em testes / debug. Não mutável.
  Map<String, AchievementDefinition> get catalog =>
      Map.unmodifiable(_catalog);

  // ─── handler + cascata ─────────────────────────────────────────────

  /// Sprint 3.3 Etapa 2.1b — handler de [DailyStatsUpdated]. Itera o
  /// cache pré-filtrado e tenta unlock de cada achievement daily. Stats
  /// já está commitado quando este handler roda (publish é pós-commit).
  Future<void> _onDailyStatsUpdated(DailyStatsUpdated evt) async {
    await ensureLoaded();
    if (_dailyAchievements.isEmpty) return;
    for (final def in _dailyAchievements) {
      await _tryUnlock(evt.playerId, def.key, depth: 0);
    }
  }

  /// Sprint 3.3 Etapa 2.1c-α — handler unificado pros 5 listeners de
  /// event_*. Itera `_eventAchievements`. [bodyMetricsEvent] é
  /// passado adiante pra `_validateEventTrigger` quando o evento fonte
  /// é `BodyMetricsUpdated` (precisa do `isFirstTime` no validador).
  Future<void> _checkEventTriggers(
    int playerId, {
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
    // Eventos gerados pelo próprio `grantAchievement` não entram no
    // fluxo de cascata pelo listener — a cascata já foi processada
    // síncronamente pelo caller com depth correto. Ignorar aqui evita
    // que o listener contorne o limite de profundidade.
    if (evt.fromAchievementCascade) return;

    // Lazy guard: se ninguém chamou attach/ensureLoaded ainda.
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
  ///
  /// Exposto como `@visibleForTesting` implícito (não tem decoração por
  /// enquanto — adicionar se testes começarem a exigir) pra permitir
  /// testes unitários sem passar pelo bus.
  ///
  /// Sprint 3.3 Etapa 2.1c-α — [bodyMetricsEvent] passado adiante pra
  /// `_validateEventTrigger` quando trigger é `event_body_metrics_updated`
  /// com `must_be_first_time=true`.
  Future<void> _tryUnlock(
    int playerId,
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
    // Sprint 3.3 Etapa 2.1c-α — shell achievements (mecânica subjacente
    // ainda não pronta) ficam carregadas mas nunca unlock. Cobre também
    // referências em cascata via `achievements_to_check`.
    if (def.disabled) {
      return;
    }
    if (!await _validateTrigger(playerId, def,
        bodyMetricsEvent: bodyMetricsEvent)) {
      return;
    }

    // Marca ANTES do grant. Garante que o re-entry do listener
    // (grantAchievement → RewardGranted → handler) cai em `isCompleted`
    // true e vira noop.
    await _achievementsRepo.markCompleted(
      playerId,
      key,
      at: DateTime.now(),
    );

    // Grant da reward da conquista, se declarada. D5 do plano: evento
    // AchievementUnlocked emite APÓS grant — consistência com pattern
    // commit-then-publish do RewardGrantService.
    RewardResolved? resolvedReward;
    if (def.reward != null) {
      final facts = await _resolvePlayerFacts(playerId);
      resolvedReward = await _rewardResolve.resolve(
        def.reward!,
        facts.snapshot,
      );
      try {
        await _rewardGrant.grantAchievement(
          playerId: playerId,
          achievementKey: key,
          resolved: resolvedReward,
        );
      } on AchievementRewardAlreadyGrantedException {
        // Race improvável (concorrência entre cascade e re-entry do
        // listener grantando a mesma chave). Idempotência natural.
        // ignore: avoid_print
        print('[achievements] grant já aplicado em "$key" — skip');
      }
    }

    _bus.publish(AchievementUnlocked(playerId: playerId, achievementKey: key));

    // Cascata síncrona. depth+1 protege contra loops; re-entry via bus
    // cai em isCompleted check.
    if (resolvedReward != null) {
      for (final nested in resolvedReward.achievementsToCheck) {
        await _tryUnlock(playerId, nested, depth: depth + 1);
      }
    }
  }

  // ─── validators de trigger ─────────────────────────────────────────

  Future<bool> _validateTrigger(
    int playerId,
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

  // ─── validators de daily trigger (Sprint 3.3 Etapa 2.1b) ───────────

  /// Resolve um [DailyMissionTrigger] contra a foundation da Etapa 2.1a
  /// (`PlayerDailyMissionStatsDao` + `PlayerDailySubtaskVolumeDao` +
  /// `players.daily_missions_streak`).
  ///
  /// Sub-types com `params` malformado (ex: window faltando) caem em
  /// fail-safe (warn + return false). Idem se DAOs forem `null` (modo
  /// degradado de testes legacy).
  Future<bool> _validateDailyTrigger(
    int playerId,
    AchievementDefinition def,
    DailyMissionTrigger trigger,
  ) async {
    final statsDao = _statsDao;
    if (statsDao == null && trigger.subType != AchievementTriggerTypes.dailyMissionStreak) {
      // Triggers que dependem de stats precisam do DAO. Streak é único
      // que lê de PlayerFacts (players.daily_missions_streak).
      // ignore: avoid_print
      print('[achievements] daily trigger "${trigger.subType}" em '
          '"${def.key}" requer statsDao — skip (modo degradado)');
      return false;
    }

    switch (trigger.subType) {
      case AchievementTriggerTypes.dailyMissionCount:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalCompleted >= trigger.target;

      case AchievementTriggerTypes.dailyMissionFailedCount:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalFailed >= trigger.target;

      case AchievementTriggerTypes.dailyMissionPartialCount:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalPartial >= trigger.target;

      case AchievementTriggerTypes.dailyMissionStreak:
        final facts = await _resolvePlayerFacts(playerId);
        return facts.dailyMissionsStreak >= trigger.target;

      case AchievementTriggerTypes.dailyMissionBestStreak:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.bestStreak >= trigger.target;

      case AchievementTriggerTypes.dailyMissionPerfectCount:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalPerfect >= trigger.target;

      case AchievementTriggerTypes.dailyMissionSuperPerfectCount:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalSuperPerfect >= trigger.target;

      case AchievementTriggerTypes.dailyNoFailStreak:
        final stats = await statsDao!.findOrCreate(playerId);
        final useBest = trigger.params?['use_best'] == true;
        final value = useBest
            ? stats.bestDaysWithoutFailing
            : stats.daysWithoutFailing;
        return value >= trigger.target;

      case AchievementTriggerTypes.dailySubtaskVolume:
        final volumeDao = _volumeDao;
        if (volumeDao == null) {
          // ignore: avoid_print
          print('[achievements] daily_subtask_volume em "${def.key}" '
              'requer volumeDao — skip');
          return false;
        }
        final key = trigger.params?['sub_task_key'];
        if (key is! String || key.isEmpty) {
          // ignore: avoid_print
          print('[achievements] daily_subtask_volume em "${def.key}" '
              'sem params.sub_task_key — fail-safe');
          return false;
        }
        final volume = await volumeDao.getVolume(playerId, key);
        return volume >= trigger.target;

      case AchievementTriggerTypes.dailySubtaskTotalVolume:
        final volumeDao = _volumeDao;
        if (volumeDao == null) {
          // ignore: avoid_print
          print('[achievements] daily_subtask_total_volume em "${def.key}" '
              'requer volumeDao — skip');
          return false;
        }
        final total = await volumeDao.getTotalVolume(playerId);
        return total >= trigger.target;

      case AchievementTriggerTypes.dailyConfirmedTimeWindow:
        final stats = await statsDao!.findOrCreate(playerId);
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
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalConfirmedOnWeekend >= trigger.target;

      case AchievementTriggerTypes.dailyPilarBalance:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalDaysAllPilars >= trigger.target;

      case AchievementTriggerTypes.dailyConsecutiveDaysActive:
        final stats = await statsDao!.findOrCreate(playerId);
        final useBest = trigger.params?['use_best'] == true;
        final value = useBest
            ? stats.bestConsecutiveActiveDays
            : stats.consecutiveActiveDays;
        return value >= trigger.target;

      case AchievementTriggerTypes.dailySpeedrun:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalSpeedrunCompletions >= trigger.target;

      case AchievementTriggerTypes.dailyAutoConfirmCount:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalAutoConfirmCompletions >= trigger.target;

      case AchievementTriggerTypes.dailyZeroProgressManualCount:
        final stats = await statsDao!.findOrCreate(playerId);
        return stats.totalZeroProgressManualConfirms >= trigger.target;

      case AchievementTriggerTypes.dailyTodayCount:
        // Sprint 3.3 Etapa 2.1c-δ. STALE GUARD: contador é tocado pelo
        // listener `_onCompleted` no `DailyMissionStatsService`. Se o
        // jogador completou X missões ontem e ainda não completou
        // nenhuma hoje, `dailyTodayCount` continua no valor de ontem
        // até a próxima `incrementTodayCount` zerar (via reset lazy).
        // Sem este guard, validador acharia que conta de ontem é de
        // hoje. Comparação YYYY-MM-DD device local — sistema PARALELO
        // ao caelum_day (intocado).
        final stats = await statsDao!.findOrCreate(playerId);
        final today = formatDay(DateTime.now());
        if (stats.lastTodayCountDate != today) {
          return false;
        }
        return stats.dailyTodayCount >= trigger.target;

      default:
        // Não deveria acontecer — o parser só cria DailyMissionTrigger
        // pra subtypes em AchievementTriggerTypes.allDaily. Defesa pra
        // caso alguém estenda a constants list sem atualizar este switch.
        // ignore: avoid_print
        print('[achievements] daily subType "${trigger.subType}" em '
            '"${def.key}" sem mapeamento — fail-safe');
        return false;
    }
  }

  // ─── validators de event trigger (Sprint 3.3 Etapa 2.1c-α) ─────────

  /// Resolve um [EventTrigger] contra players + total_gems_spent +
  /// PlayerFacts (streak/level). Sub-types com schema malformado caem
  /// em fail-safe (warn + return false).
  ///
  /// [bodyMetricsEvent] é passado quando o evento fonte é
  /// [BodyMetricsUpdated] — usado por `event_body_metrics_updated`
  /// com `params.must_be_first_time=true` pra distinguir 1ª calibração
  /// de edição posterior.
  Future<bool> _validateEventTrigger(
    int playerId,
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
          // Sem param: qualquer classe selecionada conta.
          return player.classType != null && player.classType!.isNotEmpty;
        }
        return player.classType == expectedClass;

      case AchievementTriggerTypes.eventFactionJoined:
        final expectedFaction = trigger.param<String>('faction_id');
        final player = await playerDao.findById(playerId);
        if (player == null) return false;
        final ft = player.factionType;
        if (ft == null || ft.isEmpty || ft.startsWith('pending:')) {
          // Pending = ainda em admissão; não conta como joined.
          return false;
        }
        if (expectedFaction == null) {
          // Sem param: qualquer facção final conta.
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
          // Só unlock quando o evento que disparou este check carrega
          // `isFirstTime=true`. Cascata via `achievements_to_check` ou
          // disparo por outro trigger não satisfaz.
          return bodyMetricsEvent?.isFirstTime ?? false;
        }
        // Default: qualquer save (1ª ou edição) conta.
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
          // Sem param: target = N telas distintas visitadas.
          return await svc.visitedCount(playerId) >= trigger.target;
        }
        // Com param: específica (one-shot, target geralmente 1).
        return await svc.hasVisited(playerId, expectedKey);

      default:
        // Defesa contra extensão de constants sem update neste switch.
        // ignore: avoid_print
        print('[achievements] event subType "${trigger.subType}" em '
            '"${def.key}" sem mapeamento — fail-safe');
        return false;
    }
  }

  /// Read-only acessor pro cache pré-filtrado — facilita inspeção em
  /// testes pra verificar que o load detectou os daily triggers corretos.
  List<AchievementDefinition> get dailyAchievements =>
      List.unmodifiable(_dailyAchievements);

  /// Sprint 3.3 Etapa 2.1c-α — read-only acessor pro cache pré-filtrado
  /// dos event_* triggers. Útil pra introspection em testes e UI.
  List<AchievementDefinition> get eventAchievements =>
      List.unmodifiable(_eventAchievements);

  /// Read-only — utilizado por testes pra forçar leitura sob estado
  /// arbitrário sem precisar publicar evento.
  Future<PlayerDailyMissionStats?> debugReadStats(int playerId) async {
    return _statsDao?.findByPlayerId(playerId);
  }
}
