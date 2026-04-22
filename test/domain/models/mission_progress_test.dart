import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';

Map<String, dynamic> _pendingFixture() => {
      'id': 1,
      'player_id': 42,
      'mission_key': 'DAILY_PUSHUPS_E',
      'modality': 'real',
      'tab_origin': 'daily',
      'rank': 'e',
      'target_value': 20,
      'current_value': 0,
      'reward_json': '{"xp":100,"gold":50}',
      'started_at': 1700000000000,
      'completed_at': null,
      'failed_at': null,
      'reward_claimed': false,
      'meta_json': '{}',
    };

void main() {
  group('MissionProgress — fromJson / toJson round-trip', () {
    test('row pendente', () {
      final p = MissionProgress.fromJson(_pendingFixture());
      expect(p.id, 1);
      expect(p.playerId, 42);
      expect(p.modality, MissionModality.real);
      expect(p.tabOrigin, MissionTabOrigin.daily);
      expect(p.rank, GuildRank.e);
      expect(p.currentValue, 0);
      expect(p.startedAt.millisecondsSinceEpoch, 1700000000000);
      expect(p.completedAt, isNull);
      expect(p.failedAt, isNull);
      expect(p.rewardClaimed, isFalse);
      expect(p.reward.xp, 100);
      expect(p.reward.gold, 50);
    });

    test('round-trip preserva toJson', () {
      final p = MissionProgress.fromJson(_pendingFixture());
      final back = MissionProgress.fromJson(p.toJson());
      expect(back.toJson(), p.toJson());
    });
  });

  group('MissionProgress.status calculado', () {
    test('pending — currentValue=0 sem completedAt/failedAt', () {
      final p = MissionProgress.fromJson(_pendingFixture());
      expect(p.status, MissionProgressStatus.pending);
      expect(p.progressPct, 0.0);
    });

    test('inProgress — currentValue>0 sem completed/failed', () {
      final fix = _pendingFixture()..['current_value'] = 10;
      final p = MissionProgress.fromJson(fix);
      expect(p.status, MissionProgressStatus.inProgress);
      expect(p.progressPct, 0.5);
    });

    test('completed — completedAt não null + currentValue == targetValue', () {
      final fix = _pendingFixture()
        ..['current_value'] = 20
        ..['completed_at'] = 1700000100000;
      final p = MissionProgress.fromJson(fix);
      expect(p.status, MissionProgressStatus.completed);
      expect(p.progressPct, 1.0);
    });

    test('partial — completedAt não null + currentValue < targetValue', () {
      final fix = _pendingFixture()
        ..['current_value'] = 10
        ..['completed_at'] = 1700000100000;
      final p = MissionProgress.fromJson(fix);
      expect(p.status, MissionProgressStatus.partial);
    });

    test('failed — failedAt prevalece sobre completedAt', () {
      final fix = _pendingFixture()
        ..['current_value'] = 15
        ..['completed_at'] = 1700000100000
        ..['failed_at'] = 1700000200000;
      final p = MissionProgress.fromJson(fix);
      expect(p.status, MissionProgressStatus.failed);
    });
  });

  group('MissionProgress — validações', () {
    test('reward_json inválido lança (via RewardDeclared)', () {
      final fix = _pendingFixture()..['reward_json'] = 'não-é-json';
      expect(
        () => MissionProgress.fromJson(fix),
        throwsA(isA<FormatException>()),
      );
    });

    test('modality inválido propaga', () {
      final fix = _pendingFixture()..['modality'] = 'xyz';
      expect(
        () => MissionProgress.fromJson(fix),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
