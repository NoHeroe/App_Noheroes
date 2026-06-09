import 'package:drift/drift.dart';

/// Fase B.1 — estado cíclico (soulslike) do Teste de Ascensão da Guilda.
///
/// 1 row por par (player, rank perseguido). Complementa
/// `guild_ascension_progress` (rows por-step/prova): esta guarda o estado
/// de NÍVEL-CICLO (tentativas, falhas, custo pago, janela, cooldown,
/// status da máquina).
///
/// `rankFrom` no canon MAIÚSCULO ('E'..'A') — alinhado a `players.guild_rank`
/// (A.1). A lógica de pay/janela/deadline/ascend é B.2/B.3; B.1 só cria a
/// estrutura.
///
/// `status`: `locked` (gates não atingidos) → `payable` (pode pagar a fee)
/// → `active` (fee paga, janela rodando) → `done` (ascendeu) ou `cooldown`
/// (falhou a janela; aguarda `cooldown_until_ms`, custo +10% por falha).
class GuildAscensionStateTable extends Table {
  @override
  String get tableName => 'guild_ascension_state';

  IntColumn get playerId => integer()();

  /// Rank perseguido (rank_from do ciclo), canon MAIÚSCULO 'E'..'A'.
  TextColumn get rankFrom => text()();

  /// Tentativas pagas (incrementa a cada `pay`).
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Falhas (deadline vencido sem completar). Escala o custo: +10% por falha.
  IntColumn get failures => integer().withDefault(const Constant(0))();

  /// Custo (ouro) pago na tentativa corrente.
  IntColumn get paidCost => integer().withDefault(const Constant(0))();

  /// Bloqueio pós-falha (ms epoch). Null = sem cooldown ativo.
  IntColumn get cooldownUntilMs => integer().nullable()();

  /// Início da janela das provas (= momento do pagamento, ms epoch).
  IntColumn get windowStartedMs => integer().nullable()();

  /// Prazo das provas (ms epoch). Vencido sem completar → falha.
  IntColumn get windowDeadlineMs => integer().nullable()();

  /// Máquina de estados: locked | payable | active | cooldown | done.
  TextColumn get status => text().withDefault(const Constant('locked'))();

  @override
  Set<Column> get primaryKey => {playerId, rankFrom};
}
