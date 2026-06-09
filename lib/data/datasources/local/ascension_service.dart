import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/player_events.dart';
import '../../../core/events/reward_events.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/reward_declared.dart';
import '../../../domain/services/reward_resolve_service.dart';
import '../../database/app_database.dart';
import '../../database/daos/player_dao.dart';
import 'guild_ascension_service.dart';

/// B.2 — view derivada do estado da ascensão (pra UI B.4).
enum AscensionViewState { locked, payable, active, cooldown, done }

/// Gate individual (atual vs alvo) pra exibição.
class AscensionGate {
  final String key;
  final int current;
  final int target;
  final bool met;
  const AscensionGate(this.key, this.current, this.target, this.met);
}

class AscensionView {
  final AscensionViewState state;
  final int currentCost;
  final List<AscensionGate> gates;
  final int? deadlineMs;
  final int? cooldownUntilMs;
  final int failures;
  const AscensionView({
    required this.state,
    required this.currentCost,
    required this.gates,
    this.deadlineMs,
    this.cooldownUntilMs,
    this.failures = 0,
  });
}

class PayResult {
  final bool ok;
  final String? reason; // not_payable | insufficient_gold | no_cycle
  final int cost;
  const PayResult({required this.ok, this.reason, this.cost = 0});
}

class AscendResult {
  final bool ok;
  final String? newRank;
  final String? reason; // not_active | window_expired | trials_incomplete | noop
  const AscendResult({required this.ok, this.newRank, this.reason});
}

/// B.2 — máquina de estados (soulslike) do Teste de Ascensão da Guilda.
///
/// Estados persistidos em `guild_ascension_state.status` ∈
/// {idle (ausente), active, cooldown, done}. A VIEW (locked/payable/active/
/// cooldown/done) é derivada em [evaluateGates] (read-only) a partir do
/// status + gates.
///
/// NÃO faz windowing dos trials (lifetime por ora — B.3). NÃO toca UI (B.4).
class AscensionService {
  final AppDatabase _db;
  final AppEventBus _bus;
  final RewardResolveService _resolver;
  final GuildAscensionService _ascension;
  final Future<PlayerSnapshot> Function(int playerId) _resolvePlayer;

  AscensionService({
    required AppDatabase db,
    required AppEventBus bus,
    required RewardResolveService resolver,
    required GuildAscensionService ascension,
    required Future<PlayerSnapshot> Function(int playerId) resolvePlayer,
  })  : _db = db,
        _bus = bus,
        _resolver = resolver,
        _ascension = ascension,
        _resolvePlayer = resolvePlayer;

  static const int _hourMs = 3600000;

  String _canon(String raw) {
    final r = raw.trim();
    if (r.isEmpty || r.toLowerCase() == 'none') return 'none';
    return GuildRankSystem.fromString(r).name.toUpperCase();
  }

  int _currentCost(int feeBase, int failures) =>
      (feeBase * math.pow(1.10, failures)).round();

  int _now() => DateTime.now().millisecondsSinceEpoch;

  Future<GuildAscensionStateTableData?> _readState(int playerId, String canon) {
    return (_db.select(_db.guildAscensionStateTable)
          ..where((t) =>
              t.playerId.equals(playerId) & t.rankFrom.equals(canon)))
        .getSingleOrNull();
  }

  /// (a) READ-ONLY — deriva a view + gates + custo corrente. Não escreve.
  Future<AscensionView> evaluateGates(int playerId, String rankFrom) async {
    final config = await _ascension.loadCycleConfig(rankFrom);
    final canon = config?.rankFrom ?? _canon(rankFrom);
    final state = await _readState(playerId, canon);
    final failures = state?.failures ?? 0;

    // Rank S / sem ciclo → nada a ascender.
    if (config == null) {
      return AscensionView(
        state: AscensionViewState.locked,
        currentCost: 0,
        gates: const [],
        failures: failures,
      );
    }

    final cost = _currentCost(config.feeBase, failures);

    final row = await (_db.customSelect(
      'SELECT level, total_gold_earned_lifetime AS gl, guild_rank AS gr '
      'FROM players WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(playerId)],
    )).getSingleOrNull();
    final level = (row?.data['level'] as int?) ?? 0;
    // B.3 — gate `missions_completed` usa a UNIÃO (daily + pmp), lifetime.
    final missions = await _ascension.countMissionsCompleted(playerId);
    final goldLife = (row?.data['gl'] as int?) ?? 0;
    final guildRank = (row?.data['gr'] as String?) ?? 'none';

    // Cadeia sequencial: só elegível se o rank atual == rank_from do ciclo.
    final sequentialOk = guildRank.toUpperCase() == canon;

    final gates = <AscensionGate>[
      AscensionGate('level', level, config.minLevel, level >= config.minLevel),
      AscensionGate('missions', missions, config.missionsCompleted,
          missions >= config.missionsCompleted),
      AscensionGate('gold_lifetime', goldLife, config.goldEarnedLifetime,
          goldLife >= config.goldEarnedLifetime),
      // card_wins — sistema de card-game inexistente: gate mock-SATISFEITO.
      AscensionGate('card_wins', config.cardWins, config.cardWins, true),
    ];
    final gatesOk = sequentialOk && gates.every((g) => g.met);

    final status = state?.status ?? 'idle';
    final now = _now();
    AscensionViewState view;
    if (status == 'done') {
      view = AscensionViewState.done;
    } else if (status == 'cooldown' &&
        state?.cooldownUntilMs != null &&
        now < state!.cooldownUntilMs!) {
      view = AscensionViewState.cooldown;
    } else if (status == 'active' &&
        state?.windowDeadlineMs != null &&
        now < state!.windowDeadlineMs!) {
      view = AscensionViewState.active;
    } else if (gatesOk) {
      // idle OU cooldown expirado.
      view = AscensionViewState.payable;
    } else {
      view = AscensionViewState.locked;
    }

    return AscensionView(
      state: view,
      currentCost: cost,
      gates: gates,
      deadlineMs: state?.windowDeadlineMs,
      cooldownUntilMs: state?.cooldownUntilMs,
      failures: failures,
    );
  }

