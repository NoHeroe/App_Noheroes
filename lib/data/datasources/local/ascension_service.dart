import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/player_events.dart';
import '../../../core/events/reward_events.dart';
import '../../../core/utils/guild_rank.dart';
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

/// B.2 — máquina de estados (soulslike) do Teste de Ascensão da Guilda
/// (Época 2, full-online — ADR-0024).
///
/// As transições ATÔMICAS (pay/ascend/checkDeadline/confirmManualTrial) são
/// portadas pras RPCs Postgres `ascension_pay`/`ascension_ascend`/
/// `ascension_check_deadline`/`ascension_confirm_manual_trial` — read-modify-
/// write + multi-write rodam no servidor numa única transação. Este service
/// só monta os params, despacha a RPC e propaga os eventos client-side a
/// partir dos deltas retornados.
///
/// [evaluateGates] continua client-side (read-only): deriva a VIEW
/// (locked/payable/active/cooldown/done) + gates + custo a partir de
/// leituras PostgREST (state + players + contadores).
class AscensionService {
  final SupabaseClient _client;
  final AppEventBus _bus;
  final GuildAscensionService _ascension;

  AscensionService({
    required SupabaseClient client,
    required AppEventBus bus,
    required GuildAscensionService ascension,
  })  : _client = client,
        _bus = bus,
        _ascension = ascension;

  String _canon(String raw) {
    final r = raw.trim();
    if (r.isEmpty || r.toLowerCase() == 'none') return 'none';
    return GuildRankSystem.fromString(r).name.toUpperCase();
  }

  int _currentCost(int feeBase, int failures) =>
      (feeBase * math.pow(1.10, failures)).round();

  int _now() => DateTime.now().millisecondsSinceEpoch;

  // Bridge uuid String -> int pra eventos legacy (GoldSpent/RewardGranted/
  // LevelUp ainda usam `int playerId`). Mesmo padrão da ShopsService/
  // EnchantService já migradas. Ver 'unresolved' do resumo de migração.

  Future<Map<String, dynamic>?> _readState(String playerId, String canon) {
    return _client
        .from('guild_ascension_state')
        .select()
        .eq('player_id', playerId)
        .eq('rank_from', canon)
        .maybeSingle();
  }

  /// (a) READ-ONLY — deriva a view + gates + custo corrente. Não escreve.
  Future<AscensionView> evaluateGates(String playerId, String rankFrom) async {
    final config = await _ascension.loadCycleConfig(rankFrom);
    final canon = config?.rankFrom ?? _canon(rankFrom);
    final state = await _readState(playerId, canon);
    final failures = (state?['failures'] as num?)?.toInt() ?? 0;

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

    final row = await _client
        .from('players')
        .select('level, total_gold_earned_lifetime, guild_rank')
        .eq('id', playerId)
        .maybeSingle();
    final level = (row?['level'] as num?)?.toInt() ?? 0;
    // B.3 — gate `missions_completed` usa a UNIÃO (daily + pmp), lifetime.
    final missions = await _ascension.countMissionsCompleted(playerId);
    final goldLife =
        (row?['total_gold_earned_lifetime'] as num?)?.toInt() ?? 0;
    final guildRank = (row?['guild_rank'] as String?) ?? 'none';

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

    final status = (state?['status'] as String?) ?? 'idle';
    final deadlineMs = (state?['window_deadline_ms'] as num?)?.toInt();
    final cooldownMs = (state?['cooldown_until_ms'] as num?)?.toInt();
    final now = _now();
    AscensionViewState view;
    if (status == 'done') {
      view = AscensionViewState.done;
    } else if (status == 'cooldown' &&
        cooldownMs != null &&
        now < cooldownMs) {
      view = AscensionViewState.cooldown;
    } else if (status == 'active' &&
        deadlineMs != null &&
        now < deadlineMs) {
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
      deadlineMs: deadlineMs,
      cooldownUntilMs: cooldownMs,
      failures: failures,
    );
  }

