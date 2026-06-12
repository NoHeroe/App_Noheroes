// Lote 3a — status / DoT: Sangramento, Veneno, Atordoar, Enredar.
// O tick de DoT acontece no INÍCIO do endTurn do dono da carta afetada (quando
// ele "clica encerrar"), então vários testes rodam DOIS endTurns: o 1º aplica o
// status (Fase de Ataque do atacante), o 2º faz o dono tickar/pular.
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

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
  DamageType type = DamageType.corpoACorpo,
  List<String> abilities = const <String>[],
  int bleedStacks = 0,
  int bleedTurns = 0,
  bool poisoned = false,
  bool stunned = false,
  bool entangled = false,
  int atordoarCooldown = 0,
  int desmoralizadoMelee = 0,
  int suprimidoMagico = 0,
  int diseaseStacks = 0,
}) {
  return CreatureInPlay(
    card: creature(id: id, atk: atk, hp: hp, damageType: type, abilities: abilities),
    currentHp: hp,
    lane: 0,
    bleedStacks: bleedStacks,
    bleedTurns: bleedTurns,
    poisoned: poisoned,
    stunned: stunned,
    entangled: entangled,
    atordoarCooldown: atordoarCooldown,
    desmoralizadoMelee: desmoralizadoMelee,
    suprimidoMagico: suprimidoMagico,
    diseaseStacks: diseaseStacks,
  );
}

CreatureInPlay _find(BoardSide side, String id) =>
    side.creaturesInPlay.firstWhere((c) => c.instanceId == id);

int _hpOf(BoardSide side, String id) => _find(side, id).currentHp;

bool _hasAbilityEvent(MatchState s, String ability) => s.lastTurnEvents
    .whereType<AbilityTriggered>()
    .any((e) => e.ability == ability);

