import 'package:drift/drift.dart';

/// Sprint 3.1 — preferências do jogador definidas no quiz de calibração
/// (ADR 0015). PK = player_id (relação 1:1 com players).
///
/// Campos subfocus guardam arrays JSON (até 3 seleções por grupo).
@DataClassName('PlayerMissionPreferencesData')
class PlayerMissionPreferencesTable extends Table {
  @override
  String get tableName => 'player_mission_preferences';

  IntColumn get playerId => integer()();

  /// P1 — `fisico`, `mental`, `espiritual`, `vitalismo`.
  /// (4 categorias adaptadas da Rodada 1.)
  TextColumn get primaryFocus => text()();

  /// P2 — `light`, `medium`, `heavy`, `adaptive`.
  TextColumn get intensity => text()();

  /// P3 — `real`, `internal`, `mixed`.
  TextColumn get missionStyle => text()();

  /// P4, P5, P6 — arrays JSON condicionais. Default `[]` quando não aplicável.
  TextColumn get physicalSubfocus => text().withDefault(const Constant('[]'))();
  TextColumn get mentalSubfocus => text().withDefault(const Constant('[]'))();
  TextColumn get spiritualSubfocus =>
      text().withDefault(const Constant('[]'))();

  /// P7 — minutos disponíveis por dia.
  IntColumn get timeDailyMinutes => integer().withDefault(const Constant(30))();

  IntColumn get createdAt => integer()(); // unix millis
  IntColumn get updatedAt => integer()();

  /// Incrementa a cada refazer (gating de custo: 0 grátis, 1ª = 100 gemas +
  /// 1 Seiva, 2ª+ = 300 gemas + 3 Seivas).
  IntColumn get updatesCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {playerId};
}
