import 'package:drift/drift.dart';

import '../../../domain/enums/mission_category.dart';
import '../../../domain/models/individual_mission_spec.dart';
import '../../../domain/repositories/player_individual_missions_repository.dart';
import '../../database/app_database.dart';

class PlayerIndividualMissionsRepositoryDrift
    implements PlayerIndividualMissionsRepository {
  final AppDatabase _db;
  PlayerIndividualMissionsRepositoryDrift(this._db);

  IndividualMissionSpec _toDomain(PlayerIndividualMissionData row) {
    return IndividualMissionSpec.fromJson({
      'id': row.id,
      'player_id': row.playerId,
      'name': row.name,
      'description': row.description,
      'category': row.category,
      'intensity_index': row.intensityIndex,
      'frequency': row.frequency,
      'repeats': row.repeats,
      'reward_json': row.rewardJson,
      'created_at': row.createdAt,
      'deleted_at': row.deletedAt,
      'completion_count': row.completionCount,
      'failure_count': row.failureCount,
    });
  }

  @override
  Future<List<IndividualMissionSpec>> findActive(int playerId) async {
    final query = _db.select(_db.playerIndividualMissionsTable)
      ..where((t) => t.playerId.equals(playerId))
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<IndividualMissionSpec?> findById(int id) async {
    final row = await (_db.select(_db.playerIndividualMissionsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<int> insert(IndividualMissionSpec mission) async {
    return _db.into(_db.playerIndividualMissionsTable).insert(
          PlayerIndividualMissionsTableCompanion(
            playerId: Value(mission.playerId),
            name: Value(mission.name),
            description: mission.description == null
                ? const Value.absent()
                : Value(mission.description),
            category: Value(mission.category.storage),
            intensityIndex: Value(mission.intensityIndex),
            frequency: Value(mission.frequency.storage),
            repeats: Value(mission.repeats),
            rewardJson: Value(mission.reward.toJsonString()),
            createdAt: Value(mission.createdAt.millisecondsSinceEpoch),
            deletedAt: mission.deletedAt == null
                ? const Value.absent()
                : Value(mission.deletedAt!.millisecondsSinceEpoch),
            completionCount: Value(mission.completionCount),
            failureCount: Value(mission.failureCount),
          ),
        );
  }

  @override
  Future<void> updateCounters(
    int id, {
    required int completionCount,
    required int failureCount,
  }) async {
    await (_db.update(_db.playerIndividualMissionsTable)
          ..where((t) => t.id.equals(id)))
        .write(PlayerIndividualMissionsTableCompanion(
      completionCount: Value(completionCount),
      failureCount: Value(failureCount),
    ));
  }

  @override
  Future<void> softDelete(int id, {required DateTime at}) async {
    await (_db.update(_db.playerIndividualMissionsTable)
          ..where((t) => t.id.equals(id)))
        .write(PlayerIndividualMissionsTableCompanion(
      deletedAt: Value(at.millisecondsSinceEpoch),
    ));
  }

  @override
  Future<int> countActive(int playerId) async {
    final count = _db.playerIndividualMissionsTable.id.count();
    final query = _db.selectOnly(_db.playerIndividualMissionsTable)
      ..addColumns([count])
      ..where(_db.playerIndividualMissionsTable.playerId.equals(playerId) &
          _db.playerIndividualMissionsTable.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}
