// ADR-0028 Fase A — mão de 4 (inicial 2 criaturas + 2), compra 1 grátis/round +
// extra paga, sem auto-refill, e cemitério (mortes + descartes).
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

CreatureInPlay _inPlay({required String id, int atk = 3, int hp = 10}) =>
    CreatureInPlay(
      card: creature(id: id, atk: atk, hp: hp),
      currentHp: hp,
      lane: 0,
    );

MatchState _withLanes(
    BoardSide a, BoardSide b, List<CreatureInPlay?> aL, List<CreatureInPlay?> bL,
    {SideId active = SideId.a}) {
  List<CreatureInPlay?> pad(List<CreatureInPlay?> xs) {
    final l = List<CreatureInPlay?>.filled(kLaneCount, null);
    for (var i = 0; i < xs.length && i < kLaneCount; i++) {
      l[i] = xs[i]?.copyWith(lane: i);
    }
    return l;
  }

  return MatchState(
    sideA: a.copyWith(lanes: pad(aL)),
    sideB: b.copyWith(lanes: pad(bL)),
    activeSide: active,
    turn: 2,
    phase: MatchPhase.jogo,
    rng: makeRng(1),
  );
}

void main() {
  test('mão inicial: 4 cartas, garantindo ≥2 criaturas', () {
    final s = engine.start(makeLoadout(prefix: 'A'), makeLoadout(prefix: 'B'),
        seed: 7);
    expect(s.sideA.hand.length, kHandSize); // 4
    expect(s.sideA.handCreatures.length, greaterThanOrEqualTo(kInitialHandCreatures));
    expect(s.sideB.hand.length, kHandSize);
    expect(s.sideB.handCreatures.length, greaterThanOrEqualTo(kInitialHandCreatures));
  });

  test('compra 1 GRÁTIS no início do turno (mão < 4)', () {
    final a0 = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(1));
    // Mão de 3 (deck recebe a 4ª de volta no topo).
    final a = a0.copyWith(
      hand: a0.hand.sublist(0, 3),
      deck: <Object>[a0.hand[3], ...a0.deck],
    );
    final b = BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'), makeRng(2));
    // Ativo = B (sem criaturas em jogo); ao terminar, começa o turno de A → grátis.
    final s = _withLanes(a, b, const [], const [], active: SideId.b);
    final after = engine.endTurn(s);
    expect(after.sideA.hand.length, 4, reason: '3 + 1 grátis no início do turno');
  });

  group('compra EXTRA paga (DrawCard)', () {
    BoardSide _aWithHand(int n, {int crystals = 3}) {
      final a0 = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(1));
      final removed = a0.hand.sublist(n);
      return a0.copyWith(
        hand: a0.hand.sublist(0, n),
        deck: <Object>[...removed, ...a0.deck],
        crystals: crystals,
      );
    }

    test('puxa 1 carta e debita 1 cristal', () {
      final s = _withLanes(_aWithHand(3, crystals: 3),
          BoardSide.initial(SideId.b, makeLoadout(prefix: 'B')), const [], const []);
      final after = engine.apply(s, const DrawCard());
      expect(after.sideA.hand.length, 4);
      expect(after.sideA.crystals, 3 - kExtraDrawCost);
    });

    test('mão cheia → no-op (não cobra)', () {
      final s = _withLanes(_aWithHand(4, crystals: 3),
          BoardSide.initial(SideId.b, makeLoadout(prefix: 'B')), const [], const []);
      final after = engine.apply(s, const DrawCard());
      expect(after.sideA.hand.length, 4);
      expect(after.sideA.crystals, 3);
    });

    test('sem cristais → no-op', () {
      final s = _withLanes(_aWithHand(3, crystals: 0),
          BoardSide.initial(SideId.b, makeLoadout(prefix: 'B')), const [], const []);
      final after = engine.apply(s, const DrawCard());
      expect(after.sideA.hand.length, 3);
    });
  });

  test('cemitério: sacrifício manda a carta pro cemitério', () {
    final a = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(1));
    final s = _withLanes(a, BoardSide.initial(SideId.b, makeLoadout(prefix: 'B')),
        const [], const []);
    final sacId = cardId(a.hand.first);
    final after = engine.apply(s, Sacrifice(sacId));
    expect(after.sideA.graveyard.map(cardId), contains(sacId));
  });

  test('cemitério: criatura morta em combate vai pro cemitério', () {
    final a = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(1));
    final b = BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'), makeRng(2));
    final s = _withLanes(
      a,
      b,
      [_inPlay(id: 'killer', atk: 99)],
      [_inPlay(id: 'victim', atk: 0, hp: 5)],
      active: SideId.a,
    );
    final after = engine.endTurn(s);
    expect(after.sideB.creaturesInPlay.any((c) => c.instanceId == 'victim'), isFalse);
    expect(
      after.sideB.graveyard.whereType<CreatureCard>().any((c) => c.id == 'victim'),
      isTrue,
      reason: 'a vítima morta caiu no cemitério',
    );
  });
}
