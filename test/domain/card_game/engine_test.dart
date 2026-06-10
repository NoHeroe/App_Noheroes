import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

/// Há uma carta com [id] na mão do lado?
bool _inHand(BoardSide side, String id) =>
    side.hand.any((c) => cardId(c) == id);

void main() {
  group('start', () {
    test('lado ativo recebe cristais e fase = jogo; deck+mão = 9 criaturas', () {
      final s = engine.start(makeLoadout(prefix: 'A'), makeLoadout(prefix: 'B'),
          seed: 1);
      expect(s.phase, MatchPhase.jogo);
      expect(s.turn, 1);
      expect(s.active.crystals, kCrystalsPerTurn);
      expect(s.opponent.crystals, 0);
      expect(s.sideA.remainingCreatureCount, 9);
      expect(s.sideA.hand.length, kHandSize);
    });
  });

  group('playCreature', () {
    test('paga cost, posiciona na frente, sai da mão e compra reposição', () {
      final aL = makeLoadout(prefix: 'A', cost: 1);
      final bL = makeLoadout(prefix: 'B');
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final activeId = s.activeSide;
      final handBefore = s.active.hand.length;
      final creatureId = s.active.handCreatures.first.id;

      s = engine.apply(s, PlayCreature(creatureId));
      final side = s.sideOf(activeId);
      expect(side.crystals, kCrystalsPerTurn - 1);
      expect(side.lanes[0]!.instanceId, creatureId);
      expect(_inHand(side, creatureId), isFalse, reason: 'saiu da mão');
      expect(side.hand.length, handBefore,
          reason: 'compra automática repõe a mão');
    });

    test('rejeita se cristais insuficientes (no-op)', () {
      // Ambos os lados com criaturas custo 99: qualquer que seja o ativo, a
      // criatura da mão é impagável (3 cristais).
      final aL = makeLoadout(prefix: 'A', cost: 99);
      final bL = makeLoadout(prefix: 'B', cost: 99);
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final creatureId = s.active.handCreatures.first.id;
      final before = s.active.crystals;
      s = engine.apply(s, PlayCreature(creatureId));
      expect(s.active.crystals, before);
      expect(s.active.lanes[0], isNull);
    });

    test('cardId inexistente é no-op', () {
      final s = engine.start(makeLoadout(prefix: 'A'), makeLoadout(prefix: 'B'),
          seed: 1);
      final s2 = engine.apply(s, const PlayCreature('nope'));
      expect(s2.active.crystals, s.active.crystals);
    });
  });

  group('front-packed (sem buraco na frente)', () {
    // Acha seed cujo lado ativo começa com ≥2 criaturas na mão.
    int seedWith2Creatures(CardLoadout a, CardLoadout b) {
      for (var seed = 0; seed < 256; seed++) {
        final s = engine.start(a, b, seed: seed);
        if (s.active.handCreatures.length >= 2) return seed;
      }
      return 0;
    }

    test('pedir lane 2 com tabuleiro vazio encaixa na FRENTE (lane 0)', () {
      final aL = makeLoadout(prefix: 'A', cost: 1);
      final bL = makeLoadout(prefix: 'B');
      var s = engine.start(aL, bL, seed: seedWithMixedHand(aL, bL));
      final id = s.active.handCreatures.first.id;

      // Pede o slot 3 (lane 2) com o tabuleiro vazio → não pode deixar buraco
      // na frente, então vai pro lane 0.
      s = engine.apply(s, PlayCreature(id, lane: 2));
      expect(s.active.lanes[0]?.instanceId, id);
      expect(s.active.lanes[1], isNull);
      expect(s.active.lanes[2], isNull);
    });

    test('jogar no lane 0 empurra o ocupante pra trás (re-indexa lanes)', () {
      final aL = makeLoadout(prefix: 'A', cost: 1);
      final bL = makeLoadout(prefix: 'B');
      var s = engine.start(aL, bL, seed: seedWith2Creatures(aL, bL));
      final first = s.active.handCreatures.first.id;
      final second = s.active.handCreatures[1].id;

      s = engine.apply(s, PlayCreature(first)); // auto → frente (lane 0)
      expect(s.active.lanes[0]?.instanceId, first);

      s = engine.apply(s, PlayCreature(second, lane: 0)); // fura a frente
      expect(s.active.lanes[0]?.instanceId, second, reason: 'novo na frente');
      expect(s.active.lanes[1]?.instanceId, first,
          reason: 'ocupante empurrado pra trás');
      expect(s.active.lanes[1]?.lane, 1, reason: 'lane re-indexada');
    });
  });

  group('sacrifício gera cristal', () {
    test('relíquia => +1, criatura => +2, máx 1/turno', () {
      final aL = makeLoadout(prefix: 'A', cost: 1);
      final bL = makeLoadout(prefix: 'B');
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final activeId = s.activeSide;
      final relicId = s.active.handRelics.first.id;
      final before = s.active.crystals;

      s = engine.apply(s, Sacrifice(relicId));
      expect(s.sideOf(activeId).crystals, before + kSacrificeRelicCrystals);
      expect(s.sideOf(activeId).sacrificedThisTurn, isTrue);

      // Segundo sacrifício no mesmo turno é no-op.
      final creatureId = s.sideOf(activeId).handCreatures.first.id;
      final afterFirst = s.sideOf(activeId).crystals;
      s = engine.apply(s, Sacrifice(creatureId));
      expect(s.sideOf(activeId).crystals, afterFirst);
    });

    test('criatura sacrificada dá +2 e sai da mão', () {
      final aL = makeLoadout(prefix: 'A');
      final bL = makeLoadout(prefix: 'B');
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final activeId = s.activeSide;
      final before = s.active.crystals;
      final creatureId = s.active.handCreatures.first.id;
      s = engine.apply(s, Sacrifice(creatureId));
      expect(
          s.sideOf(activeId).crystals, before + kSacrificeCreatureCrystals);
      expect(_inHand(s.sideOf(activeId), creatureId), isFalse);
    });
  });

  group('relíquia só no mesmo conceito', () {
    test('rejeita conceito diferente (no-op)', () {
      // Criaturas vita, relíquias corrompido.
      final aCreatures = List.generate(
          9, (i) => creature(id: 'ac$i', concept: CardConcept.vitalismo, cost: 1));
      final aRelics = List.generate(
          9, (i) => relic(id: 'ar$i', concept: CardConcept.corrompido, armor: 1));
      final a = CardLoadout(creatures: aCreatures, relics: aRelics);
      // Mesmo loadout dos dois lados para que o lado ativo tenha o mismatch.
      final seed = seedWithMixedHand(a, a);
      var s = engine.start(a, a, seed: seed);

      final creatureId = s.active.handCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId));
      final relicId = s.active.handRelics.first.id;
      s = engine.apply(s, PlayRelic(relicId, creatureId));

      final inPlay = s.active.lanes[0]!;
      expect(inPlay.relics, isEmpty);
      // Relíquia continua na mão (não consumida).
      expect(_inHand(s.active, relicId), isTrue);
    });

    test('aceita mesmo conceito e equipa', () {
      final aL = makeLoadout(prefix: 'A', concept: CardConcept.vitalismo, cost: 1);
      final bL = makeLoadout(prefix: 'B', concept: CardConcept.vitalismo, cost: 1);
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final creatureId = s.active.handCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId));
      final relicId = s.active.handRelics.first.id;
      s = engine.apply(s, PlayRelic(relicId, creatureId));
      final inPlay = s.active.lanes[0]!;
      expect(inPlay.relics.length, 1);
      expect(inPlay.armor, 1);
    });
  });

  group('relíquia custa cristais', () {
    /// Loadout com criaturas custo 1 e relíquias com [relicCost].
    CardLoadout loadoutWithRelicCost(String prefix, int relicCost,
        {bool flash = false}) {
      return CardLoadout(
        creatures: List.generate(
            9, (i) => creature(id: '${prefix}_c$i', cost: 1)),
        relics: List.generate(
            9,
            (i) => relic(
                id: '${prefix}_r$i',
                cost: relicCost,
                armor: flash ? null : 1,
                heal: flash ? 2 : null,
                flash: flash)),
      );
    }

    test('equipar debita o custo dos cristais', () {
      final aL = loadoutWithRelicCost('A', 2);
      final bL = loadoutWithRelicCost('B', 2);
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final activeId = s.activeSide;
      final creatureId = s.active.handCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId)); // 3 - 1 = 2
      final relicId = s.active.handRelics.first.id;
      s = engine.apply(s, PlayRelic(relicId, creatureId)); // 2 - 2 = 0

      final side = s.sideOf(activeId);
      expect(side.lanes[0]!.relics.length, 1);
      expect(side.crystals, kCrystalsPerTurn - 1 - 2);
      expect(_inHand(side, relicId), isFalse);
    });

    test('flash também debita o custo', () {
      final aL = loadoutWithRelicCost('A', 1, flash: true);
      final bL = loadoutWithRelicCost('B', 1, flash: true);
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final activeId = s.activeSide;
      final creatureId = s.active.handCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId)); // 3 - 1 = 2
      final relicId = s.active.handRelics.first.id;
      s = engine.apply(s, PlayRelic(relicId, creatureId)); // 2 - 1 = 1

      final side = s.sideOf(activeId);
      // Flash não fica equipada, mas o custo foi cobrado.
      expect(side.lanes[0]!.relics, isEmpty);
      expect(side.crystals, kCrystalsPerTurn - 1 - 1);
      expect(_inHand(side, relicId), isFalse);
    });

    test('sem cristais suficientes = no-op', () {
      final aL = loadoutWithRelicCost('A', 3);
      final bL = loadoutWithRelicCost('B', 3);
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final creatureId = s.active.handCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId)); // 3 - 1 = 2 < custo 3
      final relicId = s.active.handRelics.first.id;
      final before = s;
      s = engine.apply(s, PlayRelic(relicId, creatureId));

      expect(identical(s, before), isTrue, reason: 'deve ser no-op');
      expect(s.active.lanes[0]!.relics, isEmpty);
      expect(_inHand(s.active, relicId), isTrue);
      expect(s.active.crystals, kCrystalsPerTurn - 1);
    });

    test('bot não propõe relíquia impagável', () {
      final s = engine.start(loadoutWithRelicCost('A', 99),
          loadoutWithRelicCost('B', 99), seed: 1);
      final actions = engine.botActions(s);

      expect(actions.whereType<PlayRelic>(), isEmpty,
          reason: 'relíquias custo 99 nunca cabem nos cristais');
      // E toda ação proposta é aplicável (nenhum no-op).
      var sim = s;
      for (final a in actions) {
        if (a is Pass) continue;
        final after = engine.apply(sim, a);
        expect(identical(after, sim), isFalse,
            reason: 'bot propôs ação inválida: $a');
        sim = after;
      }
    });

    test('bot equipa relíquia pagável normalmente', () {
      // Relíquias custo 0: sempre pagáveis → o bot deve propor PlayRelic.
      // (seed escolhido pra mão inicial mista.)
      final aL = loadoutWithRelicCost('A', 0);
      final bL = loadoutWithRelicCost('B', 0);
      final s = engine.start(aL, bL, seed: seedWithMixedHand(aL, bL));
      final actions = engine.botActions(s);
      expect(actions.whereType<PlayRelic>(), isNotEmpty);
    });
  });
}
