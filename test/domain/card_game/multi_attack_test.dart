import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

CreatureCard _creature(DamageType type, int atk) => CreatureCard(
      id: 'c',
      nome: 'C',
      concepts: const [CardConcept.corrompido],
      cost: 2,
      atk: atk,
      hp: 10,
      damageType: type,
      rarity: Rarity.comum,
    );

RelicCard _relic({int? atkBonus, DamageType? attackType}) => RelicCard(
      id: 'r',
      nome: 'R',
      concepts: const [CardConcept.neutro],
      grants: RelicGrants(
          atkBonus: atkBonus, attackType: attackType, rawEffect: ''),
      rarity: Rarity.comum,
    );

CreatureInPlay _inPlay(CreatureCard c, {List<RelicCard> relics = const []}) =>
    CreatureInPlay(card: c, currentHp: 10, lane: 0, relics: relics);

void main() {
  group('multi-ataque', () {
    test('criatura simples → 1 ataque do tipo base', () {
      final c = _inPlay(_creature(DamageType.corpoACorpo, 4));
      expect(c.attacks, [isA<CardAttack>()]);
      expect(c.attacks.single.type, DamageType.corpoACorpo);
      expect(c.attacks.single.value, 4);
    });

    test('melee + relíquia à distância tipada → DOIS ataques (4 melee, 2 dist)',
        () {
      final c = _inPlay(
        _creature(DamageType.corpoACorpo, 4),
        relics: [_relic(atkBonus: 2, attackType: DamageType.aDistancia)],
      );
      expect(c.attacks.length, 2);
      final melee = c.attacks.firstWhere((a) => a.type == DamageType.corpoACorpo);
      final ranged = c.attacks.firstWhere((a) => a.type == DamageType.aDistancia);
      expect(melee.value, 4);
      expect(ranged.value, 2); // NÃO vira 6 à distância (bug corrigido)
    });

    test('relíquia do MESMO tipo soma no ataque', () {
      final c = _inPlay(
        _creature(DamageType.aDistancia, 3),
        relics: [_relic(atkBonus: 2, attackType: DamageType.aDistancia)],
      );
      expect(c.attacks.single.type, DamageType.aDistancia);
      expect(c.attacks.single.value, 5);
    });

    test('bônus genérico (sem attackType) só vale p/ tipo físico', () {
      // base mágico + relíquia genérica +5 → NÃO soma (mágico não escala genérico)
      final mag = _inPlay(_creature(DamageType.magico, 4),
          relics: [_relic(atkBonus: 5)]);
      expect(mag.attacks.single.value, 4);
      // base melee + relíquia genérica +5 → soma
      final mel = _inPlay(_creature(DamageType.corpoACorpo, 4),
          relics: [_relic(atkBonus: 5)]);
      expect(mel.attacks.single.value, 9);
    });

    test('buffs temporários (inspirar/investida) só no ataque melee', () {
      final c = CreatureInPlay(
        card: _creature(DamageType.corpoACorpo, 4),
        currentHp: 10,
        lane: 0,
        relics: [_relic(atkBonus: 2, attackType: DamageType.aDistancia)],
        inspirarBonus: 1,
        investidaBonus: 2,
      );
      final melee = c.attacks.firstWhere((a) => a.type == DamageType.corpoACorpo);
      final ranged = c.attacks.firstWhere((a) => a.type == DamageType.aDistancia);
      expect(melee.value, 4 + 3); // base + buffs
      expect(ranged.value, 2); // sem buffs
    });

    test('relíquia à distância SEM atk_bonus não cria ataque (degrada seguro)',
        () {
      final c = _inPlay(
        _creature(DamageType.corpoACorpo, 4),
        relics: [_relic(attackType: DamageType.aDistancia)],
      );
      expect(c.attacks.single.type, DamageType.corpoACorpo);
      expect(c.attacks.single.value, 4);
    });
  });
}
