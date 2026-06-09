// OBSOLETO — Época 2 full-online (ADR-0024).
//
// A implementação Drift de PlayerAchievementsRepository foi substituída por
// PlayerAchievementsRepositorySupabase
// (lib/data/repositories/supabase/player_achievements_repository_supabase.dart).
//
// O contrato PlayerAchievementsRepository migrou `playerId` de int -> String
// (uuid), então a antiga implementação Drift (int playerId + AppDatabase) não
// satisfaz mais a interface. Mantido como arquivo-tumba até o provider
// (lib/app/providers.dart) ser religado pra apontar na impl Supabase; pode ser
// removido do repo em seguida.
//
// Toda a lógica anterior vivia em queries Drift sobre
// `player_achievements_completed` — hoje a tabela é Postgres (player_id uuid)
// e o acesso é PostgREST direto na impl Supabase.
