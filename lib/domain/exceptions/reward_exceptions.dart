// Sprint 3.1 Bloco 5 — exceções de domínio de reward.
//
// Não use `StateError`/`ArgumentError` pra estes casos — eles são
// genéricos e a UI (Bloco 10) precisa diferenciar "idempotência violada
// silencia" de "erro real" (DB crash, etc.).

/// Tentativa de grantar reward numa missão que já teve a reward
/// creditada. Idempotência via `player_mission_progress.reward_claimed`
/// (Bloco 1).
class RewardAlreadyGrantedException implements Exception {
  final int missionProgressId;
  final int playerId;

  const RewardAlreadyGrantedException({
    required this.missionProgressId,
    required this.playerId,
  });

  @override
  String toString() =>
      'RewardAlreadyGranted(mission=$missionProgressId, player=$playerId)';
}

/// Missão referenciada pelo grant não existe (id deletado, race com
/// migration, dados inconsistentes). Difere de "reward já grantada" —
/// aqui a row nem está presente.
class MissionNotFoundException implements Exception {
  final int missionProgressId;

  const MissionNotFoundException(this.missionProgressId);

  @override
  String toString() => 'MissionNotFound(id=$missionProgressId)';
}

/// Sprint 3.1 Bloco 8 — análogo da [RewardAlreadyGrantedException] pra
/// grant de conquista. Idempotência via
/// `player_achievements_completed.reward_claimed`.
class AchievementRewardAlreadyGrantedException implements Exception {
  final int playerId;
  final String achievementKey;

  const AchievementRewardAlreadyGrantedException({
    required this.playerId,
    required this.achievementKey,
  });

  @override
  String toString() =>
      'AchievementRewardAlreadyGranted(player=$playerId, key=$achievementKey)';
}

/// Sprint 3.1 Bloco 8 — caller chamou [grantAchievement] sem a conquista
/// ter sido marcada como completa primeiro (faltou `markCompleted`).
/// Erro de programação — fluxo normal no `AchievementsService` sempre
/// marca antes de grantar.
class AchievementNotUnlockedException implements Exception {
  final int playerId;
  final String achievementKey;

  const AchievementNotUnlockedException({
    required this.playerId,
    required this.achievementKey,
  });

  @override
  String toString() =>
      'AchievementNotUnlocked(player=$playerId, key=$achievementKey)';
}
