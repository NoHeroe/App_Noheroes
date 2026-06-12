/// Ações da Fase de Jogo. Sealed: PlayCreature / PlayRelic / Sacrifice / Pass.
library;

sealed class GameAction {
  const GameAction();
}

/// Joga uma criatura do pool pagando seu custo. `lane` opcional: se null, o
/// engine escolhe a lane livre mais à frente disponível. `mimicTargetId`:
/// instanceId da criatura (aliada ou inimiga) que um MÍMICO copia ao entrar —
/// se null e a carta for Mímico, o engine auto-escolhe (mais forte em jogo).
class PlayCreature extends GameAction {
  const PlayCreature(this.cardId, {this.lane, this.mimicTargetId});
  final String cardId;
  final int? lane;
  final String? mimicTargetId;

  @override
  String toString() =>
      'PlayCreature($cardId, lane=$lane${mimicTargetId != null ? ', mimic=$mimicTargetId' : ''})';
}

/// Equipa uma relíquia do pool numa criatura PRÓPRIA do mesmo conceito.
class PlayRelic extends GameAction {
  const PlayRelic(this.cardId, this.targetCreatureId);
  final String cardId;
  final String targetCreatureId;

  @override
  String toString() => 'PlayRelic($cardId -> $targetCreatureId)';
}

/// Sacrifica uma carta (relíquia ou criatura do pool) por cristais. Máx 1/turno.
class Sacrifice extends GameAction {
  const Sacrifice(this.cardId);
  final String cardId;

  @override
  String toString() => 'Sacrifice($cardId)';
}

/// Recua uma criatura PRÓPRIA em jogo de volta para a mão, pagando
/// `kReturnVoluntaryCost` cristais. NÃO encerra a vez. Relíquias equipadas são
/// descartadas (MVP). A fila do tabuleiro re-compacta.
class ReturnToHand extends GameAction {
  const ReturnToHand(this.creatureId);
  final String creatureId;

  @override
  String toString() => 'ReturnToHand($creatureId)';
}

/// Troca a posição de uma criatura PRÓPRIA com outra ATRÁS dela (movimento só
/// pra trás), pagando `kReturnVoluntaryCost` cristais. NÃO encerra a vez. A
/// `creatureId` (selecionada) vai pra posição da `targetId` (mais atrás) e
/// vice-versa. (SPEC do CEO 2026-06-11.)
class SwapPosition extends GameAction {
  const SwapPosition(this.creatureId, this.targetId);
  final String creatureId; // a selecionada (vai pra trás)
  final String targetId; // a de trás (vem pra frente)

  @override
  String toString() => 'SwapPosition($creatureId <-> $targetId)';
}

/// Encerra a Fase de Jogo do lado ativo (sinaliza fim da sequência de ações).
class Pass extends GameAction {
  const Pass();

  @override
  String toString() => 'Pass()';
}
