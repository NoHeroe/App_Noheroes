import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/models/reward_declared.dart';

void main() {
  group('RewardItemDeclared', () {
    test('fromJson / toJson round-trip com defaults', () {
      final j = {'key': 'RUNE_RANDOM_E', 'quantity': 1};
      final it = RewardItemDeclared.fromJson(j);
      expect(it.key, 'RUNE_RANDOM_E');
      expect(it.quantity, 1);
      expect(it.chancePct, 100, reason: 'default');
      expect(it.toJson(), {
        'key': 'RUNE_RANDOM_E',
        'quantity': 1,
        'chance_pct': 100,
      });
    });

    test('chance_pct fora de 0..100 lança', () {
      expect(
        () => RewardItemDeclared.fromJson({
          'key': 'X',
          'quantity': 1,
          'chance_pct': 150,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('key vazio lança', () {
      expect(
        () => RewardItemDeclared.fromJson({'key': '', 'quantity': 1}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FactionReputationDelta', () {
    test('round-trip', () {
      final d = FactionReputationDelta.fromJson({
        'faction_id': 'noryan',
        'delta': 3,
      });
      expect(d.factionId, 'noryan');
      expect(d.delta, 3);
      expect(d.toJson(),
          {'faction_id': 'noryan', 'delta': 3});
    });

    test('delta negativo aceito (reputação pode cair)', () {
      final d = FactionReputationDelta.fromJson({
        'faction_id': 'noryan',
        'delta': -5,
      });
      expect(d.delta, -5);
    });
  });

  group('RewardDeclared', () {
    test('fromJson com defaults — JSON vazio vira tudo 0/[]', () {
      final r = RewardDeclared.fromJson(const {});
      expect(r.xp, 0);
      expect(r.gold, 0);
      expect(r.gems, 0);
      expect(r.seivas, 0);
      expect(r.items, isEmpty);
      expect(r.achievementsToCheck, isEmpty);
      expect(r.recipesToUnlock, isEmpty);
      expect(r.factionReputation, isNull);
    });

    test('fromJson completo + round-trip', () {
      final j = {
        'xp': 100,
        'gold': 50,
        'gems': 5,
        'seivas': 0,
        'items': [
          {'key': 'RUNE_RANDOM_E', 'quantity': 1, 'chance_pct': 100},
          {'key': 'HERB_COMMON', 'quantity': 3, 'chance_pct': 60},
        ],
        'achievements_to_check': ['ACH_FIRST_CRAFT'],
        'recipes_to_unlock': ['RECIPE_ADVANCED_POTION'],
        'faction_reputation': {'faction_id': 'noryan', 'delta': 3},
      };
      final r = RewardDeclared.fromJson(j);
      expect(r.xp, 100);
      expect(r.gold, 50);
      expect(r.gems, 5);
      expect(r.items, hasLength(2));
      expect(r.items[1].chancePct, 60);
      expect(r.factionReputation, isNotNull);
      expect(r.factionReputation!.factionId, 'noryan');

      final backAgain = RewardDeclared.fromJson(r.toJson());
      expect(backAgain.toJson(), r.toJson());
    });

    test('fromJsonString + toJsonString', () {
      const s = '{"xp":40,"gold":17,"items":[]}';
      final r = RewardDeclared.fromJsonString(s);
      expect(r.xp, 40);
      expect(r.gold, 17);
      final back = RewardDeclared.fromJsonString(r.toJsonString());
      expect(back.xp, 40);
      expect(back.gold, 17);
    });

    test('fromJsonString com raiz não-objeto lança', () {
      expect(
        () => RewardDeclared.fromJsonString('[]'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
