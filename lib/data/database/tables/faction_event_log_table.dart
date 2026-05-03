import 'package:drift/drift.dart';

/// Sprint 3.4 Etapa A — Log cronológico de eventos por (player, faction).
///
/// Histórico append-only consumido pela página `/faction/<id>` (Etapa E)
/// pra mostrar "últimas N entradas" — admissão iniciada, aprovada,
/// rejeitada, quest completada, saída, etc.
///
/// Não é o bus de eventos (`AppEventBus`); é persistência. Eventos
/// transitórios continuam no bus; entradas que importam pro player ver
/// "depois" entram aqui.
///
/// ## eventType (enum lógico — string pra evitar migration ao adicionar)
///
/// - `admission_started` — começou tentativa de admissão
/// - `admission_passed` — admissão aprovada
/// - `admission_rejected` — admissão reprovada (1+ quests falharam)
/// - `joined` — virou member (paralelo a `FactionJoined` no bus)
/// - `left` — saiu da facção (paralelo a `FactionLeft` no bus)
/// - `quest_completed` — completou quest semanal
/// - `quest_failed` — falhou quest semanal (expired no rollover)
/// - `reputation_milestone` — atingiu nível nomeado novo (Aliado/Leal/Devoto)
/// - `shop_purchase` — comprou item na loja (Etapa H)
///
/// ## payload (JSON string opaque)
///
/// Carrega contexto adicional. Schema flexível por eventType:
///
/// - `admission_*`: `{"attempt": N, "rep_before": X, "rep_after": Y}`
/// - `quest_*`: `{"mission_key": K, "currency_earned": N}`
/// - `shop_purchase`: `{"item_key": K, "price_currency": X, "price_gems": Y}`
@DataClassName('FactionEventLogData')
class FactionEventLogTable extends Table {
  @override
  String get tableName => 'faction_event_log';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get factionId => text()();
  TextColumn get eventType => text()();

  /// JSON serializado (string). Null se evento não carrega payload extra.
  TextColumn get payload => text().nullable()();

  /// ms epoch. Default = now no insert (caller passa `DateTime.now()`).
  IntColumn get createdAt => integer()();
}
