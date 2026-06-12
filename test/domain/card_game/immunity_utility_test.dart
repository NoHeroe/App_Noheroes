// Lote 6 — imunidades (Imunidade, Perseverança, Vigilante) + utilidades (Fúria,
// Encantar Armadura, Cristal Adicional).
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
}) =>
    CreatureInPlay(
      card: creature(id: id, atk: atk, hp: hp, damageType: type, abilities: abilities),
      currentHp: hp,
      lane: 0,
      relics: armor > 0 ? [relic(id: '${id}_arm', armor: armor)] : const [],
    );

CreatureInPlay _find(BoardSide s, String id) =>
    s.creaturesInPlay.firstWhere((c) => c.instanceId == id);

int _hpOf(BoardSide s, String id) => _find(s, id).currentHp;

void main() {
  group('Fúria (getter)', () {
    test('+ataque melee = PV que falta', () {
      final c = inPlay(id: 'x', atk: 3, hp: 10, abilities: ['Fúria'])
          .copyWith(currentHp: 6); // faltam 4
      expect(c.atk, 3 + 4);
    });
    test('com vida cheia não soma', () {
      final c = inPlay(id: 'x', atk: 3, hp: 10, abilities: ['Fúria']);
      expect(c.atk, 3);
    });
  });

  group('Encantar Armadura (getter)', () {
    test('com armadura existente, +1', () {
      final c = inPlay(id: 'x', abilities: ['Escudo', 'Encantar Armadura']);
      expect(c.armor, kEscudoArmor + kEncantarArmaduraBonus);
    });
    test('SEM armadura, não dá bônus', () {
      final c = inPlay(id: 'x', abilities: ['Encantar Armadura']);
      expect(c.armor, 0);
    });
  });

  group('Vigilante', () {
    test('atacante Vigilante ignora Espinhos do alvo', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10, abilities: ['Vigilante'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Espinhos'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'atk'), 10); // sem dano de espinhos.
    });
  });

  group('Perseverança', () {
    test('imune a Doença', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 2, abilities: ['Doença'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Perseverança'])],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'def').diseaseStacks, 0);
    });
  });

  group('Imunidade', () {
    test('imune a Silêncio: ataca mágico mesmo com silenciador inimigo', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'mage', atk: 4, type: DamageType.magico, abilities: ['Imunidade'])
        ],
        bLanes: [inPlay(id: 'sil', atk: 0, hp: 20, abilities: ['Silêncio'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'sil'), 16); // mágico passou (20-4).
    });

    test('imune a Desmoralizar (aura inimiga não reduz seu atk)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'demor', atk: 0, hp: 20, abilities: ['Desmoralizar'])],
        bLanes: [inPlay(id: 'bruiser', atk: 5, hp: 10, abilities: ['Imunidade'])],
        active: SideId.b, // endTurn(B) -> _beginTurn(A) aplica a aura de A em B
      );
      final after = engine.endTurn(s);
      final bruiser = _find(after.sideB, 'bruiser');
      expect(bruiser.desmoralizadoMelee, 0); // imune.
      expect(bruiser.atk, 5);
    });
  });

  group('Cristal Adicional', () {
    test('sacrificar a criatura gera cristal extra', () {
      final crystalCard =
          creature(id: 'gem', cost: 1, abilities: ['Cristal Adicional']);
      final s = MatchState(
        sideA: BoardSide(
          id: SideId.a,
          lanes: List<CreatureInPlay?>.filled(kLaneCount, null),
          crystals: 3,
          hand: <Object>[crystalCard],
          deck: const <Object>[],
          sacrificedThisTurn: false,
        ),
        sideB: BoardSide(
          id: SideId.b,
          lanes: List<CreatureInPlay?>.filled(kLaneCount, null),
          crystals: 0,
          hand: const <Object>[],
          deck: const <Object>[],
          sacrificedThisTurn: false,
        ),
        activeSide: SideId.a,
        turn: 1,
        phase: MatchPhase.jogo,
        rng: makeRng(1),
      );
      final after = engine.apply(s, const Sacrifice('gem'));
      expect(after.sideA.crystals,
          3 + kSacrificeCreatureCrystals + kCristalAdicionalCrystals);
    });
  });
}
