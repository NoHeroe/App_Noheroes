import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

void main() {
  group('CardLoadout validation', () {
    test('aceita 9 + 9', () {
      final l = makeLoadout();
      expect(l.creatures.length, 9);
      expect(l.relics.length, 9);
    });

    test('rejeita número errado de criaturas', () {
      expect(
        () => CardLoadout(
          creatures: [creature(id: 'a')],
          relics: List.generate(9, (i) => relic(id: 'r$i')),
        ),
        throwsArgumentError,
      );
    });

    test('rejeita número errado de relíquias', () {
      expect(
        () => CardLoadout(
          creatures: List.generate(9, (i) => creature(id: 'c$i')),
          relics: [relic(id: 'r')],
        ),
        throwsArgumentError,
      );
    });
  });

  group('CreatureInPlay derivados', () {
    test('armor soma das relíquias', () {
      final c = CreatureInPlay(
        card: creature(id: 'c', relicSlots: 3),
        currentHp: 5,
        lane: 0,
        relics: [
          relic(id: 'r1', armor: 2),
          relic(id: 'r2', armor: 3),
        ],
      );
      expect(c.armor, 5);
    });

    test('effectiveDamageType sobrescrito por relíquia', () {
      final c = CreatureInPlay(
        card: creature(id: 'c', damageType: DamageType.corpoACorpo),
        currentHp: 5,
        lane: 0,
        relics: [relic(id: 'r', attackType: DamageType.aDistancia)],
      );
      expect(c.effectiveDamageType, DamageType.aDistancia);
    });
  });
}
