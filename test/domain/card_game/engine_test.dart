import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

void main() {
  group('start', () {
    test('lado ativo recebe cristais e fase = jogo', () {
      final s = engine.start(makeLoadout(prefix: 'A'), makeLoadout(prefix: 'B'),
          seed: 1);
      expect(s.phase, MatchPhase.jogo);
      expect(s.turn, 1);
      expect(s.active.crystals, kCrystalsPerTurn);
      expect(s.opponent.crystals, 0);
      expect(s.sideA.poolCreatures.length, 9);
    });
  });

  group('playCreature', () {
    test('paga cost, posiciona na frente, remove do pool', () {
      var s = engine.start(makeLoadout(prefix: 'A', cost: 1),
          makeLoadout(prefix: 'B'), seed: 1);
      final activeId = s.activeSide;
      final cardId = s.active.poolCreatures.first.id;
      s = engine.apply(s, PlayCreature(cardId));
      final side = s.sideOf(activeId);
      expect(side.crystals, kCrystalsPerTurn - 1);
      expect(side.lanes[0]!.instanceId, cardId);
      expect(side.poolCreatures.any((c) => c.id == cardId), isFalse);
    });

    test('rejeita se cristais insuficientes (no-op)', () {
      var s = engine.start(makeLoadout(prefix: 'A', cost: 99),
          makeLoadout(prefix: 'B'), seed: 1);
      final cardId = s.active.poolCreatures.first.id;
      final before = s.active.crystals;
      s = engine.apply(s, PlayCreature(cardId));
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

  group('sacrifício gera cristal', () {
    test('relíquia => +1, criatura => +2, máx 1/turno', () {
      var s = engine.start(makeLoadout(prefix: 'A', cost: 1),
          makeLoadout(prefix: 'B'), seed: 1);
      final activeId = s.activeSide;
      final relicId = s.active.poolRelics.first.id;
      final before = s.active.crystals;

      s = engine.apply(s, Sacrifice(relicId));
      expect(s.sideOf(activeId).crystals, before + kSacrificeRelicCrystals);
      expect(s.sideOf(activeId).sacrificedThisTurn, isTrue);

      // Segundo sacrifício no mesmo turno é no-op.
      final creatureId = s.sideOf(activeId).poolCreatures.first.id;
      final afterFirst = s.sideOf(activeId).crystals;
      s = engine.apply(s, Sacrifice(creatureId));
      expect(s.sideOf(activeId).crystals, afterFirst);
    });

    test('criatura sacrificada dá +2', () {
      var s = engine.start(makeLoadout(prefix: 'A'), makeLoadout(prefix: 'B'),
          seed: 1);
      final activeId = s.activeSide;
      final before = s.active.crystals;
      final creatureId = s.active.poolCreatures.first.id;
      s = engine.apply(s, Sacrifice(creatureId));
      expect(
          s.sideOf(activeId).crystals, before + kSacrificeCreatureCrystals);
      expect(s.sideOf(activeId).poolCreatures.any((c) => c.id == creatureId),
          isFalse);
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
      var s = engine.start(a, a, seed: 1);

      final creatureId = s.active.poolCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId));
      final relicId = s.active.poolRelics.first.id;
      s = engine.apply(s, PlayRelic(relicId, creatureId));

      final inPlay = s.active.lanes[0]!;
      expect(inPlay.relics, isEmpty);
      // Relíquia continua no pool (não consumida).
      expect(s.active.poolRelics.any((r) => r.id == relicId), isTrue);
    });

    test('aceita mesmo conceito e equipa', () {
      var s = engine.start(
          makeLoadout(prefix: 'A', concept: CardConcept.vitalismo, cost: 1),
          makeLoadout(prefix: 'B', concept: CardConcept.vitalismo, cost: 1),
          seed: 1);
      final creatureId = s.active.poolCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId));
      final relicId = s.active.poolRelics.first.id;
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
      var s = engine.start(loadoutWithRelicCost('A', 2),
          loadoutWithRelicCost('B', 2), seed: 1);
      final activeId = s.activeSide;
      final creatureId = s.active.poolCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId)); // 3 - 1 = 2
      final relicId = s.active.poolRelics.first.id;
      s = engine.apply(s, PlayRelic(relicId, creatureId)); // 2 - 2 = 0

      final side = s.sideOf(activeId);
      expect(side.lanes[0]!.relics.length, 1);
      expect(side.crystals, kCrystalsPerTurn - 1 - 2);
      expect(side.poolRelics.any((r) => r.id == relicId), isFalse);
    });

    test('flash também debita o custo', () {
      var s = engine.start(loadoutWithRelicCost('A', 1, flash: true),
          loadoutWithRelicCost('B', 1, flash: true), seed: 1);
      final activeId = s.activeSide;
      final creatureId = s.active.poolCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId)); // 3 - 1 = 2
      final relicId = s.active.poolRelics.first.id;
      s = engine.apply(s, PlayRelic(relicId, creatureId)); // 2 - 1 = 1

      final side = s.sideOf(activeId);
      // Flash não fica equipada, mas o custo foi cobrado.
      expect(side.lanes[0]!.relics, isEmpty);
      expect(side.crystals, kCrystalsPerTurn - 1 - 1);
      expect(side.poolRelics.any((r) => r.id == relicId), isFalse);
    });

    test('sem cristais suficientes = no-op', () {
      var s = engine.start(loadoutWithRelicCost('A', 3),
          loadoutWithRelicCost('B', 3), seed: 1);
      final creatureId = s.active.poolCreatures.first.id;
      s = engine.apply(s, PlayCreature(creatureId)); // 3 - 1 = 2 < custo 3
      final relicId = s.active.poolRelics.first.id;
      final before = s;
      s = engine.apply(s, PlayRelic(relicId, creatureId));

      expect(identical(s, before), isTrue, reason: 'deve ser no-op');
      expect(s.active.lanes[0]!.relics, isEmpty);
      expect(s.active.poolRelics.any((r) => r.id == relicId), isTrue);
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
      final s = engine.start(loadoutWithRelicCost('A', 0),
          loadoutWithRelicCost('B', 0), seed: 1);
      final actions = engine.botActions(s);
      expect(actions.whereType<PlayRelic>(), isNotEmpty);
    });
  });
}
