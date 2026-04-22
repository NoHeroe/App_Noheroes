import '../models/active_faction_quest.dart';

/// Record resultado de [ActiveFactionQuestsRepository.upsertAtomic].
/// Carrega os ids do ledger e da row de progresso criada/recuperada.
typedef FactionWeeklyAssignment = ({int ledgerId, int progressId});

/// Sprint 3.1 Bloco 4 — ledger de atribuição semanal de missão de
/// facção (`active_faction_quests`).
///
/// UNIQUE `(player_id, faction_id, week_start)` do schema 24 fecha o
/// bug 3 da Sprint 2.3 (race condition do assignWeeklyQuest legacy).
/// [upsertAtomic] encapsula a transação que materializa tanto o ledger
/// quanto a entry correspondente em `player_mission_progress`.
abstract class ActiveFactionQuestsRepository {
  /// Existe ledger pra esta tripla (jogador, facção, semana)?
  /// `null` se não foi assignado ainda.
  Future<ActiveFactionQuest?> findActiveFor(
    int playerId,
    String factionId,
    String weekStart,
  );

  /// Cria atomicamente:
  ///   1. row em `active_faction_quests` (ledger)
  ///   2. row em `player_mission_progress` com tab_origin='faction'
  ///
  /// **Atomicidade** via `_db.transaction` — se o passo 2 falhar, o
  /// ledger faz rollback.
  ///
  /// **Idempotente sob race condition**: se 2 chamadas concorrentes
  /// tentarem assignar a mesma tripla, a segunda detecta a UNIQUE
  /// violation, faz rollback e retorna os ids do ledger que já existe
  /// + sua row de progresso correspondente. Ambas as chamadas voltam
  /// com um resultado válido; apenas uma row de cada tabela existe no
  /// fim. Fecha o bug 3 da Sprint 2.3.
  ///
  /// Parâmetros mission-specific (`missionKey`, dados do
  /// `MissionProgress` que vai ser criado) ficam nos campos da entry
  /// do ledger + [progressSeedJson] que o repo usa pra materializar a
  /// row de progresso dentro da mesma transação.
  Future<FactionWeeklyAssignment> upsertAtomic({
    required int playerId,
    required String factionId,
    required String missionKey,
    required String weekStart,
    required Map<String, dynamic> progressSeedJson,
  });

  /// Remove ledgers de semanas anteriores a [weekStart] (limpeza de
  /// manutenção pelo `DailyResetService` no Bloco 14). Retorna número
  /// de rows deletadas.
  Future<int> deleteExpiredBefore(String weekStart);
}
