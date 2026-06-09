import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/player.dart';
import '../../../domain/repositories/player_repository.dart';

/// Implementação Supabase do [PlayerRepository] (Época 2 — ADR-0024).
/// Lê/escreve `players` via PostgREST. RLS (`auth.uid() = id`) garante que o
/// cliente só acessa a própria row.
class PlayerRepositorySupabase implements PlayerRepository {
  final SupabaseClient _client;
  PlayerRepositorySupabase(this._client);

  @override
  Future<Player?> fetchById(String id) async {
    final row =
        await _client.from('players').select().eq('id', id).maybeSingle();
    return row == null ? null : Player.fromMap(row);
  }

  @override
  Future<Player?> fetchCurrent() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return fetchById(uid);
  }

  @override
  Future<void> updateFields(String id, Map<String, dynamic> patch) async {
    await _client.from('players').update(patch).eq('id', id);
  }

  @override
  Future<void> completeOnboarding(
      String id, String shadowName, String narrativeMode) async {
    await _client.from('players').update({
      'onboarding_done': true,
      'shadow_name': shadowName,
      'narrative_mode': narrativeMode,
    }).eq('id', id);
  }
}
