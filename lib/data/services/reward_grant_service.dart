import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/player_events.dart';
import '../../core/events/reward_events.dart';
import '../../domain/exceptions/reward_exceptions.dart';
import '../../domain/models/faction_buff_multipliers.dart';
import '../../domain/models/reward_grant_result.dart';
import '../../domain/models/reward_resolved.dart';
import '../../domain/services/faction_buff_service.dart';

/// Época 2 full-online (ADR-0024) — credita uma reward já resolvida (pelo
/// [RewardResolveService]) delegando a ATOMICIDADE às RPCs Postgres
/// `grant_mission_reward` / `grant_achievement_reward` (porta fiel da
/// transação Drift original — ver
/// supabase/migrations/20260609140010_rpc_rewards.sql).
///
/// O corpo de cada RPC é uma transação implícita (rollback total em erro),
/// equivalente ao antigo `db.transaction(...)`. Guards de idempotência
/// (`player_mission_progress.reward_claimed` /
/// `player_achievements_completed.reward_claimed`), crédito de xp/gold/gems/
/// insígnias, items, recipes e reputação de facção vivem todos DENTRO da RPC.
/// O cliente NÃO reimplementa atomicidade.
///
/// O evento `RewardGranted` (e `LevelUp`, quando houve) só é publicado
/// **depois** do RPC retornar OK — RPC que lança nunca chega ao publish.
///
/// Buffs de facção (xpMult/goldMult/gemsMult, ADR — Sprint 3.4 Etapa C)
/// continuam aplicados CLIENT-SIDE antes do RPC (via [FactionBuffService]),
/// porque a RPC credita os valores como vêm em `p_resolved`. O payload do
/// `RewardGranted` carrega os valores PÓS-buff.
class RewardGrantService {
  final SupabaseClient _client;
  final AppEventBus _eventBus;

  /// Sprint 3.4 Etapa C — buffs de facção em runtime.
  ///
  /// Opcional: testes legacy podem omitir (vira no-op via `neutral`).
  /// Em produção, sempre injetado pelo provider. Aplicado ANTES do RPC em
  /// xp/gold/gems.
  final FactionBuffService? _factionBuff;

  RewardGrantService({
    required SupabaseClient client,
    required AppEventBus eventBus,
    FactionBuffService? factionBuff,
  })  : _client = client,
        _eventBus = eventBus,
        _factionBuff = factionBuff;

  /// Aplica multipliers em (xp, gold, gems) e retorna trio escalado +
  /// mults usados. Round em xp/gold/gems (CEO confirmou). Se `_factionBuff`
  /// nulo (legacy/test path), retorna valores crus + neutral.
  Future<({int xp, int gold, int gems, FactionBuffMultipliers mults})>
      _applyBuffs(String playerId, RewardResolved resolved) async {
    if (_factionBuff == null) {
      return (
        xp: resolved.xp,
        gold: resolved.gold,
        gems: resolved.gems,
        mults: FactionBuffMultipliers.neutral
      );
    }
    final mults = await _factionBuff.getActiveMultipliers(playerId);
    return (
      xp: (resolved.xp * mults.xpMult).round(),
      gold: (resolved.gold * mults.goldMult).round(),
      gems: (resolved.gems * mults.gemsMult).round(),
      mults: mults,
    );
  }

  /// Grant atômico de reward de MISSÃO via RPC `grant_mission_reward`.
  ///
  /// [missionProgressId] é PK de linha (bigserial) — permanece `int`.
  /// [playerId] é o uuid do jogador (auth.users.id) — `String`.
  ///
  /// Lança:
  ///   - [MissionNotFoundException] se missão não existe (errcode P0002)
  ///   - [RewardAlreadyGrantedException] se já foi grantada (errcode P0001)
  ///   - propaga PostgrestException de persistência (rollback total na RPC)
  Future<RewardGrantResult> grant({
    required int missionProgressId,
    required String playerId,
    required RewardResolved resolved,
  }) async {
    // TODO comunicar pra Sprint 2.4 — `seivas` stock não tem coluna no
    // schema; só xp/gold/gems em `players`. Credito fica só nos 3 até
    // Rituais introduzirem persistência. (Mesma nota da RPC.)
    if (resolved.seivas != 0) {
      // ignore: avoid_print
      print('[reward-grant] TODO(sprint-2.4): persistência de '
          '${resolved.seivas} seivas pra player $playerId — schema '
          'pendente. Por ora apenas o evento registra o valor.');
    }

    // Buffs calculados ANTES do RPC (leitura segura; a RPC credita cru).
    final buffed = await _applyBuffs(playerId, resolved);
    final buffedResolved = await _buffedResolved(playerId, resolved, buffed);

    final Map<String, dynamic> res;
    try {
      res = (await _client.rpc('grant_mission_reward', params: {
        'p_player': playerId,
        'p_mission_progress_id': missionProgressId,
        'p_resolved': buffedResolved.toJson(),
      })) as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      // Mapeia errcodes da RPC pras exceptions de domínio (ver dartdoc).
      if (e.code == 'P0002') {
        throw MissionNotFoundException(missionProgressId);
      }
      if (e.code == 'P0001') {
        throw RewardAlreadyGrantedException(
          missionProgressId: missionProgressId,
          playerId: playerId,
        );
      }
      rethrow;
    }

    // Eventos FORA da transação — só chega aqui se a RPC retornou OK.
    // LevelUp (quando houve) emitido ANTES do RewardGranted pra listeners
    // que reagem a level processarem primeiro.
    final levelUp = _levelUpFromRpc(playerId, res['xp_result']);
    if (levelUp != null) {
      _eventBus.publish(levelUp);
    }
    _eventBus.publish(RewardGranted(
      playerId: playerId,
      rewardResolvedJson: buffedResolved.toJsonString(),
    ));

    return RewardGrantResult(resolved: buffedResolved);
  }

