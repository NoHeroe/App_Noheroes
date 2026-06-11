/// Ações da Fase de Jogo. Sealed: PlayCreature / PlayRelic / Sacrifice / Pass.
library;

sealed class GameAction {
  const GameAction();
}

/// Joga uma criatura do pool pagando seu custo. `lane` opcional: se null, o
/// engine escolhe a lane livre mais à frente disponível.
class PlayCreature extends GameAction {
  const PlayCreature(this.cardId, {this.lane});
  final String cardId;
  final int? lane;

  @override
  String toString() => 'PlayCreature($cardId, lane=$lane)';
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

/// Encerra a Fase de Jogo do lado ativo (sinaliza fim da sequência de ações).
class Pass extends GameAction {
  const Pass();

  @override
  String toString() => 'Pass()';
}
