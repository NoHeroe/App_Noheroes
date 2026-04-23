import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_context.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';

/// Helpers compartilhados dos testes de strategy.
MissionContext ctx({
  int missionProgressId = 1,
  int playerId = 42,
  String missionKey = 'TEST',
  MissionModality modality = MissionModality.internal,
  MissionTabOrigin tab = MissionTabOrigin.classTab,
  int current = 0,
  int target = 3,
  String metaJson = '{}',
}) {
  return MissionContext(
    missionProgressId: missionProgressId,
    playerId: playerId,
    missionKey: missionKey,
    modality: modality,
    tabOrigin: tab,
    currentValue: current,
    targetValue: target,
    rewardDeclared: const RewardDeclared(xp: 100, gold: 50),
    metaJson: metaJson,
  );
}

MissionProgress mission({
  int id = 1,
  int playerId = 42,
  String key = 'TEST',
  MissionModality modality = MissionModality.internal,
  MissionTabOrigin tab = MissionTabOrigin.classTab,
  GuildRank rank = GuildRank.e,
  int target = 3,
  int current = 0,
  String metaJson = '{}',
  DateTime? completedAt,
  DateTime? failedAt,
  bool rewardClaimed = false,
}) {
  return MissionProgress(
    id: id,
    playerId: playerId,
    missionKey: key,
    modality: modality,
    tabOrigin: tab,
    rank: rank,
    targetValue: target,
    currentValue: current,
    reward: const RewardDeclared(xp: 100, gold: 50),
    startedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    completedAt: completedAt,
    failedAt: failedAt,
    rewardClaimed: rewardClaimed,
    metaJson: metaJson,
  );
}
