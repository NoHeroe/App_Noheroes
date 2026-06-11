import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

void main() {
  group('cgScaleStat (+10%/nível, ceil)', () {
    test('nível 1 não muda', () {
      expect(cgScaleStat(10, 1), 10);
      expect(cgScaleStat(0, 5), 0);
    });
    test('escala arredondando pra cima', () {
      expect(cgScaleStat(10, 2), 11); // 11.0
      expect(cgScaleStat(10, 3), 12); // 12.0
      expect(cgScaleStat(7, 2), 8); // 7.7 -> 8
      expect(cgScaleStat(10, 8), 17); // *1.7
    });
  });

  test('CreatureCard.effective* usa o nível', () {
    final c = const CreatureCard(
      id: 'c1',
      nome: 'X',
      concepts: const [CardConcept.magico],
      cost: 2,
      atk: 10,
      hp: 20,
      damageType: DamageType.magico,
      rarity: Rarity.comum,
    ).withLevel(3);
    expect(c.level, 3);
    expect(c.effectiveAtk, 12); // ceil(10*1.2)
    expect(c.effectiveHp, 24); // ceil(20*1.2)
  });

  test('CreatureInPlay escala stats da carta + relíquia pelo nível', () {
    final creature = const CreatureCard(
      id: 'c1',
      nome: 'Guerreiro',
      concepts: const [CardConcept.corrompido],
      cost: 2,
      atk: 10,
      hp: 20,
      damageType: DamageType.corpoACorpo,
      rarity: Rarity.comum,
    ).withLevel(2); // +10%

    final relic = const RelicCard(
      id: 'r1',
      nome: 'Lâmina',
      concepts: const [CardConcept.corrompido],
      grants: const RelicGrants(atkBonus: 4, hpBonus: 10, rawEffect: ''),
      rarity: Rarity.comum,
    ).withLevel(2); // +10% nos bônus

    final inPlay = CreatureInPlay(
      card: creature,
      currentHp: 22,
      lane: 0,
      relics: [relic],
    );

    // atk: ceil(10*1.1)=11 + ceil(4*1.1)=5 = 16
    expect(inPlay.atk, 16);
    // maxHp: ceil(20*1.1)=22 + ceil(10*1.1)=11 = 33
    expect(inPlay.maxHp, 33);
  });

  test('nível 1 (base) preserva o comportamento antigo', () {
    final creature = const CreatureCard(
      id: 'c1',
      nome: 'Base',
      concepts: const [CardConcept.magico],
      cost: 1,
      atk: 5,
      hp: 8,
      damageType: DamageType.magico,
      rarity: Rarity.comum,
    );
    final inPlay =
        CreatureInPlay(card: creature, currentHp: 8, lane: 0);
    expect(inPlay.atk, 5);
    expect(inPlay.maxHp, 8);
  });
}
