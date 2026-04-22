import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;

import '../../../domain/models/active_faction_quest.dart';
import '../../../domain/repositories/active_faction_quests_repository.dart';
import '../../database/app_database.dart';

class ActiveFactionQuestsRepositoryDrift
    implements ActiveFactionQuestsRepository {
  final AppDatabase _db;
  ActiveFactionQuestsRepositoryDrift(this._db);

  ActiveFactionQuest _toDomain(ActiveFactionQuestData row) {
    return ActiveFactionQuest.fromJson({
      'id': row.id,
      'player_id': row.playerId,
      'faction_id': row.factionId,
      'mission_key': row.missionKey,
      'week_start': row.weekStart,
      'assigned_at': row.assignedAt,
    });
  }

  @override
  Future<ActiveFactionQuest?> findActiveFor(
    int playerId,
    String factionId,
    String weekStart,
  ) async {
    final row = await (_db.select(_db.activeFactionQuestsTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.factionId.equals(factionId) &
              t.weekStart.equals(weekStart)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<FactionWeeklyAssignment> upsertAtomic({
    required int playerId,
    required String factionId,
    required String missionKey,
    required String weekStart,
    required Map<String, dynamic> progressSeedJson,
  }) async {
    // Transação envolve as 2 inserções. Se o passo 2 falha, o ledger
    // volta via rollback. UNIQUE (player_id, faction_id, week_start) do
    // schema 24 garante idempotência sob race: se a segunda chamada
    // tentar inserir uma linha já persistida, o catch abaixo detecta e
    // retorna os ids já existentes.
    return _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      int ledgerId;
      try {
        ledgerId = await _db.into(_db.activeFactionQuestsTable).insert(
              ActiveFactionQuestsTableCompanion(
                playerId: Value(playerId),
                factionId: Value(factionId),
                missionKey: Value(missionKey),
                weekStart: Value(weekStart),
                assignedAt: Value(now),
              ),
            );
      } on SqliteException catch (e) {
        // Unique violation SQLite — outro caller venceu a corrida.
        if (e.extendedResultCode == 2067 /* SQLITE_CONSTRAINT_UNIQUE */ ||
            e.resultCode == 19 /* SQLITE_CONSTRAINT */ ||
            e.message.toLowerCase().contains('unique')) {
          final existing = await (_db.select(_db.activeFactionQuestsTable)
                ..where((t) =>
                    t.playerId.equals(playerId) &
                    t.factionId.equals(factionId) &
                    t.weekStart.equals(weekStart)))
              .getSingle();
          final existingProgress = await (_db
                  .select(_db.playerMissionProgressTable)
                ..where((t) =>
                    t.playerId.equals(playerId) &
                    t.missionKey.equals(existing.missionKey) &
                    t.tabOrigin.equals('faction') &
                    t.completedAt.isNull() &
                    t.failedAt.isNull()))
              .getSingle();
          return (
            ledgerId: existing.id,
            progressId: existingProgress.id,
          );
        }
        rethrow;
      }

      // Passo 2 — materializa a row de progresso dentro da mesma
      // transação. Reusa os campos do seed JSON; started_at e
      // reward_json devem vir preenchidos pelo caller (Bloco 14).
      final progressId =
          await _db.into(_db.playerMissionProgressTable).insert(
                PlayerMissionProgressTableCompanion(
                  playerId: Value(playerId),
                  missionKey: Value(missionKey),
                  modality: Value(progressSeedJson['modality'] as String),
                  tabOrigin: const Value('faction'),
                  rank: Value(progressSeedJson['rank'] as String),
                  targetValue:
                      Value(progressSeedJson['target_value'] as int),
                  currentValue: const Value(0),
                  rewardJson: Value(
                      progressSeedJson['reward_json'] as String? ??
                          jsonEncode(progressSeedJson['reward'])),
                  startedAt: Value(now),
                  metaJson: Value(
                      (progressSeedJson['meta_json'] as String?) ?? '{}'),
                ),
              );

      return (ledgerId: ledgerId, progressId: progressId);
    });
  }

  @override
  Future<int> deleteExpiredBefore(String weekStart) async {
    return (_db.delete(_db.activeFactionQuestsTable)
          ..where((t) => t.weekStart.isSmallerThanValue(weekStart)))
        .go();
  }
}
