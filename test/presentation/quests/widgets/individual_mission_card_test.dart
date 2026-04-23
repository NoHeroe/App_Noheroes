import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/core/utils/requirements_helper.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/repositories/mission_repository.dart';
import 'package:noheroes_app/domain/services/individual_delete_service.dart';
import 'package:noheroes_app/presentation/quests/widgets/individual_mission_card.dart';

/// Fake service — rastreia se foi chamado com quais argumentos.
class _FakeDeleteService implements IndividualDeleteService {
  int calls = 0;
  int? lastPlayerId;
  int? lastMissionId;

  @override
  Future<void> deleteIndividual({
    required int playerId,
    required int missionProgressId,
  }) async {
    calls++;
    lastPlayerId = playerId;
    lastMissionId = missionProgressId;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Sprint 3.1 Bloco 14.6b — missões individuais guardam requirements[]
/// no metaJson. Helper cria o meta no novo formato.
String _metaWithRequirements({String name = 'Forja Matinal'}) {
  return jsonEncode({
    'name': name,
    'description': 'Descrição livre',
    'category': 'fisico',
    'requirements': RequirementsHelper.serialize([
      RequirementItem(label: 'Flexões', target: 20, unit: 'reps'),
    ]),
  });
}

MissionProgress _individual({int id = 1, GuildRank rank = GuildRank.e}) {
  return MissionProgress(
    id: id,
    playerId: 10,
    missionKey: 'IND_X',
    modality: MissionModality.individual,
    tabOrigin: MissionTabOrigin.extras,
    rank: rank,
    targetValue: 20,
    currentValue: 0,
    reward: const RewardDeclared(),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: _metaWithRequirements(),
  );
}

Widget _harness(MissionProgress m, _FakeDeleteService fake) {
  return ProviderScope(
    overrides: [
      individualDeleteServiceProvider.overrideWithValue(fake),
    ],
    child: MaterialApp(
      home: Scaffold(body: IndividualMissionCard(mission: m)),
    ),
  );
}

void main() {
  testWidgets('renderiza 6 botões ± por sub-requirement + botão Apagar',
      (tester) async {
    final fake = _FakeDeleteService();
    await tester.pumpWidget(_harness(_individual(), fake));
    await tester.pumpAndSettle();

    for (final d in const [-25, -10, -1, 1, 10, 25]) {
      expect(find.byKey(ValueKey('individual-sub-0-delta-$d')),
          findsOneWidget);
    }
    expect(find.byKey(const ValueKey('individual-delete-1')), findsOneWidget);
  });

  testWidgets('tap em Apagar abre confirm dialog mostrando custo rank E',
      (tester) async {
    final fake = _FakeDeleteService();
    await tester.pumpWidget(_harness(_individual(), fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('individual-delete-1')));
    await tester.pumpAndSettle();

    expect(find.text('Apagar missão individual?'), findsOneWidget);
    expect(find.textContaining('50 ouro'), findsOneWidget);
    expect(find.textContaining('20 gemas'), findsOneWidget);
  });

  testWidgets('confirm aciona service; cancel não', (tester) async {
    final fake = _FakeDeleteService();
    await tester.pumpWidget(_harness(_individual(), fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('individual-delete-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('individual-delete-cancel')));
    await tester.pumpAndSettle();
    expect(fake.calls, 0);

    await tester.tap(find.byKey(const ValueKey('individual-delete-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('individual-delete-confirm')));
    await tester.pumpAndSettle();
    expect(fake.calls, 1);
    expect(fake.lastPlayerId, 10);
    expect(fake.lastMissionId, 1);
  });

  testWidgets('mission já falhada oculta botões + delete', (tester) async {
    final fake = _FakeDeleteService();
    final failed = MissionProgress(
      id: 2,
      playerId: 10,
      missionKey: 'IND_X',
      modality: MissionModality.individual,
      tabOrigin: MissionTabOrigin.extras,
      rank: GuildRank.e,
      targetValue: 20,
      currentValue: 0,
      reward: const RewardDeclared(),
      startedAt: DateTime.now(),
      failedAt: DateTime.now(),
      rewardClaimed: false,
      metaJson: _metaWithRequirements(),
    );
    await tester.pumpWidget(_harness(failed, fake));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('individual-delete-2')), findsNothing);
    expect(find.byKey(const ValueKey('individual-sub-0-delta-1')),
        findsNothing);
  });
}

// Classe vazia pra satisfazer compilador do noSuchMethod — não usa.
class MissionRepositoryStub implements MissionRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
