import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/crafting_events.dart';
import 'package:noheroes_app/domain/strategies/mission_strategy.dart';
import 'package:noheroes_app/domain/strategies/real_task_modality_strategy.dart';

import '_strategy_test_helpers.dart';

void main() {
  final s = RealTaskModalityStrategy();

  group('RealTaskModalityStrategy — acceptsInput', () {
    test('rejeita EventStrategyInput', () {
      final evt = ItemCrafted(playerId: 42, itemKey: 'S', recipeKey: 'R');
      expect(s.acceptsInput(ctx(), EventStrategyInput(evt)), isFalse);
    });

    test('rejeita delta com requirementIndex (isso é Mixed)', () {
      expect(
        s.acceptsInput(ctx(),
            const UserDeltaStrategyInput(5, requirementIndex: 0)),
        isFalse,
      );
    });

    test('aceita delta sem requirementIndex', () {
      expect(
          s.acceptsInput(ctx(), const UserDeltaStrategyInput(5)), isTrue);
    });
  });

  group('RealTaskModalityStrategy — computeStep', () {
    test('delta positivo incrementa', () {
      final step = s.computeStep(
        ctx(current: 5, target: 20),
        const UserDeltaStrategyInput(10),
      );
      expect(step.newCurrentValue, 15);
      expect(step.shouldComplete, isFalse);
    });

    test('delta chega em 100% → shouldComplete', () {
      final step = s.computeStep(
        ctx(current: 15, target: 20),
        const UserDeltaStrategyInput(5),
      );
      expect(step.newCurrentValue, 20);
      expect(step.shouldComplete, isTrue);
    });

    test('delta negativo decrementa', () {
      final step = s.computeStep(
        ctx(current: 10, target: 20),
        const UserDeltaStrategyInput(-3),
      );
      expect(step.newCurrentValue, 7);
      expect(step.shouldComplete, isFalse);
    });

    test('clamp inferior em 0', () {
      final step = s.computeStep(
        ctx(current: 2, target: 20),
        const UserDeltaStrategyInput(-25),
      );
      expect(step.newCurrentValue, 0);
      expect(step.shouldComplete, isFalse);
    });

    test('permite ultrapassar 100% (150% → shouldComplete + preserva)', () {
      final step = s.computeStep(
        ctx(current: 20, target: 20),
        const UserDeltaStrategyInput(10),
      );
      expect(step.newCurrentValue, 30);
      expect(step.shouldComplete, isTrue);
    });

    test('clamp superior em 300% (target=20 → max=60)', () {
      final step = s.computeStep(
        ctx(current: 50, target: 20),
        const UserDeltaStrategyInput(25),
      );
      expect(step.newCurrentValue, 60);
      expect(step.shouldComplete, isTrue);
    });

    test('delta 0 mantém valor', () {
      final step = s.computeStep(
        ctx(current: 10, target: 20),
        const UserDeltaStrategyInput(0),
      );
      expect(step.newCurrentValue, 10);
      expect(step.shouldComplete, isFalse);
    });

    test('metaJson preservado (real não mexe em meta)', () {
      final step = s.computeStep(
        ctx(current: 5, target: 20, metaJson: '{"x":1}'),
        const UserDeltaStrategyInput(5),
      );
      expect(step.newMetaJson, '{"x":1}');
    });
  });
}
