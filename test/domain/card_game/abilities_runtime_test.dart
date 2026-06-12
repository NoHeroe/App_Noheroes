// Habilidades runtime (as 12 dos dados reais): normalização de keywords,
// Escudo, Ataque Duplo, Pisotear, Roubo de PV, Inspirar, Investida, Silêncio,
// Cristal de Drenagem. (Provocar/Furtividade/Voo/Alcance estão em
// positional_combat_test.dart.)
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

MatchState _stateWith({
  required List<CreatureInPlay?> aLanes,
  required List<CreatureInPlay?> bLanes,
  SideId activeSide = SideId.a,
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
    activeSide: activeSide,
    turn: 2,
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
  List<RelicCard> relics = const <RelicCard>[],
}) {
  return CreatureInPlay(
    card: creature(
        id: id, atk: atk, hp: hp, damageType: type, abilities: abilities),
    currentHp: hp,
    lane: 0,
    relics: armor > 0
        ? [...relics, relic(id: '${id}_armor', armor: armor)]
        : relics,
  );
}

CreatureInPlay _find(BoardSide side, String id) =>
    side.creaturesInPlay.firstWhere((c) => c.instanceId == id);

void main() {
  group('normalização de keywords (AbilityKeyword)', () {
    test('canoniza variantes dos dados (com/sem espaço e acento)', () {
      expect(abilityKeywordFromString('Ataque Duplo'),
          AbilityKeyword.ataqueDuplo);
      expect(abilityKeywordFromString('AtaqueDuplo'),
          AbilityKeyword.ataqueDuplo);
      expect(abilityKeywordFromString('Silêncio'), AbilityKeyword.silencio);
      expect(abilityKeywordFromString('Silencio'), AbilityKeyword.silencio);
      expect(abilityKeywordFromString('Cristal de Drenagem'),
          AbilityKeyword.cristalDeDrenagem);
      expect(abilityKeywordFromString('Roubo de PV'),
          AbilityKeyword.rouboDePv);
      expect(abilityKeywordFromString('roubo de pv'),
          AbilityKeyword.rouboDePv);
      expect(abilityKeywordFromString('Provocar'), AbilityKeyword.provocar);
      expect(abilityKeywordFromString('Voo'), AbilityKeyword.voo);
    });

    test('keywords fora do runtime retornam null (ignoradas)', () {
      expect(abilityKeywordFromString('Golpe'), isNull);
      expect(abilityKeywordFromString('Tiro Corpo a Corpo'), isNull);
      expect(abilityKeywordFromString(''), isNull);
    });

    test('label canônico para narração', () {
      expect(abilityKeywordLabel(AbilityKeyword.ataqueDuplo), 'Ataque Duplo');
      expect(abilityKeywordLabel(AbilityKeyword.silencio), 'Silêncio');
      expect(abilityKeywordLabel(AbilityKeyword.cristalDeDrenagem),
          'Cristal de Drenagem');
    });

    test('criatura soma keywords inatas + concedidas por relíquia equipada',
        () {
      final c = inPlay(
        id: 'c',
        abilities: ['Escudo'],
        relics: [
          relic(id: 'r', abilities: ['AtaqueDuplo', 'Silencio'])
        ],
      );
      expect(
          c.keywords,
          containsAll([
            AbilityKeyword.escudo,
            AbilityKeyword.ataqueDuplo,
            AbilityKeyword.silencio,
          ]));
    });
  });

  group('Escudo (armadura inata)', () {
    test('reduz dano físico e SOMA com armadura de relíquia', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 5)],
        bLanes: [inPlay(id: 'def', hp: 10, armor: 1, abilities: ['Escudo'])],
      );
      final after = engine.endTurn(s);
      // armadura total = 1 (relíquia) + kEscudoArmor (1) = 2 -> dano 3.
      expect(_find(after.sideB, 'def').currentHp, 10 - (5 - 1 - kEscudoArmor));
    });
  });

  group('Ataque Duplo', () {
    test('melee da frente que acerta causa dano verdadeiro na retaguarda', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'ad', atk: 4, abilities: ['Ataque Duplo'])
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10, armor: 1),
          inPlay(id: 'b_back', hp: 10, armor: 5),
        ],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'b_front').currentHp, 7); // 4 - 1 armadura.
      // Hit extra: dano VERDADEIRO (ignora os 5 de armadura) na retaguarda.
      expect(_find(after.sideB, 'b_back').currentHp, 6);
      final procs = after.lastTurnEvents
          .whereType<AbilityTriggered>()
          .where((e) => e.ability == 'Ataque Duplo');
      expect(procs, hasLength(1));
    });

    test('sem retaguarda inimiga: nada acontece', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'ad', atk: 4, abilities: ['Ataque Duplo'])
        ],
        bLanes: [inPlay(id: 'b_only', hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(
          after.lastTurnEvents
              .whereType<AbilityTriggered>()
              .where((e) => e.ability == 'Ataque Duplo'),
          isEmpty);
    });

    test('NÃO dispara em melee da retaguarda (via Alcance)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'front', atk: 0),
          inPlay(id: 'ad', atk: 4, abilities: ['Alcance', 'Ataque Duplo']),
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_back', hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'b_front').currentHp, 6); // Alcance atacou.
      expect(_find(after.sideB, 'b_back').currentHp, 10); // sem hit extra.
      expect(
          after.lastTurnEvents
              .whereType<AbilityTriggered>()
              .where((e) => e.ability == 'Ataque Duplo'),
          isEmpty);
    });

    test('concedido por relíquia (variante "AtaqueDuplo") também dispara', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'ad', atk: 4, relics: [
            relic(id: 'r_ad', abilities: ['AtaqueDuplo'])
          ])
        ],
        bLanes: [
          inPlay(id: 'b_front', hp: 10),
          inPlay(id: 'b_back', hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'b_back').currentHp, 6);
    });
  });

  group('Pisotear', () {
    test('dano físico excedente transborda pra próxima criatura', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'pis', atk: 10, abilities: ['Pisotear'])
        ],
        bLanes: [
          inPlay(id: 'b_victim', hp: 3),
          inPlay(id: 'b_next', hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      // 10 de dano, vítima tinha 3 -> overflow 7 no próximo.
      expect(after.sideB.creaturesInPlay, hasLength(1));
      expect(after.sideB.lanes[0]!.instanceId, 'b_next'); // avançou.
      expect(after.sideB.lanes[0]!.currentHp, 3);
      final procs = after.lastTurnEvents
          .whereType<AbilityTriggered>()
          .where((e) => e.ability == 'Pisotear');
      expect(procs, hasLength(1));
    });

    test('armadura do segundo alvo reduz o transbordo (dano físico)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'pis', atk: 10, abilities: ['Pisotear'])
        ],
        bLanes: [
          inPlay(id: 'b_victim', hp: 3),
          inPlay(id: 'b_next', hp: 10, armor: 2),
        ],
      );
      final after = engine.endTurn(s);
      expect(after.sideB.lanes[0]!.currentHp, 5); // 10 - (7 - 2).
    });

    test('transbordo NÃO encadeia além da segunda criatura', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'pis', atk: 20, abilities: ['Pisotear'])
        ],
        bLanes: [
          inPlay(id: 'b_victim', hp: 3),
          inPlay(id: 'b_next', hp: 5),
          inPlay(id: 'b_third', hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      // overflow 17 mata b_next; o excesso NÃO transborda pra b_third.
      expect(after.sideB.creaturesInPlay, hasLength(1));
      expect(after.sideB.lanes[0]!.instanceId, 'b_third');
      expect(after.sideB.lanes[0]!.currentHp, 10);
    });

    test('sem morte do alvo, não transborda', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'pis', atk: 3, abilities: ['Pisotear'])
        ],
        bLanes: [
          inPlay(id: 'b_victim', hp: 10),
          inPlay(id: 'b_next', hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'b_next').currentHp, 10);
      expect(
          after.lastTurnEvents
              .whereType<AbilityTriggered>()
              .where((e) => e.ability == 'Pisotear'),
          isEmpty);
    });
  });

  group('Roubo de PV', () {
    test('ao acertar (dano > 0): +1 PV atual e máximo', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'vamp', atk: 3, hp: 10, abilities: ['Roubo de PV'])
        ],
        bLanes: [inPlay(id: 'def', hp: 20, atk: 0)],
      );
      final after = engine.endTurn(s);
      final vamp = _find(after.sideA, 'vamp');
      expect(vamp.currentHp, 10 + kRouboDePvAmount);
      expect(vamp.maxHp, 10 + kRouboDePvAmount);
      expect(
          after.lastTurnEvents
              .whereType<AbilityTriggered>()
              .where((e) => e.ability == 'Roubo de PV'),
          hasLength(1));
    });

    test('dano 0 (armadura absorve) NÃO dispara', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'vamp', atk: 2, hp: 10, abilities: ['Roubo de PV'])
        ],
        bLanes: [inPlay(id: 'def', hp: 20, atk: 0, armor: 5)],
      );
      final after = engine.endTurn(s);
      final vamp = _find(after.sideA, 'vamp');
      expect(vamp.currentHp, 10);
      expect(vamp.maxHp, 10);
    });
  });

  group('Inspirar', () {
    test('início do turno do dono: aliados (não ele) ganham +1 melee; expira',
        () {
      // Ativo = B; endTurn(B) inicia o turno de A -> Inspirar de A aplica.
      var s = _stateWith(
        aLanes: [
          inPlay(id: 'ally', atk: 2),
          inPlay(id: 'inspirer', atk: 2, abilities: ['Inspirar']),
        ],
        bLanes: [inPlay(id: 'b_dummy', atk: 0, hp: 50)],
        activeSide: SideId.b,
      );
      s = engine.endTurn(s);

      final ally = _find(s.sideA, 'ally');
      final inspirer = _find(s.sideA, 'inspirer');
      expect(ally.inspirarBonus, kInspirarBonus);
      expect(ally.effectiveAtk, 2 + kInspirarBonus);
      expect(inspirer.inspirarBonus, 0, reason: 'não inspira a si mesmo');
      // Proc narrável no lastTurnEvents do endTurn que iniciou o turno de A.
      expect(
          s.lastTurnEvents
              .whereType<AbilityTriggered>()
              .where((e) => e.ability == 'Inspirar'),
          hasLength(1));

      // Turno de A: o ally (frente) ataca com o bônus.
      s = engine.endTurn(s);
      final attack = s.lastTurnEvents
          .whereType<AttackResolved>()
          .firstWhere((e) => e.attackerCardId == 'ally');
      expect(attack.rawDamage, 2 + kInspirarBonus);
      // EXPIRA no fim do turno do dono.
      expect(_find(s.sideA, 'ally').inspirarBonus, 0);
    });

    test('vários Inspirar com bônus fixo igual: aplica 1× (não acumula)', () {
      var s = _stateWith(
        aLanes: [
          inPlay(id: 'ins1', atk: 2, abilities: ['Inspirar']),
          inPlay(id: 'ins2', atk: 2, abilities: ['Inspirar']),
          inPlay(id: 'ally', atk: 2),
        ],
        bLanes: [inPlay(id: 'b_dummy', atk: 0, hp: 50)],
        activeSide: SideId.b,
      );
      s = engine.endTurn(s); // inicia turno de A.
      expect(_find(s.sideA, 'ally').inspirarBonus, kInspirarBonus);
      expect(_find(s.sideA, 'ins1').inspirarBonus, kInspirarBonus);
      expect(_find(s.sideA, 'ins2').inspirarBonus, kInspirarBonus);
    });

    test('não vale para ataque não-melee', () {
      var s = _stateWith(
        aLanes: [
          inPlay(id: 'mage', atk: 2, type: DamageType.magico),
          inPlay(id: 'inspirer', atk: 2, abilities: ['Inspirar']),
        ],
        bLanes: [inPlay(id: 'b_dummy', atk: 0, hp: 50)],
        activeSide: SideId.b,
      );
      s = engine.endTurn(s);
      final mage = _find(s.sideA, 'mage');
      expect(mage.inspirarBonus, kInspirarBonus); // marcado...
      expect(mage.effectiveAtk, 2, reason: 'bônus só conta para melee');
    });
  });

  group('Investida', () {
    test('aplica no início do turno do dono e dura o turno do oponente', () {
      var s = _stateWith(
        aLanes: [
          inPlay(id: 'inv', atk: 2, abilities: ['Investida'])
        ],
        bLanes: [inPlay(id: 'b_dummy', atk: 0, hp: 50)],
        activeSide: SideId.b,
      );
      s = engine.endTurn(s); // inicia turno de A: Investida aplica.
      expect(_find(s.sideA, 'inv').investidaBonus, kInvestidaBonus);
      expect(
          s.lastTurnEvents
              .whereType<AbilityTriggered>()
              .where((e) => e.ability == 'Investida'),
          hasLength(1));

      s = engine.endTurn(s); // A ataca com o bônus; turno passa pra B.
      final attack = s.lastTurnEvents
          .whereType<AttackResolved>()
          .firstWhere((e) => e.attackerCardId == 'inv');
      expect(attack.rawDamage, 2 + kInvestidaBonus);
      // Persiste DURANTE o turno do oponente (até o fim do turno de B).
      expect(_find(s.sideA, 'inv').investidaBonus, kInvestidaBonus);
    });

    test('expira no fim do turno do oponente (sem reaplicação)', () {
      // Criatura de B com bônus residual mas SEM a habilidade (simula buff
      // que não será reaplicado): expira quando o turno de A (oponente) acaba.
      final buffed = inPlay(id: 'b_buffed', atk: 2, hp: 50)
          .copyWith(investidaBonus: kInvestidaBonus);
      var s = _stateWith(
        aLanes: [inPlay(id: 'a_dummy', atk: 0, hp: 50)],
        bLanes: [buffed],
        activeSide: SideId.a,
      );
      expect(_find(s.sideB, 'b_buffed').investidaBonus, kInvestidaBonus);
      s = engine.endTurn(s); // fim do turno de A -> expira Investida de B.
      expect(_find(s.sideB, 'b_buffed').investidaBonus, 0);
    });
  });

  group('Silêncio (aura)', () {
    test('inimigo com Silêncio vivo bloqueia mágico E cura do lado ativo', () {
      final wounded = inPlay(id: 'wounded', atk: 0, hp: 10)
          .copyWith(currentHp: 5);
      final s = _stateWith(
        aLanes: [
          wounded,
          inPlay(id: 'mage', atk: 5, type: DamageType.magico),
          inPlay(id: 'healer', atk: 3, type: DamageType.cura),
        ],
        bLanes: [
          inPlay(id: 'b_silencer', atk: 0, hp: 10, abilities: ['Silêncio'])
        ],
      );
      final after = engine.endTurn(s);
      // Mago não atacou; curador não curou.
      expect(_find(after.sideB, 'b_silencer').currentHp, 10);
      expect(_find(after.sideA, 'wounded').currentHp, 5);
      expect(after.lastTurnEvents.whereType<HealResolved>(), isEmpty);
      final blocks = after.lastTurnEvents
          .whereType<AbilityTriggered>()
          .where((e) => e.ability == 'Silêncio')
          .toList();
      expect(blocks, hasLength(2)); // 1 por bloqueio (mago + curador).
      expect(blocks.every((e) => e.cardId == 'b_silencer'), isTrue);
    });

    test('não bloqueia melee/ranged/vitalismo', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'melee', atk: 2),
          inPlay(id: 'vit', atk: 3, type: DamageType.vitalismo),
        ],
        bLanes: [
          inPlay(id: 'b_silencer', atk: 0, hp: 20, abilities: ['Silêncio'])
        ],
      );
      final after = engine.endTurn(s);
      // melee (frente) 2 + vitalismo (qualquer posição) 3 = 5.
      expect(_find(after.sideB, 'b_silencer').currentHp, 15);
    });

    test('silenciador morto não bloqueia (aura exige estar viva)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'melee', atk: 50),
          inPlay(id: 'mage', atk: 5, type: DamageType.magico),
        ],
        bLanes: [
          inPlay(id: 'b_silencer', atk: 0, hp: 10, abilities: ['Silêncio']),
          inPlay(id: 'b_back', atk: 0, hp: 20),
        ],
      );
      final after = engine.endTurn(s);
      // melee mata o silenciador primeiro; o mago (depois na ordem) age.
      expect(_find(after.sideB, 'b_back').currentHp, 15);
    });
  });

  group('Cristal de Drenagem', () {
    test('destruir com o ataque gera pendingCrystals; credita no PRÓXIMO '
        'turno do dono', () {
      var s = _stateWith(
        aLanes: [
          inPlay(id: 'drainer', atk: 10, abilities: ['Cristal de Drenagem'])
        ],
        bLanes: [
          inPlay(id: 'b_victim', hp: 5, atk: 0),
          inPlay(id: 'b_survivor', hp: 50, atk: 0),
        ],
      );
      s = engine.endTurn(s); // A mata b_victim.
      expect(s.sideA.pendingCrystals, kCristalDeDrenagemCrystals);
      expect(
          s.lastTurnEvents
              .whereType<AbilityTriggered>()
              .where((e) => e.ability == 'Cristal de Drenagem'),
          hasLength(1));

      s = engine.endTurn(s); // turno de B acaba -> início do turno de A.
      expect(s.sideA.crystals, kCrystalsPerTurn + kCristalDeDrenagemCrystals);
      expect(s.sideA.pendingCrystals, 0);
    });

    test('sem morte, sem cristal', () {
      var s = _stateWith(
        aLanes: [
          inPlay(id: 'drainer', atk: 2, abilities: ['Cristal de Drenagem'])
        ],
        bLanes: [inPlay(id: 'b_tank', hp: 50, atk: 0)],
      );
      s = engine.endTurn(s);
      expect(s.sideA.pendingCrystals, 0);
    });
  });

  group('partida bot vs bot com habilidades', () {
    test('roda até o fim sem travar', () {
      CardLoadout abilityLoadout(String prefix) {
        final abilitySets = <List<String>>[
          ['Provocar'],
          ['Escudo'],
          ['Voo'],
          ['Ataque Duplo'],
          ['Alcance'],
          ['Inspirar'],
          ['Pisotear'],
          ['Silêncio'],
          ['Furtividade', 'Roubo de PV'],
        ];
        final types = <DamageType>[
          DamageType.corpoACorpo,
          DamageType.aDistancia,
          DamageType.magico,
          DamageType.vitalismo,
          DamageType.cura,
          DamageType.corpoACorpo,
          DamageType.corpoACorpo,
          DamageType.aDistancia,
          DamageType.magico,
        ];
        final creatures = <CreatureCard>[
          for (var i = 0; i < 9; i++)
            creature(
              id: '${prefix}_c$i',
              cost: 1 + (i % 3),
              atk: 2 + (i % 4),
              hp: 6 + i,
              damageType: types[i],
              abilities: abilitySets[i],
            ),
        ];
        final relics = <RelicCard>[
          for (var i = 0; i < 9; i++)
            relic(
              id: '${prefix}_r$i',
              cost: i % 2,
              armor: i.isEven ? 1 : null,
              abilities: i == 0
                  ? const ['Investida']
                  : i == 1
                      ? const ['AtaqueDuplo']
                      : const <String>[],
            ),
        ];
        return CardLoadout(creatures: creatures, relics: relics);
      }

      for (final seed in [1, 7, 99, 12345]) {
        var s = engine.start(abilityLoadout('A'), abilityLoadout('B'),
            seed: seed);
        var guard = 0;
        while (!s.isOver && guard++ < 500) {
          for (final act in engine.botActions(s)) {
            s = engine.apply(s, act);
          }
          s = engine.endTurn(s);
        }
        expect(s.isOver, isTrue, reason: 'seed $seed não terminou');
        expect(s.winner, isNotNull);
      }
    });
  });
}
