// Lote 2 — habilidades DEFENSIVAS: Espinhos, Escudo Espelhado, Escudo Sagrado,
// Contra-Ataque, Inabalável. Cada teste monta um estado posicionado, roda a
// Fase de Ataque do lado A (engine.endTurn) e checa o resultado.
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

/// Monta um estado com criaturas já posicionadas (ordem = lane), lado ativo = A,
/// fase = jogo. Espelha o helper de `positional_combat_test`.
MatchState _stateWith({
  required List<CreatureInPlay?> aLanes,
  required List<CreatureInPlay?> bLanes,
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
    activeSide: SideId.a,
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
}) {
  return CreatureInPlay(
    card: creature(
        id: id, atk: atk, hp: hp, damageType: type, abilities: abilities),
    currentHp: hp,
    lane: 0,
    relics: armor > 0 ? [relic(id: '${id}_armor', armor: armor)] : const [],
  );
}

CreatureInPlay _find(BoardSide side, String id) =>
    side.creaturesInPlay.firstWhere((c) => c.instanceId == id);

int _hpOf(BoardSide side, String id) => _find(side, id).currentHp;

bool _alive(BoardSide side, String id) =>
    side.creaturesInPlay.any((c) => c.instanceId == id);

void main() {
  group('getters de armadura mágica', () {
    test('Escudo Espelhado dá magicArmor mas NÃO armadura física', () {
      final c = inPlay(id: 'x', abilities: ['Escudo Espelhado']);
      expect(c.magicArmor, kEscudoEspelhadoArmor);
      expect(c.armor, 0); // só mágica.
    });

    test('Escudo Sagrado dá armadura física E mágica', () {
      final c = inPlay(id: 'x', abilities: ['Escudo Sagrado']);
      expect(c.armor, kEscudoSagradoArmor);
      expect(c.magicArmor, kEscudoSagradoArmor);
    });
  });

  group('Espinhos', () {
    test('atacante melee toma dano verdadeiro ao acertar a defensora', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10)],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Espinhos'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 7); // 10 - 3 do golpe.
      expect(_hpOf(after.sideA, 'atk'), 10 - kEspinhosDamage); // espetou-se.
      expect(
        after.lastTurnEvents.whereType<AbilityTriggered>().any(
            (e) => e.ability == 'Espinhos'),
        isTrue,
      );
    });

    test('NÃO retalia ataque à distância (só melee)', () {
      final s = _stateWith(
        // arqueiro na retaguarda (atira da lane oposta vazia → frente).
        aLanes: [
          inPlay(id: 'front', atk: 0, hp: 10),
          inPlay(id: 'archer', atk: 3, hp: 10, type: DamageType.aDistancia),
        ],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Espinhos'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideA, 'archer'), 10); // ileso: espinhos não dispara.
    });
  });

  group('Escudo Espelhado', () {
    test('reduz dano MÁGICO', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'mage', atk: 3, hp: 10, type: DamageType.magico)],
        bLanes: [
          inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Escudo Espelhado'])
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 10 - (3 - kEscudoEspelhadoArmor));
    });

    test('NÃO reduz dano físico', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10)],
        bLanes: [
          inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Escudo Espelhado'])
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 7); // 10 - 3, sem redução.
    });
  });

  group('Escudo Sagrado', () {
    test('reduz dano FÍSICO', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10)],
        bLanes: [
          inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Escudo Sagrado'])
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 10 - (3 - kEscudoSagradoArmor));
    });

    test('reduz dano MÁGICO', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'mage', atk: 3, hp: 10, type: DamageType.magico)],
        bLanes: [
          inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Escudo Sagrado'])
        ],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 10 - (3 - kEscudoSagradoArmor));
    });
  });

  group('Contra-Ataque', () {
    // O único consumo de rng antes do contra-ataque (sem Voo/Ataque Duplo) é a
    // própria rolagem da chance. Escaneia seeds pra achar um que dispara e um
    // que não — robusto sem hard-codar número mágico.
    bool triggered(int seed) {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10)],
        bLanes: [
          inPlay(id: 'def', atk: 4, hp: 10, abilities: ['Contra-Ataque'])
        ],
        seed: seed,
      );
      final after = engine.endTurn(s);
      return after.lastTurnEvents
          .whereType<AbilityTriggered>()
          .any((e) => e.ability == 'Contra-Ataque');
    }

    test('dispara em ~50%: existe seed que dispara e seed que não', () {
      int? hit, miss;
      for (var seed = 0; seed < 200 && (hit == null || miss == null); seed++) {
        if (triggered(seed)) {
          hit ??= seed;
        } else {
          miss ??= seed;
        }
      }
      expect(hit, isNotNull, reason: 'deveria haver seed que dispara');
      expect(miss, isNotNull, reason: 'deveria haver seed que não dispara');
    });

    test('quando dispara, o atacante toma o ataque melee da defensora', () {
      var hit = -1;
      for (var seed = 0; seed < 200; seed++) {
        if (triggered(seed)) {
          hit = seed;
          break;
        }
      }
      expect(hit, greaterThanOrEqualTo(0));
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 3, hp: 10)],
        bLanes: [
          inPlay(id: 'def', atk: 4, hp: 10, abilities: ['Contra-Ataque'])
        ],
        seed: hit,
      );
      final after = engine.endTurn(s);
      // atacante (armadura 0) toma os 4 de atk da defensora.
      expect(_hpOf(after.sideA, 'atk'), 10 - 4);
    });
  });

  group('Reflexo Mágico', () {
    test('100%: alvo ileso e atacante toma o dano mágico cheio', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'mage', atk: 4, hp: 10, type: DamageType.magico)],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Reflexo Mágico'])],
      );
      final after = engine.endTurn(s);
      expect(_hpOf(after.sideB, 'def'), 10); // ignorou o dano.
      expect(_hpOf(after.sideA, 'mage'), 10 - 4); // dano cheio devolvido.
    });

    test('dois refletores: loop +1/loop, lançado aleatoriamente num dos dois',
        () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'mage', atk: 4, hp: 20, type: DamageType.magico, abilities: [
            'Reflexo Mágico'
          ])
        ],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 20, abilities: ['Reflexo Mágico'])],
      );
      final after = engine.endTurn(s);
      final expectedDmg = 4 + (kReflexoLoopLimit - 1) * kReflexoLoopGain;
      final hpA = _hpOf(after.sideA, 'mage');
      final hpB = _hpOf(after.sideB, 'def');
      // exatamente UM dos dois tomou o dano acumulado do loop.
      final aHit = hpA == 20 - expectedDmg;
      final bHit = hpB == 20 - expectedDmg;
      expect(aHit ^ bHit, isTrue,
          reason: 'um (e só um) dos refletores recebe o dano do loop');
      expect(
        after.lastTurnEvents
            .whereType<AbilityTriggered>()
            .any((e) => e.ability == 'Reflexo Mágico' && e.detail.contains('loop')),
        isTrue,
      );
    });
  });

  group('Inabalável', () {
    test('golpe letal NÃO destrói: ressuscita com vida cheia, 1×', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 99, hp: 10)],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, abilities: ['Inabalável'])],
      );
      final after = engine.endTurn(s);
      expect(_alive(after.sideB, 'def'), isTrue, reason: 'não morreu');
      final def = _find(after.sideB, 'def');
      expect(def.currentHp, def.maxHp); // voltou cheia.
      expect(def.inabalavelUsed, isTrue); // gastou o uso (não revive de novo).
      expect(
        after.lastTurnEvents.whereType<AbilityTriggered>().any(
            (e) => e.ability == 'Inabalável'),
        isTrue,
      );
    });
  });
}
