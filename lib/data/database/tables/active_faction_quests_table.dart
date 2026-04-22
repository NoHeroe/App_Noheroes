import 'package:drift/drift.dart';

/// Sprint 3.1 — missão semanal ativa por (jogador, facção).
///
/// Substitui a `FactionQuestsTable` legacy (mesmo nome SQL
/// `active_faction_quests`, reset brutal no schema 24). Agora carrega
/// UNIQUE lógico via `@TableIndex` em `(player_id, faction_id, week_start)`,
/// fechando a dívida da Sprint 2.3 e eliminando a race condition conhecida.
///
/// Reward é referenciada por `mission_key` no catálogo JSON de facções;
/// progresso e estado migram pra `player_mission_progress` quando a missão
/// é disparada, mas esta tabela guarda o registro "quem é a quest da semana".
@DataClassName('ActiveFactionQuestData')
@TableIndex(
  name: 'unique_player_faction_week',
  columns: {#playerId, #factionId, #weekStart},
  unique: true,
)
class ActiveFactionQuestsTable extends Table {
  @override
  String get tableName => 'active_faction_quests';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get factionId => text()();

  /// Chave da quest no catálogo JSON (assets/data/faction_quests_weekly.json).
  TextColumn get missionKey => text()();

  /// yyyy-MM-dd da segunda-feira — âncora do reset semanal.
  TextColumn get weekStart => text()();

  IntColumn get assignedAt => integer()(); // unix millis
}
