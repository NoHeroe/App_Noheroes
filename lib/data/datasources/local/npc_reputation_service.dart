import 'package:drift/drift.dart';
import '../../database/app_database.dart';

enum NpcRepLevel { hostile, distrustful, neutral, ally, loyal, devout }

class NpcReputationService {
  final AppDatabase _db;
  static const _dailyLimit = 20;

  NpcReputationService(this._db);

  static NpcRepLevel levelFromValue(int value) {
    if (value <= 20) return NpcRepLevel.hostile;
    if (value <= 40) return NpcRepLevel.distrustful;
    if (value <= 60) return NpcRepLevel.neutral;
    if (value <= 75) return NpcRepLevel.ally;
    if (value <= 90) return NpcRepLevel.loyal;
    return NpcRepLevel.devout;
  }

  static String labelFromLevel(NpcRepLevel level) => switch (level) {
        NpcRepLevel.hostile     => 'Hostil',
        NpcRepLevel.distrustful => 'Desconfiado',
        NpcRepLevel.neutral     => 'Neutro',
        NpcRepLevel.ally        => 'Aliado',
        NpcRepLevel.loyal       => 'Leal',
        NpcRepLevel.devout      => 'Devoto',
      };

  static String levelKey(NpcRepLevel level) => switch (level) {
        NpcRepLevel.hostile     => 'hostile',
        NpcRepLevel.distrustful => 'distrustful',
        NpcRepLevel.neutral     => 'neutral',
        NpcRepLevel.ally        => 'ally',
        NpcRepLevel.loyal       => 'loyal',
        NpcRepLevel.devout      => 'devout',
      };

  Future<NpcReputationTableData> _ensure(int playerId, String npcId) async {
    final existing = await (_db.select(_db.npcReputationTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.npcId.equals(npcId)))
        .getSingleOrNull();
    if (existing != null) return existing;
    await _db.into(_db.npcReputationTable).insert(
      NpcReputationTableCompanion(
        playerId: Value(playerId),
        npcId: Value(npcId),
      ),
    );
    return (await (_db.select(_db.npcReputationTable)
              ..where((t) => t.playerId.equals(playerId))
              ..where((t) => t.npcId.equals(npcId)))
            .getSingleOrNull())!;
  }

  Future<NpcReputationTableData> get(int playerId, String npcId) =>
      _ensure(playerId, npcId);

  Future<List<NpcReputationTableData>> getAll(int playerId) {
    return (_db.select(_db.npcReputationTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
  }

  /// Adiciona reputação respeitando limite diário de +20
  Future<int> addReputation(int playerId, String npcId, int amount) async {
    final row = await _ensure(playerId, npcId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Reset diário
    int dailyGained = row.dailyGained;
    if (row.lastGainAt == null ||
        DateTime(row.lastGainAt!.year, row.lastGainAt!.month,
                row.lastGainAt!.day)
            .isBefore(today)) {
      dailyGained = 0;
    }

    final remaining = _dailyLimit - dailyGained;
    if (remaining <= 0) return 0;

    final actual = amount.clamp(0, remaining);
    final newRep = (row.reputation + actual).clamp(0, 100);

    await (_db.update(_db.npcReputationTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.npcId.equals(npcId)))
        .write(NpcReputationTableCompanion(
      reputation: Value(newRep),
      lastGainAt: Value(now),
      dailyGained: Value(dailyGained + actual),
    ));

    return actual;
  }

  Future<void> loseReputation(int playerId, String npcId, int amount) async {
    final row = await _ensure(playerId, npcId);
    final newRep = (row.reputation - amount).clamp(0, 100);
    await (_db.update(_db.npcReputationTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.npcId.equals(npcId)))
        .write(NpcReputationTableCompanion(
      reputation: Value(newRep),
    ));
  }
}
