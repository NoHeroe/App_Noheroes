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
    turn: 3,
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
  CardConcept concept = CardConcept.vitalismo,
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
  // Armadura = POOL que DESGASTA (CEO 2026-06-12): dano físico é absorvido
  // INTEIRO (PV não cai); a armadura decai pelo dano e, se dano ≥ pool, quebra
  // (vai a 0, overkill perdido). Mágico/verdadeiro ignoram. À distância conta
  // como físico.
  group('armadura (pool que desgasta)', () {
    test('dano físico < armadura: desgasta o pool, PV intacto', () {
      // 1 PV, 3 armadura, toma 2 → sobra 1 de armadura, PV intacto.
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 2, type: DamageType.corpoACorpo)],
        bLanes: [inPlay(id: 'def', hp: 1, armor: 3)],
      );
      final after = engine.endTurn(s);
      final def = after.sideB.lanes[0]!;
      expect(def.currentHp, 1);
      expect(def.armor, 1); // 3 - 2
    });

    test('dano físico = armadura: quebra a armadura, sobrevive', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, type: DamageType.corpoACorpo)],
        bLanes: [inPlay(id: 'def', hp: 1, armor: 3)],
      );
      final after = engine.endTurn(s);
      final def = after.sideB.lanes[0]!;
      expect(def.currentHp, 1);
      expect(def.armor, 0); // quebrou
    });

    test('dano físico > armadura: absorve o golpe inteiro (overkill perdido)',
        () {
      // 1 PV, 3 armadura, toma 4 → armadura quebra e absorve tudo; sobrevive.
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 4, type: DamageType.corpoACorpo)],
        bLanes: [inPlay(id: 'def', hp: 1, armor: 3)],
      );
      final after = engine.endTurn(s);
      final def = after.sideB.lanes[0]!;
      expect(def.currentHp, 1);
      expect(def.armor, 0);
    });

    test('à distância conta como físico (também é absorvido)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'dummy', atk: 0, type: DamageType.corpoACorpo),
          inPlay(id: 'atk', atk: 5, type: DamageType.aDistancia),
        ],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 3)],
      );
      final after = engine.endTurn(s);
      final def = after.sideB.lanes[0]!;
      expect(def.currentHp, 10); // absorvido
      expect(def.armor, 0); // 5 ≥ 3 quebrou
    });

    test('mágico ignora a armadura (não desgasta)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, type: DamageType.magico)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 4)],
      );
      final after = engine.endTurn(s);
      final def = after.sideB.lanes[0]!;
      expect(def.currentHp, 5); // ignora armor
      expect(def.armor, 4); // intacta
    });

    test('vitalismo (verdadeiro) ignora a armadura', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, type: DamageType.vitalismo)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 4)],
      );
      final after = engine.endTurn(s);
      expect(after.sideB.lanes[0]!.currentHp, 5);
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

  group('magico mira menor PV', () {
    // (O alvo de aDistancia mudou para "lane oposta; senão a frente" — fiel a
    // tipos_de_dano.md; coberto em positional_combat_test.dart. A intenção
    // original deste grupo — padrão de alvo por menor PV — vale pro mágico.)
    test('magico ataca o de menor PV em qualquer lane', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, type: DamageType.magico)],
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
