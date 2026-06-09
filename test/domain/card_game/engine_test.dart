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
}
