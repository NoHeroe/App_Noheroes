import 'package:drift/drift.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/events/player_events.dart';
import '../../data/database/app_database.dart';
import '../balance/individual_delete_cost.dart';
import '../enums/mission_modality.dart';
import '../exceptions/reward_exceptions.dart';
import '../models/mission_progress.dart';
import '../repositories/mission_repository.dart';

/// Lançada quando o jogador tenta apagar uma missão que não é
/// individual (bug de UI enviando mission errada). `ArgumentError`
/// seria genérico demais — caller diferencia.
class NotIndividualMissionException implements Exception {
  final int missionProgressId;
  final MissionModality actualModality;
  const NotIndividualMissionException({
    required this.missionProgressId,
    required this.actualModality,
  });

  @override
  String toString() =>
      'NotIndividualMission(id=$missionProgressId, modality=${actualModality.name})';
}

/// Lançada quando o jogador não tem ouro suficiente pra pagar o custo
/// de delete. `InsufficientGemsException` é o caso análogo pra gemas
/// (reusada do Bloco 9).
class InsufficientGoldException implements Exception {
  final int playerId;
  final int required;
  final int available;
  const InsufficientGoldException({
    required this.playerId,
    required this.required,
    required this.available,
  });

  @override
  String toString() =>
      'InsufficientGold(player=$playerId, need=$required, have=$available)';
}

/// Sprint 3.1 Bloco 10a.2 — apaga uma missão individual repetível
/// mediante pagamento em gold + gems (ver `IndividualDeleteCost`).
///
/// ## Decisão D2 do plan-first
///
/// Schema 24 **não** tem coluna `deleted_at`. Em vez de adicionar
/// migration schema 25 (Regra 6 — migration em sprint própria), reusamos
/// `failed_at` + `MissionFailureReason.deletedByUser` como marker
/// semântico. Aba Histórico (Bloco 12) discrimina via `reason` pra
/// mostrar badge "Apagada" separado de "Expirou"/"Desistiu".
///
/// ## Atomicidade
///
/// Tudo numa transação:
///   1. Confirma modality=individual (caller não deve chamar em outros)
///   2. Calcula custo via `IndividualDeleteCost.forRank`
///   3. Valida saldos gold + gems (lança Insufficient* se faltar)
///   4. Debita ambas currencies com `updates: {playersTable}` pra
///      invalidar streams dependentes
///   5. Marca `failed_at = now`
///
/// Eventos pós-commit (ordem: currency spends → MissionFailed):
///   - `GoldSpent(source: individualDelete)`
///   - `GemsSpent(source: individualDelete)`
///   - `MissionFailed(reason: deletedByUser)`
///
/// `QuestsScreenNotifier` já escuta `MissionFailed` e reinvalida —
/// UI refresca sem `ref.invalidate` manual.
///
/// ## Regra 4 (race condition)
///
/// O caller **não** precisa aplicar `unawaited + delay + go` porque o
/// único passo pós-delete é fechar o dialog de confirmação (Navigator
/// pop), não navegar entre rotas. O bus carrega o refresh de UI.
class IndividualDeleteService {
  final AppDatabase _db;
  final MissionRepository _missionRepo;
  final AppEventBus _bus;

  IndividualDeleteService({
    required AppDatabase db,
    required MissionRepository missionRepo,
    required AppEventBus bus,
  })  : _db = db,
        _missionRepo = missionRepo,
        _bus = bus;

  /// Calcula o custo pra apagar [mission]. Função pura — não toca DB
  /// nem bus. Expõe IndividualDeleteCost pro caller usar na UI
  /// (confirm dialog mostra o valor antes de o jogador aceitar).
  IndividualDeleteCost costFor(MissionProgress mission) =>
      IndividualDeleteCost.forRank(mission.rank);

  /// Apaga a missão. Ver docstring da classe pros contratos.
  Future<void> deleteIndividual({
    required int playerId,
    required int missionProgressId,
  }) async {
    // Lê fora da transaction pra pegar o rank e rejeitar cedo em caso
    // de modality errada — evita abrir transaction desnecessária.
    final mission = await _missionRepo.findById(missionProgressId);
    if (mission == null) {
      throw MissionNotFoundException(missionProgressId);
    }
    if (mission.modality != MissionModality.individual) {
      throw NotIndividualMissionException(
        missionProgressId: missionProgressId,
        actualModality: mission.modality,
      );
    }
    final cost = IndividualDeleteCost.forRank(mission.rank);

    await _db.transaction(() async {
      // 1. Check saldos DENTRO da tx pra evitar race entre leitura e
      //    debit (outro gasto concorrente poderia esvaziar saldo).
      final row = await (_db.select(_db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingleOrNull();
      if (row == null) {
        throw InsufficientGoldException(
          playerId: playerId,
          required: cost.gold,
          available: 0,
        );
      }
      if (row.gold < cost.gold) {
        throw InsufficientGoldException(
          playerId: playerId,
          required: cost.gold,
          available: row.gold,
        );
      }
      if (row.gems < cost.gems) {
        throw InsufficientGemsException(
          playerId: playerId,
          required: cost.gems,
          available: row.gems,
        );
      }

      // 2. Debita currencies — customUpdate com updates: {playersTable}
      //    invalida o playerStreamProvider downstream.
      await _db.customUpdate(
        'UPDATE players SET gold = gold - ?, gems = gems - ? '
        'WHERE id = ?',
        variables: [
          Variable.withInt(cost.gold),
          Variable.withInt(cost.gems),
          Variable.withInt(playerId),
        ],
        updates: {_db.playersTable},
      );

      // 3. Marca failed_at — reusa markFailed do repo (Bloco 4).
      await _missionRepo.markFailed(missionProgressId, at: DateTime.now());
    });

    // Eventos pós-commit. Ordem: spends → failure pra alinhar
    // observadores que logam economia antes de estado de missão.
    _bus.publish(GoldSpent(
      playerId: playerId,
      amount: cost.gold,
      source: GoldSink.individualDelete,
    ));
    _bus.publish(GemsSpent(
      playerId: playerId,
      amount: cost.gems,
      source: GemSink.individualDelete,
    ));
    _bus.publish(MissionFailed(
      missionKey: mission.missionKey,
      playerId: playerId,
      reason: MissionFailureReason.deletedByUser,
    ));
  }
}
