import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/crafting_events.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/strategies/internal_modality_strategy.dart';
import 'package:noheroes_app/domain/strategies/mission_strategy.dart';
import 'package:noheroes_app/domain/strategies/mixed_modality_strategy.dart';
import 'package:noheroes_app/domain/strategies/real_task_modality_strategy.dart';

import '_strategy_test_helpers.dart';

/// meta inicial pra missão mixed com 2 reqs:
/// - req 0: internal ItemCrafted, target=3
/// - req 1: real Meditar 15min
String _initialMeta() => jsonEncode({
      'requirements_progress': [0, 0],
      'requirements_meta': [
        {'internal_event': 'ItemCrafted', 'target': 3},
        {'target': 15},
      ],
    });

void main() {
  final s = MixedModalityStrategy(
    InternalModalityStrategy(),
    RealTaskModalityStrategy(),
  );

  group('MixedModalityStrategy — acceptsInput', () {
    test('aceita EventStrategyInput quando algum req internal matches',
        () {
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'S', recipeKey: 'R');
      expect(
        s.acceptsInput(
          ctx(
              modality: MissionModality.mixed,
              target: 2,
              metaJson: _initialMeta()),
          EventStrategyInput(evt),
        ),
        isTrue,
      );
    });

    test('rejeita evento que não bate com nenhum req internal', () {
      final evt = LevelUp(playerId: 42, newLevel: 5, previousLevel: 4);
      expect(
        s.acceptsInput(
          ctx(
              modality: MissionModality.mixed,
              target: 2,
              metaJson: _initialMeta()),
          EventStrategyInput(evt),
        ),
        isFalse,
      );
    });

    test('aceita UserDelta com requirementIndex válido (req real)', () {
      expect(
        s.acceptsInput(
          ctx(
              modality: MissionModality.mixed,
              target: 2,
              metaJson: _initialMeta()),
          const UserDeltaStrategyInput(5, requirementIndex: 1),
        ),
        isTrue,
      );
    });

    test('rejeita UserDelta apontando pra req internal', () {
      expect(
        s.acceptsInput(
          ctx(
              modality: MissionModality.mixed,
              target: 2,
              metaJson: _initialMeta()),
          const UserDeltaStrategyInput(5, requirementIndex: 0),
        ),
        isFalse,
      );
    });

    test('rejeita UserDelta sem requirementIndex (família simples)', () {
      expect(
        s.acceptsInput(
          ctx(
              modality: MissionModality.mixed,
              target: 2,
              metaJson: _initialMeta()),
          const UserDeltaStrategyInput(5),
        ),
        isFalse,
      );
    });

    test('rejeita UserDelta com requirementIndex fora da faixa', () {
      expect(
        s.acceptsInput(
          ctx(
              modality: MissionModality.mixed,
              target: 2,
              metaJson: _initialMeta()),
          const UserDeltaStrategyInput(5, requirementIndex: 99),
        ),
        isFalse,
      );
    });
  });

  group('MixedModalityStrategy — computeStep', () {
    test('evento internal incrementa req 0, currentValue agregado = 0 '
        '(ainda)', () {
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'S', recipeKey: 'R');
      final step = s.computeStep(
        ctx(
            modality: MissionModality.mixed,
            target: 2,
            metaJson: _initialMeta()),
        EventStrategyInput(evt),
      );
      expect(step.newCurrentValue, 0,
          reason: 'req 0 ainda em 1/3, nenhum req completo');
      expect(step.shouldComplete, isFalse);
      final meta = jsonDecode(step.newMetaJson) as Map;
      expect(meta['requirements_progress'], [1, 0]);
    });

    test('3 eventos internal completam req 0, agregado vira 1', () {
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'S', recipeKey: 'R');
      var meta = _initialMeta();
      for (var i = 0; i < 3; i++) {
        final step = s.computeStep(
          ctx(
              modality: MissionModality.mixed,
              target: 2,
              metaJson: meta),
          EventStrategyInput(evt),
        );
        meta = step.newMetaJson;
      }
      final decoded = jsonDecode(meta) as Map;
      expect(decoded['requirements_progress'], [3, 0]);
      final finalStep = s.computeStep(
        ctx(
            modality: MissionModality.mixed,
            target: 2,
            current: 1,
            metaJson: meta),
        const UserDeltaStrategyInput(5, requirementIndex: 1),
      );
      expect((jsonDecode(finalStep.newMetaJson) as Map)
          ['requirements_progress'], [3, 5]);
      expect(finalStep.newCurrentValue, 1,
          reason: 'req 0 completo; req 1 ainda não');
    });

    test('completar os 2 reqs → shouldComplete', () {
      // Req 0 já completo (3/3); aplica delta pra fechar req 1 (15/15).
      final meta = jsonEncode({
        'requirements_progress': [3, 10],
        'requirements_meta': [
          {'internal_event': 'ItemCrafted', 'target': 3},
          {'target': 15},
        ],
      });
      final step = s.computeStep(
        ctx(
            modality: MissionModality.mixed,
            target: 2,
            current: 1,
            metaJson: meta),
        const UserDeltaStrategyInput(5, requirementIndex: 1),
      );
      expect(step.newCurrentValue, 2);
      expect(step.shouldComplete, isTrue);
    });

    test('req já completo não consome eventos extras', () {
      // Req 0 já em 3/3. Novo ItemCrafted não deve incrementar.
      final meta = jsonEncode({
        'requirements_progress': [3, 0],
        'requirements_meta': [
          {'internal_event': 'ItemCrafted', 'target': 3},
          {'target': 15},
        ],
      });
      final evt =
          ItemCrafted(playerId: 42, itemKey: 'S', recipeKey: 'R');
      final step = s.computeStep(
        ctx(
            modality: MissionModality.mixed,
            target: 2,
            current: 1,
            metaJson: meta),
        EventStrategyInput(evt),
      );
      final decoded = jsonDecode(step.newMetaJson) as Map;
      expect(decoded['requirements_progress'], [3, 0]);
      expect(step.newCurrentValue, 1);
    });

    test('delta negativo em req real respeita floor 0', () {
      final meta = jsonEncode({
        'requirements_progress': [0, 3],
        'requirements_meta': [
          {'internal_event': 'ItemCrafted', 'target': 3},
          {'target': 15},
        ],
      });
      final step = s.computeStep(
        ctx(
            modality: MissionModality.mixed,
            target: 2,
            metaJson: meta),
        const UserDeltaStrategyInput(-10, requirementIndex: 1),
      );
      expect((jsonDecode(step.newMetaJson) as Map)
          ['requirements_progress'], [0, 0]);
    });

    test('delta real clampa no target do requirement (não 300%)', () {
      final meta = jsonEncode({
        'requirements_progress': [0, 10],
        'requirements_meta': [
          {'internal_event': 'ItemCrafted', 'target': 3},
          {'target': 15},
        ],
      });
      final step = s.computeStep(
        ctx(
            modality: MissionModality.mixed,
            target: 2,
            metaJson: meta),
        const UserDeltaStrategyInput(50, requirementIndex: 1),
      );
      // Clampa em 15 (não 45 — sub-req não tem bônus 300%)
      expect((jsonDecode(step.newMetaJson) as Map)
          ['requirements_progress'], [0, 15]);
    });
  });
}
