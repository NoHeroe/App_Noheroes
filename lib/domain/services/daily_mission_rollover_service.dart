import 'package:supabase_flutter/supabase_flutter.dart';

/// Época 2 (ADR-0024) — port full-online do rollover.
///
/// O rollover inteiro virou a RPC `process_daily_rollover(uuid, bigint)`
/// (rpc_daily.sql), que encapsula server-side (evita N+1):
///   1. guard "primeira abertura do dia" via
///      `players.last_daily_mission_rollover`;
///   2. fecha pendentes/parciais com `data < hoje`:
///        - `auto_confirm_enabled` & todas subs 100%+ → auto-completed;
///        - `completedSubCount >= 1` → partial;
///        - senão → failed (sem reward);
///   3. streak: missões de ONTEM todas `completed` → +1, senão reset;
///      sem missões ontem → mantém;
///   4. marca `last_daily_mission_rollover = now`.
///
/// **Eventos:** a RPC fecha as missões internamente e NÃO publica eventos
/// (server-side). As branches partial/auto chamam
/// `apply_partial_daily_reward` / `apply_auto_completed_daily` no
/// servidor, então os listeners client-side de stats NÃO recebem
/// `DailyMissionCompleted`/`Failed` desse caminho. Ver 'risks' no resumo
/// — tracking de stats do rollover precisa de revisão (provavelmente via
/// a própria RPC alimentando as stats, ou re-fetch + replay).
class DailyMissionRolloverService {
  final SupabaseClient _client;

  DailyMissionRolloverService({required SupabaseClient client})
      : _client = client;

  Future<void> processRollover(String playerId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _client.rpc('process_daily_rollover', params: {
      'p_player': playerId,
      'p_now_ms': at.millisecondsSinceEpoch,
    });
  }
}
