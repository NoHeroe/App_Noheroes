// Combate POSICIONAL fiel a `tipos_de_dano.md` (seção "Padrões de ataque por
// tipo — cravados"): elegibilidade por posição, alvos por tipo, Provocar,
// Furtividade e Voo.
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

/// Monta um estado com criaturas já posicionadas (ordem da lista = lane),
/// lado ativo = A, fase = jogo. `null` na lista deixa a lane vazia.
MatchState _stateWith({
  required List<CreatureInPlay?> aLanes,
  required List<CreatureInPlay?> bLanes,
  int seed = 42,
}) {
  List<CreatureInPlay?> pad(List<CreatureInPlay?> xs) {
    final l = List<CreatureInPlay?>.filled(kLaneCount, null);
    for (var i = 0; i < xs.length && i < kLaneCount; i++) {
      l[i] = xs[i]?.copyWith(lane: i);
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
    rng: makeRng(seed),
  );
}

CreatureInPlay inPlay({
  required String id,
  int atk = 3,
  int hp = 10,
  int armor = 0,
  DamageType type = DamageType.corpoACorpo,
  List<String> abilities = const <String>[],
}) {
  return CreatureInPlay(
    card: creature(
        id: id, atk: atk, hp: hp, damageType: type, abilities: abilities),
    currentHp: hp,
    lane: 0,
    relics: armor > 0 ? [relic(id: '${id}_armor', armor: armor)] : const [],
  );
}

/// HP atual da criatura [id] no lado [side] (em jogo).
int _hpOf(BoardSide side, String id) =>
    side.creaturesInPlay.firstWhere((c) => c.instanceId == id).currentHp;

void main() {
  group('elegibilidade: corpoACorpo', () {
    test('melee na retaguarda NÃO ataca', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'back', atk: 5),
        ],
        bLanes: [inPlay(id: 'def', hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 10); // só o dummy atk 0 atacou.
      expect(
        after.lastTurnEvents
            .whereType<AttackResolved>()
            .where((e) => e.attackerCardId == 'back'),
        isEmpty,
        reason: 'melee fora da frente não ataca',
      );
    });

    test('melee na retaguarda COM Alcance ataca (mira a frente)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'back', atk: 5, abilities: ['Alcance']),
        ],
        bLanes: [inPlay(id: 'def', hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 5); // 10 - 5 (Alcance).
    });

    test('melee sozinho ocupa a frente e ataca normalmente', () {
      final s = _stateWith(
        // Lane 0 vazia: sozinho na lane 2, ele É a linha de frente.
        aLanes: [null, null, inPlay(id: 'solo', atk: 4)],
        bLanes: [inPlay(id: 'def', hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 6);
    });
  });

  group('elegibilidade: aDistancia', () {
    test('ranged na frente (sozinho) NÃO ataca', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'archer', atk: 5, type: DamageType.aDistancia)],
        bLanes: [inPlay(id: 'def', hp: 10, atk: 0)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 10);
      expect(after.lastTurnEvents.whereType<AttackResolved>(), isEmpty);
      // "Tiro Corpo a Corpo" liberaria da frente — não existe nos dados reais
      // (sem runtime no MVP).
    });

    test('ranged na retaguarda ataca a lane OPOSTA (mesmo índice)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'archer', atk: 3, type: DamageType.aDistancia),
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_opp', hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'b_opp'), 7); // lane oposta (índice 1).
      expect(_hpOf(after.sideB, 'b_front'), 10);
    });

    test('lane oposta vazia -> fallback na frente inimiga', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          null,
          inPlay(id: 'archer', atk: 3, type: DamageType.aDistancia),
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_mid', hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      // Oposta do archer (lane 2) vazia -> frente.
      expect(_hpOf(after.sideB, 'b_front'), 7);
      expect(_hpOf(after.sideB, 'b_mid'), 10);
    });
  });

  group('elegibilidade: magico e vitalismo', () {
    test('magico ataca de qualquer posição, no menor PV atual', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'mid', atk: 0),
          inPlay(id: 'mage', atk: 3, type: DamageType.magico),
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_weak', hp: 4),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'b_weak'), 1);
      expect(_hpOf(after.sideB, 'b_front'), 10);
    });

    test('vitalismo ataca da retaguarda, mira a frente e ignora armadura', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'vit', atk: 5, type: DamageType.vitalismo),
        ],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 4)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 5); // ignora armadura (verdadeiro).
    });
  });

  group('cura posicional', () {
    test('cura de qualquer posição, no aliado mais ferido', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0).copyWith(currentHp: 6),
          inPlay(id: 'mid', atk: 0).copyWith(currentHp: 2),
          inPlay(id: 'healer', atk: 3, type: DamageType.cura),
        ],
        bLanes: [inPlay(id: 'enemy', atk: 0, hp: 50)],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'mid'), 5); // 2 + 3 (mais ferido).
      expect(_hpOf(after.sideA, 'front'), 6);
    });
  });

  group('Provocar', () {
    test('redireciona aDistancia para o provocador', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'archer', atk: 3, type: DamageType.aDistancia),
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_opp', hp: 10),
          inPlay(id: 'b_taunt', hp: 10, abilities: ['Provocar']),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'b_taunt'), 7); // redirecionado.
      expect(_hpOf(after.sideB, 'b_opp'), 10);
      expect(_hpOf(after.sideB, 'b_front'), 10);
    });

    test('redireciona magico para o provocador (de menor lane se vários)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'mage', atk: 3, type: DamageType.magico)],
        bLanes: [
          inPlay(id: 'b_weak', hp: 2),
          inPlay(id: 'b_taunt1', hp: 10, abilities: ['Provocar']),
          inPlay(id: 'b_taunt2', hp: 10, abilities: ['Provocar']),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'b_taunt1'), 7); // menor lane entre os dois.
      expect(_hpOf(after.sideB, 'b_taunt2'), 10);
      expect(_hpOf(after.sideB, 'b_weak'), 2); // menor PV ignorado: provocado.
    });

    test('NÃO redireciona melee (continua na frente)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'melee', atk: 3)],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_taunt', hp: 10, abilities: ['Provocar']),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'b_front'), 7);
      expect(_hpOf(after.sideB, 'b_taunt'), 10);
    });
  });

  group('Furtividade', () {
    test('bloqueia aDistancia na lane oposta -> cai pra frente', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'archer', atk: 3, type: DamageType.aDistancia),
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_sneak', hp: 10, abilities: ['Furtividade']),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'b_sneak'), 10); // protegida na retaguarda.
      expect(_hpOf(after.sideB, 'b_front'), 7); // fallback.
    });

    test('bloqueia magico no menor PV -> pula pro próximo válido', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'mage', atk: 3, type: DamageType.magico)],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_sneak', hp: 2, abilities: ['Furtividade']),
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'b_sneak'), 2);
      expect(_hpOf(after.sideB, 'b_front'), 7);
    });

    test('NÃO protege a frente', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'archer', atk: 3, type: DamageType.aDistancia),
        ],
        bLanes: [inPlay(id: 'b_sneaky_front', hp: 10, abilities: ['Furtividade'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'b_sneaky_front'), 7);
    });

    test('Provocar furtivo na retaguarda: redirecionamento falha -> frente', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'archer', atk: 3, type: DamageType.aDistancia),
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_both', hp: 10, abilities: ['Provocar', 'Furtividade']),
        ],
      );
      final after = engine.endTurn(s);
      // Provocador está furtivo na retaguarda: não pode ser alvo; nem a lane
      // oposta (ele mesmo) -> frente.
      expect(_hpOf(after.sideB, 'b_both'), 10);
      expect(_hpOf(after.sideB, 'b_front'), 7);
    });
  });

  group('Voo (determinístico por seed)', () {
    MatchState meleeVsVoo(int seed) => _stateWith(
          aLanes: [inPlay(id: 'melee', atk: 5)],
          bLanes: [
            inPlay(id: 'b_fly', hp: 10, atk: 0, abilities: ['Voo'])
          ],
          seed: seed,
        );

    test('existe seed que evade e seed que acerta; ambas determinísticas', () {
      int? evadeSeed;
      int? hitSeed;
      for (var seed = 0; seed < 100; seed++) {
        final after = engine.endTurn(meleeVsVoo(seed));
        final evaded =
            after.lastTurnEvents.whereType<AttackEvaded>().isNotEmpty;
        if (evaded) {
          expect(after.sideB.lanes[0]!.currentHp, 10, reason: 'evadiu: dano 0');
          expect(after.lastTurnEvents.whereType<AttackResolved>(), isEmpty);
          evadeSeed ??= seed;
        } else {
          expect(after.sideB.lanes[0]!.currentHp, 5);
          hitSeed ??= seed;
        }
        if (evadeSeed != null && hitSeed != null) break;
      }
      expect(evadeSeed, isNotNull, reason: '50% de evasão em 100 seeds');
      expect(hitSeed, isNotNull);

      // Determinismo: repetir a mesma seed dá o mesmo resultado.
      final again = engine.endTurn(meleeVsVoo(evadeSeed!));
      expect(again.lastTurnEvents.whereType<AttackEvaded>(), isNotEmpty);
      final again2 = engine.endTurn(meleeVsVoo(hitSeed!));
      expect(again2.lastTurnEvents.whereType<AttackEvaded>(), isEmpty);
    });

    test('atacante COM Voo nunca é evadido por alvo voador', () {
      for (var seed = 0; seed < 30; seed++) {
        final s = _stateWith(
          aLanes: [inPlay(id: 'flyer', atk: 5, abilities: ['Voo'])],
          bLanes: [
            inPlay(id: 'b_fly', hp: 10, atk: 0, abilities: ['Voo'])
          ],
          seed: seed,
        );
        final after = engine.endTurn(s);
        expect(after.lastTurnEvents.whereType<AttackEvaded>(), isEmpty);
        expect(after.sideB.lanes[0]!.currentHp, 5);
      }
    });

    test('magico nunca é evadido por Voo', () {
      for (var seed = 0; seed < 30; seed++) {
        final s = _stateWith(
          aLanes: [inPlay(id: 'mage', atk: 5, type: DamageType.magico)],
          bLanes: [
            inPlay(id: 'b_fly', hp: 10, atk: 0, abilities: ['Voo'])
          ],
          seed: seed,
        );
        final after = engine.endTurn(s);
        expect(after.lastTurnEvents.whereType<AttackEvaded>(), isEmpty);
        expect(after.sideB.lanes[0]!.currentHp, 5);
      }
    });
  });
}
