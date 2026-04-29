import 'package:drift/drift.dart';

/// Sprint 3.3 Etapa 2.1a — volume all-time por (player × subTaskKey),
/// alimentado pelo `DailyMissionStatsService` em eventos terminais
/// (`DailyMissionCompleted/Partial/Failed`).
///
/// Tracking **terminal**: o service soma `progressoAtual` de cada
/// sub-task ao fechar a missão. Decisão deliberada (vs incremental) pra
/// evitar cache em memória + race condition entre eventos
/// `DailyMissionProgressed`.
///
/// Schema 28. PK composta `(playerId, subTaskKey)`. Lazy creation:
/// começa vazia; row é criada via UPSERT (`INSERT ON CONFLICT DO UPDATE`)
/// no primeiro `incrementVolume`.
@DataClassName('PlayerDailySubtaskVolumeData')
class PlayerDailySubtaskVolumeTable extends Table {
  @override
  String get tableName => 'player_daily_subtask_volume';

  IntColumn get playerId => integer()();

  /// Chave canônica da sub-tarefa (ex: `flexao`, `abdominal`,
  /// `meditacao`). Igual ao `subTaskKey` em `DailySubTaskInstance`.
  TextColumn get subTaskKey => text()();

  /// Soma all-time de `progressoAtual` ao fechar missões. Unidade
  /// depende da sub-tarefa (reps, minutos, km, …) — semantics ficam
  /// com o caller que interpreta.
  IntColumn get totalUnits =>
      integer().withDefault(const Constant(0))();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {playerId, subTaskKey};
}
