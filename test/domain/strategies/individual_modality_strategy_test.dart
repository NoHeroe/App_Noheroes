import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/strategies/individual_modality_strategy.dart';
import 'package:noheroes_app/domain/strategies/mission_strategy.dart';

import '_strategy_test_helpers.dart';

void main() {
  final s = IndividualModalityStrategy();

  group('IndividualModalityStrategy — herda RealTask behavior', () {
    test('aceita delta sem requirementIndex', () {
      expect(s.acceptsInput(ctx(), const UserDeltaStrategyInput(5)), isTrue);
    });

    test('delta positivo incrementa', () {
      final step = s.computeStep(
        ctx(current: 0, target: 10),
        const UserDeltaStrategyInput(3),
      );
      expect(step.newCurrentValue, 3);
      expect(step.shouldComplete, isFalse);
    });

    test('shouldComplete ao atingir target', () {
      final step = s.computeStep(
        ctx(current: 7, target: 10),
        const UserDeltaStrategyInput(3),
      );
      expect(step.newCurrentValue, 10);
      expect(step.shouldComplete, isTrue);
    });

    test('clamp em 300% mesmo que RealTask', () {
      final step = s.computeStep(
        ctx(current: 25, target: 10),
        const UserDeltaStrategyInput(20),
      );
      expect(step.newCurrentValue, 30); // target 10 × 3 = 30
    });

    test('delta negativo respeita floor 0', () {
      final step = s.computeStep(
        ctx(current: 1, target: 10),
        const UserDeltaStrategyInput(-10),
      );
      expect(step.newCurrentValue, 0);
    });
  });
}
