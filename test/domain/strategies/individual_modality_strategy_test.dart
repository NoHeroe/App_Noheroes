import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/requirements_helper.dart';
import 'package:noheroes_app/domain/strategies/individual_modality_strategy.dart';
import 'package:noheroes_app/domain/strategies/mission_strategy.dart';

import '_strategy_test_helpers.dart';

String _meta(List<RequirementItem> reqs) =>
    jsonEncode({'requirements': RequirementsHelper.serialize(reqs)});

void main() {
  final s = IndividualModalityStrategy();

  group('IndividualModalityStrategy — Sprint 14.6b requirements múltiplos', () {
    test('rejeita input sem requirementIndex', () {
      final metaJson = _meta([
        RequirementItem(label: 'Flexões', target: 20, unit: 'reps'),
      ]);
      final c = ctx(current: 0, target: 20, metaJson: metaJson);
      expect(
        s.acceptsInput(c, const UserDeltaStrategyInput(5)),
        isFalse,
      );
    });

    test('rejeita input quando metaJson não tem requirements', () {
      final c = ctx(current: 0, target: 10, metaJson: '{}');
      expect(
        s.acceptsInput(
            c, const UserDeltaStrategyInput(5, requirementIndex: 0)),
        isFalse,
      );
    });

    test('delta positivo incrementa requirement[idx].done', () {
      final metaJson = _meta([
        RequirementItem(label: 'Flexões', target: 20, unit: 'reps'),
        RequirementItem(label: 'Corrida', target: 3, unit: 'km'),
      ]);
      final c = ctx(current: 0, target: 23, metaJson: metaJson);
      final step = s.computeStep(
        c,
        const UserDeltaStrategyInput(5, requirementIndex: 0),
      );
      expect(step.newCurrentValue, 5);
      expect(step.shouldComplete, isFalse);
      final reqs = RequirementsHelper.parse(
          (jsonDecode(step.newMetaJson)['requirements']) as String);
      expect(reqs[0].done, 5);
      expect(reqs[1].done, 0);
    });

    test('currentValue agregado = soma dos dones', () {
      final metaJson = _meta([
        RequirementItem(label: 'Flexões', target: 20, unit: 'reps', done: 15),
        RequirementItem(label: 'Corrida', target: 3, unit: 'km', done: 1),
      ]);
      final c = ctx(current: 16, target: 23, metaJson: metaJson);
      final step = s.computeStep(
        c,
        const UserDeltaStrategyInput(2, requirementIndex: 1),
      );
      // Req[0].done=15 + Req[1].done=3 = 18
      expect(step.newCurrentValue, 18);
      expect(step.shouldComplete, isFalse);
    });

    test('shouldComplete quando soma dos dones >= targetValue', () {
      final metaJson = _meta([
        RequirementItem(label: 'Flexões', target: 20, unit: 'reps', done: 20),
        RequirementItem(label: 'Corrida', target: 3, unit: 'km', done: 2),
      ]);
      final c = ctx(current: 22, target: 23, metaJson: metaJson);
      final step = s.computeStep(
        c,
        const UserDeltaStrategyInput(1, requirementIndex: 1),
      );
      expect(step.newCurrentValue, 23);
      expect(step.shouldComplete, isTrue);
    });

    test('clamp de 300% por sub-requirement (ADR 0013 §4)', () {
      final metaJson = _meta([
        RequirementItem(label: 'Flexões', target: 10, unit: 'reps', done: 25),
      ]);
      final c = ctx(current: 25, target: 10, metaJson: metaJson);
      final step = s.computeStep(
        c,
        const UserDeltaStrategyInput(20, requirementIndex: 0),
      );
      // done clampa em target*3 = 30
      expect(step.newCurrentValue, 30);
    });

    test('delta negativo respeita floor 0 por sub-requirement', () {
      final metaJson = _meta([
        RequirementItem(label: 'Flexões', target: 10, unit: 'reps', done: 1),
      ]);
      final c = ctx(current: 1, target: 10, metaJson: metaJson);
      final step = s.computeStep(
        c,
        const UserDeltaStrategyInput(-10, requirementIndex: 0),
      );
      expect(step.newCurrentValue, 0);
    });
  });
}
