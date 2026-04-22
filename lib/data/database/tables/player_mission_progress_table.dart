import 'package:drift/drift.dart';

/// Sprint 3.1 — tabela unificada de progresso de missões.
///
/// Substitui `habits` + `habit_logs` + `class_quests` + `active_faction_quests`
/// como fonte única de estado pro novo sistema (Diárias, Classe, Facção,
/// Extras, Admissão).
///
/// Schema Postgres-ready (ADR 0016): timestamps em int millis, JSON como TEXT,
/// naming snake_case, sem features exclusivas de SQLite.
@DataClassName('PlayerMissionProgressData')
class PlayerMissionProgressTable extends Table {
  @override
  String get tableName => 'player_mission_progress';

  IntColumn get id => integer().autoIncrement()();

  /// FK lógico pra `players.id`. Mantido como int pra compatibilidade com
  /// o schema atual; migração pra UUID fica pra Época Supabase.
  IntColumn get playerId => integer()();

  /// Chave estável da missão no catálogo JSON (ex: `DAILY_PUSHUPS_E`,
  /// `CLASS_WARRIOR_ENDURANCE`). Mapeia pra entrada declarativa de reward.
  TextColumn get missionKey => text()();

  /// Família: `internal`, `real`, `individual`, `mista` (ADR 0014).
  TextColumn get modality => text()();

  /// Aba de origem: `daily`, `class`, `faction`, `extras`, `admission`.
  TextColumn get tabOrigin => text()();

  /// Rank da missão (E/D/C/B/A/S) — usado no assignment e rank gating.
  TextColumn get rank => text()();

  IntColumn get targetValue => integer()();
  IntColumn get currentValue => integer().withDefault(const Constant(0))();

  /// Reward declarado (JSON com xp/gold/gems/seivas/items/achievements/...).
  /// Resolver aplica SOULSLIKE multipliers na hora do grant.
  TextColumn get rewardJson => text()();

  IntColumn get startedAt => integer()(); // unix millis
  IntColumn get completedAt => integer().nullable()();
  IntColumn get failedAt => integer().nullable()();

  /// True quando reward já foi creditada (idempotência).
  BoolColumn get rewardClaimed =>
      boolean().withDefault(const Constant(false))();

  /// Meta extras (ex: sub-tarefas da família mista, breakdown por requisito).
  TextColumn get metaJson => text().withDefault(const Constant('{}'))();
}
