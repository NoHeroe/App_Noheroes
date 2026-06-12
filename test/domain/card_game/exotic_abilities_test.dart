// Lote 5 — exóticas: Andorinha, Crescimento, Ressurreição, Carta Zumbi,
// Transformar e Mímico.
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

  return MatchState(
    sideA: BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'))
        .copyWith(lanes: pad(aLanes)),
    sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'))
        .copyWith(lanes: pad(bLanes)),
    activeSide: SideId.a,
    turn: 3,
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
}) =>
    CreatureInPlay(
      card: creature(id: id, atk: atk, hp: hp, damageType: type, abilities: abilities),
      currentHp: hp,
      lane: 0,
    );

CreatureInPlay _find(BoardSide s, String id) =>
    s.creaturesInPlay.firstWhere((c) => c.instanceId == id);

bool _ability(MatchState s, String a) => s.lastTurnEvents
    .whereType<AbilityTriggered>()
    .any((e) => e.ability == a);

void main() {
  test('Andorinha: ao destruir, ganho permanente em ataque e PV máximo', () {
    final s = _stateWith(
      aLanes: [inPlay(id: 'atk', atk: 10, hp: 10, abilities: ['Andorinha'])],
      bLanes: [inPlay(id: 'prey', atk: 0, hp: 4)],
    );
    final after = engine.endTurn(s);
    final atk = _find(after.sideA, 'atk');
    expect(atk.permanentAtkBonus, kAndorinhaGain);
    expect(atk.atk, 10 + kAndorinhaGain); // todos os ataques sobem.
    expect(_ability(after, 'Andorinha'), isTrue);
  });

  test('Crescimento: após ser curada, ganho permanente', () {
    final s = _stateWith(
      aLanes: [
        inPlay(id: 'ally', atk: 3, hp: 10, abilities: ['Crescimento'])
            .copyWith(currentHp: 5),
        inPlay(id: 'healer', atk: 3, type: DamageType.cura),
      ],
      bLanes: [inPlay(id: 'dummy', atk: 0, hp: 10)],
    );
    final after = engine.endTurn(s);
    final ally = _find(after.sideA, 'ally');
    expect(ally.permanentAtkBonus, kCrescimentoGain);
    expect(ally.atk, 3 + kCrescimentoGain);
    expect(_ability(after, 'Crescimento'), isTrue);
  });

  test('Ressurreição: golpe letal revive com PV reduzido (1×)', () {
    final s = _stateWith(
      aLanes: [inPlay(id: 'atk', atk: 99, hp: 10)],
      bLanes: [inPlay(id: 'phoenix', atk: 0, hp: 10, abilities: ['Ressurreição'])],
    );
    final after = engine.endTurn(s);
    final ph = _find(after.sideB, 'phoenix');
    expect(ph.currentHp, (10 * kRessurreicaoPercent).floor()); // PV reduzido.
    expect(ph.ressureicaoUsed, isTrue);
    expect(_ability(after, 'Ressurreição'), isTrue);
  });

  test('Carta Zumbi: ao morrer, volta enfraquecida pra mão/deck do dono', () {
    final s = _stateWith(
      aLanes: [inPlay(id: 'atk', atk: 99, hp: 10)],
      bLanes: [inPlay(id: 'zed', atk: 5, hp: 10, abilities: ['Carta Zumbi'])],
    );
    final after = engine.endTurn(s);
    // O 'zed' morreu no tabuleiro...
    expect(after.sideB.creaturesInPlay.any((c) => c.instanceId == 'zed'), isFalse);
    // ...e voltou enfraquecido pra mão OU topo do deck de B.
    final pool = <Object>[...after.sideB.hand, ...after.sideB.deck];
    final z = pool.whereType<CreatureCard>().where((c) => c.id == 'zed').toList();
    expect(z, hasLength(1));
    expect(z.first.atk, 5 - kZumbiAtkPenalty);
    expect(z.first.hp, 10 - kZumbiHpPenalty);
    expect(z.first.abilities.contains('Carta Zumbi'), isFalse); // sem re-trigger.
    expect(_ability(after, 'Carta Zumbi'), isTrue);
  });

  test('Transformar (2ª forma específica): vira a carta de transforma_em', () {
    final form2 = creature(id: 'dragao', atk: 9, hp: 30, abilities: ['Voo']);
    final base = creature(id: 'ovo', atk: 2, hp: 10, abilities: ['Transformar'])
        .copyWith(transformTo: form2);
    final s = _stateWith(
      aLanes: [inPlay(id: 'atk', atk: 6, hp: 10)],
      bLanes: [CreatureInPlay(card: base, currentHp: 10, lane: 0)],
    );
    final after = engine.endTurn(s);
    final m = _find(after.sideB, 'ovo'); // instanceId preservado (= id 'ovo').
    expect(m.transformed, isTrue);
    expect(m.card.nome, 'dragao'); // adotou a 2ª forma.
    expect(m.card.atk, 9);
    expect(m.hasKeyword(AbilityKeyword.voo), isTrue);
    expect(m.maxHp, 30);
    expect(m.currentHp, 30); // curou ao novo máximo.
  });

  test('Transformar (genérico): sem transforma_em, ativa boost (cura + bônus)',
      () {
    final s = _stateWith(
      // atk 6 leva o defensor de 10 -> 4 (≤ 50%): dispara.
      aLanes: [inPlay(id: 'atk', atk: 6, hp: 10)],
      bLanes: [inPlay(id: 'morph', atk: 2, hp: 10, abilities: ['Transformar'])],
    );
    final after = engine.endTurn(s);
    final m = _find(after.sideB, 'morph');
    expect(m.transformed, isTrue);
    expect(m.permanentAtkBonus, kTransformarAtkBonus);
    expect(m.maxHp, 10 + kTransformarHpBonus);
    expect(m.currentHp, m.maxHp); // curou ao novo máximo.
    expect(_ability(after, 'Transformar'), isTrue);
  });

  group('Mímico', () {
    // Estado mínimo: A ativo com um Mímico na mão; B com uma criatura forte.
    MatchState mimicState({String? targetId}) {
      final mimic = creature(id: 'mim', cost: 0, atk: 1, hp: 1, abilities: ['Mímico']);
      final boss = inPlay(id: 'boss', atk: 9, hp: 20, abilities: ['Voo']);
      return MatchState(
        sideA: BoardSide(
          id: SideId.a,
          lanes: List<CreatureInPlay?>.filled(kLaneCount, null),
          crystals: 5,
          hand: <Object>[mimic],
          deck: const <Object>[],
          sacrificedThisTurn: false,
        ),
        sideB: BoardSide(
          id: SideId.b,
          lanes: [boss.copyWith(lane: 0), null, null],
          crystals: 0,
          hand: const <Object>[],
          deck: const <Object>[],
          sacrificedThisTurn: false,
        ),
        activeSide: SideId.a,
        turn: 3,
        phase: MatchPhase.jogo,
        rng: makeRng(1),
      );
    }

    test('copia stats e keywords do alvo marcado (inimigo)', () {
      final s = mimicState();
      final after = engine.apply(s, const PlayCreature('mim', mimicTargetId: 'boss'));
      final placed = _find(after.sideA, 'mim');
      expect(placed.card.atk, 9);
      expect(placed.card.hp, 20);
      expect(placed.currentHp, 20);
      expect(placed.hasKeyword(AbilityKeyword.voo), isTrue);
    });

    test('sem alvo marcado, auto-escolhe o mais forte em jogo', () {
      final s = mimicState();
      final after = engine.apply(s, const PlayCreature('mim'));
      final placed = _find(after.sideA, 'mim');
      expect(placed.card.atk, 9); // copiou o boss (único em jogo).
    });
  });
}
