import '../enums/mission_tab_origin.dart';
import '../models/mission_progress.dart';

/// Sprint 3.1 Bloco 4 — Repository das missões em progresso
/// (`player_mission_progress`).
///
/// Interface abstrata da camada de domínio (ADR 0016). Hoje existe apenas
/// a implementação `MissionRepositoryDrift`. Quando a Época Supabase
/// chegar, uma segunda impl é adicionada e o `missionRepositoryProvider`
/// troca de 1 linha.
abstract class MissionRepository {
  /// Missão por id. `null` se não existe.
  Future<MissionProgress?> findById(int id);

  /// Todas as missões em andamento do jogador
  /// (completed_at IS NULL AND failed_at IS NULL).
  Future<List<MissionProgress>> findActive(int playerId);

  /// Missões do jogador numa aba específica, em qualquer estado
  /// (ativa, completa, falha) — ordenação temporal reversa por
  /// started_at.
  Future<List<MissionProgress>> findByTab(
    int playerId,
    MissionTabOrigin tab,
  );

  /// Sprint 3.1 Bloco 10a.1 — missões não-ativas (completadas OU falhadas)
  /// de **todas** as abas. Alimenta a aba Histórico de `/quests` (Bloco 12
  /// refina integração com drawer Santuário). Ordenação DESC pelo
  /// timestamp de conclusão/falha — `coalesce(completed_at, failed_at)`
  /// garante que missões falhadas também entrem, mais recentes primeiro.
  Future<List<MissionProgress>> findHistorical(int playerId);

  /// Sprint 3.1 Bloco 12 — missões não-ativas cujo encerramento
  /// (`completed_at` OU `failed_at`) caiu na janela `[from, to]`
  /// **inclusivo**. Alimenta o `WeeklyMissionsChart` + `MissionCounters`
  /// da aba Histórico.
  ///
  /// Janela típica: últimos 7 dias (gráfico semanal) ou últimos 30 dias
  /// (lista padrão). Hoje/Semana no counters derivam da mesma lista
  /// retornada — evita queries duplicadas.
  ///
  /// Ordenação DESC por `COALESCE(completed_at, failed_at)`.
  Future<List<MissionProgress>> findCompletedInWindow(
    int playerId, {
    required DateTime from,
    required DateTime to,
  });

  /// Stream reativa das missões ativas — consumida pela UI do Bloco 10
  /// pra animar barras e popups. Emite nova lista em cada mudança de row.
  Stream<List<MissionProgress>> watchActive(int playerId);

  /// Insere nova missão em progresso. Retorna o id gerado.
  Future<int> insert(MissionProgress progress);

  /// Atualiza `current_value` (e opcionalmente `meta_json` pra
  /// sub-tasks da família mixed).
  Future<void> updateProgress(
    int id, {
    required int currentValue,
    String? metaJson,
  });

  /// Marca a missão como completa em [at].
  ///
  /// **ADR 0011 — atomicidade obrigatória**: este método deve ser
  /// chamado DENTRO de um `db.transaction` do chamador, junto com a
  /// persistência da reward (currency increments + items adicionados +
  /// recipes unlocked). Chamadas diretas sem `db.transaction` violam o
  /// ADR 0011 e podem deixar a missão "feita sem ganho" se o processo
  /// crashar entre o mark e o grant.
  ///
  /// O chamador canônico é `RewardGrantService.grant` (Bloco 5) que
  /// orquestra:
  ///
  /// ```dart
  /// await db.transaction(() async {
  ///   await missionRepository.markCompleted(id, at: now, rewardClaimed: true);
  ///   await rewardGrantService._persist(resolved); // currency + items
  /// });
  /// ```
  Future<void> markCompleted(
    int id, {
    required DateTime at,
    required bool rewardClaimed,
  });

  /// Marca a missão como falha em [at]. `current_value` preservado pra
  /// histórico (Bloco 12). Idêntica semântica transacional de
  /// [markCompleted] quando a falha for parcial com reward proporcional
  /// (Diárias 25-99%).
  Future<void> markFailed(int id, {required DateTime at});
}
