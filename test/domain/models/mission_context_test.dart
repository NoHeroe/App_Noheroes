import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_context.dart';

Map<String, dynamic> _fixture() => {
      'mission_progress_id': 1,
      'player_id': 42,
      'mission_key': 'DAILY_PUSHUPS_E',
      'modality': 'real',
      'tab_origin': 'daily',
      'current_value': 5,
      'target_value': 20,
      'reward_declared': {'xp': 100, 'gold': 50},
      'meta_json': '{}',
    };

void main() {
  test('MissionContext — round-trip', () {
    final ctx = MissionContext.fromJson(_fixture());
    expect(ctx.missionProgressId, 1);
    expect(ctx.playerId, 42);
    expect(ctx.modality, MissionModality.real);
    expect(ctx.tabOrigin, MissionTabOrigin.daily);
    expect(ctx.currentValue, 5);
    expect(ctx.targetValue, 20);
    expect(ctx.rewardDeclared.xp, 100);

    final back = MissionContext.fromJson(ctx.toJson());
    expect(back.toJson(), ctx.toJson());
  });

  test('MissionContext — campo obrigatório ausente lança', () {
    final bad = _fixture()..remove('mission_key');
    expect(
      () => MissionContext.fromJson(bad),
      throwsA(isA<FormatException>()),
    );
  });

  test('MissionContext — default meta_json "{}" quando ausente', () {
    final fix = _fixture()..remove('meta_json');
    final ctx = MissionContext.fromJson(fix);
    expect(ctx.metaJson, '{}');
  });
}
