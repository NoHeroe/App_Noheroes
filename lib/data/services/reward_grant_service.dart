import 'package:drift/drift.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/player_events.dart';
import '../../core/events/reward_events.dart';
import '../../domain/enums/source_type.dart';
import '../../domain/exceptions/reward_exceptions.dart';
import '../../domain/models/faction_buff_multipliers.dart';
import '../../domain/models/reward_grant_result.dart';
import '../../domain/models/reward_resolved.dart';
import '../../domain/repositories/mission_repository.dart';
import '../../domain/repositories/player_achievements_repository.dart';
import '../../domain/repositories/player_faction_reputation_repository.dart';
import '../../domain/services/faction_buff_service.dart';
import '../database/app_database.dart';
import '../database/daos/player_dao.dart';
import '../datasources/local/player_inventory_service.dart';
import '../datasources/local/player_recipes_service.dart';

/// Sprint 3.1 Bloco 5 — credita uma reward já resolvida (pelo
/// [RewardResolveService]) na forma de UMA transação Drift atômica
/// (ADR 0011).
///
/// Se qualquer passo da transação lança, rollback total. O evento
/// `RewardGranted` só é emitido **depois** do commit bem-sucedido —
/// transação falhada nunca emite evento.
///
/// Idempotência: se `player_mission_progress.reward_claimed == true`
/// pra `missionProgressId`, lança [RewardAlreadyGrantedException] (UI
/// diferencia esse caso de erro real). O check vive **dentro** da
/// transação pra evitar race.
class RewardGrantService {
  final AppDatabase _db;
  final MissionRepository _missionRepo;
  final PlayerAchievementsRepository _achievementsRepo;
  final PlayerInventoryService _inventory;
  final PlayerRecipesService _recipes;
  final PlayerFactionReputationRepository _factionRep;
  final AppEventBus _eventBus;

  /// Sprint 3.4 Etapa C — buffs de facção em runtime.
  ///
  /// Opcional: testes legacy podem omitir (vira no-op via `neutral`).
  /// Em produção, sempre injetado pelo provider.
  ///
  /// Aplicado ANTES do persist em xp/gold/gems. xpMult universal —
  /// reputação ganha em `_factionRep.delta` permanece com delta cru
  /// porque a propagação é via `FactionReputationService` (que sim
  /// aplica xpMult) — no caller chamado abaixo (passo 6) usamos delta
  /// direto do `resolved` porque o repo de reputação é direto, sem
  /// service. Decisão: aplicar xpMult ANTES de chamar `_factionRep.delta`.
  final FactionBuffService? _factionBuff;

  RewardGrantService({
    required AppDatabase db,
    required MissionRepository missionRepo,
    required PlayerAchievementsRepository achievementsRepo,
    required PlayerInventoryService inventory,
    required PlayerRecipesService recipes,
    required PlayerFactionReputationRepository factionRep,
    required AppEventBus eventBus,
    FactionBuffService? factionBuff,
  })  : _db = db,
        _missionRepo = missionRepo,
        _achievementsRepo = achievementsRepo,
        _inventory = inventory,
        _recipes = recipes,
        _factionRep = factionRep,
        _eventBus = eventBus,
        _factionBuff = factionBuff;

