import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/models/reward_resolved.dart';

void main() {
  group('RewardItemResolved', () {
    test('round-trip', () {
      final it = RewardItemResolved.fromJson(
          const {'key': 'RUNE_FIRE_E', 'quantity': 1});
      expect(it.key, 'RUNE_FIRE_E');
      expect(it.quantity, 1);
      expect(it.toJson(), const {'key': 'RUNE_FIRE_E', 'quantity': 1});
    });

    test('key vazio lança', () {
      expect(
        () => RewardItemResolved.fromJson(const {'key': '', 'quantity': 1}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RewardResolved', () {
    test('defaults quando campos omitidos', () {
      final r = RewardResolved.fromJson(const {});
      expect(r.xp, 0);
      expect(r.items, isEmpty);
      expect(r.factionId, isNull);
      expect(r.factionReputationDelta, isNull);
    });

    test('round-trip completo', () {
      final j = {
        'xp': 40,
        'gold': 17,
        'gems': 7,
        'seivas': 0,
        'items': [
          {'key': 'RUNE_FIRE_E', 'quantity': 1},
        ],
        'achievements_to_check': ['ACH_FIRST_CRAFT'],
        'recipes_to_unlock': <String>[],
        'faction_id': 'noryan',
        'faction_reputation_delta': 3,
      };
      final r = RewardResolved.fromJson(j);
      expect(r.xp, 40);
      expect(r.items.single.key, 'RUNE_FIRE_E');
      expect(r.factionId, 'noryan');
      expect(r.factionReputationDelta, 3);

      final back = RewardResolved.fromJson(r.toJson());
      expect(back.toJson(), r.toJson());
    });

    test('faction_id sem delta (e vice-versa) lança FormatException', () {
      expect(
        () => RewardResolved.fromJson(const {'faction_id': 'noryan'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => RewardResolved.fromJson(
            const {'faction_reputation_delta': 3}),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJsonString + toJsonString', () {
      final r = RewardResolved.fromJsonString('{"xp":40}');
      expect(r.xp, 40);
      final back = RewardResolved.fromJsonString(r.toJsonString());
      expect(back.xp, 40);
    });
  });
}
