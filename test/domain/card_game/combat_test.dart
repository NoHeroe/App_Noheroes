import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

/// Monta um estado com criaturas já posicionadas em ambos os lados,
/// lado ativo = A, fase = jogo, cristais à vontade.
MatchState _stateWith({
  required List<CreatureInPlay> aLanes,
  required List<CreatureInPlay> bLanes,
}) {
  List<CreatureInPlay?> pad(List<CreatureInPlay> xs) {
    final l = List<CreatureInPlay?>.filled(kLaneCount, null);
    for (var i = 0; i < xs.length && i < kLaneCount; i++) {
      l[i] = xs[i].copyWith(lane: i);
    }
    return l;
  }

  final a = makeLoadout(prefix: 'A');
  final b = makeLoadout(prefix: 'B');
  return MatchState(
    sideA: BoardSide.initial(SideId.a, a).copyWith(lanes: pad(aLanes)),
    sideB: BoardSide.initial(SideId.b, b).copyWith(lanes: pad(bLanes)),
    activeSide: SideId.a,
    turn: 1,
    phase: MatchPhase.jogo,
    rng: makeRng(),
  );
}

CreatureInPlay inPlay({
  required String id,
  int atk = 3,
  int hp = 10,
  int armor = 0,
  DamageType type = DamageType.corpoACorpo,
  CardConcept concept = CardConcept.vita,
}) {
  return CreatureInPlay(
    card: creature(id: id, atk: atk, hp: hp, damageType: type, concept: concept),
    currentHp: hp,
    lane: 0,
    relics: armor > 0
        ? [relic(id: '${id}_armor', concept: concept, armor: armor)]
        : const [],
  );
}

void main() {
  group('armadura', () {
    test('reduz dano físico (corpoACorpo)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, type: DamageType.corpoACorpo)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 2)],
      );
      final after = engine.endTurn(s);
      // 5 - 2 = 3 de dano. hp 10 -> 7.
      expect(after.sideB.lanes[0]!.currentHp, 7);
    });

    test('reduz dano à distância', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, type: DamageType.aDistancia)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 3)],
      );
      final after = engine.endTurn(s);
      expect(after.sideB.lanes[0]!.currentHp, 8); // 5-3=2
    });

    test('NÃO reduz dano mágico', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, type: DamageType.magico)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 4)],
      );
      final after = engine.endTurn(s);
      expect(after.sideB.lanes[0]!.currentHp, 5); // ignora armor
    });

    test('NÃO reduz vitalismo (dano verdadeiro)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, type: DamageType.vitalismo)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 4)],
      );
      final after = engine.endTurn(s);
      expect(after.sideB.lanes[0]!.currentHp, 5);
    });

    test('dano nunca fica negativo (mín 0)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 1, type: DamageType.corpoACorpo)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 5)],
      );
      final after = engine.endTurn(s);
      expect(after.sideB.lanes[0]!.currentHp, 10);
    });
  });

  group('cura', () {
    test('não estoura hp máximo', () {
      // Curador (atk grande) + aliado ferido.
      final healer =
          inPlay(id: 'heal', atk: 100, hp: 10, type: DamageType.cura);
      final wounded = inPlay(id: 'wound', hp: 10).copyWith(currentHp: 3);
      final s = _stateWith(
        aLanes: [healer, wounded],
        bLanes: [inPlay(id: 'enemy', hp: 50)],
      );
      final after = engine.endTurn(s);
      // wounded curado de 3 até no máx 10 (não 103).
      final w = after.sideA.creaturesInPlay
          .firstWhere((c) => c.instanceId == 'wound');
      expect(w.currentHp, 10);
    });

    test('cura escolhe o mais ferido', () {
      final healer =
          inPlay(id: 'heal', atk: 4, hp: 20, type: DamageType.cura);
      final a1 = inPlay(id: 'a1', hp: 20).copyWith(currentHp: 18);
      final a2 = inPlay(id: 'a2', hp: 20).copyWith(currentHp: 5);
      final s = _stateWith(
        aLanes: [healer, a1, a2],
        bLanes: [inPlay(id: 'enemy', hp: 50)],
      );
      final after = engine.endTurn(s);
      final c2 =
          after.sideA.creaturesInPlay.firstWhere((c) => c.instanceId == 'a2');
      expect(c2.currentHp, 9); // 5 + 4
    });
  });

  group('lanes avançam ao morrer da frente', () {
    test('retaguarda avança para a frente', () {
      // A com 1 atacante forte; B com frente fraca + retaguarda.
      final s = _stateWith(
        aLanes: [inPlay(id: 'killer', atk: 100, type: DamageType.corpoACorpo)],
        bLanes: [
          inPlay(id: 'front', hp: 1),
          inPlay(id: 'back', hp: 20),
        ],
      );
      final after = engine.endTurn(s);
      // front morre, back vira lane 0.
      expect(after.sideB.lanes[0]!.instanceId, 'back');
      expect(after.sideB.lanes[0]!.lane, 0);
      expect(after.sideB.lanes[1], isNull);
    });
  });

  group('corpoACorpo mira a frente', () {
    test('ataca a menor lane ocupada', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, type: DamageType.corpoACorpo)],
        bLanes: [
          inPlay(id: 'front', hp: 10),
          inPlay(id: 'back', hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      expect(after.sideB.lanes[0]!.currentHp, 7);
      expect(after.sideB.lanes[1]!.currentHp, 10);
    });
  });

  group('aDistancia/magico miram menor HP', () {
    test('aDistancia ataca o de menor HP em qualquer lane', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, type: DamageType.aDistancia)],
        bLanes: [
          inPlay(id: 'front', hp: 10),
          inPlay(id: 'weak', hp: 4),
        ],
      );
      final after = engine.endTurn(s);
      final weak =
          after.sideB.creaturesInPlay.firstWhere((c) => c.instanceId == 'weak');
      expect(weak.currentHp, 1); // 4 - 3
      expect(after.sideB.creaturesInPlay
          .firstWhere((c) => c.instanceId == 'front')
          .currentHp, 10);
    });
  });
}
