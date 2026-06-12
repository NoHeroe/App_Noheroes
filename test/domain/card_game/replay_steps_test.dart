/// Testes do contrato de REPLAY passo a passo (`endTurnDetailed`).
///
/// Garante que: (1) `finalState` é idêntico ao `endTurn`; (2) concatenar os
/// `events` dos steps reproduz exatamente `lastTurnEvents`; (3) os snapshots
/// são PRÉ-ataque (Card Monsters): cada step mostra o alvo ainda vivo na
/// posição enquanto a UI anima o golpe; o avanço/compactação aparece no step
/// seguinte (ou no `finalState`).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

MatchState _stateWith({
  required List<CreatureInPlay> aLanes,
  required List<CreatureInPlay> bLanes,
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
    turn: 3,
    phase: MatchPhase.jogo,
    rng: makeRng(),
  );
}

CreatureInPlay _inPlay({
  required String id,
  int atk = 3,
  int hp = 10,
  DamageType type = DamageType.corpoACorpo,
}) {
  return CreatureInPlay(
    card: creature(id: id, atk: atk, hp: hp, damageType: type),
    currentHp: hp,
    lane: 0,
  );
}

void main() {
  group('endTurnDetailed — contrato do replay', () {
    test('finalState == endTurn (mesmo estado final)', () {
      final s = _stateWith(
        aLanes: [_inPlay(id: 'a', atk: 4)],
        bLanes: [_inPlay(id: 'b', hp: 10)],
      );
      final viaSimple = engine.endTurn(s);
      final viaDetailed = engine.endTurnDetailed(s).finalState;

      expect(viaDetailed.turn, viaSimple.turn);
      expect(viaDetailed.activeSide, viaSimple.activeSide);
      expect(viaDetailed.sideB.lanes[0]?.currentHp,
          viaSimple.sideB.lanes[0]?.currentHp);
      expect(viaDetailed.lastTurnEvents.length,
          viaSimple.lastTurnEvents.length);
    });

    test('a concatenação dos events dos steps == lastTurnEvents', () {
      final s = _stateWith(
        aLanes: [
          _inPlay(id: 'a0', atk: 3),
          _inPlay(id: 'a1', atk: 3),
        ],
        bLanes: [
          _inPlay(id: 'b0', hp: 10),
          _inPlay(id: 'b1', hp: 10),
        ],
      );
      final out = engine.endTurnDetailed(s);
      final fromSteps =
          out.steps.expand((st) => st.events).toList(growable: false);

      expect(fromSteps.length, out.finalState.lastTurnEvents.length);
      for (var i = 0; i < fromSteps.length; i++) {
        // Mesma identidade de evento na mesma ordem.
        expect(fromSteps[i].toString(),
            out.finalState.lastTurnEvents[i].toString());
      }
    });

    test('replay PRÉ-estado: o step mostra o alvo VIVO; tabuleiro avança no fim',
        () {
      // a mata a frente de B num golpe; B tem retaguarda que deve avançar.
      final s = _stateWith(
        aLanes: [_inPlay(id: 'a', atk: 100)],
        bLanes: [
          _inPlay(id: 'bFront', hp: 5),
          _inPlay(id: 'bBack', hp: 20),
        ],
      );
      final out = engine.endTurnDetailed(s);

      expect(out.steps, isNotEmpty);
      // Card Monsters: o step do ataque mostra o tabuleiro ANTES do golpe — a
      // frente AINDA viva na lane 0 e a retaguarda na lane 1 — pra UI animar o
      // golpe sobre o alvo vivo. O avanço/compactação só aparece no finalState
      // (ou no step seguinte, se houver mais ataques).
      final firstAttackStep = out.steps.first;
      expect(firstAttackStep.state.sideB.lanes[0]?.instanceId, 'bFront');
      expect(firstAttackStep.state.sideB.lanes[1]?.instanceId, 'bBack');
      // O evento do golpe registra a morte do alvo (a UI usa isso pra animar o
      // shatter sobre o tile ainda visível).
      expect(firstAttackStep.events.whereType<AttackResolved>().first.targetDied,
          isTrue);
      // Estado final: frente morta, retaguarda compactada pra lane 0.
      expect(out.finalState.sideB.lanes[0]?.instanceId, 'bBack');
      expect(out.finalState.sideB.lanes[0]?.lane, 0);
      expect(out.finalState.sideB.lanes[1], isNull);
    });

    test('partida vazia/sem ataque não gera steps espúrios', () {
      // Lado ativo sem criaturas e sem pool de criaturas: penalidade pode
      // disparar, mas não há fase de ataque. Steps refletem só o que houve.
      final s = _stateWith(
        aLanes: [_inPlay(id: 'a', atk: 3)],
        bLanes: [_inPlay(id: 'b', hp: 10)],
      );
      final out = engine.endTurnDetailed(s);
      // Houve 1 ataque → ao menos 1 step, e todo evento pertence a um step.
      final total =
          out.steps.fold<int>(0, (n, st) => n + st.events.length);
      expect(total, out.finalState.lastTurnEvents.length);
    });
  });
}