  /// (b) Paga a fee e abre a janela. Precondição: view == payable.
  Future<PayResult> pay(int playerId, String rankFrom) async {
    final view = await evaluateGates(playerId, rankFrom);
    if (view.state != AscensionViewState.payable) {
      return PayResult(ok: false, reason: 'not_payable', cost: view.currentCost);
    }
    final config = await _ascension.loadCycleConfig(rankFrom);
    if (config == null) return const PayResult(ok: false, reason: 'no_cycle');
    final canon = config.rankFrom;
    final cost = view.currentCost;

    var insufficient = false;
    await _db.transaction(() async {
      final pr = await (_db.customSelect(
        'SELECT gold FROM players WHERE id = ? LIMIT 1',
        variables: [Variable.withInt(playerId)],
      )).getSingle();
      final gold = pr.read<int>('gold');
      if (gold < cost) {
        insufficient = true;
        return;
      }
      final now = _now();
      await _db.customUpdate(
        'UPDATE players SET gold = gold - ? WHERE id = ?',
        variables: [Variable.withInt(cost), Variable.withInt(playerId)],
        updates: {_db.playersTable},
      );
      final state = await _readState(playerId, canon);
      await _db
          .into(_db.guildAscensionStateTable)
          .insertOnConflictUpdate(GuildAscensionStateTableCompanion(
        playerId: Value(playerId),
        rankFrom: Value(canon),
        attempts: Value((state?.attempts ?? 0) + 1),
        failures: Value(state?.failures ?? 0),
        paidCost: Value(cost),
        cooldownUntilMs: const Value(null),
        windowStartedMs: Value(now),
        windowDeadlineMs: Value(now + config.windowHours * _hourMs),
        status: const Value('active'),
      ));
      // Materializa os trials (motor A.2 avança o progresso por evento).
      await _ascension.initCycle(playerId, canon);
    });

    if (insufficient) {
      return PayResult(ok: false, reason: 'insufficient_gold', cost: cost);
    }
    // Débito de fee (NÃO toca total_gold_earned_lifetime — é gasto).
    _bus.publish(GoldSpent(
        playerId: playerId, amount: cost, source: GoldSink.ascension));
    return PayResult(ok: true, cost: cost);
  }

  /// (c) Boot + abertura da tab: se a janela venceu sem completar → falha
  /// (cooldown + failures++ + reset dos trials).
  Future<void> checkDeadline(int playerId, String rankFrom) async {
    final canon = _canon(rankFrom);
    final state = await _readState(playerId, canon);
    if (state == null || state.status != 'active') return;
    final deadline = state.windowDeadlineMs;
    if (deadline == null) return;
    if (_now() < deadline) return;
    // Vencido — se já completou os trials, deixa pro ascend (não falha).
    if (await _ascension.canAscend(playerId, canon)) return;

    final config = await _ascension.loadCycleConfig(canon);
    final cooldownH = config?.cooldownHours ?? 4;
    final now = _now();
    await _db.transaction(() async {
      await _db
          .into(_db.guildAscensionStateTable)
          .insertOnConflictUpdate(GuildAscensionStateTableCompanion(
        playerId: Value(playerId),
        rankFrom: Value(canon),
        attempts: Value(state.attempts),
        failures: Value(state.failures + 1),
        paidCost: Value(state.paidCost),
        cooldownUntilMs: Value(now + cooldownH * _hourMs),
        windowStartedMs: const Value(null),
        windowDeadlineMs: const Value(null),
        status: const Value('cooldown'),
      ));
      // Reset dos trials — próxima tentativa recomeça do zero.
      await _db.customStatement(
        'DELETE FROM guild_ascension_progress '
        'WHERE player_id = ? AND rank_from = ?',
        [playerId, canon],
      );
    });
  }

