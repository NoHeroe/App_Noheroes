// Reposicionamento (SwapPosition) — SPEC do CEO 2026-06-11: mover criatura
// própria só PRA TRÁS (trocar com uma de trás), custo 2 cristais, sem encerrar
// a vez.
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

MatchState _state(List<CreatureInPlay?> aLanes, {int crystals = 3}) {
  List<CreatureInPlay?> pad(List<CreatureInPlay?> xs) {
    final l = List<CreatureInPlay?>.filled(kLaneCount, null);
    for (var i = 0; i < xs.length && i < kLaneCount; i++) {
      l[i] = xs[i]?.copyWith(lane: i);
    }
    return l;
  }

  return MatchState(
    sideA: BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'))
        .copyWith(lanes: pad(aLanes), crystals: crystals),
    sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B')),
    activeSide: SideId.a,
    turn: 3,
    phase: MatchPhase.jogo,
    rng: makeRng(1),
  );
}

CreatureInPlay _c(String id) =>
    CreatureInPlay(card: creature(id: id), currentHp: 10, lane: 0);

void main() {
  group('SwapPosition (reposicionar só pra trás)', () {
    test('troca a selecionada (frente) com um alvo atrás; debita 2 cristais', () {
      final s = _state([_c('x'), _c('y'), _c('z')]);
      final r = engine.apply(s, const SwapPosition('x', 'z'));
      final lanes = r.sideA.creaturesInPlay;
      expect(lanes[0].instanceId, 'z'); // z veio pra frente
      expect(lanes[2].instanceId, 'x'); // x foi pra trás
      expect(lanes[0].lane, 0); // lanes atualizadas
      expect(lanes[2].lane, 2);
      expect(r.sideA.crystals, 1); // 3 - 2
    });

    test('mover PRA FRENTE é rejeitado (no-op)', () {
      final s = _state([_c('x'), _c('y'), _c('z')]);
      // tentar trazer z (trás) pra frente via seleção de z → alvo x à frente.
      final r = engine.apply(s, const SwapPosition('z', 'x'));
      expect(r.sideA.creaturesInPlay[0].instanceId, 'x'); // inalterado
      expect(r.sideA.crystals, 3); // não cobrou
    });

    test('cristais insuficientes → no-op', () {
      final s = _state([_c('x'), _c('y')], crystals: 1);
      final r = engine.apply(s, const SwapPosition('x', 'y'));
      expect(r.sideA.creaturesInPlay[0].instanceId, 'x'); // inalterado
      expect(r.sideA.crystals, 1);
    });
  });
}
