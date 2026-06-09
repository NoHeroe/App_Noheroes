/// Testes do orquestrador da partida PvE (`PveMatchController`).
///
/// Loadouts vêm de `test/domain/card_game/fixtures.dart` (stats controlados).
/// `botStepDelay: Duration.zero` — sem pacing nos testes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';
import 'package:noheroes_app/presentation/card_game/pve_match_controller.dart';

import '../../domain/card_game/fixtures.dart';

void main() {
  /// Acha um seed cuja moeda (`engine.start`) dá o primeiro turno a [starter].
  int seedForStarter(SideId starter) {
    const engine = CardBattleEngine();
    for (var seed = 0; seed < 64; seed++) {
      final s = engine.start(makeLoadout(), makeLoadout(prefix: 'Y'), seed: seed);
      if (s.activeSide == starter) return seed;
    }
    fail('Nenhum seed em 0..63 fez o lado ${starter.name} começar.');
  }

  PveMatchController makeController() => PveMatchController();

  Future<void> startPlayerFirst(
    PveMatchController c, {
    CardLoadout? player,
    CardLoadout? bot,
  }) async {
    await c.startMatch(
      player ?? makeLoadout(prefix: 'P'),
      bot ?? makeLoadout(prefix: 'B'),
      seed: seedForStarter(SideId.a),
      botStepDelay: Duration.zero,
    );
  }

  group('startMatch', () {
    test('jogador começa: fase playerTurn + log da moeda', () async {
      final c = makeController();
      await startPlayerFirst(c);

      expect(c.state.phase, PveMatchPhase.playerTurn);
      expect(c.state.match, isNotNull);
      expect(c.state.match!.activeSide, SideId.a);
      expect(c.state.log.first.kind, MatchLogKind.system);
      expect(c.state.log.first.text, contains('você começa'));
    });

    test('bot começa: roda o turno do bot e devolve a vez ao jogador',
        () async {
      final c = makeController();
      await c.startMatch(
        makeLoadout(prefix: 'P'),
        makeLoadout(prefix: 'B'),
        seed: seedForStarter(SideId.b),
        botStepDelay: Duration.zero,
      );

      expect(c.state.log.first.text, contains('a IA começa'));
      // Após o turno do bot, a vez volta ao jogador (partida não acaba no T1).
      expect(c.state.phase, PveMatchPhase.playerTurn);
      expect(c.state.match!.activeSide, SideId.a);
      // O bot jogou pelo menos uma criatura (cristais 3, custo 1).
      expect(
        c.state.log.any((e) => e.kind == MatchLogKind.bot),
        isTrue,
        reason: 'log deve conter jogadas do bot',
      );
    });
  });

  group('ações do jogador', () {
    test('playCreature válida retorna true e loga; inválida retorna false '
        'sem mudar a partida', () async {
      final c = makeController();
      await startPlayerFirst(c);

      final card = c.state.playerBoard!.poolCreatures.first;
      expect(c.canPlayCreature(card), isTrue);
      expect(c.playCreature(card.id, lane: 0), isTrue);
      expect(c.state.playerBoard!.lanes[0]?.card.id, card.id);
      expect(
        c.state.log.last.kind,
        MatchLogKind.player,
      );
      expect(c.state.log.last.text, contains('Você jogou'));

      // Inválida: mesma carta de novo (já saiu do pool) → no-op + false.
      final before = c.state.match;
      expect(c.playCreature(card.id), isFalse);
      expect(identical(c.state.match, before), isTrue);
      expect(c.state.log.last.text, contains('inválida'));
    });

    test('playCreature sem cristais suficientes retorna false', () async {
      final c = makeController();
      // Criaturas caras (custo 9) — 3 cristais não pagam.
      await startPlayerFirst(c, player: makeLoadout(prefix: 'P', cost: 9));

      final card = c.state.playerBoard!.poolCreatures.first;
      expect(c.canAfford(card), isFalse);
      expect(c.playCreature(card.id), isFalse);
      expect(c.state.playerBoard!.creaturesInPlay, isEmpty);
    });

    test('sacrifice só 1×/turno: segundo retorna false', () async {
      final c = makeController();
      await startPlayerFirst(c);

      final r1 = c.state.playerBoard!.poolRelics[0];
      final r2 = c.state.playerBoard!.poolRelics[1];

      expect(c.canSacrifice, isTrue);
      final crystalsBefore = c.state.playerBoard!.crystals;
      expect(c.sacrifice(r1.id), isTrue);
      expect(c.state.playerBoard!.crystals,
          crystalsBefore + kSacrificeRelicCrystals);

      expect(c.canSacrifice, isFalse);
      expect(c.sacrifice(r2.id), isFalse);
      expect(c.state.playerBoard!.poolRelics.length, 8);
    });

    test('relíquia incompatível retorna false (no-op)', () async {
      final c = makeController();
      // Criaturas vitalismo; relíquias do bot não importam. Monta um loadout
      // do jogador com uma relíquia corrompida (não-universal) na mão.
      final player = CardLoadout(
        creatures: [
          for (var i = 0; i < 9; i++)
            creature(id: 'P_c$i', concept: CardConcept.vitalismo),
        ],
        relics: [
          relic(id: 'P_bad', concept: CardConcept.corrompido),
          for (var i = 1; i < 9; i++)
            relic(id: 'P_r$i', concept: CardConcept.vitalismo),
        ],
      );
      await startPlayerFirst(c, player: player);

      expect(c.playCreature('P_c0', lane: 0), isTrue);
      final badRelic =
          c.state.playerBoard!.poolRelics.firstWhere((r) => r.id == 'P_bad');
      expect(c.compatibleTargets(badRelic), isEmpty);
      expect(c.playRelic('P_bad', 'P_c0'), isFalse);
      expect(c.state.playerBoard!.lanes[0]!.relics, isEmpty);

      // Compatível funciona.
      expect(c.playRelic('P_r1', 'P_c0'), isTrue);
      expect(c.state.playerBoard!.lanes[0]!.relics, hasLength(1));
    });

    test('relíquia impagável: canAffordRelic/canPlayRelic false e playRelic '
        'retorna false (no-op)', () async {
      final c = makeController();
      // Relíquia compatível mas cara (custo 5 > 3 cristais do turno) na mão.
      final player = CardLoadout(
        creatures: [
          for (var i = 0; i < 9; i++)
            creature(id: 'P_c$i', concept: CardConcept.vitalismo),
        ],
        relics: [
          relic(id: 'P_cara', concept: CardConcept.vitalismo, cost: 5),
          relic(id: 'P_ok', concept: CardConcept.vitalismo, cost: 1, armor: 1),
          for (var i = 2; i < 9; i++)
            relic(id: 'P_r$i', concept: CardConcept.vitalismo),
        ],
      );
      await startPlayerFirst(c, player: player);

      expect(c.playCreature('P_c0', lane: 0), isTrue); // 3 - 1 = 2 cristais

      final cara = c.state.playerBoard!.poolRelics
          .firstWhere((r) => r.id == 'P_cara');
      expect(c.canAffordRelic(cara), isFalse);
      expect(c.canPlayRelic(cara), isFalse);
      // Alvo compatível existe, mas falta cristal → engine recusa (no-op).
      expect(c.compatibleTargets(cara), isNotEmpty);
      expect(c.playRelic('P_cara', 'P_c0'), isFalse);
      expect(c.state.playerBoard!.lanes[0]!.relics, isEmpty);
      expect(c.state.playerBoard!.crystals, 2);

      // Pagável: joga e debita.
      final ok =
          c.state.playerBoard!.poolRelics.firstWhere((r) => r.id == 'P_ok');
      expect(c.canAffordRelic(ok), isTrue);
      expect(c.canPlayRelic(ok), isTrue);
      expect(c.playRelic('P_ok', 'P_c0'), isTrue);
      expect(c.state.playerBoard!.lanes[0]!.relics, hasLength(1));
      expect(c.state.playerBoard!.crystals, 1);
    });

    test('ações fora de playerTurn são no-op (idle e finished)', () async {
      final c = makeController();

      // idle: nada começou.
      expect(c.playCreature('P_c0'), isFalse);
      expect(c.playRelic('P_r0', 'P_c0'), isFalse);
      expect(c.sacrifice('P_r0'), isFalse);
      expect(c.canSacrifice, isFalse);

      await startPlayerFirst(c);
      c.forfeit();
      expect(c.state.phase, PveMatchPhase.finished);

      final logLen = c.state.log.length;
      expect(c.playCreature(c.state.playerBoard!.poolCreatures.first.id),
          isFalse);
      expect(c.sacrifice(c.state.playerBoard!.poolRelics.first.id), isFalse);
      expect(c.state.log.length, logLen, reason: 'no-op não loga');
    });
  });

  group('endPlayerTurn', () {
    test('resolve ataque, roda o bot e devolve a vez ao jogador', () async {
      final c = makeController();
      await startPlayerFirst(c);

      final card = c.state.playerBoard!.poolCreatures.first;
      expect(c.playCreature(card.id, lane: 0), isTrue);

      await c.endPlayerTurn();

      expect(c.state.phase, PveMatchPhase.playerTurn);
      expect(c.state.match!.activeSide, SideId.a);
      expect(c.state.log.any((e) => e.kind == MatchLogKind.bot), isTrue,
          reason: 'o bot deve ter jogado no turno dele');
    });

    test('eventos de combate viram log combat', () async {
      final c = makeController();
      await startPlayerFirst(c);

      // T1 jogador: joga criatura. Bot joga as dele no turno dele.
      expect(
          c.playCreature(c.state.playerBoard!.poolCreatures.first.id,
              lane: 0),
          isTrue);
      await c.endPlayerTurn();

      // T3 jogador: agora os dois lados têm criaturas → o ataque do jogador
      // gera AttackResolved → entrada combat.
      expect(c.state.phase, PveMatchPhase.playerTurn);
      await c.endPlayerTurn();

      final combat =
          c.state.log.where((e) => e.kind == MatchLogKind.combat).toList();
      expect(combat, isNotEmpty);
      expect(combat.any((e) => e.text.contains('atacou')), isTrue);
    });

    test('penalidade de terminar sem criaturas é narrada', () async {
      final c = makeController();
      await startPlayerFirst(c);

      // Termina sem jogar nada → perde 1 carta aleatória.
      await c.endPlayerTurn();

      expect(
        c.state.log.any((e) =>
            e.kind == MatchLogKind.combat &&
            e.text.contains('sem criaturas') &&
            e.text.contains('Você')),
        isTrue,
      );
    });

    test('fora de playerTurn é no-op (guard de reentrância)', () async {
      final c = makeController();
      await startPlayerFirst(c);

      final before = c.state.match;
      // Duas chamadas: a primeira processa, a segunda (estado já mudou de
      // playerTurn) é descartada.
      final f1 = c.endPlayerTurn();
      final f2 = c.endPlayerTurn();
      await Future.wait([f1, f2]);

      expect(c.state.match, isNot(same(before)));
      // O turno só avançou UMA rodada (jogador T1 + bot T2 → jogador T3).
      expect(c.state.match!.turn, 3);
    });

    test('partida dirigida até finished sem travar', () async {
      final c = makeController();
      // Jogador forte vs bot fraco → vitória do jogador em poucas rodadas.
      await startPlayerFirst(
        c,
        player: makeLoadout(prefix: 'P', atk: 9, hp: 9),
        bot: makeLoadout(prefix: 'B', atk: 1, hp: 1),
      );

      var guard = 0;
      while (c.state.phase != PveMatchPhase.finished && guard++ < 60) {
        expect(c.state.phase, PveMatchPhase.playerTurn,
            reason: 'entre rodadas a vez deve ser do jogador');
        // Joga a primeira criatura jogável, se houver.
        final pool = c.state.playerBoard!.poolCreatures;
        for (final card in pool) {
          if (c.canPlayCreature(card)) {
            expect(c.playCreature(card.id), isTrue);
            break;
          }
        }
        await c.endPlayerTurn();
      }

      expect(c.state.phase, PveMatchPhase.finished,
          reason: 'a partida deve terminar dentro do guard');
      expect(c.state.playerWon, isTrue);
      expect(c.state.match!.isOver, isTrue);
      expect(c.state.match!.winner, SideId.a);
      expect(c.state.log.last.text, contains('FIM'));
    });
  });

  group('forfeit', () {
    test('encerra com derrota e loga', () async {
      final c = makeController();
      await startPlayerFirst(c);

      c.forfeit();

      expect(c.state.phase, PveMatchPhase.finished);
      expect(c.state.playerWon, isFalse);
      expect(c.state.log.last.text, contains('desistiu'));

      // Forfeit de novo: no-op.
      final logLen = c.state.log.length;
      c.forfeit();
      expect(c.state.log.length, logLen);
    });

    test('antes de startMatch é no-op', () {
      final c = makeController();
      c.forfeit();
      expect(c.state.phase, PveMatchPhase.idle);
      expect(c.state.playerWon, isNull);
    });
  });

  group('helpers de UI', () {
    test('freeLanes / canPlayCreature / compatibleTargets / selectCard',
        () async {
      final c = makeController();
      await startPlayerFirst(c);

      expect(c.freeLanes(), [0, 1, 2]);

      final card = c.state.playerBoard!.poolCreatures.first;
      c.selectCard(card.id);
      expect(c.state.selectedCardId, card.id);
      // Selecionar a mesma carta deseleciona (toggle).
      c.selectCard(card.id);
      expect(c.state.selectedCardId, isNull);

      c.selectCard(card.id);
      expect(c.playCreature(card.id, lane: 1), isTrue);
      // Ação bem-sucedida limpa a seleção.
      expect(c.state.selectedCardId, isNull);
      expect(c.freeLanes(), [0, 2]);

      final relicCard = c.state.playerBoard!.poolRelics.first;
      final targets = c.compatibleTargets(relicCard);
      expect(targets.map((t) => t.instanceId), contains(card.id));
    });
  });
}
