import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/data/services/card_match_reward_service.dart';

void main() {
  group('CardMatchReward.fromRpc', () {
    test('1ª vitória do dia: xp+gold+pacote, winNumber=1, isFirstWin', () {
      final r = CardMatchReward.fromRpc('p1', {
        'won': true,
        'xp': 30,
        'gold': 20,
        'packs': 1,
        'win_number': 1,
        'xp_result': {'previous_level': 3, 'new_level': 3},
      });
      expect(r.won, isTrue);
      expect(r.xp, 30);
      expect(r.gold, 20);
      expect(r.packs, 1);
      expect(r.winNumber, 1);
      expect(r.isFirstWinOfDay, isTrue);
      expect(r.levelUp, isNull); // mesmo nível → sem LevelUp
    });

    test('vitória além do teto: só xp simbólico, sem pacote, não é 1ª', () {
      final r = CardMatchReward.fromRpc('p1', {
        'won': true,
        'xp': 5,
        'gold': 0,
        'packs': 0,
        'win_number': 4,
        'xp_result': null,
      });
      expect(r.xp, 5);
      expect(r.gold, 0);
      expect(r.packs, 0);
      expect(r.winNumber, 4);
      expect(r.isFirstWinOfDay, isFalse);
    });

    test('derrota: consolação, sem vitória contabilizada', () {
      final r = CardMatchReward.fromRpc('p1', {
        'won': false,
        'xp': 5,
        'gold': 0,
        'packs': 0,
        'win_number': 0,
        'xp_result': null,
      });
      expect(r.won, isFalse);
      expect(r.isFirstWinOfDay, isFalse);
      expect(r.winNumber, 0);
    });

    test('level-up reconstruído do xp_result', () {
      final r = CardMatchReward.fromRpc('p1', {
        'won': true,
        'xp': 30,
        'gold': 20,
        'packs': 1,
        'win_number': 1,
        'xp_result': {'previous_level': 4, 'new_level': 5},
      });
      expect(r.levelUp, isNotNull);
      expect(r.levelUp!.previousLevel, 4);
      expect(r.levelUp!.newLevel, 5);
      expect(r.levelUp!.playerId, 'p1');
    });
  });
}
