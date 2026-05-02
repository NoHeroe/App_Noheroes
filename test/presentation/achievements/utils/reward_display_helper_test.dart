import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/presentation/achievements/utils/reward_display_helper.dart';

/// Sprint 3.3 Etapa Final-B — RewardDisplay aplica multipliers SOULSLIKE
/// (ADR 0013 §3) sobre `RewardDeclared`. Testa os tiers canônicos do
/// `achievements.json` (tier_definitions).
void main() {
  group('RewardDisplay.fromDeclared', () {
    test('tier trivial (xp:20 gold:25 gems:0) → 8/9/0 pós-multiplier', () {
      final d = const RewardDeclared(xp: 20, gold: 25, gems: 0);
      final r = RewardDisplay.fromDeclared(d);
      expect(r.xp, 8);     // 20 * 0.4 = 8
      expect(r.gold, 9);   // 25 * 0.35 = 8.75 → 9 round
      expect(r.gems, 0);
    });

    test('tier comum (60/75/1) → 24/26/1', () {
      final d = const RewardDeclared(xp: 60, gold: 75, gems: 1);
      final r = RewardDisplay.fromDeclared(d);
      expect(r.xp, 24);    // 60 * 0.4 = 24
      expect(r.gold, 26);  // 75 * 0.35 = 26.25 → 26 round
      expect(r.gems, 1);   // 1 * 0.7 = 0.7 → 1 round
    });

    test('tier notavel (150/200/3) → 60/70/2', () {
      final d = const RewardDeclared(xp: 150, gold: 200, gems: 3);
      final r = RewardDisplay.fromDeclared(d);
      expect(r.xp, 60);
      expect(r.gold, 70);
      expect(r.gems, 2);   // 3 * 0.7 = 2.1 → 2 round
    });

    test('tier lendaria_boost_10 (1320/1650/55) → 528/578/39', () {
      final d = const RewardDeclared(xp: 1320, gold: 1650, gems: 55);
      final r = RewardDisplay.fromDeclared(d);
      expect(r.xp, 528);   // 1320 * 0.4
      expect(r.gold, 578); // 1650 * 0.35 = 577.5 → 578 round
      expect(r.gems, 39);  // 55 * 0.7 = 38.5 → 39 round (banker's rounding)
    });

    test('items passam crus, sem multiplier', () {
      final d = const RewardDeclared(
        xp: 0,
        items: [
          RewardItemDeclared(key: 'CHEST_DEFEATED', quantity: 1),
        ],
      );
      final r = RewardDisplay.fromDeclared(d);
      expect(r.items, hasLength(1));
      expect(r.items.first.key, 'CHEST_DEFEATED');
      expect(r.items.first.quantity, 1);
    });

    test('isEmpty quando todas currencies = 0 e sem items', () {
      final d = const RewardDeclared();
      final r = RewardDisplay.fromDeclared(d);
      expect(r.isEmpty, isTrue);
    });

    test('isEmpty=false quando tem items mas xp/gold/gems=0', () {
      final d = const RewardDeclared(
        items: [RewardItemDeclared(key: 'CHEST_SECRET', quantity: 1)],
      );
      final r = RewardDisplay.fromDeclared(d);
      expect(r.isEmpty, isFalse);
    });
  });
}
