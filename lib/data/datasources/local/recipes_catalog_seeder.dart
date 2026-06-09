import 'package:supabase_flutter/supabase_flutter.dart';

// OBSOLETO (Época 2 — full-online Supabase, ADR-0024).
//
// O catálogo de receitas agora vive no servidor (tabela recipes_catalog
// populada por migration/seed Postgres) — o seed client-side de
// assets/data/recipes.json não é mais necessário. seed() vira no-op.
//
// unlockStarterRecipesFor permanece como wrapper fino sobre a RPC
// public.unlock_starter_recipes(p_player uuid), que desbloqueia toda receita
// com unlock_sources contendo {"type":"starter"} de forma idempotente
// (on conflict do nothing) e retorna o nº de receitas efetivamente inseridas.
class RecipesCatalogSeeder {
  final SupabaseClient _client;
  RecipesCatalogSeeder(this._client);

  // OBSOLETO: catálogo é server-side. Mantido como stub pra não quebrar
  // call-sites de bootstrap legados.
  Future<void> seed() async {
    // no-op — recipes_catalog é populado no servidor.
  }

  // Desbloqueia todas as receitas 'starter' para o jogador via RPC atômica.
  // playerId é o jogador (uuid) -> String. Retorna o nº de receitas inseridas
  // nesta chamada (0 se todas já presentes ou em caso de erro).
  Future<int> unlockStarterRecipesFor(String playerId) async {
    try {
      final result = await _client.rpc(
        'unlock_starter_recipes',
        params: {'p_player': playerId},
      );
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (e) {
      // ignore: avoid_print
      print('[recipes_catalog_seeder] unlockStarterRecipesFor failed: $e');
      return 0;
    }
  }
}
