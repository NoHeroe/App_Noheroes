import 'package:drift/drift.dart';

/// Sprint 3.2 Etapa 1.2 — missões diárias geradas dinamicamente.
///
/// Schema 27. Cada player tem (até) 3 missões por dia, sorteadas pelo
/// `DailyMissionGeneratorService` a partir dos pools da Etapa 1.1
/// (`assets/data/daily_pool_*.json`).
///
/// `sub_tarefas_json` armazena `List<DailySubTaskInstance>` serializada —
/// cardinalidade fixa em 3 por missão; evita join secundário e mantém o
/// snapshot dos campos visíveis (nomeVisivel, escalaAlvo, unidade) imune
/// a mudanças no JSON canônico.
///
/// `sub_categoria` é null quando `modalidade == 'vitalismo'` (Vitalismo
/// pega 1 sub-tarefa de cada pilar, sem sub-categoria única).
@TableIndex(name: 'idx_daily_missions_player_data',
    columns: {#playerId, #data})
class DailyMissionsTable extends Table {
  @override
  String get tableName => 'daily_missions';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get data => text()(); // YYYY-MM-DD
  TextColumn get modalidade => text()();
  TextColumn get subCategoria => text().nullable()();
  TextColumn get tituloKey => text()();
  TextColumn get tituloResolvido => text()();
  TextColumn get quoteResolvida => text()();
  TextColumn get subTarefasJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  BoolColumn get rewardClaimed => boolean().withDefault(const Constant(false))();

  /// Sprint 3.3 Etapa 2.1c-β — flag setada quando o rollover detecta
  /// `players.auto_confirm_enabled=true` E todas as sub-tarefas em 100%
  /// → `applyAutoCompleted` marca missão como `completed` sem exigir
  /// clique manual. Propagado via `DailyMissionCompleted.wasAutoConfirmed`
  /// pro listener de stats (alimenta trigger `daily_auto_confirm_count`
  /// + anti-cheese de `total_zero_progress_manual_confirms`).
  ///
  /// Default false. Confirmações manuais via `confirmCompletion` mantêm
  /// false. Migrações 27→30 deixaram coluna ausente → schema 31 adiciona.
  BoolColumn get wasAutoConfirmed =>
      boolean().withDefault(const Constant(false))();
}
