import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';

Future<int> _seedMission(
  MissionRepositoryDrift repo,
  int playerId, {
  DateTime? completedAt,
  DateTime? failedAt,
  DateTime? startedAt,
}) async {
  return repo.insert(MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: 'M${DateTime.now().microsecondsSinceEpoch}',
    modality: MissionModality.real,
    tabOrigin: MissionTabOrigin.daily,
    rank: GuildRank.e,
    targetValue: 10,
    currentValue: 10,
    reward: const RewardDeclared(xp: 10),
    startedAt: startedAt ?? DateTime.now().subtract(const Duration(days: 10)),
    completedAt: completedAt,
    failedAt: failedAt,
    rewardClaimed: false,
    metaJson: '{}',
  ));
}

Future<void> _updateTimestamps(
  AppDatabase db,
  int id, {
  int? completedAt,
  int? failedAt,
}) async {
  if (completedAt != null) {
    await db.customUpdate(
      'UPDATE player_mission_progress SET completed_at = ? WHERE id = ?',
      variables: [Variable.withInt(completedAt), Variable.withInt(id)],
      updates: {db.playerMissionProgressTable},
    );
  }
  if (failedAt != null) {
    await db.customUpdate(
      'UPDATE player_mission_progress SET failed_at = ? WHERE id = ?',
      variables: [Variable.withInt(failedAt), Variable.withInt(id)],
      updates: {db.playerMissionProgressTable},
    );
  }
}

void main() {
  late AppDatabase db;
  late MissionRepositoryDrift repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MissionRepositoryDrift(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MissionRepository.findCompletedInWindow', () {
    test('retorna completed+failed dentro da janela DESC', () async {
      const playerId = 1;
      final now = DateTime.now();
      // Dentro janela: 2 dias atrás (completed) + 3 dias atrás (failed)
      final mId1 = await _seedMission(repo, playerId);
      await _updateTimestamps(db, mId1,
          completedAt: now
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch);
      final mId2 = await _seedMission(repo, playerId);
      await _updateTimestamps(db, mId2,
          failedAt: now
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch);
      // Fora janela: 30 dias atrás
      final mId3 = await _seedMission(repo, playerId);
      await _updateTimestamps(db, mId3,
          completedAt: now
              .subtract(const Duration(days: 30))
              .millisecondsSinceEpoch);
      // Ativa (não entra)
      await _seedMission(repo, playerId);

      final list = await repo.findCompletedInWindow(
        playerId,
        from: now.subtract(const Duration(days: 7)),
        to: now,
      );
      expect(list.length, 2);
      // DESC: 2 dias atrás antes de 3 dias atrás
      expect(list[0].id, mId1);
      expect(list[1].id, mId2);
    });

    test('janela vazia (nenhuma missão) retorna lista vazia', () async {
      final now = DateTime.now();
      final list = await repo.findCompletedInWindow(
        1,
        from: now.subtract(const Duration(days: 7)),
        to: now,
      );
      expect(list, isEmpty);
    });
  });
}
