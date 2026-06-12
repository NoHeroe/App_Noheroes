// Bug do device (CEO 2026-06-12): relíquia que dá +PV deve subir o PV ATUAL
// junto do máximo (não é cura ao máximo). 4/4 + (+1) => 5/5; ferida 3/5 => 4/6.
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

void main() {
  CreatureInPlay inPlay({required String id, int hp = 4, int cur = 4}) =>
      CreatureInPlay(
        card: creature(
            id: id, atk: 2, hp: hp, damageType: DamageType.corpoACorpo),
        currentHp: cur,
        lane: 0,
      );

  MatchState stateWith(CreatureInPlay c, RelicCard r) {
    final a = BoardSide(
      id: SideId.a,
      lanes: [c.copyWith(lane: 0), null, null],
      crystals: 5,
      hand: <Object>[r],
      deck: const <Object>[],
      sacrificedThisTurn: false,
    );
    final b = BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'));
    return MatchState(
      sideA: a,
      sideB: b,
      activeSide: SideId.a,
      turn: 2,
      phase: MatchPhase.jogo,
      rng: makeRng(1),
    );
  }

  test('Relíquia +PV sobe o PV ATUAL junto do máximo (4/4 -> 5/5)', () {
    final c = inPlay(id: 'guard', hp: 4, cur: 4);
    final r = relic(id: 'vigor', concept: CardConcept.neutro, hpBonus: 1, cost: 0);
    final after = engine.apply(stateWith(c, r), const PlayRelic('vigor', 'guard'));
    final updated = after.sideA.creaturesInPlay.first;
    expect(updated.maxHp, 5);
    expect(updated.currentHp, 5);
  });

  test('Relíquia +PV em criatura ferida soma só o bônus (3/5 -> 4/6)', () {
    final c = inPlay(id: 'wounded', hp: 5, cur: 3);
    final r = relic(id: 'vigor', concept: CardConcept.neutro, hpBonus: 1, cost: 0);
    final after =
        engine.apply(stateWith(c, r), const PlayRelic('vigor', 'wounded'));
    final updated = after.sideA.creaturesInPlay.first;
    expect(updated.maxHp, 6);
    expect(updated.currentHp, 4);
  });

  test('Relíquia +2 PV em ferida (2/4 -> 4/6)', () {
    final c = inPlay(id: 'big', hp: 4, cur: 2);
    final r = relic(id: 'vigor2', concept: CardConcept.neutro, hpBonus: 2, cost: 0);
    final after =
        engine.apply(stateWith(c, r), const PlayRelic('vigor2', 'big'));
    final updated = after.sideA.creaturesInPlay.first;
    expect(updated.maxHp, 6);
    expect(updated.currentHp, 4);
  });
}
