import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/crafting_events.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/domain/strategies/internal_modality_strategy.dart';
import 'package:noheroes_app/domain/strategies/mission_strategy.dart';

import '_strategy_test_helpers.dart';

void main() {
  final s = InternalModalityStrategy();

  group('InternalModalityStrategy — acceptsInput', () {
    test('rejeita UserDeltaStrategyInput', () {
      expect(
        s.acceptsInput(
          ctx(metaJson: '{"internal_event":"ItemCrafted"}'),
          const UserDeltaStrategyInput(5),
        ),
        isFalse,
      );
    });

    test('rejeita quando metaJson não declara internal_event', () {
      expect(
        s.acceptsInput(
          ctx(metaJson: '{}'),
          EventStrategyInput(ItemCrafted(
              playerId: 42, itemKey: 'SWORD', recipeKey: 'R')),
        ),
        isFalse,
      );
    });

    test('rejeita evento de tipo diferente do esperado', () {
      final evt = LevelUp(playerId: 42, newLevel: 5, previousLevel: 4);
      expect(
        s.acceptsInput(
          ctx(metaJson: '{"internal_event":"ItemCrafted"}'),
          EventStrategyInput(evt),
        ),
        isFalse,
      );
    });

    test('rejeita evento com playerId diferente', () {
      final evt =
          ItemCrafted(playerId: 99, itemKey: 'SWORD', recipeKey: 'R');
      expect(
        s.acceptsInput(
          ctx(playerId: 42, metaJson: '{"internal_event":"ItemCrafted"}'),
          EventStrategyInput(evt),
        ),
        isFalse,
      );
    });

    test('aceita evento certo do player certo', () {
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'SWORD', recipeKey: 'R');
      expect(
        s.acceptsInput(
          ctx(playerId: 42, metaJson: '{"internal_event":"ItemCrafted"}'),
          EventStrategyInput(evt),
        ),
        isTrue,
      );
    });

    test('rejeita string expected que não está no switch', () {
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'SWORD', recipeKey: 'R');
      expect(
        s.acceptsInput(
          ctx(metaJson: '{"internal_event":"UnknownEvent"}'),
          EventStrategyInput(evt),
        ),
        isFalse,
      );
    });
  });

  group('InternalModalityStrategy — computeStep', () {
    test('incrementa 1 por evento', () {
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'S', recipeKey: 'R');
      final step = s.computeStep(
        ctx(current: 1, target: 3,
            metaJson: '{"internal_event":"ItemCrafted"}'),
        EventStrategyInput(evt),
      );
      expect(step.newCurrentValue, 2);
      expect(step.shouldComplete, isFalse);
      expect(step.newMetaJson, '{"internal_event":"ItemCrafted"}');
    });

    test('shouldComplete quando atinge target', () {
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'S', recipeKey: 'R');
      final step = s.computeStep(
        ctx(current: 2, target: 3,
            metaJson: '{"internal_event":"ItemCrafted"}'),
        EventStrategyInput(evt),
      );
      expect(step.newCurrentValue, 3);
      expect(step.shouldComplete, isTrue);
    });

    test('shouldComplete quando passa do target (ex: +1 além)', () {
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'S', recipeKey: 'R');
      final step = s.computeStep(
        ctx(current: 3, target: 3,
            metaJson: '{"internal_event":"ItemCrafted"}'),
        EventStrategyInput(evt),
      );
      expect(step.newCurrentValue, 4);
      expect(step.shouldComplete, isTrue);
    });
  });
}
