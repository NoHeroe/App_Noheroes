import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/models/mission_requirement.dart';

void main() {
  group('MissionRequirement — internal', () {
    test('parse + round-trip', () {
      final j = {'type': 'internal', 'event': 'ItemCrafted', 'target': 3};
      final r = MissionRequirement.fromJson(j);
      expect(r.type, 'internal');
      expect(r.event, 'ItemCrafted');
      expect(r.target, 3);
      expect(r.name, isNull);
      expect(r.unit, isNull);
      expect(r.toJson(), j);
    });

    test('internal sem event lança', () {
      expect(
        () => MissionRequirement.fromJson(const {
          'type': 'internal',
          'target': 3,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('MissionRequirement — real', () {
    test('parse + round-trip com unit', () {
      final j = {
        'type': 'real',
        'name': 'Meditar',
        'target': 15,
        'unit': 'min'
      };
      final r = MissionRequirement.fromJson(j);
      expect(r.type, 'real');
      expect(r.name, 'Meditar');
      expect(r.target, 15);
      expect(r.unit, 'min');
      expect(r.toJson(), j);
    });

    test('real sem name lança', () {
      expect(
        () => MissionRequirement.fromJson(const {
          'type': 'real',
          'target': 10,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('type inválido lança', () {
    expect(
      () => MissionRequirement.fromJson(
          const {'type': 'mystery', 'target': 1}),
      throwsA(isA<FormatException>()),
    );
  });

  test('target 0 ou negativo lança', () {
    expect(
      () => MissionRequirement.fromJson(const {
        'type': 'internal',
        'event': 'ItemCrafted',
        'target': 0,
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => MissionRequirement.fromJson(const {
        'type': 'internal',
        'event': 'ItemCrafted',
        'target': -1,
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
