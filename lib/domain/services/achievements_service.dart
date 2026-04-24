import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/events/app_event_bus.dart';
import '../../core/events/reward_events.dart';
import '../../data/services/reward_grant_service.dart';
import '../exceptions/reward_exceptions.dart';
import '../models/achievement_definition.dart';
import '../models/player_snapshot.dart';
import '../models/reward_resolved.dart';
import '../repositories/player_achievements_repository.dart';
import 'reward_resolve_service.dart';

/// Snapshot mínimo de atributos do jogador consumido pelos validators de
/// trigger e pelo resolver. Mantido separado do `PlayerSnapshot` (que é
/// focado em equipamento/combate) porque conquistas pedem contadores
/// distintos — manter os dois isolados evita crescer `PlayerSnapshot`
/// por motivos alheios.
class PlayerFacts {
  final int level;
  final int totalQuestsCompleted;
  final PlayerSnapshot snapshot;
  const PlayerFacts({
    required this.level,
    required this.totalQuestsCompleted,
    required this.snapshot,
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

  /// Path do catálogo — exposto como `static const` pra facilitar override
  /// em teste de load e pra caller inspecionar em debug.
  static const String catalogAssetPath = 'assets/data/achievements.json';

  /// Limite duro de profundidade da cascata (conta em níveis encadeados).
  /// Depth 0 = unlock direto do `RewardGranted` externo; 1 = 1º nested;
  /// 2 = 2º nested; >=3 = log warn + skip.
  static const int maxCascadeDepth = 3;

  final Map<String, AchievementDefinition> _catalog = {};
  bool _loaded = false;
  Future<void>? _loadingFuture;

  AchievementsService({
    required PlayerAchievementsRepository achievementsRepo,
    required RewardResolveService rewardResolve,
    required RewardGrantService rewardGrant,
    required AppEventBus bus,
    required PlayerFactsResolver resolvePlayerFacts,
    AssetBundle? assetBundle,
  })  : _achievementsRepo = achievementsRepo,
        _rewardResolve = rewardResolve,
        _rewardGrant = rewardGrant,
        _bus = bus,
        _resolvePlayerFacts = resolvePlayerFacts,
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
    _loaded = true;
  }

  /// Carrega catálogo e assina o listener de `RewardGranted`. Retorna a
  /// subscription — caller deve cancelar em dispose (provider faz isso
  /// via `ref.onDispose`).
  Future<StreamSubscription<RewardGranted>> attach() async {
    await ensureLoaded();
    return _bus.on<RewardGranted>().listen(_handleRewardGranted);
  }

  /// Acessor pra inspeção em testes / debug. Não mutável.
  Map<String, AchievementDefinition> get catalog =>
      Map.unmodifiable(_catalog);

  // ─── handler + cascata ─────────────────────────────────────────────

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
  Future<void> _tryUnlock(
    int playerId,
    String key, {
    required int depth,
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
    if (!await _validateTrigger(playerId, def)) {
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
      int playerId, AchievementDefinition def) async {
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
      case UnknownAchievementTrigger(rawType: final t):
        // ignore: avoid_print
        print('[achievements] trigger type "$t" não reconhecido em '
            '"${def.key}" — skip (Bloco 14 expande)');
        return false;
    }
  }
}
