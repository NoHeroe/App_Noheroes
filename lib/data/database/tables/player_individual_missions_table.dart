import 'package:drift/drift.dart';

/// Sprint 3.1 — missões criadas pelo próprio jogador (família Individual,
/// ADR 0014). Reward calculada no momento da criação via
/// `MissionBalancerService` (intensidade × categoria × SOULSLIKE).
///
/// Impacto de falha em Sombra é 200% do padrão (promessa pessoal quebrada).
/// Delete de repetível custa gemas + ouro (desincentiva abuso).
@DataClassName('PlayerIndividualMissionData')
class PlayerIndividualMissionsTable extends Table {
  @override
  String get tableName => 'player_individual_missions';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();

  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  /// `fisico`, `mental`, `espiritual`, `vitalismo`.
  TextColumn get category => text()();

  /// 1..4 (leve, médio, pesado, extremo).
  IntColumn get intensityIndex => integer()();

  /// `daily`, `weekly`, `monthly`, `one-shot`.
  TextColumn get frequency => text()();

  BoolColumn get repeats => boolean().withDefault(const Constant(true))();

  /// Reward calculada no momento da criação, em JSON declarativo.
  TextColumn get rewardJson => text()();

  IntColumn get createdAt => integer()(); // unix millis

  /// Soft delete — preserva histórico e evita race conditions com progresso
  /// ativo quando jogador remove missão antes do reset.
  IntColumn get deletedAt => integer().nullable()();

  IntColumn get completionCount => integer().withDefault(const Constant(0))();
  IntColumn get failureCount => integer().withDefault(const Constant(0))();
}