  /// (b) Paga a fee e abre a janela. RPC `ascension_pay` (revalida payable +
  /// gates + ouro, debita, abre janela e materializa os trials atomicamente).
  Future<PayResult> pay(String playerId, String rankFrom) async {
    final res = await _client.rpc('ascension_pay', params: {
      'p_player': playerId,
      'p_rank_from': rankFrom,
    }) as Map<String, dynamic>;

    final ok = res['ok'] == true;
    final cost = (res['cost'] as num?)?.toInt() ?? 0;
    if (!ok) {
      return PayResult(
          ok: false, reason: res['reason'] as String?, cost: cost);
    }
    // Débito de fee (NÃO toca total_gold_earned_lifetime — é gasto).
    _bus.publish(GoldSpent(
        playerId: playerId,
        amount: cost,
        source: GoldSink.ascension));
    return PayResult(ok: true, cost: cost);
  }

  /// (c) Boot + abertura da tab: RPC `ascension_check_deadline` (se a janela
  /// venceu sem completar → cooldown + failures++ + reset dos trials).
  Future<void> checkDeadline(String playerId, String rankFrom) async {
    await _client.rpc('ascension_check_deadline', params: {
      'p_player': playerId,
      'p_rank_from': rankFrom,
    });
  }

  /// B.3 — marca um trial MANUAL (`manual_proof`) como concluído. RPC
  /// `ascension_confirm_manual_trial` (guards: active + janela vigente +
  /// trial manual_proof não completo). Retorna true se marcou.
  Future<bool> confirmManualTrial(
      String playerId, String rankFrom, String trialKey) async {
    final res = await _client.rpc('ascension_confirm_manual_trial', params: {
      'p_player': playerId,
      'p_rank_from': rankFrom,
      'p_trial_key': trialKey,
    });
    return res == true;
  }

  /// (d) Sobe de rank. RPC `ascension_ascend` (guards active/janela/canAscend,
  /// resolve reward, credita xp/gold/gems/insígnias, sobe rank + Colar, marca
  /// done — tudo atômico e idempotente). Propaga RewardGranted + LevelUp a
  /// partir dos deltas retornados.
  Future<AscendResult> ascend(String playerId, String rankFrom) async {
    final res = await _client.rpc('ascension_ascend', params: {
      'p_player': playerId,
      'p_rank_from': rankFrom,
    }) as Map<String, dynamic>;

    final ok = res['ok'] == true;
    if (!ok) {
      return AscendResult(
          ok: false, newRank: null, reason: res['reason'] as String?);
    }
    final newRank = res['new_rank'] as String?;

    // O servidor já creditou xp/gold/gems/insígnias e subiu o rank. Propaga
    // os eventos client-side (analytics/quests/UI) a partir dos deltas.
    // NOTA: RewardGranted carrega o JSON resolvido — aqui reconstruímos um
    // payload mínimo com os deltas (xp/gold/insignias) devolvidos pela RPC.
    final rewardXp = (res['reward_xp'] as num?)?.toInt() ?? 0;
    final rewardGold = (res['reward_gold'] as num?)?.toInt() ?? 0;
    final rewardIns = (res['reward_insignias'] as num?)?.toInt() ?? 0;
    final resolvedJson =
        '{"xp":$rewardXp,"gold":$rewardGold,"insignias":$rewardIns}';
    _bus.publish(RewardGranted(
        playerId: playerId,
        rewardResolvedJson: resolvedJson,
        fromAscension: true));

    final prevLevel = (res['previous_level'] as num?)?.toInt();
    final newLevel = (res['new_level'] as num?)?.toInt();
    if (prevLevel != null && newLevel != null && newLevel > prevLevel) {
      _bus.publish(LevelUp(
        playerId: playerId,
        previousLevel: prevLevel,
        newLevel: newLevel,
      ));
    }
    return AscendResult(ok: true, newRank: newRank, reason: null);
  }
}
