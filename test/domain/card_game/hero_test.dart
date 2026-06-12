// ADR-0028 Fase B — framework de Herói: Esquiva (evasão ampla) + ativa 1×/partida
// (Trapaceiro rouba cristais; Assassino mata carta do deck do oponente).
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

CreatureInPlay _inPlay({
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
    sideA: BoardSide.initial(SideId.a, makeLoadout(prefix: 'A')).copyWith(lanes: pad(aLanes)),
    sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B')).copyWith(lanes: pad(bLanes)),
    activeSide: SideId.a,
    turn: 1,
    phase: MatchPhase.jogo,
    rng: makeRng(seed),
  );
}

void main() {
  test('Esquiva: evade ataque MÁGICO (que o Voo não evita)', () {
    // Escaneia seeds pra achar um em que a Esquiva (50%) dispara.
    int evadeSeed = -1;
    for (var seed = 0; seed < 200; seed++) {
      final s = _stateWith(
        aLanes: [_inPlay(id: 'mage', atk: 4, type: DamageType.magico)],
        bLanes: [_inPlay(id: 'ninja', atk: 0, hp: 10, abilities: ['Esquiva'])],
        seed: seed,
      );
      final after = engine.endTurn(s);
      if (after.lastTurnEvents.whereType<AttackEvaded>().isNotEmpty) {
        evadeSeed = seed;
        break;
      }
    }
    expect(evadeSeed, greaterThanOrEqualTo(0));
    final s = _stateWith(
      aLanes: [_inPlay(id: 'mage', atk: 4, type: DamageType.magico)],
      bLanes: [_inPlay(id: 'ninja', atk: 0, hp: 10, abilities: ['Esquiva'])],
      seed: evadeSeed,
    );
    final after = engine.endTurn(s);
    expect(after.sideB.creaturesInPlay.first.currentHp, 10); // ileso (evadiu).
  });

  group('Ativa do herói (1×/partida)', () {
    MatchState _heroState({
      required HeroId hero,
      int myCrystals = 3,
      int oppCrystals = 3,
    }) {
      final a = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(1))
          .copyWith(heroId: hero, crystals: myCrystals);
      final b = BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'), makeRng(2))
          .copyWith(crystals: oppCrystals);
      return MatchState(
        sideA: a,
        sideB: b,
        activeSide: SideId.a,
        turn: 2,
        phase: MatchPhase.jogo,
        rng: makeRng(3),
      );
    }

    test('Trapaceiro: rouba 2 cristais do oponente; só 1×', () {
      final s = _heroState(hero: HeroId.trapaceiro, myCrystals: 1, oppCrystals: 5);
      final after = engine.apply(s, const UseHeroActive());
      expect(after.sideA.crystals, 1 + kTrapaceiroSteal);
      expect(after.sideB.crystals, 5 - kTrapaceiroSteal);
      expect(after.sideA.heroActiveUsed, isTrue);
      // 2º uso = no-op.
      final again = engine.apply(after, const UseHeroActive());
      expect(again.sideA.crystals, after.sideA.crystals);
    });

    test('Assassino: mata 1 carta do deck do oponente (→ cemitério)', () {
      final s = _heroState(hero: HeroId.assassino);
      final deckBefore = s.sideB.deck.length;
      final after = engine.apply(s, const UseHeroActive());
      expect(after.sideB.deck.length, deckBefore - 1);
      expect(after.sideB.graveyard.length, 1);
      expect(after.sideA.heroActiveUsed, isTrue);
    });

    test('sem herói: UseHeroActive é no-op', () {
      final s = MatchState(
        sideA: BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(1)),
        sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'), makeRng(2)),
        activeSide: SideId.a,
        turn: 1,
        phase: MatchPhase.jogo,
        rng: makeRng(3),
      );
      final after = engine.apply(s, const UseHeroActive());
      expect(after.sideA.heroActiveUsed, isFalse);
      expect(identical(after, s), isTrue);
    });
  });
}
