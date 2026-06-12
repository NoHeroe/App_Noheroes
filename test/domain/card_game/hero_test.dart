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

    test('Trapaceiro PASSIVA: chance de comprar 1 carta extra no início do turno',
        () {
      // A = trapaceiro, mão de 2; ativo = B. Ao começar o turno de A: 1 grátis +
      // (chance) 1 extra. Escaneia um seed em que a passiva dispara → mão 4.
      BoardSide aHand2(int seed) {
        final a0 = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(seed));
        return a0.copyWith(
          heroId: HeroId.trapaceiro,
          hand: a0.hand.sublist(0, 2),
          deck: <Object>[...a0.hand.sublist(2), ...a0.deck],
        );
      }

      var hitSeed = -1;
      for (var seed = 0; seed < 300; seed++) {
        final s = MatchState(
          sideA: aHand2(seed),
          sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'), makeRng(seed + 1)),
          activeSide: SideId.b,
          turn: 2,
          phase: MatchPhase.jogo,
          rng: makeRng(seed),
        );
        final after = engine.endTurn(s);
        final fired = after.lastTurnEvents
            .whereType<AbilityTriggered>()
            .any((e) => e.ability == 'Trapaceiro');
        if (fired) {
          expect(after.sideA.hand.length, 4, reason: '2 + grátis + extra');
          hitSeed = seed;
          break;
        }
      }
      expect(hitSeed, greaterThanOrEqualTo(0));
    });

    test('Assassino PASSIVA: concede Esquiva (buff) a uma criatura ao fim do turno',
        () {
      // A = assassino com uma criatura; ativo = A. Ao terminar, chance de buff.
      var hitSeed = -1;
      for (var seed = 0; seed < 300; seed++) {
        final a = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(seed))
            .copyWith(
                heroId: HeroId.assassino,
                lanes: [_inPlay(id: 'ace', atk: 0, hp: 10), null, null]);
        final s = MatchState(
          sideA: a,
          sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'), makeRng(seed + 1)),
          activeSide: SideId.a,
          turn: 2,
          phase: MatchPhase.jogo,
          rng: makeRng(seed),
        );
        final after = engine.endTurn(s);
        if (after.lastTurnEvents
            .whereType<AbilityTriggered>()
            .any((e) => e.ability == 'Assassino')) {
          expect(after.sideA.creaturesInPlay.first.esquivaBuffTurns, greaterThan(0));
          hitSeed = seed;
          break;
        }
      }
      expect(hitSeed, greaterThanOrEqualTo(0));
    });

    test('Esquiva 100% (buff): evade o ataque com certeza', () {
      final a = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(1))
          .copyWith(lanes: [
        _inPlay(id: 'shielded', atk: 0, hp: 10).copyWith(esquivaBuffTurns: 1),
        null,
        null
      ]);
      final b = BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'), makeRng(2))
          .copyWith(lanes: [_inPlay(id: 'hitter', atk: 5), null, null]);
      final s = MatchState(
        sideA: a,
        sideB: b,
        activeSide: SideId.b, // B ataca A
        turn: 2,
        phase: MatchPhase.jogo,
        rng: makeRng(9),
      );
      final after = engine.endTurn(s);
      expect(after.sideA.creaturesInPlay.first.currentHp, 10); // evadiu 100%.
    });

    test('Coringa ATIVA: põe o Fragmento do Deus Louco na mão', () {
      final base = _heroState(hero: HeroId.coringa);
      // Abre espaço na mão (capacidade 4) pra caber o Fragmento.
      final s = base.withSide(
          SideId.a, base.sideA.copyWith(hand: base.sideA.hand.sublist(0, 2)));
      final after = engine.apply(s, const UseHeroActive());
      expect(
        after.sideA.hand
            .whereType<CreatureCard>()
            .any((c) => c.id == 'fragmento_deus_louco'),
        isTrue,
      );
      expect(after.sideA.heroActiveUsed, isTrue);
    });

    test('Fragmento do Deus Louco tem 3 ataques nativos', () {
      final c = CreatureInPlay(
          card: fragmentoDoDeusLoucoCard(), currentHp: 4, lane: 0);
      final types = c.attacks.map((a) => a.type).toSet();
      expect(types, containsAll(<DamageType>{
        DamageType.corpoACorpo,
        DamageType.magico,
        DamageType.aDistancia,
      }));
    });

    test('Coringa PASSIVA: invoca Caixa Coringa quando uma carta morre', () {
      var hitSeed = -1;
      for (var seed = 0; seed < 300; seed++) {
        final a = BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'), makeRng(seed))
            .copyWith(
                heroId: HeroId.coringa,
                lanes: [_inPlay(id: 'doomed', atk: 0, hp: 4), null, null]);
        final b = BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'), makeRng(seed + 1))
            .copyWith(lanes: [_inPlay(id: 'killer', atk: 99), null, null]);
        final s = MatchState(
          sideA: a,
          sideB: b,
          activeSide: SideId.b, // B mata a criatura de A
          turn: 2,
          phase: MatchPhase.jogo,
          rng: makeRng(seed),
        );
        final after = engine.endTurn(s);
        if (after.lastTurnEvents
            .whereType<AbilityTriggered>()
            .any((e) => e.ability == 'Coringa')) {
          expect(
            after.sideA.creaturesInPlay.any((c) => c.card.id == 'caixa_coringa'),
            isTrue,
          );
          hitSeed = seed;
          break;
        }
      }
      expect(hitSeed, greaterThanOrEqualTo(0));
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
