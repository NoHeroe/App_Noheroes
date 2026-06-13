// instanceId ÚNICO por instância (CreatureInPlay.uid): tokens duplicados (ex.:
// várias "Caixa Coringa" do Coringa) compartilham `card.id`, mas precisam ser
// DISTINGUÍVEIS pra mira/morte. Antes `instanceId => card.id` conflundia as
// cópias (matar uma "matava" as duas). Agora `instanceId => uid ?? card.id`.
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

import 'fixtures.dart';

const engine = CardBattleEngine();

MatchState _stateWith({
  required List<CreatureInPlay?> aLanes,
  required List<CreatureInPlay?> bLanes,
  SideId activeSide = SideId.a,
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
    activeSide: activeSide,
    turn: 3,
    phase: MatchPhase.jogo,
    rng: makeRng(seed),
  );
}

void main() {
  group('CreatureInPlay.instanceId (uid único por instância)', () {
    test('sem uid → instanceId cai no card.id (criaturas normais do deck)', () {
      final c = CreatureInPlay(
          card: creature(id: 'goblin', hp: 3), currentHp: 3, lane: 0);
      expect(c.instanceId, 'goblin');
    });

    test('com uid → instanceId é o uid; duas cópias do MESMO card são distintas',
        () {
      final base = creature(id: 'caixa_coringa', hp: 1);
      final a = CreatureInPlay(card: base, currentHp: 1, lane: 0, uid: 'cx#0');
      final b = CreatureInPlay(card: base, currentHp: 1, lane: 1, uid: 'cx#1');
      expect(a.instanceId, 'cx#0');
      expect(b.instanceId, 'cx#1');
      expect(a.instanceId == b.instanceId, isFalse);
      // o card.id segue igual nas duas (identidade de CARTA, não de instância).
      expect(a.card.id, b.card.id);
    });

    test('uid sobrevive ao copyWith', () {
      final a = CreatureInPlay(
          card: creature(id: 'caixa_coringa', hp: 1),
          currentHp: 1,
          lane: 0,
          uid: 'cx#0');
      final moved = a.copyWith(lane: 2, currentHp: 1);
      expect(moved.instanceId, 'cx#0');
    });
  });

  group('engine distingue instâncias com o MESMO card.id (cenário Caixa Coringa)',
      () {
    // Duas criaturas com o mesmo card.id porém uids distintos (como as Caixas
    // Coringa invocadas pelo Coringa). Matar a da FRENTE deve deixar a de TRÁS.
    CreatureInPlay dup(String uid) => CreatureInPlay(
          card: creature(id: 'token_dup', atk: 0, hp: 1),
          currentHp: 1,
          lane: 0,
          uid: uid,
        );

    test('matar uma cópia deixa a outra viva (sem conflundir as duas)', () {
      final s = _stateWith(
        aLanes: [inPlayKiller()],
        bLanes: [dup('dup#0'), dup('dup#1')],
      );
      final after = engine.endTurn(s);
      final survivors =
          after.sideB.creaturesInPlay.map((c) => c.instanceId).toList();
      expect(survivors, contains('dup#1'),
          reason: 'a cópia não-atingida deve sobreviver');
      expect(survivors, isNot(contains('dup#0')),
          reason: 'a cópia atingida deve morrer');
      expect(after.sideB.graveyard.length, 1,
          reason: 'só a atingida vai pro cemitério');
    });
  });
}

/// Atacante melee forte o bastante pra matar a Caixa da frente (1 PV).
CreatureInPlay inPlayKiller() => CreatureInPlay(
      card: creature(id: 'killer', atk: 5, hp: 10),
      currentHp: 10,
      lane: 0,
    );
