import 'package:drift/drift.dart';

/// Sprint 3.4 Etapa A — Membership do jogador em cada facção.
///
/// Substitui parcialmente a `guild_status` legacy (Sprint 2.x): membership
/// passa a ser GENERAL (uma row por par player×faction), não específica
/// da Guilda.
///
/// PK composta `(playerId, factionId)` garante uma row por par.
///
/// ## Lifecycle
///
/// - **Pendente:** row criada com `joinedAt = null` quando jogador inicia
///   admissão (`pending:X` em `players.faction_type`). `admissionAttempts`
///   incrementa a cada tentativa.
/// - **Member:** `joinedAt` setado quando admissão completa. Player
///   continua tendo só uma facção em `players.faction_type`, mas pode
///   ter multiple membership rows historicamente (de facções anteriores).
/// - **Saiu:** `leftAt` setado, `lockedUntil` = now + 7d (não pode entrar
///   em outra facção até essa data), `debuffUntil` = now + 48h (-30%
///   XP/gold ativo até essa data).
///
/// ## Campos
///
/// - `lockedUntil`: ms epoch. Se `> now`, jogador não pode entrar em
///   nenhuma facção (regra Sprint 3.4 §Saída).
/// - `debuffUntil`: ms epoch. Se `> now`, debuff -30% XP/gold ativo
///   (aplicado pelo `FactionBuffService` na Etapa C).
/// - `admissionAttempts`: contador de tentativas de admissão (informativo;
///   permite cooldown 48h pós-rejeição via `lockedUntil` parcial).
@DataClassName('PlayerFactionMembershipData')
class PlayerFactionMembershipTable extends Table {
  @override
  String get tableName => 'player_faction_membership';

  IntColumn get playerId => integer()();
  TextColumn get factionId => text()();

  /// ms epoch. Null = ainda não entrou (pendente ou rejeitado).
  IntColumn get joinedAt => integer().nullable()();

  /// ms epoch. Null = nunca saiu (member ativo OU pendente).
  IntColumn get leftAt => integer().nullable()();

  /// ms epoch. Se `> now`, lock ativo.
  IntColumn get lockedUntil => integer().nullable()();

  /// ms epoch. Se `> now`, debuff ativo.
  IntColumn get debuffUntil => integer().nullable()();

  IntColumn get admissionAttempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {playerId, factionId};
}