  /// Aplica multipliers em (xp, gold, gems) e retorna trio escalado +
  /// mults usados (pra propagar em reputação no caller). Round em
  /// xp/gold/gems (CEO confirmou). Se `_factionBuff` nulo (legacy/test
  /// path), retorna valores crus + neutral.
  Future<({int xp, int gold, int gems, FactionBuffMultipliers mults})>
      _applyBuffs(int playerId, RewardResolved resolved) async {
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

  /// Grant atômico. Joga:
  ///   - [MissionNotFoundException] se missão não existe
  ///   - [RewardAlreadyGrantedException] se já foi grantada
  ///   - propaga exceptions de persistência (rollback total)
  Future<RewardGrantResult> grant({
    required int missionProgressId,
    required int playerId,
    required RewardResolved resolved,
  }) async {
    // TODO comunicar pra Sprint 2.4 — `seivas` stock não tem coluna no
    // schema 24; só xp/gold/gems em `players`. Credito fica só nos 3
    // até Rituais introduzirem persistência.
    if (resolved.seivas != 0) {
      // ignore: avoid_print
      print('[reward-grant] TODO(sprint-2.4): persistência de '
          '${resolved.seivas} seivas pra player $playerId — schema '
          'pendente. Por ora apenas o evento registra o valor.');
    }

    LevelUp? levelUpEvent;
    // Sprint 3.4 Etapa C — calcula buffs ANTES da transação (lê DB,
    // mas leitura segura fora da tx — buffs estáveis durante a tx).
    final buffed = await _applyBuffs(playerId, resolved);

    final result = await _db.transaction(() async {
      // 1. Check idempotência + existência — DENTRO da transação pra
      //    bloquear race com outro caller tentando grantar a mesma
      //    missão.
      final current = await _missionRepo.findById(missionProgressId);
      if (current == null) {
        throw MissionNotFoundException(missionProgressId);
      }
      if (current.rewardClaimed) {
        throw RewardAlreadyGrantedException(
          missionProgressId: missionProgressId,
          playerId: playerId,
        );
      }

      // 2. Marca missão como completa + rewardClaimed=true.
      //    Segue contrato do MissionRepository Bloco 4: markCompleted
      //    DENTRO de db.transaction (ver dartdoc da interface).
      await _missionRepo.markCompleted(
        missionProgressId,
        at: DateTime.now(),
        rewardClaimed: true,
      );

      // 3. Sprint 3.1 Bloco 14.5 — fix do débito #1: XP passa pelo
      //    `PlayerDao.addXp` (recalcula level, xpToNext, maxHp, maxMp,
      //    attributePoints via `XpCalculator`). Gold/gems continuam via
      //    `customUpdate` — só XP precisa de scaling.
      //
      //    `PlayerDao(_db)` dentro da transação usa o mesmo executor;
      //    Drift enfileira todos os writes na tx corrente. Se level
      //    mudou, `addXp` retorna `LevelUp` que emitimos pós-commit
      //    junto com o `RewardGranted`.
      //
      //    Sprint 3.4 Etapa C — XP/gold/gems passam pelos multipliers
      //    de facção (ou debuff de saída -30%) via `_applyBuffs`.
      if (buffed.xp != 0) {
        levelUpEvent =
            await PlayerDao(_db).addXp(playerId, buffed.xp);
      }
      if (buffed.gold != 0 || buffed.gems != 0) {
        await _db.customUpdate(
          'UPDATE players SET gold = gold + ?, gems = gems + ? '
          'WHERE id = ?',
          variables: [
            Variable.withInt(buffed.gold),
            Variable.withInt(buffed.gems),
            Variable.withInt(playerId),
          ],
          updates: {_db.playersTable},
        );
      }

      // 3b. Sprint 3.1 Bloco 7b — fix bug 4 (totalQuestsCompleted
      //     parcial). No legacy só class/faction/guild incrementavam
      //     esse contador. Agora CADA missão que grantou reward
      //     incrementa 1x — diárias, individuais, classe, facção,
      //     admissão todas contam. Idempotência garantida pelo check
      //     de rewardClaimed no passo 1.
      await _db.customUpdate(
        'UPDATE players SET total_quests_completed = '
        'total_quests_completed + 1 WHERE id = ?',
        variables: [Variable.withInt(playerId)],
        updates: {_db.playersTable},
      );

      // 4. Items — delega pro PlayerInventoryService que já existe.
      //    Cada addItem respeita stacking/durabilidade do schema
      //    (Sprint 2.1). SourceType.questReward alinha ADR 0010.
      for (final item in resolved.items) {
        await _inventory.addItem(
          playerId: playerId,
          itemKey: item.key,
          quantity: item.quantity,
          acquiredVia: SourceType.questReward,
        );
      }

      // 5. Recipes unlock — também reuso.
      for (final recipeKey in resolved.recipesToUnlock) {
        await _recipes.unlock(
          playerId: playerId,
          recipeKey: recipeKey,
          via: SourceType.questReward,
        );
      }

      // 6. Reputação de facção (se aplicável). Clamp 0..100 já vive
      //    no repo (Bloco 4).
      //
      //    Sprint 3.4 Etapa C — xpMult universal: buff aplica em
      //    reputação ganha (delta > 0). Regra OPÇÃO A: Guilda member
      //    ganhando rep da Guilda própria NÃO buffa (buff só vale pra
      //    relações com facções terceiras).
      if (resolved.factionId != null &&
          resolved.factionReputationDelta != null) {
        final repDelta = await _applyBuffToRepDelta(
          playerId,
          resolved.factionId!,
          resolved.factionReputationDelta!,
          buffed.mults,
        );
        await _factionRep.delta(
          playerId,
          resolved.factionId!,
          repDelta,
        );
      }

      return RewardGrantResult(resolved: _buffedResolved(resolved, buffed));
    });

    // 7. Emite eventos FORA da transação — chega aqui só se commit OK.
    //    Qualquer exception acima propaga e este ponto não é alcançado.
    //    14.5 — LevelUp (quando houve) emitido ANTES do RewardGranted
    //    pra listeners que reagem a level (ex: `phaseUnlock` popups)
    //    processarem primeiro.
    //
    //    Sprint 3.4 Etapa C — RewardGranted carrega valores PÓS-buff
    //    (xp/gold/gems). UI ouve este evento e mostra "+110 XP" em vez
    //    de "+100 XP". Listeners que contabilizam (QuestRewardStats)
    //    contam o ganho REAL.
    if (levelUpEvent != null) {
      _eventBus.publish(levelUpEvent!);
    }
    _eventBus.publish(RewardGranted(
      playerId: playerId,
      rewardResolvedJson: _buffedResolved(resolved, buffed).toJsonString(),
    ));

    return result;
  }

  /// Sprint 3.1 Bloco 8 — variante do [grant] pra rewards de conquista.
  ///
  /// Diferenças em relação ao [grant]:
  ///
  ///   - Idempotência via `player_achievements_completed.reward_claimed`
  ///     (não `player_mission_progress`). Caller (`AchievementsService`)
  ///     deve ter chamado `markCompleted` ANTES — grant não cria a row.
  ///   - **Não incrementa** `total_quests_completed` — é contador de
  ///     missões, não de conquistas.
  ///   - Propaga todas as mesmas operações atômicas (xp/gold/gems, items,
  ///     recipes, reputação) e emite o mesmo `RewardGranted` pós-commit.
  ///
  /// Débito técnico herdado (Bloco 15.5): xp via `customUpdate` sem
  /// recalc de level/HP max. Mesmo comportamento do [grant] — fix
  /// consolidado em Bloco 15.5.
  ///
  /// Lança:
  ///   - [AchievementNotUnlockedException] se row não existe
  ///   - [AchievementRewardAlreadyGrantedException] se já foi grantada
  ///   - propaga exceptions de persistência (rollback total)
  Future<RewardGrantResult> grantAchievement({
    required int playerId,
    required String achievementKey,
    required RewardResolved resolved,
  }) async {
    // Mesma observação do grant: seivas ainda não persistem no schema 24.
    if (resolved.seivas != 0) {
      // ignore: avoid_print
      print('[reward-grant] TODO(sprint-2.4): persistência de '
          '${resolved.seivas} seivas pra player $playerId (achievement '
          '$achievementKey) — schema pendente.');
    }

    LevelUp? levelUpEvent;
    // Sprint 3.4 Etapa C — calcula buffs ANTES da transação.
    final buffed = await _applyBuffs(playerId, resolved);

    final result = await _db.transaction(() async {
      // 1. Check precondition + idempotência DENTRO da transação.
      final completed =
          await _achievementsRepo.isCompleted(playerId, achievementKey);
      if (!completed) {
        throw AchievementNotUnlockedException(
          playerId: playerId,
          achievementKey: achievementKey,
        );
      }
      final alreadyClaimed =
          await _achievementsRepo.isRewardClaimed(playerId, achievementKey);
      if (alreadyClaimed) {
        throw AchievementRewardAlreadyGrantedException(
          playerId: playerId,
          achievementKey: achievementKey,
        );
      }

      // 2. Sprint 3.1 Bloco 14.5 — mesmo fix do `grant`: XP passa pelo
      //    `PlayerDao.addXp` (scaling correto). Gold/gems via customUpdate.
      //    Sprint 3.4 Etapa C — buffs aplicados via `_applyBuffs`.
      if (buffed.xp != 0) {
        levelUpEvent =
            await PlayerDao(_db).addXp(playerId, buffed.xp);
      }
      if (buffed.gold != 0 || buffed.gems != 0) {
        await _db.customUpdate(
          'UPDATE players SET gold = gold + ?, gems = gems + ? '
          'WHERE id = ?',
          variables: [
            Variable.withInt(buffed.gold),
            Variable.withInt(buffed.gems),
            Variable.withInt(playerId),
          ],
          updates: {_db.playersTable},
        );
      }

      // 3. Items — delega pro PlayerInventoryService. SourceType.achievement
      //    alinha ADR 0010 (fonte canônica distinta de questReward).
      for (final item in resolved.items) {
        await _inventory.addItem(
          playerId: playerId,
          itemKey: item.key,
          quantity: item.quantity,
          acquiredVia: SourceType.achievement,
        );
      }

      // 4. Recipes unlock.
      for (final recipeKey in resolved.recipesToUnlock) {
        await _recipes.unlock(
          playerId: playerId,
          recipeKey: recipeKey,
          via: SourceType.achievement,
        );
      }

      // 5. Reputação de facção (raro em achievement mas contratualmente
      //    suportado pelo schema declarativo).
      //    Sprint 3.4 Etapa C — xpMult aplica em rep ganha (mesma regra
      //    OPÇÃO A do `grant`).
      if (resolved.factionId != null &&
          resolved.factionReputationDelta != null) {
        final repDelta = await _applyBuffToRepDelta(
          playerId,
          resolved.factionId!,
          resolved.factionReputationDelta!,
          buffed.mults,
        );
        await _factionRep.delta(
          playerId,
          resolved.factionId!,
          repDelta,
        );
      }

      // 6. Marca reward_claimed. Previne re-grant em retry do listener.
      await _achievementsRepo.markRewardClaimed(playerId, achievementKey);

      return RewardGrantResult(resolved: _buffedResolved(resolved, buffed));
    });

    // 7. Emite eventos FORA da transação — só chega aqui se commit OK.
    //    14.5: LevelUp (quando houve) emitido antes do RewardGranted.
    //    Flag `fromAchievementCascade=true` no RewardGranted faz o
    //    AchievementsService ignorar este evento no listener (a cascata
    //    síncrona já cuidou dos achievementsToCheck com depth correto).
    //    Outros listeners (UI, analytics) consomem normalmente.
    //    Sprint 3.4 Etapa C — RewardGranted carrega valores pós-buff.
    if (levelUpEvent != null) {
      _eventBus.publish(levelUpEvent!);
    }
    _eventBus.publish(RewardGranted(
      playerId: playerId,
      rewardResolvedJson: _buffedResolved(resolved, buffed).toJsonString(),
      fromAchievementCascade: true,
    ));

    return result;
  }

  /// Aplica xpMult em rep delta positivo. Regra OPÇÃO A: se player é
  /// member da Guilda E rep alvo também é Guilda → buff NÃO aplica
  /// (Guilda buffa relações com terceiros, não consigo mesma). Delta
  /// negativo passa cru (debuff/penalidades não amplificam perdas).
  Future<int> _applyBuffToRepDelta(
    int playerId,
    String targetFactionId,
    int delta,
    FactionBuffMultipliers mults,
  ) async {
    if (delta <= 0) return delta;
    if (mults.xpMult == 1.0) return delta;
    if (targetFactionId == 'guild') {
      // OPÇÃO A — leitura de faction_type pra detectar self-buff.
      final rows = await _db.customSelect(
        'SELECT faction_type FROM players WHERE id = ? LIMIT 1',
        variables: [Variable.withInt(playerId)],
      ).get();
      if (rows.isNotEmpty &&
          rows.first.read<String?>('faction_type') == 'guild') {
        return delta; // Guilda member ganhando rep da Guilda — sem buff
      }
    }
    return (delta * mults.xpMult).round();
  }

  /// Cria RewardResolved espelho do declarado, mas com xp/gold/gems
  /// pós-buff. Preserva items, achievementsToCheck, recipesToUnlock,
  /// factionId/factionReputationDelta (delta cru — buff aplicado em
  /// `_applyBuffToRepDelta` no momento do persist).
  RewardResolved _buffedResolved(
    RewardResolved declared,
    ({int xp, int gold, int gems, FactionBuffMultipliers mults}) buffed,
  ) {
    return RewardResolved(
      xp: buffed.xp,
      gold: buffed.gold,
      gems: buffed.gems,
      seivas: declared.seivas,
      items: declared.items,
      achievementsToCheck: declared.achievementsToCheck,
      recipesToUnlock: declared.recipesToUnlock,
      factionId: declared.factionId,
      factionReputationDelta: declared.factionReputationDelta,
    );
  }
}
