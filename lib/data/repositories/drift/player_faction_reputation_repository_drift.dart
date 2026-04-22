import 'package:drift/drift.dart';

import '../../../domain/repositories/player_faction_reputation_repository.dart';
import '../../database/app_database.dart';

class PlayerFactionReputationRepositoryDrift
    implements PlayerFactionReputationRepository {
  final AppDatabase _db;
  PlayerFactionReputationRepositoryDrift(this._db);

  static const int _neutralDefault = 50;

  int _clamp(int value) {
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  @override
  Future<int> getOrDefault(int playerId, String factionId) async {
    final row = await (_db.select(_db.playerFactionReputationTable)
          ..where((t) =>
              t.playerId.equals(playerId) & t.factionId.equals(factionId)))
        .getSingleOrNull();
    return row?.reputation ?? _neutralDefault;
  }

  @override
  Future<Map<String, int>> findAllByPlayer(int playerId) async {
    final rows = await (_db.select(_db.playerFactionReputationTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    return {for (final r in rows) r.factionId: r.reputation};
  }

  @override
  Future<void> setAbsolute(
    int playerId,
    String factionId,
    int reputation,
  ) async {
    final clamped = _clamp(reputation);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.playerFactionReputationTable).insertOnConflictUpdate(
          PlayerFactionReputationTableCompanion(
            playerId: Value(playerId),
            factionId: Value(factionId),
            reputation: Value(clamped),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<void> delta(
    int playerId,
    String factionId,
    int delta,
  ) async {
    await _db.transaction(() async {
      final current = await getOrDefault(playerId, factionId);
      final next = _clamp(current + delta);
      await setAbsolute(playerId, factionId, next);
    });
  }
}
