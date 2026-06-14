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
/// `grantedAbility` (round 3): habilidade ESCOLHIDA pelo jogador quando a
/// relíquia concede Magnetismo (string canônica; só vale se o portador tiver
/// Magnetismo). Vem de fora (UI/bot) — não afeta o determinismo do motor.
class PlayRelic extends GameAction {
  const PlayRelic(this.cardId, this.targetCreatureId, {this.grantedAbility});
  final String cardId;
  final String targetCreatureId;
  final String? grantedAbility;

  @override
  String toString() =>
      'PlayRelic($cardId -> $targetCreatureId${grantedAbility != null ? ', +$grantedAbility' : ''})';
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

/// Compra EXTRA de carta durante a partida (ADR-0028): paga `kExtraDrawCost`
/// cristais e puxa 1 carta do topo do deck pra mão. No-op se mão cheia, deck
/// vazio ou cristais insuficientes.
class DrawCard extends GameAction {
  const DrawCard();

  @override
  String toString() => 'DrawCard()';
}

/// Usa a ATIVA do herói representante do lado (ADR-0028), 1×/partida. O efeito
/// depende do herói (despachado no engine). No-op se não há herói, se já foi
/// usada, ou se o herói ainda não tem ativa implementada.
class UseHeroActive extends GameAction {
  const UseHeroActive();

  @override
  String toString() => 'UseHeroActive()';
}

/// Reposiciona 1 carta dentro do topo (`kOraculoPeekCount`) do DECK — passiva da
/// Oráculo (ADR-0028). Move a carta do índice [from] para [to] (ambos no topo).
/// `from == to` ou índices fora do topo = só limpa o peek pendente (pular).
/// No-op se não há peek pendente.
class ReorderDeck extends GameAction {
  const ReorderDeck(this.from, this.to);
  final int from;
  final int to;

  @override
  String toString() => 'ReorderDeck($from -> $to)';
}

/// ATIVA da Oráculo (ADR-0028), 1×/partida. A revelação do deck+mão do oponente
/// é feita na UI; esta ação aplica a ESCOLHA: se [shuffle], embaralha a mão do
/// oponente de volta no deck e ele recompra a mesma quantidade (você ganha
/// `kOraculoShuffleCrystals`); senão, você ganha `kOraculoKeepCrystals`.
class OraculoActive extends GameAction {
  const OraculoActive(this.shuffle);
  final bool shuffle;

  @override
  String toString() => 'OraculoActive(shuffle=$shuffle)';
}

/// Encerra a Fase de Jogo do lado ativo (sinaliza fim da sequência de ações).
class Pass extends GameAction {
  const Pass();

  @override
  String toString() => 'Pass()';
}
