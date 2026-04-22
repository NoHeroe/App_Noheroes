import '../models/individual_mission_spec.dart';

/// Sprint 3.1 Bloco 4 — Repository das missões criadas pelo jogador
/// (`player_individual_missions`). Soft delete: `deleted_at` nullable.
///
/// `countActive` existe pra enforce do limite FREE=5 no UI do Bloco 11
/// (`IndividualMissionCard` mostra indicador "X/5").
abstract class PlayerIndividualMissionsRepository {
  /// Missões ativas do jogador (`deleted_at IS NULL`), ordenadas por
  /// `created_at` desc (mais recentes no topo).
  Future<List<IndividualMissionSpec>> findActive(int playerId);

  /// Missão por id (mesmo deletada — útil pro histórico).
  Future<IndividualMissionSpec?> findById(int id);

  /// Insere nova missão. Retorna o id gerado.
  Future<int> insert(IndividualMissionSpec mission);

  /// Atualiza contadores (após conclusão ou falha da instância semanal
  /// da missão individual repetível).
  Future<void> updateCounters(
    int id, {
    required int completionCount,
    required int failureCount,
  });

  /// Soft delete em [at]. Preserva a row pra histórico e pra evitar
  /// race conditions com progresso ativo. Custo de gemas + ouro é
  /// cobrado pela UI do Bloco 11 **antes** de chamar este método.
  Future<void> softDelete(int id, {required DateTime at});

  /// Total de missões ativas — enforce do limite FREE=5.
  Future<int> countActive(int playerId);
}
