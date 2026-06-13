// Magnitudes honradas (espinhos_N / roubo_de_pv_N / escudo_N) + skills novas do
// docx 2026-06-12 (Executor, Percepção).
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

MatchState _stateWith({
  required List<CreatureInPlay?> aLanes,
  required List<CreatureInPlay?> bLanes,
  SideId active = SideId.a,
  int seed = 42,
}) {
  List<CreatureInPlay?> pad(List<CreatureInPlay?> xs) {
    final l = List<CreatureInPlay?>.filled(kLaneCount, null);
    for (var i = 0; i < xs.length && i < kLaneCount; i++) {
      l[i] = xs[i]?.copyWith(lane: i);
    }
    return l;
  }

  return MatchState(
    sideA: BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'))
        .copyWith(lanes: pad(aLanes)),
    sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'))
        .copyWith(lanes: pad(bLanes)),
    activeSide: active,
    turn: 3,
    phase: MatchPhase.jogo,
    rng: makeRng(seed),
  );
}

CreatureInPlay inPlay({
  required String id,
  int atk = 3,
  int hp = 10,
  DamageType type = DamageType.corpoACorpo,
  List<String> abilities = const <String>[],
}) =>
    CreatureInPlay(
      card:
          creature(id: id, atk: atk, hp: hp, damageType: type, abilities: abilities),
      currentHp: hp,
      lane: 0,
    );

CreatureInPlay _find(BoardSide s, String id) =>
    s.creaturesInPlay.firstWhere((c) => c.instanceId == id);
int _hpOf(BoardSide s, String id) => _find(s, id).currentHp;
bool _alive(BoardSide s, String id) =>
    s.creaturesInPlay.any((c) => c.instanceId == id);

void main() {
  group('Magnitudes (_N honrada)', () {
    test('espinhos_3 reflete 3 de dano verdadeiro ao atacante melee', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 1, hp: 10)],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['espinhos_3'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'atk'), 10 - 3);
    });

    test('roubo_de_pv_2 (vampirismo_2) cura 2 ao acertar', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'atk', atk: 3, hp: 10, abilities: ['roubo_de_pv_2'])
        ],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'atk'), 12); // +2 PV atual (e máximo)
    });

    test('escudo_4: pool de 4 (magnitude no armorMax)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10)],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['escudo_4'])],
      );
      final after = engine.endTurn(s);
      final def = _find(after.sideB, 'def');
      expect(def.currentHp, 10); // absorvido
      expect(def.armor, 1); // 4 - 3
    });
  });

  group('Executor', () {
    test('finaliza alvo que ficaria com PV baixo (≤ limite)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 1, hp: 10, abilities: ['executor'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 3)], // 3 - 1 = 2 ≤ limite
      );
      final after = engine.endTurn(s);
      expect(_alive(after.sideB, 'def'), isFalse);
    });

    test('NÃO finaliza alvo com PV acima do limite', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 1, hp: 10, abilities: ['executor'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)], // 10 - 1 = 9 > limite
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 9);
    });

    test('só executa ao causar dano (armadura absorveu → não executa)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 1, hp: 10, abilities: ['executor'])],
        bLanes: [
          CreatureInPlay(
            card: creature(id: 'def', atk: 0, hp: 3, abilities: ['escudo_4']),
            currentHp: 3,
            lane: 0,
          ),
        ],
      );
      final after = engine.endTurn(s);
      expect(_alive(after.sideB, 'def'), isTrue); // golpe foi absorvido
    });
  });

  group('Percepção', () {
    test('mira o alvo furtivo da retaguarda (mágico fura a Furtividade)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(
              id: 'mage',
              atk: 5,
              hp: 10,
              type: DamageType.magico,
              abilities: ['percepcao'])
        ],
        bLanes: [
          inPlay(id: 'front', atk: 0, hp: 10),
          inPlay(id: 'rear', atk: 0, hp: 10, abilities: ['furtividade']),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'rear'), 5); // furtividade ignorada
      expect(_hpOf(after.sideB, 'front'), 10);
    });

    test('sem Percepção, o furtivo da retaguarda fica protegido', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'mage', atk: 5, hp: 10, type: DamageType.magico)],
        bLanes: [
          inPlay(id: 'front', atk: 0, hp: 10),
          inPlay(id: 'rear', atk: 0, hp: 10, abilities: ['furtividade']),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'rear'), 10); // protegido
      expect(_hpOf(after.sideB, 'front'), 5);
    });
  });

  group('Cura (keyword)', () {
    test('faz ação de cura no aliado mais ferido (= ATK)', () {
      final healer = inPlay(
          id: 'healer',
          atk: 3,
          hp: 10,
          type: DamageType.magico,
          abilities: ['cura']);
      final ally = inPlay(id: 'ally', atk: 0, hp: 10).copyWith(currentHp: 5);
      final s = _stateWith(
        aLanes: [healer, ally],
        bLanes: [inPlay(id: 'enemy', atk: 0, hp: 20)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'ally'), 8); // 5 + 3 (ATK do healer)
    });

    test('sem ninguém ferido, cura o próprio conjurador (no-op se cheio)', () {
      final healer = inPlay(
          id: 'healer',
          atk: 3,
          hp: 10,
          type: DamageType.magico,
          abilities: ['cura']);
      final s = _stateWith(
        aLanes: [healer],
        bLanes: [inPlay(id: 'enemy', atk: 0, hp: 20)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'healer'), 10); // todos cheios → sem overheal
    });
  });

  group('Recuo (keyword)', () {
    test('retorno pra mão é GRÁTIS com a keyword Recuo', () {
      var s = _stateWith(
        aLanes: [inPlay(id: 'r', atk: 1, hp: 5, abilities: ['recuo'])],
        bLanes: [inPlay(id: 'e', atk: 0, hp: 5)],
      );
      s = s.withSide(SideId.a, s.sideA.copyWith(crystals: 5));
      final after = engine.apply(s, const ReturnToHand('r'));
      expect(after.sideA.crystals, 5); // não debitou
      expect(after.sideA.hand.whereType<CreatureCard>().any((c) => c.id == 'r'),
          isTrue);
    });

    test('sem a keyword, o retorno custa kReturnVoluntaryCost', () {
      var s = _stateWith(
        aLanes: [inPlay(id: 'n', atk: 1, hp: 5)],
        bLanes: [inPlay(id: 'e', atk: 0, hp: 5)],
      );
      s = s.withSide(SideId.a, s.sideA.copyWith(crystals: 5));
      final after = engine.apply(s, const ReturnToHand('n'));
      expect(after.sideA.crystals, 5 - kReturnVoluntaryCost);
    });
  });
}
