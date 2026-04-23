import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/presentation/quests/widgets/history_filter_chips.dart';
import 'package:noheroes_app/presentation/quests/widgets/history_mission_card.dart';
import 'package:noheroes_app/presentation/quests/widgets/mission_counters.dart';
import 'package:noheroes_app/presentation/quests/widgets/weekly_missions_chart.dart';

MissionProgress _m({
  required int id,
  DateTime? completedAt,
  DateTime? failedAt,
}) {
  return MissionProgress(
    id: id,
    playerId: 1,
    missionKey: 'M$id',
    modality: MissionModality.real,
    tabOrigin: MissionTabOrigin.daily,
    rank: GuildRank.e,
    targetValue: 10,
    currentValue: 10,
    reward: const RewardDeclared(xp: 20, gold: 10),
    startedAt: DateTime.now().subtract(const Duration(days: 1)),
    completedAt: completedAt,
    failedAt: failedAt,
    rewardClaimed: false,
    metaJson: '{}',
  );
}

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('WeeklyMissionsChart', () {
    testWidgets('render com dados agrupa por weekday', (tester) async {
      await tester.pumpWidget(_wrap(WeeklyMissionsChart(
        missionsLast7Days: [
          _m(id: 1, completedAt: DateTime.now()),
          _m(id: 2, completedAt: DateTime.now()),
          _m(id: 3,
              completedAt:
                  DateTime.now().subtract(const Duration(days: 1))),
        ],
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-weekly-chart')),
          findsOneWidget);
      expect(find.text('MISSÕES SEMANAIS'), findsOneWidget);
    });

    testWidgets('render com lista vazia renderiza barras zero', (tester) async {
      await tester.pumpWidget(
          _wrap(const WeeklyMissionsChart(missionsLast7Days: [])));
      await tester.pumpAndSettle();
      // Sempre renderiza 7 dias — os `0` aparecem como labels
      expect(find.text('0'), findsNWidgets(7));
    });
  });

  group('MissionCounters', () {
    testWidgets('render 3 métricas com Hoje/Semana/Total', (tester) async {
      await tester.pumpWidget(_wrap(MissionCounters(
        missionsLast7Days: [
          _m(id: 1, completedAt: DateTime.now()),
          _m(id: 2,
              completedAt:
                  DateTime.now().subtract(const Duration(days: 3))),
        ],
        totalQuestsCompleted: 42,
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-mission-counters')),
          findsOneWidget);
      // Hoje = 1 (só uma hoje); Semana = 2 (ambas completed); Total = 42
      expect(find.text('1'), findsOneWidget); // Hoje
      expect(find.text('2'), findsOneWidget); // Semana
      expect(find.text('42'), findsOneWidget); // Total
    });
  });

  group('HistoryFilterChips', () {
    testWidgets('3 chips renderizam + tap dispara callback', (tester) async {
      HistoryFilter? lastSelected;
      await tester.pumpWidget(_wrap(HistoryFilterChips(
        active: HistoryFilter.todas,
        onSelect: (f) => lastSelected = f,
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-filter-todas')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('history-filter-concluidas')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('history-filter-falhadas')),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('history-filter-falhadas')));
      await tester.pumpAndSettle();
      expect(lastSelected, HistoryFilter.falhadas);
    });
  });

  group('HistoryMissionCard', () {
    testWidgets('completada → badge "Concluída" + expand mostra detail',
        (tester) async {
      await tester.pumpWidget(_wrap(HistoryMissionCard(
        mission: _m(id: 7, completedAt: DateTime.now()),
      )));
      await tester.pumpAndSettle();
      expect(find.text('CONCLUÍDA'), findsOneWidget);
      expect(find.text('M7'), findsOneWidget);
      // Expande
      await tester.tap(find.text('M7'));
      await tester.pumpAndSettle();
      expect(find.text('Progresso final'), findsOneWidget);
      expect(find.text('10 / 10'), findsOneWidget);
    });

    testWidgets('falhada → badge "Falhou"', (tester) async {
      await tester.pumpWidget(_wrap(HistoryMissionCard(
        mission: _m(id: 8, failedAt: DateTime.now()),
      )));
      await tester.pumpAndSettle();
      expect(find.text('FALHOU'), findsOneWidget);
    });
  });
}
