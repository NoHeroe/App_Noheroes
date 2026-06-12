// Testes do log estruturado de eventos do `endTurn` (MatchState.lastTurnEvents).
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

/// Monta um estado com criaturas já posicionadas em ambos os lados,
/// lado ativo = A, fase = jogo.
MatchState _stateWith({
  required List<CreatureInPlay> aLanes,
  required List<CreatureInPlay> bLanes,
  int turn = 3, // turno 1 é preparatório (sem combate); combate testa a partir do 2
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
    turn: turn,
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
  group('AttackResolved', () {
    test('corpoACorpo: damageDealt = atk - armor, rawDamage = atk', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5, type: DamageType.corpoACorpo)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 2)],
      );
      final after = engine.endTurn(s);

      final attacks = after.lastTurnEvents.whereType<AttackResolved>().toList();
      expect(attacks, hasLength(1));
      final e = attacks.single;
      expect(e.attackerSide, SideId.a);
      expect(e.attackerCardId, 'atk');
      expect(e.attackerName, 'atk');
      expect(e.targetCardId, 'def');
      expect(e.targetName, 'def');
      expect(e.damageType, DamageType.corpoACorpo);
      expect(e.rawDamage, 5);
      expect(e.damageDealt, 3); // 5 - 2 armor
      expect(e.targetHpAfter, 7);
      expect(e.targetDied, isFalse);
    });

    test('damageDealt nunca fica negativo (mín 0)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 1, type: DamageType.corpoACorpo)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 5)],
      );
      final after = engine.endTurn(s);

      final e = after.lastTurnEvents.whereType<AttackResolved>().single;
      expect(e.rawDamage, 1);
      expect(e.damageDealt, 0);
      expect(e.targetHpAfter, 10);
      expect(e.targetDied, isFalse);
    });

    test('alvo morre -> targetDied true e targetHpAfter 0', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'killer', atk: 50, type: DamageType.corpoACorpo)],
        bLanes: [inPlay(id: 'victim', hp: 10)],
      );
      final after = engine.endTurn(s);

      final e = after.lastTurnEvents.whereType<AttackResolved>().single;
      expect(e.targetCardId, 'victim');
      expect(e.targetDied, isTrue);
      expect(e.targetHpAfter, 0);
    });

    test('magico ignora armadura: damageDealt == rawDamage', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'mage', atk: 5, type: DamageType.magico)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 4)],
      );
      final after = engine.endTurn(s);

      final e = after.lastTurnEvents.whereType<AttackResolved>().single;
      expect(e.damageType, DamageType.magico);
      expect(e.rawDamage, 5);
      expect(e.damageDealt, 5);
      expect(e.targetHpAfter, 5);
    });

    test('vitalismo (dano verdadeiro) ignora armadura', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'vit', atk: 5, type: DamageType.vitalismo)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 4)],
      );
      final after = engine.endTurn(s);

      final e = after.lastTurnEvents.whereType<AttackResolved>().single;
      expect(e.damageType, DamageType.vitalismo);
      expect(e.damageDealt, 5);
      expect(e.targetHpAfter, 5);
    });

    test('ataque que encerra a partida também preenche lastTurnEvents', () {
      final a = makeLoadout(prefix: 'A');
      final b = makeLoadout(prefix: 'B');
      // B: última criatura em jogo, mão/deck vazios -> morrer = derrota de B.
      final aSide = BoardSide.initial(SideId.a, a).copyWith(lanes: [
        inPlay(id: 'killer', atk: 50).copyWith(lane: 0),
        null,
        null,
      ]);
      final bSide = BoardSide.initial(SideId.b, b).copyWith(
        hand: const <Object>[],
        deck: const <Object>[],
        lanes: [inPlay(id: 'last', hp: 5).copyWith(lane: 0), null, null],
      );
      var s = MatchState(
        sideA: aSide,
        sideB: bSide,
        activeSide: SideId.a,
        turn: 3,
        phase: MatchPhase.jogo,
        rng: makeRng(),
      );
      s = engine.endTurn(s);

      expect(s.isOver, isTrue);
      expect(s.winner, SideId.a);
      final e = s.lastTurnEvents.whereType<AttackResolved>().single;
      expect(e.targetCardId, 'last');
      expect(e.targetDied, isTrue);
    });
  });

  group('HealResolved', () {
    test('emite só quando curou de fato (>0), com clamp no hp máximo', () {
      final healer =
          inPlay(id: 'heal', atk: 100, hp: 10, type: DamageType.cura);
      final wounded = inPlay(id: 'wound', hp: 10).copyWith(currentHp: 3);
      final s = _stateWith(
        aLanes: [healer, wounded],
        bLanes: [inPlay(id: 'enemy', hp: 50, atk: 0)],
      );
      final after = engine.endTurn(s);

      final heals = after.lastTurnEvents.whereType<HealResolved>().toList();
      expect(heals, hasLength(1));
      final e = heals.single;
      expect(e.side, SideId.a);
      expect(e.healerCardId, 'heal');
      expect(e.healerName, 'heal');
      expect(e.targetCardId, 'wound');
      expect(e.targetName, 'wound');
      expect(e.amount, 7); // 3 -> 10 (clamp no máx), não 100.
    });

    test('sem alvo ferido -> nenhum HealResolved', () {
      final healer = inPlay(id: 'heal', atk: 4, hp: 10, type: DamageType.cura);
      final fullHp = inPlay(id: 'full', hp: 10); // já no máximo
      final s = _stateWith(
        aLanes: [healer, fullHp],
        bLanes: [inPlay(id: 'enemy', hp: 50, atk: 0)],
      );
      final after = engine.endTurn(s);

      expect(after.lastTurnEvents.whereType<HealResolved>(), isEmpty);
    });
  });

  group('NoCreaturePenaltyApplied', () {
    test('terminar o turno sem criaturas emite o evento da carta perdida', () {
      final a = makeLoadout(prefix: 'A');
      final b = makeLoadout(prefix: 'B');
      final aSide = BoardSide.initial(SideId.a, a); // sem criaturas em jogo
      final bSide = BoardSide.initial(SideId.b, b).copyWith(
        lanes: [inPlay(id: 'B_alive', hp: 5).copyWith(lane: 0), null, null],
      );
      var s = MatchState(
        sideA: aSide,
        sideB: bSide,
        activeSide: SideId.a,
        turn: 3,
        phase: MatchPhase.jogo,
        rng: makeRng(),
      );
      Set<String> creatureIds(BoardSide x) => <String>{
            for (final c in x.hand.whereType<CreatureCard>()) c.id,
            for (final c in x.deck.whereType<CreatureCard>()) c.id,
          };
      Set<String> relicIds(BoardSide x) => <String>{
            for (final r in x.hand.whereType<RelicCard>()) r.id,
            for (final r in x.deck.whereType<RelicCard>()) r.id,
          };
      final creatureIdsBefore = creatureIds(s.sideA);
      final relicIdsBefore = relicIds(s.sideA);

      s = engine.endTurn(s);

      final penalties =
          s.lastTurnEvents.whereType<NoCreaturePenaltyApplied>().toList();
      expect(penalties, hasLength(kNoCreaturePenaltyCards));
      final e = penalties.single;
      expect(e.side, SideId.a);
      // A carta narrada de fato saiu da mão/deck, e o tipo bate.
      if (e.wasCreature) {
        expect(creatureIdsBefore, contains(e.lostCardId));
        expect(creatureIds(s.sideA), isNot(contains(e.lostCardId)));
      } else {
        expect(relicIdsBefore, contains(e.lostCardId));
        expect(relicIds(s.sideA), isNot(contains(e.lostCardId)));
      }
      expect(e.lostCardName, e.lostCardId); // fixtures usam nome == id.
    });

    test('lado com criaturas em jogo NÃO sofre penalidade nem emite evento', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'alive', atk: 0)],
        bLanes: [inPlay(id: 'enemy', atk: 0, hp: 50)],
      );
      final after = engine.endTurn(s);
      expect(after.lastTurnEvents.whereType<NoCreaturePenaltyApplied>(),
          isEmpty);
    });
  });

  group('StallLimitReached', () {
    test('trava do turno limite emite o evento com o vencedor', () {
      // A com 2 vivas, B com 1 -> desempate favorece A. Atk 0 para não matar.
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'a1', atk: 0, hp: 5),
          inPlay(id: 'a2', atk: 0, hp: 5),
        ],
        bLanes: [inPlay(id: 'b1', atk: 0, hp: 5)],
        turn: kStallTurnLimit,
      );
      final after = engine.endTurn(s);

      expect(after.isOver, isTrue);
      expect(after.winner, SideId.a);
      final stalls =
          after.lastTurnEvents.whereType<StallLimitReached>().toList();
      expect(stalls, hasLength(1));
      expect(stalls.single.winner, SideId.a);
    });
  });

  group('semântica de lastTurnEvents', () {
    test('estado inicial (start) tem lastTurnEvents vazio', () {
      final s = engine.start(
          makeLoadout(prefix: 'A'), makeLoadout(prefix: 'B'), seed: 1);
      expect(s.lastTurnEvents, isEmpty);
    });

    test('apply (Fase de Jogo) não gera eventos', () {
      final aL = makeLoadout(prefix: 'A');
      final bL = makeLoadout(prefix: 'B');
      var s = engine.start(aL, bL, seed: seedWithMixedHand(aL, bL));
      final card = s.active.handCreatures.first;
      s = engine.apply(s, PlayCreature(card.id));
      expect(s.lastTurnEvents, isEmpty);
    });

    test('eventos são SUBSTITUÍDOS a cada endTurn (não acumulam)', () {
      // A e B com 1 criatura cada, atk baixo, hp alto: 1 ataque por turno.
      var s = _stateWith(
        aLanes: [inPlay(id: 'a1', atk: 1, hp: 50)],
        bLanes: [inPlay(id: 'b1', atk: 1, hp: 50)],
      );

      // Turno de A.
      s = engine.endTurn(s);
      expect(s.lastTurnEvents, hasLength(1));
      final first = s.lastTurnEvents.single as AttackResolved;
      expect(first.attackerSide, SideId.a);
      expect(first.attackerCardId, 'a1');

      // Turno de B: a lista é substituída, não acumulada.
      s = engine.endTurn(s);
      expect(s.lastTurnEvents, hasLength(1));
      final second = s.lastTurnEvents.single as AttackResolved;
      expect(second.attackerSide, SideId.b);
      expect(second.attackerCardId, 'b1');
    });

    test('toString dos eventos é legível (smoke)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 2)],
      );
      final after = engine.endTurn(s);
      final text = after.lastTurnEvents.single.toString();
      expect(text, contains('AttackResolved'));
      expect(text, contains('atk'));
      expect(text, contains('def'));
      expect(text, contains('dealt=3'));
    });
  });
}
