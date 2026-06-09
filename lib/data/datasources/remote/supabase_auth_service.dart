import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/player.dart';
import '../../../domain/repositories/player_repository.dart';

/// Auth full-online via Supabase Auth (Época 2 — ADR-0024). Substitui o
/// `AuthLocalDs` (sha256 + SharedPreferences + Drift).
///
/// - `register`: `auth.signUp`. A row em `players` é criada pelo trigger
///   `handle_new_user` (que também desbloqueia as receitas starter), então
///   aqui só buscamos o Player resultante.
/// - `login`: `auth.signInWithPassword` + RPC `touch_last_login` (streak/dia).
/// - `currentSession`: lê `auth.currentUser` (sessão persistida pelo
///   supabase_flutter) e carrega o Player.
/// - Erros viram `AuthException` (não mais `null`) — as telas devem tratar.
class SupabaseAuthService {
  final SupabaseClient _client;
  final PlayerRepository _players;
  SupabaseAuthService(this._client, this._players);

  Future<Player?> register({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(
      email: email.toLowerCase().trim(),
      password: password,
    );
    final user = res.user;
    if (user == null) return null;
    // players row + starter recipes criadas server-side pelo trigger
    // handle_new_user; busca o resultado.
    return _players.fetchById(user.id);
  }

  Future<Player?> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email.toLowerCase().trim(),
      password: password,
    );
    final user = res.user;
    if (user == null) return null;
    await _client.rpc('touch_last_login', params: {'p_player': user.id});
    return _players.fetchById(user.id);
  }

  Future<Player?> currentSession() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    await _client.rpc('touch_last_login', params: {'p_player': uid});
    return _players.fetchById(uid);
  }

  Future<void> logout() => _client.auth.signOut();

  Future<void> completeOnboarding(
    String id,
    String shadowName,
    String narrativeMode,
  ) =>
      _players.completeOnboarding(id, shadowName, narrativeMode);
}
