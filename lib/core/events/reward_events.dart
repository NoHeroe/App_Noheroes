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
  final int playerId;
  final String rewardResolvedJson;

  RewardGranted({
    required this.playerId,
    required this.rewardResolvedJson,
    super.at,
  });

  @override
  String toString() => 'RewardGranted(player=$playerId)';
}

/// Conquista desbloqueada. Registrada em `player_achievements_completed`
/// pelo `AchievementsService` (Bloco 8) antes do emit — idempotência
/// garantida pela PK composta da tabela.
class AchievementUnlocked extends AppEvent {
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
