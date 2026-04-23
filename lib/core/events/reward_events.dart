import 'app_event.dart';

/// Sprint 3.1 Bloco 2 — eventos de recompensas e conquistas.

/// Reward foi creditada com sucesso numa transação Drift atômica (ADR 0011).
///
/// Emitido pelo `RewardGrantService` (Bloco 5) no fim da transação, após
/// itens/moedas/recipes serem de fato persistidos. `AchievementsService`
/// (Bloco 8) escuta pra cascatear conquistas que dependem de items ganhos.
///
/// `rewardResolvedJson` carrega a reward após SOULSLIKE + random resolver
/// (ADR 0013 + 0017) — ou seja, valores finais, não os declarados no JSON.
class RewardGranted extends AppEvent {
  @override
  final int playerId;
  final String rewardResolvedJson;

  /// Bloco 8 — se `true`, o evento foi emitido dentro de
  /// `RewardGrantService.grantAchievement` (reward de conquista). O
  /// `AchievementsService` ignora esses no listener pra evitar que a
  /// re-entry pela bus bypasse o limite de profundidade da cascata
  /// (cascata já foi processada síncronamente por quem chamou grant).
  /// Outros listeners (UI, analytics) consomem normalmente — a flag só
  /// altera o comportamento de cascata de conquistas.
  final bool fromAchievementCascade;

  RewardGranted({
    required this.playerId,
    required this.rewardResolvedJson,
    this.fromAchievementCascade = false,
    super.at,
  });

  @override
  String toString() =>
      'RewardGranted(player=$playerId, cascade=$fromAchievementCascade)';
}

/// Conquista desbloqueada. Registrada em `player_achievements_completed`
/// pelo `AchievementsService` (Bloco 8) antes do emit — idempotência
/// garantida pela PK composta da tabela.
class AchievementUnlocked extends AppEvent {
  @override
  final int playerId;
  final String achievementKey;

  AchievementUnlocked({
    required this.playerId,
    required this.achievementKey,
    super.at,
  });

  @override
  String toString() =>
      'AchievementUnlocked($achievementKey, player=$playerId)';
}
