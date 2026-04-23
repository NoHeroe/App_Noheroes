import 'package:drift/drift.dart';

import '../../../domain/enums/mission_modality.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/repositories/mission_repository.dart';
import '../../database/app_database.dart';

class MissionRepositoryDrift implements MissionRepository {
  final AppDatabase _db;
  MissionRepositoryDrift(this._db);

  /// Row Drift → domain model. Reusa `MissionProgress.fromJson` do
  /// Bloco 3 passando os campos da row como map.
  MissionProgress _toDomain(PlayerMissionProgressData row) {
    return MissionProgress.fromJson({
      'id': row.id,
      'player_id': row.playerId,
      'mission_key': row.missionKey,
      'modality': row.modality,
      'tab_origin': row.tabOrigin,
      'rank': row.rank,
      'target_value': row.targetValue,
      'current_value': row.currentValue,
      'reward_json': row.rewardJson,
      'started_at': row.startedAt,
      'completed_at': row.completedAt,
      'failed_at': row.failedAt,
      'reward_claimed': row.rewardClaimed,
      'meta_json': row.metaJson,
    });
  }

  @override
  Future<MissionProgress?> findById(int id) async {
    final row = await (_db.select(_db.playerMissionProgressTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<MissionProgress>> findActive(int playerId) async {
    final query = _db.select(_db.playerMissionProgressTable)
      ..where((t) => t.playerId.equals(playerId))
      ..where((t) => t.completedAt.isNull() & t.failedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<MissionProgress>> findByTab(
    int playerId,
    MissionTabOrigin tab,
  ) async {
    final query = _db.select(_db.playerMissionProgressTable)
      ..where((t) => t.playerId.equals(playerId))
      ..where((t) => t.tabOrigin.equals(tab.storage))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<MissionProgress>> findHistorical(int playerId) async {
    // Ordenação DESC por coalesce(completed_at, failed_at). Drift não
    // expõe coalesce direto na DSL; usa customSelect pra SQL literal.
    // Missões com ambos nulos (ativas) são filtradas pelo WHERE.
    final rows = await _db.customSelect(
      'SELECT * FROM player_mission_progress '
      'WHERE player_id = ? '
      'AND (completed_at IS NOT NULL OR failed_at IS NOT NULL) '
      'ORDER BY COALESCE(completed_at, failed_at) DESC',
      variables: [Variable.withInt(playerId)],
      readsFrom: {_db.playerMissionProgressTable},
    ).get();
    return rows
        .map((row) => _toDomain(PlayerMissionProgressData(
              id: row.read<int>('id'),
              playerId: row.read<int>('player_id'),
              missionKey: row.read<String>('mission_key'),
              modality: row.read<String>('modality'),
              tabOrigin: row.read<String>('tab_origin'),
              rank: row.read<String>('rank'),
              targetValue: row.read<int>('target_value'),
              currentValue: row.read<int>('current_value'),
              rewardJson: row.read<String>('reward_json'),
              startedAt: row.read<int>('started_at'),
              completedAt: row.readNullable<int>('completed_at'),
              failedAt: row.readNullable<int>('failed_at'),
              rewardClaimed: row.read<bool>('reward_claimed'),
              metaJson: row.read<String>('meta_json'),
            )))
        .toList(growable: false);
  }

  @override
  Future<List<MissionProgress>> findCompletedInWindow(
    int playerId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _db.customSelect(
      'SELECT * FROM player_mission_progress '
      'WHERE player_id = ? '
      'AND (completed_at IS NOT NULL OR failed_at IS NOT NULL) '
      'AND COALESCE(completed_at, failed_at) BETWEEN ? AND ? '
      'ORDER BY COALESCE(completed_at, failed_at) DESC',
      variables: [
        Variable.withInt(playerId),
        Variable.withInt(from.millisecondsSinceEpoch),
        Variable.withInt(to.millisecondsSinceEpoch),
      ],
      readsFrom: {_db.playerMissionProgressTable},
    ).get();
    return rows
        .map((row) => _toDomain(PlayerMissionProgressData(
              id: row.read<int>('id'),
              playerId: row.read<int>('player_id'),
              missionKey: row.read<String>('mission_key'),
              modality: row.read<String>('modality'),
              tabOrigin: row.read<String>('tab_origin'),
              rank: row.read<String>('rank'),
              targetValue: row.read<int>('target_value'),
              currentValue: row.read<int>('current_value'),
              rewardJson: row.read<String>('reward_json'),
              startedAt: row.read<int>('started_at'),
              completedAt: row.readNullable<int>('completed_at'),
              failedAt: row.readNullable<int>('failed_at'),
              rewardClaimed: row.read<bool>('reward_claimed'),
              metaJson: row.read<String>('meta_json'),
            )))
        .toList(growable: false);
  }

  @override
  Stream<List<MissionProgress>> watchActive(int playerId) {
    final query = _db.select(_db.playerMissionProgressTable)
      ..where((t) => t.playerId.equals(playerId))
      ..where((t) => t.completedAt.isNull() & t.failedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]);
    return query.watch().map(
        (rows) => rows.map(_toDomain).toList(growable: false));
  }

  @override
  Future<int> insert(MissionProgress progress) async {
    return _db.into(_db.playerMissionProgressTable).insert(
          PlayerMissionProgressTableCompanion(
            playerId: Value(progress.playerId),
            missionKey: Value(progress.missionKey),
            modality: Value(progress.modality.storage),
            tabOrigin: Value(progress.tabOrigin.storage),
            rank: Value(progress.rank.name),
            targetValue: Value(progress.targetValue),
            currentValue: Value(progress.currentValue),
            rewardJson: Value(progress.reward.toJsonString()),
            startedAt: Value(progress.startedAt.millisecondsSinceEpoch),
            completedAt: progress.completedAt == null
                ? const Value.absent()
                : Value(progress.completedAt!.millisecondsSinceEpoch),
            failedAt: progress.failedAt == null
                ? const Value.absent()
                : Value(progress.failedAt!.millisecondsSinceEpoch),
            rewardClaimed: Value(progress.rewardClaimed),
            metaJson: Value(progress.metaJson),
          ),
        );
  }

  @override
  Future<void> updateProgress(
    int id, {
    required int currentValue,
    String? metaJson,
  }) async {
    await (_db.update(_db.playerMissionProgressTable)
          ..where((t) => t.id.equals(id)))
        .write(PlayerMissionProgressTableCompanion(
      currentValue: Value(currentValue),
      metaJson: metaJson == null ? const Value.absent() : Value(metaJson),
    ));
  }

  @override
  Future<void> markCompleted(
    int id, {
    required DateTime at,
    required bool rewardClaimed,
  }) async {
    await (_db.update(_db.playerMissionProgressTable)
          ..where((t) => t.id.equals(id)))
        .write(PlayerMissionProgressTableCompanion(
      completedAt: Value(at.millisecondsSinceEpoch),
      rewardClaimed: Value(rewardClaimed),
    ));
  }

  @override
  Future<void> markFailed(int id, {required DateTime at}) async {
    await (_db.update(_db.playerMissionProgressTable)
          ..where((t) => t.id.equals(id)))
        .write(PlayerMissionProgressTableCompanion(
      failedAt: Value(at.millisecondsSinceEpoch),
    ));
  }
}
