// Lote 7 — Espinho de Escudo, Névoa, Anti-Aéreo, Quebra de Armadura, Explosão
// Mágica, Névoa Tóxica.
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
  int armor = 0,
  DamageType type = DamageType.corpoACorpo,
  List<String> abilities = const <String>[],
  bool nevoaArmed = false,
}) =>
    CreatureInPlay(
      card: creature(id: id, atk: atk, hp: hp, damageType: type, abilities: abilities),
      currentHp: hp,
      lane: 0,
      relics: armor > 0 ? [relic(id: '${id}_arm', armor: armor)] : const [],
      nevoaArmed: nevoaArmed,
    );

CreatureInPlay _find(BoardSide s, String id) =>
    s.creaturesInPlay.firstWhere((c) => c.instanceId == id);
int _hpOf(BoardSide s, String id) => _find(s, id).currentHp;
bool _ability(MatchState s, String a) => s.lastTurnEvents
    .whereType<AbilityTriggered>()
    .any((e) => e.ability == a);

void main() {
  group('Espinho de Escudo', () {
    test('devolve dano à fonte ao sofrer dano (qualquer tipo)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10, type: DamageType.magico)],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Espinho de Escudo'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'atk'), 10 - kEspinhoDeEscudoDamage);
      expect(_ability(after, 'Espinho de Escudo'), isTrue);
    });

    test('anti-loop: fonte com Espinho de Escudo não toma de volta', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10, abilities: ['Espinho de Escudo'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Espinho de Escudo'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'atk'), 10); // não tomou de volta.
    });
  });

  group('Névoa', () {
    test('armada: o golpe é prevenido e desarma', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, hp: 10)],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Névoa'], nevoaArmed: true)],
      );
      final after = engine.endTurn(s);
      final def = _find(after.sideB, 'def');
      expect(def.currentHp, 10); // dano prevenido.
      expect(def.nevoaArmed, isFalse); // desarmou.
      expect(_ability(after, 'Névoa'), isTrue);
    });

    test('desarmada: toma o golpe e ARMA pro próximo', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, hp: 10)],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Névoa'])],
      );
      final after = engine.endTurn(s);
      final def = _find(after.sideB, 'def');
      expect(def.currentHp, 5); // tomou.
      expect(def.nevoaArmed, isTrue); // armou.
    });
  });

  test('Anti-Aéreo: não deixa o alvo voar evadir + dano extra', () {
    final s = _stateWith(
      aLanes: [inPlay(id: 'aa', atk: 3, hp: 10, abilities: ['Anti-Aéreo'])],
      bLanes: [inPlay(id: 'flyer', atk: 0, hp: 10, abilities: ['Voo'])],
    );
    final after = engine.endTurn(s);
    expect(_hpOf(after.sideB, 'flyer'), 10 - (3 + kAntiAereoBonus));
  });

  test('Quebra de Armadura: fura a armadura (dano vai ao PV) e a destrói', () {
    final s = _stateWith(
      aLanes: [inPlay(id: 'atk', atk: 5, hp: 10, abilities: ['Quebra de Armadura'])],
      bLanes: [inPlay(id: 'def', atk: 0, hp: 10, armor: 2)],
    );
    final after = engine.endTurn(s);
    // Ignora os 2 de armadura: 5 de dano direto no PV; e zera a armadura.
    expect(_hpOf(after.sideB, 'def'), 5);
    final def = after.sideB.creaturesInPlay
        .firstWhere((c) => c.instanceId == 'def');
    expect(def.armor, 0);
  });

  test('Explosão Mágica: dano mágico excedente transborda', () {
    final s = _stateWith(
      aLanes: [
        inPlay(id: 'mage', atk: 10, hp: 10, type: DamageType.magico, abilities: [
          'Explosão Mágica'
        ])
      ],
      // magico mira o MENOR PV (lane1, hp4); transborda pra lane seguinte (lane2).
      bLanes: [
        inPlay(id: 'tank', atk: 0, hp: 20),
        inPlay(id: 'weak', atk: 0, hp: 4),
        inPlay(id: 'back', atk: 0, hp: 10),
      ],
    );
    final after = engine.endTurn(s);
    expect(after.sideB.creaturesInPlay.any((c) => c.instanceId == 'weak'), isFalse);
    expect(_hpOf(after.sideB, 'back'), 10 - (10 - 4)); // transbordo de 6.
    expect(_ability(after, 'Explosão Mágica'), isTrue);
  });

  test('Névoa Tóxica: adoece todos os inimigos no início do turno', () {
    final s = _stateWith(
      aLanes: [inPlay(id: 'toxic', atk: 0, hp: 20, abilities: ['Névoa Tóxica'])],
      bLanes: [
        inPlay(id: 'b1', atk: 0, hp: 10),
        inPlay(id: 'b2', atk: 0, hp: 10),
      ],
      active: SideId.b, // endTurn(B) -> _beginTurn(A) dispara a Névoa Tóxica de A
    );
    final after = engine.endTurn(s);
    expect(_find(after.sideB, 'b1').diseaseStacks, kNevoaToxicaStacks);
    expect(_find(after.sideB, 'b2').diseaseStacks, kNevoaToxicaStacks);
    expect(_ability(after, 'Névoa Tóxica'), isTrue);
  });
}
