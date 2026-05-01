/// Sprint 3.3 Etapa 2.1c-δ — formatação canônica de "dia civil" usada
/// em todo o subsistema de daily missions.
///
/// Padrão `YYYY-MM-DD` em horário local do device, idêntico ao usado em
/// `daily_missions.data`, `lastActiveDay` e `lastPilarBalanceDay`.
/// Sistema PARALELO ao `caelum_day` (lore narrativa em `players`) — este
/// helper não toca em caelum_day.
///
/// Extraído de `DailyMissionStatsService._formatDay` na Etapa 2.1c-δ pra
/// permitir uso compartilhado pelo `AchievementsService` (validador do
/// trigger `daily_today_count` precisa do mesmo helper sem acoplar a
/// `DailyMissionStatsService`).
String formatDay(DateTime ts) {
  final y = ts.year.toString().padLeft(4, '0');
  final m = ts.month.toString().padLeft(2, '0');
  final d = ts.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
