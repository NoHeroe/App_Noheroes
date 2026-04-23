import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/models/achievement_definition.dart';

void main() {
  group('AchievementDefinition.fromJson', () {
    test('parse mínimo sem reward', () {
      final def = AchievementDefinition.fromJson({
        'key': 'ACH_X',
        'name': 'Teste',
        'description': 'desc',
        'category': 'progression',
        'trigger': {'type': 'meta', 'target_count': 1},
      });
      expect(def.key, 'ACH_X');
      expect(def.reward, isNull);
      expect(def.isSecret, isFalse);
      expect(def.trigger, isA<MetaTrigger>());
      expect((def.trigger as MetaTrigger).targetCount, 1);
    });

    test('parse completo event_count com reward + is_secret', () {
      final def = AchievementDefinition.fromJson({
        'key': 'ACH_FULL',
        'name': 'Full',
        'description': 'x',
        'category': 'meta',
        'trigger': {
          'type': 'event_count',
          'event': 'MissionCompleted',
          'count': 5,
        },
        'reward': {'xp': 10, 'gold': 20},
        'is_secret': true,
      });
      expect(def.isSecret, isTrue);
      expect(def.reward!.xp, 10);
      expect(def.reward!.gold, 20);
      final t = def.trigger as EventCountTrigger;
      expect(t.eventName, 'MissionCompleted');
      expect(t.count, 5);
    });

    test('threshold_stat com level', () {
      final def = AchievementDefinition.fromJson({
        'key': 'ACH_LV',
        'name': 'Level',
        'description': 'd',
        'category': 'c',
        'trigger': {'type': 'threshold_stat', 'stat': 'level', 'value': 10},
      });
      final t = def.trigger as ThresholdStatTrigger;
      expect(t.stat, 'level');
      expect(t.value, 10);
    });

    test('trigger type desconhecido cai em UnknownAchievementTrigger', () {
      final def = AchievementDefinition.fromJson({
        'key': 'ACH_SEQ',
        'name': 'x',
        'description': 'y',
        'category': 'c',
        'trigger': {'type': 'sequence', 'events': ['A', 'B']},
      });
      expect(def.trigger, isA<UnknownAchievementTrigger>());
      expect((def.trigger as UnknownAchievementTrigger).rawType, 'sequence');
    });

    test('key ausente lança FormatException', () {
      expect(
        () => AchievementDefinition.fromJson({
          'name': 'x',
          'description': 'y',
          'category': 'c',
          'trigger': {'type': 'meta', 'target_count': 1},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('event_count.count inválido lança', () {
      expect(
        () => AchievementDefinition.fromJson({
          'key': 'K',
          'name': 'x',
          'description': 'y',
          'category': 'c',
          'trigger': {'type': 'event_count', 'event': 'X', 'count': 0},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('toJson round-trip preserva campos', () {
      final original = AchievementDefinition.fromJson({
        'key': 'K',
        'name': 'n',
        'description': 'd',
        'category': 'c',
        'trigger': {'type': 'meta', 'target_count': 3},
        'reward': {'gems': 5},
        'is_secret': true,
      });
      final roundtripped =
          AchievementDefinition.fromJson(original.toJson());
      expect(roundtripped.key, original.key);
      expect(roundtripped.isSecret, original.isSecret);
      expect(roundtripped.reward!.gems, 5);
      expect((roundtripped.trigger as MetaTrigger).targetCount, 3);
    });
  });
}
