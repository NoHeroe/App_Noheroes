import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/guild_status_table.dart';

part 'guild_dao.g.dart';

@DriftAccessor(tables: [GuildStatusTable])
class GuildDao extends DatabaseAccessor<AppDatabase> with _$GuildDaoMixin {
  GuildDao(super.db);

  Future<GuildStatusTableData?> getStatus(int playerId) =>
      (select(guildStatusTable)
            ..where((t) => t.playerId.equals(playerId)))
          .getSingleOrNull();

  Future<void> ensureExists(int playerId) async {
    final existing = await getStatus(playerId);
    if (existing == null) {
      await into(guildStatusTable).insert(
        GuildStatusTableCompanion(playerId: Value(playerId)),
      );
    }
  }

  Future<void> addGoldSpent(int playerId, int amount) async {
    await ensureExists(playerId);
    final status = await getStatus(playerId);
    if (status == null) return;
    await (update(guildStatusTable)
          ..where((t) => t.playerId.equals(playerId)))
        .write(GuildStatusTableCompanion(
      totalGoldSpent: Value(status.totalGoldSpent + amount),
    ));
  }

  Future<bool> hasCompletedAdmission(int playerId) async {
    final status = await getStatus(playerId);
    return status != null && status.guildRank != 'none';
  }

  Future<void> completeAdmission(int playerId) async {
    await ensureExists(playerId);
    await (update(guildStatusTable)
          ..where((t) => t.playerId.equals(playerId)))
        .write(GuildStatusTableCompanion(
      guildRank: const Value('e'),
      collarLevel: const Value(1),
      joinedAt: Value(DateTime.now()),
    ));
  }

  Future<void> addReputation(int playerId, int amount) async {
    await ensureExists(playerId);
    final status = await getStatus(playerId);
    if (status == null) return;
    await (update(guildStatusTable)
          ..where((t) => t.playerId.equals(playerId)))
        .write(GuildStatusTableCompanion(
      guildReputation: Value(status.guildReputation + amount),
    ));
  }
}
