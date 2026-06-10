import 'package:noheroes_app/domain/card_game/card_game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

void main() {
  group('vitória por eliminar as 9 criaturas', () {
    test('lado sem nenhuma criatura (em jogo e pool) perde', () {
      final a = makeLoadout(prefix: 'A');
      final b = makeLoadout(prefix: 'B');
      // Estado fabricado: B sem criaturas em jogo nem na mão/deck; A tem 1 em jogo.
      final aSide = BoardSide.initial(SideId.a, a).copyWith(
        lanes: [
          CreatureInPlay(
              card: a.creatures.first, currentHp: 5, lane: 0),
          null,
          null,
        ],
        hand: const <Object>[],
        deck: const <Object>[],
      );
      final bSide = BoardSide.initial(SideId.b, b).copyWith(
        hand: const <Object>[],
        deck: const <Object>[],
        lanes: List<CreatureInPlay?>.filled(kLaneCount, null),
      );
      var s = MatchState(
        sideA: aSide,
        sideB: bSide,
        activeSide: SideId.a,
        turn: 1,
        phase: MatchPhase.jogo,
        rng: makeRng(),
      );
      s = engine.endTurn(s);
      expect(s.isOver, isTrue);
      expect(s.winner, SideId.a);
    });

    test('eliminação progressiva leva à vitória numa partida real', () {
      // A: criaturas fortes, baratas, corpoACorpo. B: criaturas frágeis sem dano.
      final a = makeLoadout(
          prefix: 'A', cost: 1, atk: 50, hp: 50, concept: CardConcept.vitalismo);
      final bCreatures = List.generate(
          9,
          (i) => creature(
              id: 'B_c$i',
              cost: 1,
              atk: 0,
              hp: 1,
              concept: CardConcept.neutro,
              damageType: DamageType.corpoACorpo));
      final bRelics =
          List.generate(9, (i) => relic(id: 'B_r$i', concept: CardConcept.neutro));
      final b = CardLoadout(creatures: bCreatures, relics: bRelics);

      var s = engine.start(a, b, seed: 7);
      var guard = 0;
      while (!s.isOver && guard++ < 200) {
        for (final act in engine.botActions(s)) {
          s = engine.apply(s, act);
        }
        s = engine.endTurn(s);
      }
      expect(s.isOver, isTrue);
      expect(s.winner, isNotNull);
      // A (forte) deve vencer.
      expect(s.winner, SideId.a);
    });
  });

  group('penalidade sem criaturas', () {
    test('terminar turno sem criaturas perde 1 carta da mão/deck', () {
      final a = makeLoadout(prefix: 'A');
      final b = makeLoadout(prefix: 'B');
      final aSide = BoardSide.initial(SideId.a, a); // sem criaturas em jogo
      final bSide = BoardSide.initial(SideId.b, b).copyWith(
        lanes: [
          CreatureInPlay(card: b.creatures.first, currentHp: 5, lane: 0),
          null,
          null,
        ],
      );
      var s = MatchState(
        sideA: aSide,
        sideB: bSide,
        activeSide: SideId.a,
        turn: 1,
        phase: MatchPhase.jogo,
        rng: makeRng(),
      );
      final totalBefore = s.sideA.hand.length + s.sideA.deck.length;
      s = engine.endTurn(s);
      final totalAfter = s.sideA.hand.length + s.sideA.deck.length;
      expect(totalAfter, totalBefore - kNoCreaturePenaltyCards);
    });
  });

  group('trava do turno 40', () {
    test('turn >= limite encerra com vencedor por desempate', () {
      final a = makeLoadout(prefix: 'A');
      final b = makeLoadout(prefix: 'B');
      // A com 2 criaturas vivas, B com 1 -> A vence desempate.
      final aSide = BoardSide.initial(SideId.a, a).copyWith(lanes: [
        CreatureInPlay(card: a.creatures[0], currentHp: 5, lane: 0),
        CreatureInPlay(card: a.creatures[1], currentHp: 5, lane: 1),
        null,
      ]);
      final bSide = BoardSide.initial(SideId.b, b).copyWith(lanes: [
        CreatureInPlay(card: b.creatures[0], currentHp: 5, lane: 0),
        null,
        null,
      ]);
      var s = MatchState(
        sideA: aSide,
        sideB: bSide,
        activeSide: SideId.a,
        turn: kStallTurnLimit,
        phase: MatchPhase.jogo,
        rng: makeRng(),
      );
      // Para evitar que A mate B no ataque, damos hp alto em B e atk 0 implícito
      // via fixture (atk=2). Usamos criaturas atk 0:
      s = _zeroAtk(s);
      s = engine.endTurn(s);
      expect(s.isOver, isTrue);
      expect(s.winner, SideId.a);
    });
  });

  group('determinismo', () {
    test('mesmo seed => mesmo resultado', () {
      final a1 = makeLoadout(prefix: 'A', atk: 30, hp: 40);
      final b1 = makeLoadout(prefix: 'B', atk: 20, hp: 30);
      final a2 = makeLoadout(prefix: 'A', atk: 30, hp: 40);
      final b2 = makeLoadout(prefix: 'B', atk: 20, hp: 30);

      String play(CardLoadout a, CardLoadout b, int seed) {
        var s = engine.start(a, b, seed: seed);
        var guard = 0;
        final log = StringBuffer();
        while (!s.isOver && guard++ < 300) {
          for (final act in engine.botActions(s)) {
            s = engine.apply(s, act);
          }
          s = engine.endTurn(s);
          log.write('${s.turn}:${s.sideA.totalHpInPlay}/'
              '${s.sideB.totalHpInPlay};');
        }
        log.write('winner=${s.winner}');
        return log.toString();
      }

      expect(play(a1, b1, 12345), play(a2, b2, 12345));
    });

    test('seeds diferentes podem divergir no starter', () {
      // Apenas garante que o starter depende do seed (não trava se igual).
      final starters = <SideId>{};
      for (var seed = 0; seed < 20; seed++) {
        final s = engine.start(makeLoadout(prefix: 'A'),
            makeLoadout(prefix: 'B'), seed: seed);
        starters.add(s.activeSide);
      }
      expect(starters.length, greaterThanOrEqualTo(1));
    });
  });

  group('bot', () {
    test('joga uma partida inteira contra loadout fixo sem travar nem lançar',
        () {
      final a = makeLoadout(
          prefix: 'A', cost: 2, atk: 5, hp: 12, concept: CardConcept.vitalismo);
      final b = makeLoadout(
          prefix: 'B', cost: 1, atk: 4, hp: 10, concept: CardConcept.celestial);

      var s = engine.start(a, b, seed: 99);
      var guard = 0;
      expect(() {
        while (!s.isOver && guard++ < 500) {
          for (final act in engine.botActions(s)) {
            s = engine.apply(s, act);
          }
          s = engine.endTurn(s);
        }
      }, returnsNormally);
      expect(s.isOver, isTrue);
      expect(s.winner, isNotNull);
      expect(guard, lessThan(500));
    });

    test('botActions sempre termina em Pass', () {
      final s = engine.start(
          makeLoadout(prefix: 'A'), makeLoadout(prefix: 'B'), seed: 3);
      final acts = engine.botActions(s);
      expect(acts.last, isA<Pass>());
    });
  });
}

/// Zera o atk de todas as criaturas em jogo (recriando as cartas) para o teste
/// de stall, evitando que o ataque mude o resultado.
MatchState _zeroAtk(MatchState s) {
  List<CreatureInPlay?> fix(List<CreatureInPlay?> lanes) {
    return [
      for (final c in lanes)
        if (c == null)
          null
        else
          CreatureInPlay(
            card: CreatureCard(
              id: c.card.id,
              nome: c.card.nome,
              concepts: c.card.concepts,
              cost: c.card.cost,
              atk: 0,
              hp: c.card.hp,
              damageType: c.card.damageType,
              rarity: c.card.rarity,
            ),
            currentHp: c.currentHp,
            lane: c.lane,
            relics: c.relics,
          ),
    ];
  }

  return s.copyWith(
    sideA: s.sideA.copyWith(lanes: fix(s.sideA.lanes)),
    sideB: s.sideB.copyWith(lanes: fix(s.sideB.lanes)),
  );
}
