import 'package:drift/drift.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/player_events.dart';
import '../../core/events/reward_events.dart';
import '../../domain/enums/source_type.dart';
import '../../domain/exceptions/reward_exceptions.dart';
import '../../domain/models/reward_grant_result.dart';
import '../../domain/models/reward_resolved.dart';
import '../../domain/repositories/mission_repository.dart';
import '../../domain/repositories/player_achievements_repository.dart';
import '../../domain/repositories/player_faction_reputation_repository.dart';
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

  RewardGrantService({
    required AppDatabase db,
    required MissionRepository missionRepo,
    required PlayerAchievementsRepository achievementsRepo,
    required PlayerInventoryService inventory,
    required PlayerRecipesService recipes,
    required PlayerFactionReputationRepository factionRep,
    required AppEventBus eventBus,
  })  : _db = db,
        _missionRepo = missionRepo,
        _achievementsRepo = achievementsRepo,
        _inventory = inventory,
        _recipes = recipes,
        _factionRep = factionRep,
        _eventBus = eventBus;

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
      if (resolved.xp != 0) {
        levelUpEvent =
            await PlayerDao(_db).addXp(playerId, resolved.xp);
      }
      if (resolved.gold != 0 || resolved.gems != 0) {
        await _db.customUpdate(
          'UPDATE players SET gold = gold + ?, gems = gems + ? '
          'WHERE id = ?',
          variables: [
            Variable.withInt(resolved.gold),
            Variable.withInt(resolved.gems),
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
      if (resolved.factionId != null &&
          resolved.factionReputationDelta != null) {
        await _factionRep.delta(
          playerId,
          resolved.factionId!,
          resolved.factionReputationDelta!,
        );
      }

      return RewardGrantResult(resolved: resolved);
    });

    // 7. Emite eventos FORA da transação — chega aqui só se commit OK.
    //    Qualquer exception acima propaga e este ponto não é alcançado.
    //    14.5 — LevelUp (quando houve) emitido ANTES do RewardGranted
    //    pra listeners que reagem a level (ex: `phaseUnlock` popups)
    //    processarem primeiro.
    if (levelUpEvent != null) {
      _eventBus.publish(levelUpEvent!);
    }
    _eventBus.publish(RewardGranted(
      playerId: playerId,
      rewardResolvedJson: resolved.toJsonString(),
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
      if (resolved.xp != 0) {
        levelUpEvent =
            await PlayerDao(_db).addXp(playerId, resolved.xp);
      }
      if (resolved.gold != 0 || resolved.gems != 0) {
        await _db.customUpdate(
          'UPDATE players SET gold = gold + ?, gems = gems + ? '
          'WHERE id = ?',
          variables: [
            Variable.withInt(resolved.gold),
            Variable.withInt(resolved.gems),
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
      if (resolved.factionId != null &&
          resolved.factionReputationDelta != null) {
        await _factionRep.delta(
          playerId,
          resolved.factionId!,
          resolved.factionReputationDelta!,
        );
      }

      // 6. Marca reward_claimed. Previne re-grant em retry do listener.
      await _achievementsRepo.markRewardClaimed(playerId, achievementKey);

      return RewardGrantResult(resolved: resolved);
    });

    // 7. Emite eventos FORA da transação — só chega aqui se commit OK.
    //    14.5: LevelUp (quando houve) emitido antes do RewardGranted.
    //    Flag `fromAchievementCascade=true` no RewardGranted faz o
    //    AchievementsService ignorar este evento no listener (a cascata
    //    síncrona já cuidou dos achievementsToCheck com depth correto).
    //    Outros listeners (UI, analytics) consomem normalmente.
    if (levelUpEvent != null) {
      _eventBus.publish(levelUpEvent!);
    }
    _eventBus.publish(RewardGranted(
      playerId: playerId,
      rewardResolvedJson: resolved.toJsonString(),
      fromAchievementCascade: true,
    ));

    return result;
  }
}
