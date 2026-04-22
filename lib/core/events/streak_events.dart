import 'app_event.dart';

/// Sprint 3.1 Bloco 2 — eventos de streak de missões diárias.
///
/// `StreakMaintained` dispara todo reset diário em que o jogador concluiu
/// ao menos 1 missão (completa ou parcial); `StreakBroken` dispara no reset
/// em que nenhuma missão foi concluída no dia anterior.
///
/// Strategies internal (Bloco 6) escutam `StreakMaintained` pra quests
/// "mantenha 10 dias de streak"; `AchievementsService` (Bloco 8) escuta
/// ambos pra badges de consistência.

class StreakMaintained extends AppEvent {
  final int playerId;

  /// Streak atual após o incremento (em dias).
  final int currentStreak;

  StreakMaintained({
    required this.playerId,
    required this.currentStreak,
    super.at,
  });

  @override
  String toString() =>
      'StreakMaintained(player=$playerId, days=$currentStreak)';
}

class StreakBroken extends AppEvent {
  final int playerId;

  /// Streak imediatamente antes da quebra (em dias). Útil pra badge "era
  /// 30 dias, quebrou".
  final int lastStreak;

  StreakBroken({
    required this.playerId,
    required this.lastStreak,
    super.at,
  });

  @override
  String toString() =>
      'StreakBroken(player=$playerId, lastStreak=$lastStreak)';
}
