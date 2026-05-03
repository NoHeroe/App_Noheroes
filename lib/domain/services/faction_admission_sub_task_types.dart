/// Sprint 3.4 Etapa B (Sub-Etapa B.1) — strings canônicas dos 11
/// sub-types de sub-task do `FactionAdmissionValidator`.
///
/// Mantidos em uma classe abstract (sem instância) pra evitar typos
/// quando referenciados em `faction_admission_quests_v2.json`, testes
/// e docs.
///
/// ## Por que NÃO reusar `AchievementTriggerTypes`?
///
/// Triggers de conquista são **all-time monotônicos** — resolvem
/// `stats.totalCompleted >= target`. Sub-tasks de admissão precisam de
/// **janela móvel desde unlock da missão** (ex.: "5 dailies físicas em
/// 48h após desbloquear esta missão de admissão"). A semântica é
/// fundamentalmente diferente; criar tipos paralelos preserva a
/// pureza do AchievementsService e evita coupling cruzado.
///
/// Cada sub-type tem:
/// - **Query SQL própria** em `FactionAdmissionValidator._evaluate`
/// - **Janela** = `metaJson.window_start_ms` (timestamp ms quando a
///   missão de admissão foi desbloqueada)
/// - **Snapshot rank opcional** = `metaJson.snapshot_rank` (player.
///   guildRank no momento de unlock; usado em filtros que dependem
///   de rank)
abstract class FactionAdmissionSubTaskTypes {
  FactionAdmissionSubTaskTypes._();

  /// "Completar N dailies de modalidade X em janela Y".
  /// `params`:
  ///   - `modalidade`: `String?` (`fisico`/`mental`/`espiritual`/
  ///     `vitalismo`); null = qualquer modalidade
  ///   - opcional `respect_snapshot_rank`: bool — se true, conta
  ///     apenas dailies completadas com `player.guildRank >=
  ///     snapshot_rank` (D2 do plan-first)
  static const String dailyCountWindow =
      'admission_daily_count_window';

  /// "0 falhas em janela Y" (D1: niet = failed).
  /// Sucesso = COUNT(daily_missions WHERE status='failed' AND
  /// completed_at >= window_start) == 0.
  static const String zeroFailedWindow =
      'admission_zero_failed_window';

  /// "100% dailies em 1 dia" (existir um dia onde TODAS as 3 dailies
  /// do player foram `completed`).
  static const String fullPerfectDayWindow =
      'admission_full_perfect_day_window';

  /// "1+ missão individual completada na janela".
  static const String individualCompletedWindow =
      'admission_individual_completed_window';

  /// "1+ entrada de diário escrita na janela".
  static const String diaryEntryWindow =
      'admission_diary_entry_window';

  /// "0 missões de modalidade X completadas na janela" (Trindade
  /// "Jejum do Conhecimento"). `params.modalidade` obrigatório.
  static const String zeroCategoryWindow =
      'admission_zero_category_window';

  /// "Streak de dailies >= target" (verifica
  /// `players.daily_missions_streak`). Sem janela — é um snapshot do
  /// estado atual do streak.
  static const String streakMinimum = 'admission_streak_minimum';

  /// "Acumular X+ ouro via quests na janela". Usa
  /// `players.total_gold_earned_via_quests` com baseline snapshot
  /// no unlock. Validador faz `current - baseline >= target`.
  static const String goldEarnedViaQuestsWindow =
      'admission_gold_earned_via_quests_window';

  /// "Ter X+ gold no inventário em algum momento da janela" (D4
  /// substituição de "1 compra"). Validador captura snapshot de
  /// `players.gold` em cada evento terminal e marca completo se já
  /// atingiu pelo menos uma vez.
  static const String goldBalanceThreshold =
      'admission_gold_balance_threshold';

  /// "1+ dia sem partial completion" (existir um dia onde todas as
  /// dailies do player têm `status='completed'` E zero `partial`).
  static const String noPartialDayWindow =
      'admission_no_partial_day_window';

  /// "Completar EXATAMENTE N dailies na janela" (Renegado "Caminho
  /// Próprio" — não-monótono: ultrapassar threshold = falha).
  /// Validador retorna **false** se `count > target` (já queimou).
  /// Cardinal exact: `count == target` na janela.
  static const String exactDailyCountWindow =
      'admission_exact_daily_count_window';

  /// Set de todos os sub-types — usado pelo parser pra validar JSON
  /// de catálogo (rejeita sub-types desconhecidos com
  /// `FormatException` em vez de silenciosamente ignorar).
  static const Set<String> all = {
    dailyCountWindow,
    zeroFailedWindow,
    fullPerfectDayWindow,
    individualCompletedWindow,
    diaryEntryWindow,
    zeroCategoryWindow,
    streakMinimum,
    goldEarnedViaQuestsWindow,
    goldBalanceThreshold,
    noPartialDayWindow,
    exactDailyCountWindow,
  };
}