void main() {
  group('Sangramento', () {
    test('atacante físico aplica 1 acúmulo e reseta a duração', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 2, abilities: ['Sangramento'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      final def = _find(after.sideB, 'def');
      expect(def.bleedStacks, 1);
      expect(def.bleedTurns, kSangramentoTurns);
      expect(_hasAbilityEvent(after, 'Sangramento'), isTrue);
    });

    test('atacante mágico NÃO aplica sangramento (só físico)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'mage', atk: 2, type: DamageType.magico, abilities: ['Sangramento'])
        ],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'def').bleedStacks, 0);
    });

    test('tick causa dano = acúmulos no endTurn do dono e decai 1 turno', () {
      // 'bleeder' já sangrando (2 stacks, 2 turnos) no lado ativo A.
      final s = _stateWith(
        aLanes: [inPlay(id: 'bleeder', atk: 0, hp: 10, bleedStacks: 2, bleedTurns: 2)],
        bLanes: [inPlay(id: 'dummy', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      final b = _find(after.sideA, 'bleeder');
      expect(b.currentHp, 10 - 2); // 2 stacks = 2 de dano.
      expect(b.bleedTurns, 1); // decaiu.
      expect(b.bleedStacks, 2); // mantém enquanto durar.
      expect(
        after.lastTurnEvents
            .whereType<StatusDamageResolved>()
            .any((e) => e.statusLabel == 'Sangramento' && e.damage == 2),
        isTrue,
      );
    });

    test('expira ao zerar a duração (limpa acúmulos)', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'bleeder', atk: 0, hp: 10, bleedStacks: 1, bleedTurns: 1)],
        bLanes: [inPlay(id: 'dummy', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      final b = _find(after.sideA, 'bleeder');
      expect(b.currentHp, 9);
      expect(b.bleedTurns, 0);
      expect(b.bleedStacks, 0); // limpo.
    });
  });

  group('Veneno', () {
    test('aplicação ao acertar; envenenado fica true', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 2, abilities: ['Veneno'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'def').poisoned, isTrue);
      expect(_hasAbilityEvent(after, 'Veneno'), isTrue);
    });

    test('tick permanente: 1/turno, sem decair', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'sick', atk: 0, hp: 10, poisoned: true)],
        bLanes: [inPlay(id: 'dummy', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      final sick = _find(after.sideA, 'sick');
      expect(sick.currentHp, 10 - kVenenoPerTurn);
      expect(sick.poisoned, isTrue); // persiste.
    });

    test('cura limpa o veneno', () {
      // A: curandeiro (cura) + aliado envenenado e ferido (alvo da cura).
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'sick', atk: 0, hp: 10, poisoned: true)
              .copyWith(currentHp: 5),
          inPlay(id: 'healer', atk: 3, type: DamageType.cura),
        ],
        bLanes: [inPlay(id: 'dummy', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      // tick de veneno (5→4) e depois cura (+3 e limpa).
      final sick = _find(after.sideA, 'sick');
      expect(sick.poisoned, isFalse);
      expect(sick.currentHp, greaterThan(4)); // foi curado após o tick.
    });
  });

  group('Atordoar', () {
    test('melee atordoa o alvo e a atacante entra em cooldown', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 2, abilities: ['Atordoar'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'def').stunned, isTrue);
      expect(_find(after.sideA, 'atk').atordoarCooldown, greaterThan(0));
      expect(_hasAbilityEvent(after, 'Atordoar'), isTrue);
    });

    test('alvo atordoado PULA a próxima Fase de Ataque dele e limpa o status', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 2, abilities: ['Atordoar'])],
        bLanes: [inPlay(id: 'def', atk: 5, hp: 10)],
      );
      final afterA = engine.endTurn(s); // aplica atordoamento, vira turno de B.
      final beforeHp = _hpOf(afterA.sideA, 'atk');
      final afterB = engine.endTurn(afterA); // B deveria pular o ataque.
      // 'atk' não tomou dano de 'def' (B pulou).
      expect(_hpOf(afterB.sideA, 'atk'), beforeHp);
      expect(_find(afterB.sideB, 'def').stunned, isFalse); // limpou.
      expect(_hasAbilityEvent(afterB, 'Atordoar'), isTrue); // narrou o "presa".
    });

    test('só melee atordoa (mágico não)', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'mage', atk: 2, type: DamageType.magico, abilities: ['Atordoar'])
        ],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'def').stunned, isFalse);
    });

    test('em cooldown NÃO atordoa', () {
      final s = _stateWith(
        aLanes: [
          inPlay(id: 'atk', atk: 2, abilities: ['Atordoar'], atordoarCooldown: 1)
        ],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'def').stunned, isFalse);
    });
  });

  group('Enredar', () {
    // Atacante com Voo (alvo não evade) + Enredar; alvo com Voo. Escaneia seeds
    // pra achar um em que o Enredar (50%) dispara.
    int seedThatEnredates() {
      for (var seed = 0; seed < 300; seed++) {
        final s = _stateWith(
          aLanes: [
            inPlay(id: 'atk', atk: 2, abilities: ['Voo', 'Enredar'])
          ],
          bLanes: [inPlay(id: 'flyer', atk: 0, hp: 10, abilities: ['Voo'])],
          seed: seed,
        );
        final after = engine.endTurn(s);
        if (_hasAbilityEvent(after, 'Enredar')) return seed;
      }
      return -1;
    }

    test('enreda alvo voador: remove Voo e marca entangled', () {
      final seed = seedThatEnredates();
      expect(seed, greaterThanOrEqualTo(0));
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 2, abilities: ['Voo', 'Enredar'])],
        bLanes: [inPlay(id: 'flyer', atk: 0, hp: 10, abilities: ['Voo'])],
        seed: seed,
      );
      final after = engine.endTurn(s);
      final flyer = _find(after.sideB, 'flyer');
      expect(flyer.entangled, isTrue);
      expect(flyer.canFly, isFalse); // perdeu o Voo enquanto enredado.
    });

    test('não enreda alvo SEM Voo (nenhum seed)', () {
      for (var seed = 0; seed < 50; seed++) {
        final s = _stateWith(
          aLanes: [inPlay(id: 'atk', atk: 2, abilities: ['Enredar'])],
          bLanes: [inPlay(id: 'ground', atk: 0, hp: 10)],
          seed: seed,
        );
        final after = engine.endTurn(s);
        expect(_find(after.sideB, 'ground').entangled, isFalse);
        expect(_hasAbilityEvent(after, 'Enredar'), isFalse);
      }
    });

    test('enredado pula a próxima Fase de Ataque e volta a poder voar', () {
      // 'flyer' já enredado no lado ativo A.
      final s = _stateWith(
        aLanes: [inPlay(id: 'flyer', atk: 5, hp: 10, abilities: ['Voo'], entangled: true)],
        bLanes: [inPlay(id: 'victim', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      // 'flyer' pulou: 'victim' não tomou dano.
      expect(_hpOf(after.sideB, 'victim'), 10);
      final flyer = _find(after.sideA, 'flyer');
      expect(flyer.entangled, isFalse); // limpou.
      expect(flyer.canFly, isTrue); // Voo de volta.
      expect(_hasAbilityEvent(after, 'Enredar'), isTrue);
    });
  });

  group('Desmoralizar (aura)', () {
    test('reduz o ataque melee dos inimigos no início do turno do dono', () {
      // A tem Desmoralizador; rodamos endTurn(B) -> _beginTurn(A) aplica a aura
      // sobre B. 'bruiser' de B fica com -1 de melee.
      final s = _stateWith(
        aLanes: [inPlay(id: 'demor', atk: 0, hp: 20, abilities: ['Desmoralizar'])],
        bLanes: [inPlay(id: 'bruiser', atk: 5, hp: 10)],
      ).copyWith(activeSide: SideId.b);
      final after = engine.endTurn(s);
      final bruiser = _find(after.sideB, 'bruiser');
      expect(bruiser.desmoralizadoMelee, kDesmoralizarReduction);
      expect(bruiser.atk, 5 - kDesmoralizarReduction); // atk efetivo reduzido.
      expect(_hasAbilityEvent(after, 'Desmoralizar'), isTrue);
    });

    test('debuff expira no fim do turno do lado debuffado', () {
      // 'bruiser' de B já desmoralizado; ao fim do turno de B, limpa.
      final s = _stateWith(
        aLanes: [inPlay(id: 'dummy', atk: 0, hp: 10)],
        bLanes: [inPlay(id: 'bruiser', atk: 5, hp: 10, desmoralizadoMelee: 1)],
      ).copyWith(activeSide: SideId.b);
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'bruiser').desmoralizadoMelee, 0);
    });
  });

  group('Suprimir Magia (aura)', () {
    test('reduz o ataque mágico dos inimigos', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'supr', atk: 0, hp: 20, abilities: ['Suprimir Magia'])],
        bLanes: [inPlay(id: 'mage', atk: 5, hp: 10, type: DamageType.magico)],
      ).copyWith(activeSide: SideId.b);
      final after = engine.endTurn(s);
      final mage = _find(after.sideB, 'mage');
      expect(mage.suprimidoMagico, kSuprimirReduction);
      expect(mage.atk, 5 - kSuprimirReduction);
    });
  });

  group('Doença', () {
    test('aplica acúmulo ao acertar dano físico', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 2, abilities: ['Doença'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'def').diseaseStacks, 1);
      expect(_hasAbilityEvent(after, 'Doença'), isTrue);
    });

    test('suprime Inspirar do inspirador doente', () {
      // B: inspirador DOENTE + aliado. endTurn(A) -> _beginTurn(B): o aliado NÃO
      // é inspirado (Inspirar suprimida pela Doença).
      final s = _stateWith(
        aLanes: [inPlay(id: 'dummy', atk: 0, hp: 10)],
        bLanes: [
          inPlay(id: 'insp', atk: 0, hp: 10, abilities: ['Inspirar'], diseaseStacks: 1),
          inPlay(id: 'ally', atk: 3, hp: 10),
        ],
      );
      final after = engine.endTurn(s); // ativo = A -> inicia o turno de B.
      expect(_find(after.sideB, 'ally').inspirarBonus, 0);
    });

    test('controle: inspirador SÃO inspira o aliado', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'dummy', atk: 0, hp: 10)],
        bLanes: [
          inPlay(id: 'insp', atk: 0, hp: 10, abilities: ['Inspirar']),
          inPlay(id: 'ally', atk: 3, hp: 10),
        ],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'ally').inspirarBonus, kInspirarBonus);
    });
  });

  group('Surto', () {
    test('detona Doença: remove acúmulos e reduz o PV máximo', () {
      // 'def' já doente (2 acúmulos); A acerta com Surto (físico).
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 1, abilities: ['Surto'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10, diseaseStacks: 2)],
      );
      final after = engine.endTurn(s);
      final def = _find(after.sideB, 'def');
      expect(def.diseaseStacks, 0); // detonou.
      expect(def.maxHp, 10 - 2 * kSurtoMaxHpPerStack); // PV máx reduzido.
      expect(def.currentHp, lessThanOrEqualTo(def.maxHp));
      expect(_hasAbilityEvent(after, 'Surto'), isTrue);
    });

    test('sem Doença no alvo, Surto não faz nada', () {
      final s = _stateWith(
        aLanes: [inPlay(id: 'atk', atk: 1, abilities: ['Surto'])],
        bLanes: [inPlay(id: 'def', atk: 0, hp: 10)],
      );
      final after = engine.endTurn(s);
      expect(_find(after.sideB, 'def').maxHp, 10); // intacto.
      expect(_hasAbilityEvent(after, 'Surto'), isFalse);
    });
  });
}
