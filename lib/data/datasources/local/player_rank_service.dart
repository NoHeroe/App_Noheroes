import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/guild_rank.dart';
import '../../../core/utils/item_equip_policy.dart';

// Rank universal da Guilda (ADR 0009). Lê/escreve players.guild_rank com
// valores normalizados 'E'..'S' + 'none' como sentinela pra "sem rank".
//
// setRank + auto-evolução do Colar da Guilda é multi-write atômico → RPC
// `set_guild_rank`. getRank é leitura simples (PostgREST).
//
// attemptRankAscension é stub — lógica real entra na Sprint 3.4 (Guilda
// completa), que vai encher o Teste de Ascensão real.
class PlayerRankService {
  final SupabaseClient _client;
  PlayerRankService(this._client);

  Future<GuildRank?> getRank(String playerId) async {
    final row = await _client
        .from('players')
        .select('guild_rank')
        .eq('id', playerId)
        .maybeSingle();
    if (row == null) return null;
    return ItemEquipPolicy.parseRank(row['guild_rank'] as String?);
  }

  Future<void> setRank(String playerId, GuildRank? rank) async {
    // A RPC normaliza ('none'/uppercase) e auto-evolui o Colar da Guilda
    // (no-op se o jogador não o possui) na mesma transação. Passamos o rank
    // cru; null/'none' → sem rank.
    await _client.rpc('set_guild_rank', params: {
      'p_player': playerId,
      'p_rank': rank?.name.toUpperCase(),
    });
  }

  // TODO Sprint 3.4 — Teste de Ascensão real (guest progression, cooldowns,
  // missões encadeadas). Até lá, sempre falha.
  Future<bool> attemptRankAscension(String playerId) async {
    // ignore: avoid_print
    print('[player_rank_service] attemptRankAscension($playerId) — '
        'TODO Sprint 3.4 (Guilda completa)');
    return false;
  }
}
