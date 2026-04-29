import 'package:drift/drift.dart';

/// Sprint 3.3 Etapa 2.1a — stats agregadas all-time por jogador, alimentadas
/// pelo `DailyMissionStatsService` (listener de eventos terminais
/// `DailyMissionGenerated/Completed/Partial/Failed`). Foundation pros
/// triggers de conquista da Etapa 2.1b — esta tabela NÃO é consumida por
/// nenhum service de gameplay direto, só por `AchievementsService` (futuro).
///
/// Schema 28. PK = `playerId` (1 row por jogador). Auto-criada pra players
/// existentes na migration 27→28; pra novos jogadores, o DAO faz lazy
/// `findOrCreate` no primeiro acesso (evita acoplar criação a signup flow).
///
/// ## Convenções dos contadores
///
/// - `total*` = contadores monotônicos (só incrementam — exceto
///   `consecutiveFailsCount` e `daysWithoutFailing` que resetam)
/// - `best*` = recordes all-time (MAX entre valor atual e novo)
/// - `last*At` = unix millis; nullable até primeiro evento
/// - `last*Day` = `YYYY-MM-DD` text; usado pra detectar virada de dia em
///   contadores que só incrementam 1× por dia (pilar balance, active days)
@DataClassName('PlayerDailyMissionStat')
class PlayerDailyMissionStatsTable extends Table {
  @override
  String get tableName => 'player_daily_mission_stats';

  IntColumn get playerId => integer()();

  // ─── Contadores de status terminal ─────────────────────────────────
  IntColumn get totalCompleted =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalFailed =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalPartial =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalPerfect =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalSuperPerfect =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalGenerated =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalConfirmed =>
      integer().withDefault(const Constant(0))();

  // ─── Streaks / sequências ───────────────────────────────────────────
  IntColumn get bestStreak =>
      integer().withDefault(const Constant(0))();
  IntColumn get daysWithoutFailing =>
      integer().withDefault(const Constant(0))();
  IntColumn get bestDaysWithoutFailing =>
      integer().withDefault(const Constant(0))();
  IntColumn get consecutiveFailsCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get maxConsecutiveFails =>
      integer().withDefault(const Constant(0))();
  IntColumn get consecutiveActiveDays =>
      integer().withDefault(const Constant(0))();
  IntColumn get bestConsecutiveActiveDays =>
      integer().withDefault(const Constant(0))();

  // ─── Volume de sub-tarefas (terminal) ──────────────────────────────
  IntColumn get totalSubTasksCompleted =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalSubTasksOvershoot =>
      integer().withDefault(const Constant(0))();

  // ─── Janelas temporais de confirmação ──────────────────────────────
  // `.named(...)` explícito porque o auto-snake do Drift produz nomes
  // estranhos (`total_confirmed_before8_a_m`) com numerais misturados.
  IntColumn get totalConfirmedBefore8AM => integer()
      .named('total_confirmed_before_8am')
      .withDefault(const Constant(0))();
  IntColumn get totalConfirmedAfter10PM => integer()
      .named('total_confirmed_after_10pm')
      .withDefault(const Constant(0))();
  IntColumn get totalConfirmedOnWeekend =>
      integer().withDefault(const Constant(0))();

  // ─── Easter eggs / triggers exóticos (foundation pra secret) ───────
  IntColumn get daysOfWeekCompletedBitmask =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalZeroProgressConfirms =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalDaysAllPilars =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalSpeedrunCompletions =>
      integer().withDefault(const Constant(0))();

  // ─── Markers ───────────────────────────────────────────────────────
  IntColumn get firstCompletedAt => integer().nullable()();
  IntColumn get lastCompletedAt => integer().nullable()();

  /// Última data (YYYY-MM-DD) em que `totalDaysAllPilars` foi
  /// incrementado — guard contra duplo-count no mesmo dia.
  TextColumn get lastPilarBalanceDay => text().nullable()();

  /// Última data (YYYY-MM-DD) em que houve atividade — usado pra
  /// detectar gap em `consecutiveActiveDays`.
  TextColumn get lastActiveDay => text().nullable()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {playerId};
}
