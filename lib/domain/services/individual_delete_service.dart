import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/events/player_events.dart';
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
  final String playerId;
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
  final SupabaseClient _client;
  final MissionRepository _missionRepo;
  final AppEventBus _bus;

  IndividualDeleteService({
    required SupabaseClient client,
    required MissionRepository missionRepo,
    required AppEventBus bus,
  })  : _client = client,
        _missionRepo = missionRepo,
        _bus = bus;

  /// Calcula o custo pra apagar [mission]. Função pura — não toca DB
  /// nem bus. Expõe IndividualDeleteCost pro caller usar na UI
  /// (confirm dialog mostra o valor antes de o jogador aceitar).
  IndividualDeleteCost costFor(MissionProgress mission) =>
      IndividualDeleteCost.forRank(mission.rank);

  /// Apaga a missão. Ver docstring da classe pros contratos.
  Future<void> deleteIndividual({
    required String playerId,
    required int missionProgressId,
  }) async {
    // Lê o rank/modality pra rejeitar cedo em caso de modality errada
    // (evita roundtrip à RPC) e calcular o custo a publicar nos eventos.
    // A RPC delete_individual_mission revalida modality/saldos server-side.
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

    // Operação atômica (valida saldos gold+gems, debita ambos, markFailed)
    // delegada à RPC — NÃO reimplementamos a atomicidade no cliente.
    try {
      await _client.rpc('delete_individual_mission', params: {
        'p_player': playerId,
        'p_mission_progress_id': missionProgressId,
        'p_gold_cost': cost.gold,
        'p_gems_cost': cost.gems,
      });
    } on PostgrestException catch (e) {
      // A RPC sinaliza saldo insuficiente via raise_exception. Remapeia
      // pras exceptions de domínio que a UI já diferencia.
      if (e.message.contains('InsufficientGold')) {
        throw InsufficientGoldException(
          playerId: playerId,
          required: cost.gold,
          available: 0,
        );
      }
      if (e.message.contains('InsufficientGems')) {
        throw InsufficientGemsException(
          playerId: playerId,
          required: cost.gems,
          available: 0,
        );
      }
      if (e.message.contains('MissionNotFound')) {
        throw MissionNotFoundException(missionProgressId);
      }
      if (e.message.contains('NotIndividualMission')) {
        throw NotIndividualMissionException(
          missionProgressId: missionProgressId,
          actualModality: mission.modality,
        );
      }
      rethrow;
    }

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
