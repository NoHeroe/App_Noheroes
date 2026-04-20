import 'package:drift/drift.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../database/app_database.dart';

// Rank universal da Guilda (ADR 0009). Lê/escreve players.guildRank com
// valores normalizados 'E'..'S' + 'none' como sentinela pra "sem rank".
//
// attemptRankAscension é stub — lógica real entra na Sprint 3.4 (Guilda
// completa), que vai encher o Teste de Ascensão real.
class PlayerRankService {
  final AppDatabase _db;
  PlayerRankService(this._db);

  Future<GuildRank?> getRank(int playerId) async {
    final row = await (_db.select(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .getSingleOrNull();
    if (row == null) return null;
    return ItemEquipPolicy.parseRank(row.guildRank);
  }

  Future<void> setRank(int playerId, GuildRank? rank) async {
    final value = rank == null ? 'none' : rank.name.toUpperCase();
    await (_db.update(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .write(PlayersTableCompanion(guildRank: Value(value)));

    // Auto-evolui o Colar da Guilda se o jogador o possui — o evolution_stage
    // do Colar segue o rank em tempo real. Se não houver Colar, no-op.
    await _evolveCollarIfPresent(playerId, rank);
  }

  static const String _collarKey = 'COLLAR_GUILD';

  Future<void> _evolveCollarIfPresent(int playerId, GuildRank? rank) async {
    final stageKey =
        rank == null ? 'stage_null' : 'stage_${rank.name.toUpperCase()}';
    await (_db.update(_db.playerInventoryTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.itemKey.equals(_collarKey)))
        .write(PlayerInventoryTableCompanion(
      evolutionStage: Value(stageKey),
    ));
  }

  // TODO Sprint 3.4 — Teste de Ascensão real (guest progression, cooldowns,
  // missões encadeadas). Até lá, sempre falha.
  Future<bool> attemptRankAscension(int playerId) async {
    // ignore: avoid_print
    print('[player_rank_service] attemptRankAscension($playerId) — '
        'TODO Sprint 3.4 (Guilda completa)');
    return false;
  }
}
