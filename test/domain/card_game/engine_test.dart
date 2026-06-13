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
      expect(s.active.crystals, kStartingCrystals);
      expect(s.opponent.crystals, 0);
      expect(s.sideA.remainingCreatureCount, 9);
      // Turno 1 = PREPARATÓRIO: ninguém compra (nem a grátis); os dois lados
      // ficam com o deal inicial de 4.
      expect(s.active.hand.length, kInitialHandSize);
      expect(s.opponent.hand.length, kInitialHandSize);
    });
  });

  group('playCreature', () {
    test('paga cost, posiciona na frente, sai da mão SEM repor (ADR-0028)', () {
      final aL = makeLoadout(prefix: 'A', cost: 1);
      final bL = makeLoadout(prefix: 'B');
      final seed = seedWithMixedHand(aL, bL);
      var s = engine.start(aL, bL, seed: seed);
      final activeId = s.activeSide;
      final handBefore = s.active.hand.length;
      final creatureId = s.active.handCreatures.first.id;

      s = engine.apply(s, PlayCreature(creatureId));
      final side = s.sideOf(activeId);
      expect(side.crystals, kStartingCrystals - 1);
      expect(side.lanes[0]!.instanceId, creatureId);
      expect(_inHand(side, creatureId), isFalse, reason: 'saiu da mão');
      // ADR-0028: sem auto-refill — a mão encolhe ao jogar.
      expect(side.hand.length, handBefore - 1,
          reason: 'mão não repõe automaticamente ao jogar');
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

  group('tabuleiro CHEIO: jogar criatura é PROIBIDO (CEO 2026-06-13)', () {
    // Seed cujo lado ativo começa com ≥4 criaturas na mão. Custo 0 isola o
    // motivo do no-op (tabuleiro cheio, NÃO falta de cristais).
    int seedWith4Creatures(CardLoadout a, CardLoadout b) {
      for (var seed = 0; seed < 256; seed++) {
        final s = engine.start(a, b, seed: seed);
        if (s.active.handCreatures.length >= 4) return seed;
      }
      return -1;
    }

    test('com 3 criaturas em jogo, a 4ª é no-op (sem empurrar pra mão)', () {
      final aL = makeLoadout(prefix: 'A', cost: 0);
      final bL = makeLoadout(prefix: 'B', cost: 0);
      final seed = seedWith4Creatures(aL, bL);
      expect(seed, isNonNegative,
          reason: 'precisa de 4 criaturas na mão inicial');
      var s = engine.start(aL, bL, seed: seed);
      final ids = s.active.handCreatures.take(4).map((c) => c.id).toList();
      s = engine.apply(s, PlayCreature(ids[0]));
      s = engine.apply(s, PlayCreature(ids[1]));
      s = engine.apply(s, PlayCreature(ids[2]));
      expect(s.active.creaturesInPlay.length, kLaneCount,
          reason: 'as 3 lanes encheram');
      final handBefore = s.active.hand.length;
      final crystalsBefore = s.active.crystals;

      // 4ª jogada com o tabuleiro cheio → no-op TOTAL (removido o "empurra
      // a última pra mão", CEO 2026-06-13).
      final s2 = engine.apply(s, PlayCreature(ids[3]));
      expect(s2.active.creaturesInPlay.length, kLaneCount,
          reason: 'a 4ª NÃO entra');
      expect(_inHand(s2.active, ids[3]), isTrue,
          reason: 'a 4ª continua na mão (não empurrada nem descartada)');
      expect(s2.active.hand.length, handBefore, reason: 'mão intacta');
      expect(s2.active.crystals, crystalsBefore, reason: 'cristais intactos');
    });
  });

  group('relíquia de ATK genérica = capacidade MELEE (CEO 2026-06-13)', () {
    CreatureInPlay withAtkRelic(DamageType type) => CreatureInPlay(
          card: creature(id: 'c_${type.name}', atk: 3, damageType: type),
          currentHp: 5,
          lane: 0,
          relics: [relic(id: 'r_${type.name}', atkBonus: 5)],
        );

    test('corpo a corpo: bônus soma no próprio melee (3+5=8)', () {
      expect(withAtkRelic(DamageType.corpoACorpo).atk, 8);
    });
    test('à distância: bônus vira ATAQUE MELEE; projétil NÃO infla', () {
      final c = withAtkRelic(DamageType.aDistancia);
      // O projétil (à distância) continua 3 — não é inflado pelo +5 genérico.
      final ranged =
          c.attacks.firstWhere((a) => a.type == DamageType.aDistancia);
      expect(ranged.value, 3);
      // E o atirador GANHA um golpe corpo-a-corpo de 5 (regra "+1 atk" = melee).
      final melee =
          c.attacks.where((a) => a.type == DamageType.corpoACorpo).toList();
      expect(melee, hasLength(1));
      expect(melee.first.value, 5);
    });
    test('mágico: bônus genérico IGNORADO (não ganha melee; fica 3)', () {
      final c = withAtkRelic(DamageType.magico);
      expect(c.atk, 3);
      expect(c.attacks.any((a) => a.type == DamageType.corpoACorpo), isFalse);
    });
    test('vitalismo: bônus genérico IGNORADO (fica 3)', () {
      expect(withAtkRelic(DamageType.vitalismo).atk, 3);
    });
  });

  group('ReturnToHand (recuar criatura pra mão)', () {
    test('recua criatura própria pra mão por kReturnVoluntaryCost', () {
      final aL = makeLoadout(prefix: 'A', cost: 1);
      final bL = makeLoadout(prefix: 'B');
      var s = engine.start(aL, bL, seed: seedWithMixedHand(aL, bL));
      final id = s.active.handCreatures.first.id;
      s = engine.apply(s, PlayCreature(id)); // crystals 3-1=2
      expect(s.active.lanes[0]?.instanceId, id);
      final before = s.active.crystals;

      s = engine.apply(s, ReturnToHand(id)); // 2-2=0
      expect(s.active.lanes[0], isNull, reason: 'saiu do tabuleiro');
      expect(s.active.crystals, before - kReturnVoluntaryCost);
      expect(_inHand(s.active, id), isTrue, reason: 'voltou pra mão');
    });

    test('sem cristais suficientes é no-op', () {
      final aL = makeLoadout(prefix: 'A', cost: 1);
      final bL = makeLoadout(prefix: 'B');
      var s = engine.start(aL, bL, seed: seedWithMixedHand(aL, bL));
      final id = s.active.handCreatures.first.id;
      s = engine.apply(s, PlayCreature(id));
      s = engine.apply(s, ReturnToHand(id)); // crystals 2->0
      // Sem criatura em jogo e 0 cristais: nova tentativa é no-op.
      final s2 = engine.apply(s, ReturnToHand(id));
      expect(identical(s2.active, s.active) || s2.active.crystals == 0, isTrue);
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
      expect(side.crystals, kStartingCrystals - 1 - 2);
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
      expect(side.crystals, kStartingCrystals - 1 - 1);
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
      expect(s.active.crystals, kStartingCrystals - 1);
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
