import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/presentation/quests/widgets/mixed_mission_card.dart';

MissionProgress _mixed({
  required List<Map<String, dynamic>> requirementsMeta,
  required List<int> requirementsProgress,
  int currentValue = 0,
}) {
  return MissionProgress(
    id: 99,
    playerId: 1,
    missionKey: 'MIX_X',
    modality: MissionModality.mixed,
    tabOrigin: MissionTabOrigin.extras,
    rank: GuildRank.e,
    targetValue: requirementsMeta.length,
    currentValue: currentValue,
    reward: const RewardDeclared(),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: jsonEncode({
      'requirements_meta': requirementsMeta,
      'requirements_progress': requirementsProgress,
    }),
  );
}

Widget _harness(MissionProgress m) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: MixedMissionCard(mission: m)),
      ),
    );

void main() {
  testWidgets('renderiza 2 sub-tasks internal + 1 real', (tester) async {
    final m = _mixed(
      requirementsMeta: [
        {'type': 'internal', 'event': 'ItemCrafted', 'target': 3},
        {'type': 'internal', 'event': 'LevelUp', 'target': 1},
        {'type': 'real', 'name': 'Meditar', 'unit': 'min', 'target': 15},
      ],
      requirementsProgress: [1, 0, 5],
      currentValue: 0,
    );
    await tester.pumpWidget(_harness(m));
    await tester.pumpAndSettle();

    // Labels — internal usa 'event', real usa 'name'
    expect(find.text('ItemCrafted'), findsOneWidget);
    expect(find.text('LevelUp'), findsOneWidget);
    expect(find.text('Meditar'), findsOneWidget);

    // Contadores por sub-task
    expect(find.text('1/3'), findsOneWidget); // ItemCrafted internal
    expect(find.text('0/1'), findsOneWidget); // LevelUp internal
    expect(find.text('5/15 min'), findsOneWidget); // Meditar real
  });

  testWidgets('sub-task real tem botões ± com ValueKey indexada',
      (tester) async {
    final m = _mixed(
      requirementsMeta: [
        {'type': 'internal', 'event': 'GoldSpent', 'target': 100},
        {'type': 'real', 'name': 'Flexão', 'unit': 'reps', 'target': 20},
      ],
      requirementsProgress: [50, 3],
    );
    await tester.pumpWidget(_harness(m));
    await tester.pumpAndSettle();

    // Sub-task index 1 = real → 6 botões ±
    for (final d in const [-25, -10, -1, 1, 10, 25]) {
      expect(
          find.byKey(ValueKey('mixed-sub-1-delta-$d')), findsOneWidget);
    }
    // Sub-task index 0 = internal → nenhum botão
    for (final d in const [-25, -10, -1, 1, 10, 25]) {
      expect(find.byKey(ValueKey('mixed-sub-0-delta-$d')), findsNothing);
    }
  });

  testWidgets('header agregado mostra N/M requisitos', (tester) async {
    final m = _mixed(
      requirementsMeta: [
        {'type': 'internal', 'event': 'X', 'target': 1},
        {'type': 'internal', 'event': 'Y', 'target': 1},
        {'type': 'internal', 'event': 'Z', 'target': 1},
      ],
      requirementsProgress: [1, 1, 0],
      currentValue: 2, // 2 dos 3 requirements completos
    );
    await tester.pumpWidget(_harness(m));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3 requisitos completos'), findsOneWidget);
  });

  testWidgets('metaJson malformado renderiza placeholder sem crashar',
      (tester) async {
    final m = MissionProgress(
      id: 88,
      playerId: 1,
      missionKey: 'MIX_BAD',
      modality: MissionModality.mixed,
      tabOrigin: MissionTabOrigin.extras,
      rank: GuildRank.e,
      targetValue: 0,
      currentValue: 0,
      reward: const RewardDeclared(),
      startedAt: DateTime.now(),
      rewardClaimed: false,
      metaJson: '{"bogus": true}',
    );
    await tester.pumpWidget(_harness(m));
    await tester.pumpAndSettle();
    expect(find.text('(sub-tarefas indisponíveis)'), findsOneWidget);
  });
}
