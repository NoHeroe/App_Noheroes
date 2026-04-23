/// Sprint 3.1 Bloco 4 — Repository de conquistas desbloqueadas pelo
/// jogador (`player_achievements_completed`).
///
/// Catálogo de achievements (metadata, rewards, triggers) vive em
/// `assets/data/achievements.json` e é carregado em memória pelo
/// `AchievementsService` (Bloco 8). Este Repository guarda só a
/// interseção jogador × key.
abstract class PlayerAchievementsRepository {
  /// Já desbloqueou esta conquista? Idempotência — evita emitir evento
  /// `AchievementUnlocked` 2x.
  Future<bool> isCompleted(int playerId, String achievementKey);

  /// Keys de todas as conquistas desbloqueadas pelo jogador, ordenadas
  /// por `completed_at` desc (mais recentes primeiro).
  Future<List<String>> listCompletedKeys(int playerId);

  /// Registra desbloqueio em [at]. Falha silenciosamente se já existe
  /// (INSERT OR IGNORE semântico — PK composta garante idempotência).
  Future<void> markCompleted(
    int playerId,
    String achievementKey, {
    required DateTime at,
  });

  /// Marca `reward_claimed = 1`. Chamado após grant bem-sucedido.
  Future<void> markRewardClaimed(int playerId, String achievementKey);

  /// `true` se a row existe **e** já teve reward creditada. Usado pelo
  /// `RewardGrantService.grantAchievement` (Bloco 8) como guard de
  /// idempotência dentro da transação.
  Future<bool> isRewardClaimed(int playerId, String achievementKey);

  /// Total de conquistas desbloqueadas — consumido por conquistas
  /// meta (`trigger: meta`, completar N outras — Bloco 8).
  Future<int> countCompleted(int playerId);
}
