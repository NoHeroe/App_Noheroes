import 'package:drift/drift.dart';

/// Sprint 3.1 — reputação do jogador com cada facção (0..100, neutro = 50).
/// Afeta dificuldade dinâmica de admissão e cruza entre facções aliadas
/// (`FactionReputationService` no Bloco 14).
///
/// PK composta garante uma linha por par (jogador, facção).
@DataClassName('PlayerFactionReputationData')
class PlayerFactionReputationTable extends Table {
  @override
  String get tableName => 'player_faction_reputation';

  IntColumn get playerId => integer()();
  TextColumn get factionId => text()();

  /// Clamp lógico entre 0 e 100 aplicado na camada de service.
  IntColumn get reputation => integer().withDefault(const Constant(50))();

  IntColumn get updatedAt => integer()(); // unix millis

  @override
  Set<Column> get primaryKey => {playerId, factionId};
}
