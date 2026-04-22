import 'package:drift/drift.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/reward_events.dart';
import '../../domain/enums/source_type.dart';
import '../../domain/exceptions/reward_exceptions.dart';
import '../../domain/models/reward_grant_result.dart';
import '../../domain/models/reward_resolved.dart';
import '../../domain/repositories/mission_repository.dart';
import '../../domain/repositories/player_faction_reputation_repository.dart';
import '../database/app_database.dart';
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
  final PlayerInventoryService _inventory;
  final PlayerRecipesService _recipes;
  final PlayerFactionReputationRepository _factionRep;
  final AppEventBus _eventBus;

  RewardGrantService({
    required AppDatabase db,
    required MissionRepository missionRepo,
    required PlayerInventoryService inventory,
    required PlayerRecipesService recipes,
    required PlayerFactionReputationRepository factionRep,
    required AppEventBus eventBus,
  })  : _db = db,
        _missionRepo = missionRepo,
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

      // 3. Credita currencies (xp + gold + gems) via customUpdate com
      //    updates: {playersTable} — playerStreamProvider reage ao
      //    commit e UI atualiza imediatamente (REGRAS §8). customUpdate
      //    pula por inteiro se amount total é zero (evita write
      //    desnecessário).
      if (resolved.xp != 0 || resolved.gold != 0 || resolved.gems != 0) {
        await _db.customUpdate(
          'UPDATE players SET xp = xp + ?, gold = gold + ?, '
          'gems = gems + ? WHERE id = ?',
          variables: [
            Variable.withInt(resolved.xp),
            Variable.withInt(resolved.gold),
            Variable.withInt(resolved.gems),
            Variable.withInt(playerId),
          ],
          updates: {_db.playersTable},
        );
      }

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

    // 7. Emite evento FORA da transação — chega aqui só se commit OK.
    //    Qualquer exception acima propaga e este ponto não é alcançado.
    _eventBus.publish(RewardGranted(
      playerId: playerId,
      rewardResolvedJson: resolved.toJsonString(),
    ));

    return result;
  }
}
