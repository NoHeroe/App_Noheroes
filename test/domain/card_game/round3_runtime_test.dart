// Round 3 (CEO 2026-06-14) — runtime das habilidades novas:
//  • Suporte: 2º slot de relíquia (ver também card_models_test).
//  • Magnetismo: jogador escolhe a habilidade extra ao equipar (PlayRelic.grantedAbility).
//  • Sorte: a cada início de turno do dono, manifesta uma habilidade aleatória.
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

List<CreatureInPlay?> _pad(List<CreatureInPlay?> xs) {
  final l = List<CreatureInPlay?>.filled(kLaneCount, null);
  for (var i = 0; i < xs.length && i < kLaneCount; i++) {
    l[i] = xs[i]?.copyWith(lane: i);
  }
  return l;
}

CreatureInPlay _c(String id,
        {int atk = 1,
        int hp = 20,
        List<String> abilities = const <String>[],
        List<RelicCard> relics = const <RelicCard>[]}) =>
    CreatureInPlay(
      card: creature(id: id, atk: atk, hp: hp, abilities: abilities),
      currentHp: hp,
      lane: 0,
      relics: relics,
    );

void main() {
  group('pool concedível (Sorte / Magnetismo)', () {
    test('inclui habilidades existentes e EXCLUI as 3 meta', () {
      expect(kGrantableAbilities, contains(AbilityKeyword.investida));
      expect(kGrantableAbilities, contains(AbilityKeyword.espinhos));
      expect(kGrantableAbilities, isNot(contains(AbilityKeyword.suporte)));
      expect(kGrantableAbilities, isNot(contains(AbilityKeyword.magnetismo)));
      expect(kGrantableAbilities, isNot(contains(AbilityKeyword.sorte)));
    });
  });

  group('keywords folding (gating)', () {
    test('magnetismoAbility só vale se a criatura tem Magnetismo', () {
      // Sem a keyword magnetismo → a escolhida é ignorada.
      final semMag = _c('c').copyWith(magnetismoAbility: AbilityKeyword.voo);
      expect(semMag.hasKeyword(AbilityKeyword.voo), isFalse);
      // Com magnetismo (via relíquia) → a escolhida vale.
      final comMag = _c('c', relics: [
        relic(id: 'e', concept: CardConcept.neutro, abilities: const [
          'magnetismo',
        ])
      ]).copyWith(magnetismoAbility: AbilityKeyword.voo);
      expect(comMag.hasKeyword(AbilityKeyword.voo), isTrue);
    });

    test('sorteAbility só vale se a criatura tem Sorte', () {
      final semSorte = _c('c').copyWith(sorteAbility: AbilityKeyword.espinhos);
      expect(semSorte.hasKeyword(AbilityKeyword.espinhos), isFalse);
      final comSorte = _c('c', abilities: const ['sorte'])
          .copyWith(sorteAbility: AbilityKeyword.espinhos);
      expect(comSorte.hasKeyword(AbilityKeyword.espinhos), isTrue);
    });
  });

  group('Magnetismo (PlayRelic.grantedAbility)', () {
    MatchState _state(RelicCard inHand) => MatchState(
          sideA: BoardSide.initial(SideId.a, makeLoadout(prefix: 'A'))
              .copyWith(lanes: _pad([_c('tgt')]), hand: [inHand], crystals: 9),
          sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B')),
          activeSide: SideId.a,
          turn: 3,
          phase: MatchPhase.jogo,
          rng: makeRng(1),
        );

    test('equipar com escolha → portador ganha a habilidade escolhida', () {
      final emblema = relic(
          id: 'emb',
          concept: CardConcept.neutro,
          cost: 2,
          abilities: const ['suporte', 'magnetismo']);
      final after = engine.apply(
          _state(emblema), const PlayRelic('emb', 'tgt', grantedAbility: 'investida'));
      final c =
          after.sideA.creaturesInPlay.firstWhere((x) => x.instanceId == 'tgt');
      expect(c.hasKeyword(AbilityKeyword.magnetismo), isTrue);
      expect(c.hasKeyword(AbilityKeyword.investida), isTrue);
      // Suporte abre o 2º slot.
      expect(c.relicSlots, 2);
    });

    test('sem escolha → só as habilidades da própria relíquia', () {
      final emblema = relic(
          id: 'emb',
          concept: CardConcept.neutro,
          cost: 2,
          abilities: const ['suporte', 'magnetismo']);
      final after =
          engine.apply(_state(emblema), const PlayRelic('emb', 'tgt'));
      final c =
          after.sideA.creaturesInPlay.firstWhere((x) => x.instanceId == 'tgt');
      expect(c.hasKeyword(AbilityKeyword.magnetismo), isTrue);
      expect(c.hasKeyword(AbilityKeyword.investida), isFalse);
    });
  });

  group('Sorte (início de turno do dono)', () {
    test('manifesta uma habilidade aleatória e emite evento', () {
      // É a vez de B; ao encerrar, passa pra A → _beginTurn de A sorteia.
      final s = MatchState(
        sideA: BoardSide.initial(SideId.a, makeLoadout(prefix: 'A')).copyWith(
            lanes: _pad([_c('lucky', atk: 0, abilities: const ['sorte'])])),
        sideB: BoardSide.initial(SideId.b, makeLoadout(prefix: 'B'))
            .copyWith(lanes: _pad([_c('dummy', atk: 0)])),
        activeSide: SideId.b,
        turn: 3,
        phase: MatchPhase.jogo,
        rng: makeRng(7),
      );
      final after = engine.endTurn(s);
      final c = after.sideA.creaturesInPlay
          .firstWhere((x) => x.instanceId == 'lucky');
      expect(c.sorteAbility, isNotNull);
      expect(c.keywords.contains(c.sorteAbility), isTrue);
      expect(
          after.lastTurnEvents
              .whereType<AbilityTriggered>()
              .any((e) => e.ability == 'Sorte'),
          isTrue);
    });
  });
}