  /// Grant atômico de reward de CONQUISTA via RPC `grant_achievement_reward`.
  ///
  /// Diferenças vs [grant]:
  ///   - Idempotência via `player_achievements_completed.reward_claimed`.
  ///     Caller (`AchievementsService`) deve ter chamado `markCompleted`
  ///     ANTES — a RPC não cria a row.
  ///   - **Não incrementa** `total_quests_completed`.
  ///   - Emite `RewardGranted` com `fromAchievementCascade=true`.
  ///
  /// Lança:
  ///   - [AchievementNotUnlockedException] se row não existe (errcode P0002)
  ///   - [AchievementRewardAlreadyGrantedException] se já foi grantada
  ///     (errcode P0001)
  ///   - propaga PostgrestException de persistência (rollback total na RPC)
  Future<RewardGrantResult> grantAchievement({
    required String playerId,
    required String achievementKey,
    required RewardResolved resolved,
  }) async {
    if (resolved.seivas != 0) {
      // ignore: avoid_print
      print('[reward-grant] TODO(sprint-2.4): persistência de '
          '${resolved.seivas} seivas pra player $playerId (achievement '
          '$achievementKey) — schema pendente.');
    }

    final buffed = await _applyBuffs(playerId, resolved);
    final buffedResolved = await _buffedResolved(playerId, resolved, buffed);

    final Map<String, dynamic> res;
    try {
      res = (await _client.rpc('grant_achievement_reward', params: {
        'p_player': playerId,
        'p_achievement_key': achievementKey,
        'p_resolved': buffedResolved.toJson(),
      })) as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      if (e.code == 'P0002') {
        throw AchievementNotUnlockedException(
          playerId: playerId,
          achievementKey: achievementKey,
        );
      }
      if (e.code == 'P0001') {
        throw AchievementRewardAlreadyGrantedException(
          playerId: playerId,
          achievementKey: achievementKey,
        );
      }
      rethrow;
    }

    // Eventos pós-RPC. Flag `fromAchievementCascade=true` faz o
    // AchievementsService ignorar este RewardGranted no listener (a cascata
    // de meta unlocks é dirigida por AchievementUnlocked, não por este
    // evento). Outros listeners (UI, analytics) consomem normalmente.
    final levelUp = _levelUpFromRpc(playerId, res['xp_result']);
    if (levelUp != null) {
      _eventBus.publish(levelUp);
    }
    _eventBus.publish(RewardGranted(
      playerId: playerId,
      rewardResolvedJson: buffedResolved.toJsonString(),
      fromAchievementCascade: true,
    ));

    return RewardGrantResult(resolved: buffedResolved);
  }

  /// Reconstrói `LevelUp?` a partir do `xp_result` (`{previous_level,
  /// new_level}`) que a RPC `add_xp` devolve aninhado no retorno. `null`
  /// quando não houve XP ou não houve subida de nível. Mesmo pattern do
  /// `PlayerDao.addXp`.
  LevelUp? _levelUpFromRpc(String playerId, Object? xpResult) {
    if (xpResult is! Map) return null;
    final prev = (xpResult['previous_level'] as num?)?.toInt();
    final next = (xpResult['new_level'] as num?)?.toInt();
    if (prev == null || next == null) return null;
    if (next > prev) {
      return LevelUp(playerId: playerId, newLevel: next, previousLevel: prev);
    }
    return null;
  }

  /// Cria RewardResolved espelho do declarado, mas com xp/gold/gems
  /// pós-buff E com `factionReputationDelta` já bufado (xpMult universal —
  /// a RPC `faction_reputation_delta` aplica o valor cru, então o buff tem
  /// de vir do cliente, como na transação Drift original). Preserva items,
  /// achievementsToCheck, recipesToUnlock, factionId.
  Future<RewardResolved> _buffedResolved(
    String playerId,
    RewardResolved declared,
    ({int xp, int gold, int gems, FactionBuffMultipliers mults}) buffed,
  ) async {
    int? repDelta = declared.factionReputationDelta;
    if (declared.factionId != null && repDelta != null) {
      repDelta = await _applyBuffToRepDelta(
        playerId,
        declared.factionId!,
        repDelta,
        buffed.mults,
      );
    }
    return RewardResolved(
      xp: buffed.xp,
      gold: buffed.gold,
      gems: buffed.gems,
      seivas: declared.seivas,
      insignias: declared.insignias,
      items: declared.items,
      achievementsToCheck: declared.achievementsToCheck,
      recipesToUnlock: declared.recipesToUnlock,
      factionId: declared.factionId,
      factionReputationDelta: repDelta,
    );
  }

  /// Aplica xpMult em rep delta positivo. Regra OPÇÃO A: se player é member
  /// da Guilda E rep alvo também é Guilda → buff NÃO aplica (Guilda buffa
  /// relações com terceiros, não consigo mesma). Delta negativo passa cru
  /// (debuff/penalidades não amplificam perdas).
  Future<int> _applyBuffToRepDelta(
    String playerId,
    String targetFactionId,
    int delta,
    FactionBuffMultipliers mults,
  ) async {
    if (delta <= 0) return delta;
    if (mults.xpMult == 1.0) return delta;
    if (targetFactionId == 'guild') {
      // OPÇÃO A — leitura de faction_type pra detectar self-buff.
      final row = await _client
          .from('players')
          .select('faction_type')
          .eq('id', playerId)
          .maybeSingle();
      if (row != null && row['faction_type'] == 'guild') {
        return delta; // Guilda member ganhando rep da Guilda — sem buff
      }
    }
    return (delta * mults.xpMult).round();
  }
}
