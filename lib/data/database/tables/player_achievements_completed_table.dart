import 'package:drift/drift.dart';

/// Sprint 3.1 — registro de conquistas desbloqueadas pelo jogador. Substitui
/// a tabela `player_achievements` legacy. PK composta garante idempotência:
/// mesma conquista não pode ser registrada 2x pro mesmo jogador.
///
/// Catálogo de conquistas vive no JSON `assets/data/achievements.json`
/// (Bloco 8) — esta tabela guarda só a interseção jogador × achievement.
@DataClassName('PlayerAchievementCompletedData')
class PlayerAchievementsCompletedTable extends Table {
  @override
  String get tableName => 'player_achievements_completed';

  IntColumn get playerId => integer()();

  /// Chave estável da conquista (ex: `ACH_FIRST_CRAFT`). Mapeia pra JSON.
  TextColumn get achievementKey => text()();

  IntColumn get completedAt => integer()(); // unix millis

  /// Idempotência do grant — reward só é creditada 1x mesmo que o trigger
  /// recalcule a conquista.
  BoolColumn get rewardClaimed =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {playerId, achievementKey};
}