  /// B.3 — marca um trial MANUAL (`manual_proof`) como concluído (auto-
  /// report físico). Guard: status active + janela não vencida. Retorna
  /// true se marcou. UI = B.4.
  Future<bool> confirmManualTrial(
      int playerId, String rankFrom, String trialKey) async {
    final canon = _canon(rankFrom);
    final state = await _readState(playerId, canon);
    if (state == null || state.status != 'active') return false;
    if (state.windowDeadlineMs == null || _now() >= state.windowDeadlineMs!) {
      return false;
    }
    var updated = false;
    await _db.transaction(() async {
      final rows = await (_db.select(_db.guildAscensionTable)
            ..where((t) =>
                t.playerId.equals(playerId) &
                t.rankFrom.equals(canon) &
                t.questKey.equals(trialKey)))
          .get();
      if (rows.isEmpty) return;
      final row = rows.first;
      if (row.checkType != 'manual_proof' || row.completed) return;
      await (_db.update(_db.guildAscensionTable)
            ..where((t) => t.id.equals(row.id)))
          .write(GuildAscensionTableCompanion(
        completed: const Value(true),
        progress: Value(row.progressTarget),
      ));
      updated = true;
    });
    return updated;
  }

  /// (d) Sobe de rank. Precondição: status active, janela não vencida,
  /// canAscend. Idempotente (2ª chamada após done = no-op).
  Future<AscendResult> ascend(int playerId, String rankFrom) async {
    final canon = _canon(rankFrom);
    final state = await _readState(playerId, canon);
    if (state == null || state.status != 'active') {
      return const AscendResult(ok: false, reason: 'not_active');
    }
    if (state.windowDeadlineMs == null || _now() >= state.windowDeadlineMs!) {
      return const AscendResult(ok: false, reason: 'window_expired');
    }
    if (!await _ascension.canAscend(playerId, canon)) {
      return const AscendResult(ok: false, reason: 'trials_incomplete');
    }
    final config = await _ascension.loadCycleConfig(canon);
    if (config == null) return const AscendResult(ok: false, reason: 'no_cycle');

    final snapshot = await _resolvePlayer(playerId);
    final declared = RewardDeclared.fromJson({
      'xp': config.rewardXp,
      'gold': config.rewardGold,
      'insignias': config.rewardInsignias,
    });
    final resolved = await _resolver.resolve(declared, snapshot, progressPct: 100);

    LevelUp? levelUp;
    String? newRank;
    await _db.transaction(() async {
      // Idempotência: relê status DENTRO da tx.
      final fresh = await _readState(playerId, canon);
      if (fresh == null || fresh.status == 'done') return; // no-op

      // Crédito DIRETO (sem total_quests_completed — não é quest).
      if (resolved.xp != 0) {
        levelUp = await PlayerDao(_db).addXp(playerId, resolved.xp);
      }
      if (resolved.gold != 0 || resolved.gems != 0) {
        final lifeGold = resolved.gold > 0 ? resolved.gold : 0;
        await _db.customUpdate(
          'UPDATE players SET gold = gold + ?, '
          'total_gold_earned_lifetime = total_gold_earned_lifetime + ?, '
          'gems = gems + ? WHERE id = ?',
          variables: [
            Variable.withInt(resolved.gold),
            Variable.withInt(lifeGold),
            Variable.withInt(resolved.gems),
            Variable.withInt(playerId),
          ],
          updates: {_db.playersTable},
        );
      }
      if (resolved.insignias != 0) {
        await _db.customUpdate(
          'UPDATE players SET insignias = insignias + ? WHERE id = ?',
          variables: [
            Variable.withInt(resolved.insignias),
            Variable.withInt(playerId),
          ],
          updates: {_db.playersTable},
        );
      }

      // Rank↑ + colar (mesma tx) via GuildAscensionService → setRank.
      newRank = await _ascension.ascend(playerId, canon);

      await _db
          .into(_db.guildAscensionStateTable)
          .insertOnConflictUpdate(GuildAscensionStateTableCompanion(
        playerId: Value(playerId),
        rankFrom: Value(canon),
        attempts: Value(fresh.attempts),
        failures: Value(fresh.failures),
        paidCost: Value(fresh.paidCost),
        cooldownUntilMs: const Value(null),
        windowStartedMs: const Value(null),
        windowDeadlineMs: const Value(null),
        status: const Value('done'),
      ));
    });

    if (newRank == null) {
      return const AscendResult(ok: false, reason: 'noop');
    }
    _bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: resolved.toJsonString(),
        fromAscension: true));
    if (levelUp != null) _bus.publish(levelUp!);
    return AscendResult(ok: true, newRank: newRank);
  }
}
