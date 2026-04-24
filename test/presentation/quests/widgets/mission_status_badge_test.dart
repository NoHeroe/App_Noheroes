import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/constants/app_colors.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/presentation/quests/widgets/mission_status_badge.dart';

Widget _harness(MissionProgressStatus s) => MaterialApp(
      home: Scaffold(body: MissionStatusBadge(status: s)),
    );

void main() {
  group('MissionStatusBadge Sprint 14.6c (sem Niet)', () {
    testWidgets('completed → "✓ Concluído" em shadowAscending', (tester) async {
      await tester.pumpWidget(_harness(MissionProgressStatus.completed));
      final textWidget = tester.widget<Text>(find.text('✓ Concluído'));
      expect(textWidget.style?.color, AppColors.shadowAscending);
    });

    testWidgets('partial → "◑ Parcial" em mp', (tester) async {
      await tester.pumpWidget(_harness(MissionProgressStatus.partial));
      final textWidget = tester.widget<Text>(find.text('◑ Parcial'));
      expect(textWidget.style?.color, AppColors.mp);
    });

    testWidgets('failed → "✗ Falhou" em shadowChaotic', (tester) async {
      await tester.pumpWidget(_harness(MissionProgressStatus.failed));
      final textWidget = tester.widget<Text>(find.text('✗ Falhou'));
      expect(textWidget.style?.color, AppColors.shadowChaotic);
    });

    testWidgets('pending → "Pendente" em textMuted', (tester) async {
      await tester.pumpWidget(_harness(MissionProgressStatus.pending));
      final textWidget = tester.widget<Text>(find.text('Pendente'));
      expect(textWidget.style?.color, AppColors.textMuted);
    });

    testWidgets('inProgress → "Pendente" (mesmo copy do pending)',
        (tester) async {
      await tester.pumpWidget(_harness(MissionProgressStatus.inProgress));
      expect(find.text('Pendente'), findsOneWidget);
    });
  });
}
