/// Orquestrador da PARTIDA PvE do Card Game "Modo Cartas ACDA".
///
/// Camada fina e testável entre o `CardBattleEngine` (puro, em
/// `lib/domain/card_game/`) e a tela interativa (`card_match_screen.dart`):
///
///   - O JOGADOR é sempre o lado A; o BOT é sempre o lado B.
///   - Ações do jogador só são processadas em `PveMatchPhase.playerTurn`;
///     ação inválida (engine devolve o MESMO estado) → retorna `false` e
///     loga um aviso, sem alterar a partida.
///   - O turno do bot roda com pacing injetável (`botStepDelay`) para a UI
///     conseguir narrar passo a passo; nos testes usa `Duration.zero`.
///   - Eventos do `endTurn` (`MatchState.lastTurnEvents`) viram entradas de
///     log PT-BR legíveis (`MatchLogKind.combat`).
///
/// Sem Flame, sem widgets: este arquivo não importa Flutter (apenas
/// flutter_riverpod pelo StateNotifier), então os testes rodam puros.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/card_game/card_game.dart';

/// Fase da PARTIDA do ponto de vista da UI (não confundir com `MatchPhase`
/// do engine, que é jogo/ataque/fim).
enum PveMatchPhase { idle, playerTurn, resolving, botTurn, finished }

/// Categoria de uma entrada do log da partida (cor/ícone na UI).
enum MatchLogKind { system, player, bot, combat }

/// Uma linha do log narrado da partida.
class MatchLogEntry {
  const MatchLogEntry({
    required this.text,
    required this.kind,
    required this.turn,
  });

  final String text;
  final MatchLogKind kind;

  /// Turno em que a entrada foi gerada (turno do engine no momento).
  final int turn;

  @override
  String toString() => '[T$turn][${kind.name}] $text';
}

/// Destaque visual de UM evento de combate durante o replay narrado.
///
/// A tela usa isto para animar os tiles das lanes (atacante avança, alvo
/// treme, número de dano flutua). `null` fora do replay.
class CombatHighlight {
  const CombatHighlight({
    this.attackerCardId,
    this.targetCardId,
    this.attackerSide,
    this.targetSide,
    this.amount,
    this.isHeal = false,
    this.evaded = false,
    this.targetDied = false,
    this.ability,
    this.damageType,
  });

  /// Tipo do ataque (dirige a animação: físico avança+espada, mágico projétil,
  /// arqueiro flecha). null quando não se aplica (proc de habilidade).
  final DamageType? damageType;

  /// Criatura que agiu (atacante/curador/dona da habilidade).
  final String? attackerCardId;

  /// Criatura atingida/curada.
  final String? targetCardId;

  /// Lado dono do atacante / lado onde está o alvo. A tela usa [targetSide]
  /// para ancorar o número flutuante quando o alvo já saiu do tabuleiro
  /// (morreu e as lanes compactaram).
  final SideId? attackerSide;
  final SideId? targetSide;

  /// Dano causado (ou cura, se [isHeal]). null quando não se aplica.
  final int? amount;

  final bool isHeal;
  final bool evaded;
  final bool targetDied;

  /// Nome canônico da habilidade que disparou (eventos `AbilityTriggered`).
  final String? ability;
}

/// Estado imutável consumido pela tela. `match == null` apenas em `idle`.
class PveMatchUiState {
  const PveMatchUiState({
    this.match,
    this.phase = PveMatchPhase.idle,
    this.log = const <MatchLogEntry>[],
    this.selectedCardId,
    this.playerSide = SideId.a,
    this.playerWon,
    this.highlight,
    this.playLocked = false,
  });

  final MatchState? match;
  final PveMatchPhase phase;
  final List<MatchLogEntry> log;

  /// Evento de combate sendo narrado AGORA (replay passo a passo). A tela
  /// anima a partir dele; null fora do replay.
  final CombatHighlight? highlight;

  /// Carta do pool do jogador atualmente selecionada (fluxo de 2 toques).
  final String? selectedCardId;

  /// O jogador humano é SEMPRE o lado A (o bot é o B).
  final SideId playerSide;

  /// null enquanto a partida não terminou.
  final bool? playerWon;

  /// Após uma troca com o tabuleiro CHEIO (carta empurrada volta pra mão), o
  /// resto das ações da Fase de Jogo fica bloqueado — só sobra Encerrar Turno.
  /// Resetado no início de cada turno do jogador.
  final bool playLocked;

  SideId get botSideId => playerSide == SideId.a ? SideId.b : SideId.a;

  BoardSide? get playerBoard => match?.sideOf(playerSide);
  BoardSide? get botBoard => match?.sideOf(botSideId);

  bool get isPlayerTurn => phase == PveMatchPhase.playerTurn;
  bool get isFinished => phase == PveMatchPhase.finished;

  PveMatchUiState copyWith({
    MatchState? match,
    PveMatchPhase? phase,
    List<MatchLogEntry>? log,
    String? selectedCardId,
    bool clearSelectedCard = false,
    bool? playerWon,
    CombatHighlight? highlight,
    bool clearHighlight = false,
    bool? playLocked,
  }) {
    return PveMatchUiState(
      match: match ?? this.match,
      phase: phase ?? this.phase,
      log: log ?? this.log,
      selectedCardId:
          clearSelectedCard ? null : (selectedCardId ?? this.selectedCardId),
      playerSide: playerSide,
      playerWon: playerWon ?? this.playerWon,
      highlight: clearHighlight ? null : (highlight ?? this.highlight),
      playLocked: playLocked ?? this.playLocked,
    );
  }
}

/// Controller da partida PvE. Toda mutação passa por aqui; a tela só lê o
/// `PveMatchUiState` e dispara métodos.
class PveMatchController extends StateNotifier<PveMatchUiState> {
  PveMatchController({CardBattleEngine engine = const CardBattleEngine()})
      : _engine = engine,
        super(const PveMatchUiState());

  final CardBattleEngine _engine;

  // Ritmo deliberado estilo Card Monsters: cada jogada do bot e cada golpe do
  // replay precisam ser LEGÍVEIS. Valores base tunáveis (o CEO afina no flutter
  // run). O delay de evento precisa caber a animação do golpe + número + morte.
  // 1300ms nas jogadas do bot (CEO achou "um pouco rápido" a 1000).
  Duration _botStepDelay = const Duration(milliseconds: 1300);

  /// Delay entre EVENTOS narrados da Fase de Ataque (replay passo a passo).
  /// Acompanha o pacing do bot: `Duration.zero` (testes) => replay síncrono,
  /// sem highlight. Mesmo valor para os DOIS lados (ritmo simétrico).
  Duration get _eventStepDelay => _botStepDelay > Duration.zero
      ? const Duration(milliseconds: 1200)
      : Duration.zero;

  /// Guard de reentrância: cobre `startMatch` e `endPlayerTurn` (pipelines
  /// async). Ações síncronas do jogador também respeitam.
  bool _busy = false;

  /// Aborta pipelines async se o notifier foi descartado (tela saiu) ou a
  /// partida foi encerrada por fora (forfeit durante o pacing do bot).
  bool get _aborted => !mounted || state.phase == PveMatchPhase.finished;

  // ---------------------------------------------------------------------------
  // Ciclo de vida da partida
  // ---------------------------------------------------------------------------

  /// Inicia (ou reinicia) a partida. O engine joga a moeda via [seed]; se o
  /// bot começar, o turno dele roda já aqui (com pacing) e a vez volta ao
  /// jogador antes do Future completar.
  Future<void> startMatch(
    CardLoadout player,
    CardLoadout bot, {
    int seed = 0,
    Duration botStepDelay = const Duration(milliseconds: 1300),
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      _botStepDelay = botStepDelay;
      final match = _engine.start(player, bot, seed: seed);
      final youStart = match.activeSide == SideId.a;

      state = PveMatchUiState(
        match: match,
        phase: youStart ? PveMatchPhase.playerTurn : PveMatchPhase.botTurn,
        log: <MatchLogEntry>[
          MatchLogEntry(
            text: youStart
                ? 'Cara ou coroa: você começa!'
                : 'Cara ou coroa: a IA começa.',
            kind: MatchLogKind.system,
            turn: match.turn,
          ),
        ],
      );

      if (!youStart) {
        await _runBotTurn();
      }
    } finally {
      _busy = false;
    }
  }

  /// Desiste da partida: derrota imediata do jogador.
  void forfeit() {
    if (state.match == null ||
        state.phase == PveMatchPhase.idle ||
        state.phase == PveMatchPhase.finished) {
      return;
    }
    state = state.copyWith(
      phase: PveMatchPhase.finished,
      playerWon: false,
      clearSelectedCard: true,
      clearHighlight: true,
      log: _appended(MatchLogEntry(
        text: 'Você desistiu da partida. Derrota.',
        kind: MatchLogKind.system,
        turn: state.match!.turn,
      )),
    );
  }

  // ---------------------------------------------------------------------------
  // Ações do jogador (Fase de Jogo) — só em playerTurn
  // ---------------------------------------------------------------------------

  /// Joga uma criatura do pool do jogador. `lane` null = engine escolhe a
  /// lane livre mais à frente. Retorna false se não for a vez do jogador ou
  /// se o engine recusar (no-op).
  bool playCreature(String cardId, {int? lane, String? mimicTargetId}) {
    // Detecta (ANTES de aplicar) a jogada especial de "tabuleiro cheio →
    // carta empurrada volta pra mão", que custa 3 cristais e ENCERRA a vez.
    final match = state.match;
    final fullReturn = lane != null &&
        match != null &&
        match.activeSide == state.playerSide &&
        _engine.isFullBoardReturnPlay(match, cardId, lane);

    final ok = _playerAction(
      PlayCreature(cardId, lane: lane, mimicTargetId: mimicTargetId),
      onApplied: (before, after) {
        final name = _creatureName(before, cardId);
        final placed = _findCreature(after.sideOf(state.playerSide), cardId);
        final laneLabel = placed == null ? '' : ' na ${_laneLabel(placed.lane)}';
        if (fullReturn) {
          return 'Você jogou $name$laneLabel (tabuleiro cheio: '
              'carta recuada volta pra mão, −$kReturnToHandCost · só resta '
              'encerrar o turno).';
        }
        return 'Você jogou $name$laneLabel.';
      },
      invalidText: () =>
          'Jogada inválida: ${_creatureName(state.match!, cardId)} '
          'não pôde ser jogada.',
    );

    // Troca com tabuleiro cheio: bloqueia o resto das ações do turno (só sobra
    // Encerrar Turno) em vez de encerrar automaticamente.
    if (ok && fullReturn) {
      state = state.copyWith(playLocked: true, clearSelectedCard: true);
    }
    return ok;
  }

  /// Recua uma criatura PRÓPRIA em jogo de volta pra mão por
  /// `kReturnVoluntaryCost` cristais. NÃO encerra a vez.
  bool returnToHand(String creatureId) {
    if (state.playLocked) return false;
    return _playerAction(
      ReturnToHand(creatureId),
      onApplied: (before, after) {
        final c = _findCreature(before.sideOf(state.playerSide), creatureId);
        return 'Você recuou ${c?.card.nome ?? creatureId} pra mão '
            '(−$kReturnVoluntaryCost cristais).';
      },
      invalidText: () => 'Não dá pra recuar essa criatura '
          '(cristais insuficientes?).',
    );
  }

  /// Compra EXTRA de carta (ADR-0028): paga `kExtraDrawCost` cristais e puxa 1
  /// carta do deck pra mão. No-op se mão cheia, deck vazio ou sem cristais.
  bool drawCard() {
    if (state.playLocked) return false;
    return _playerAction(
      const DrawCard(),
      onApplied: (before, after) =>
          'Você comprou uma carta (−$kExtraDrawCost cristal).',
      invalidText: () =>
          'Não dá pra comprar (mão cheia, deck vazio ou sem cristais).',
    );
  }

  /// Troca a posição de uma criatura PRÓPRIA com outra ATRÁS dela (movimento só
  /// pra trás), por `kReturnVoluntaryCost` cristais. NÃO encerra a vez.
  bool swapPosition(String creatureId, String targetId) {
    if (state.playLocked) return false;
    return _playerAction(
      SwapPosition(creatureId, targetId),
      onApplied: (before, after) {
        final c = _findCreature(before.sideOf(state.playerSide), creatureId);
        return 'Você recuou ${c?.card.nome ?? creatureId} '
            '(−$kReturnVoluntaryCost cristais).';
      },
      invalidText: () => 'Movimento inválido (só pra trás; '
          'cristais insuficientes?).',
    );
  }

  /// Equipa/usa uma relíquia numa criatura própria em jogo.
  bool playRelic(String cardId, String targetCreatureId) {
    return _playerAction(
      PlayRelic(cardId, targetCreatureId),
      onApplied: (before, after) {
        final side = before.sideOf(state.playerSide);
        final relic = _relicInPool(side, cardId);
        final target = _findCreature(side, targetCreatureId);
        final verb = (relic?.isFlash ?? false) ? 'usou' : 'equipou';
        return 'Você $verb ${relic?.nome ?? cardId} '
            'em ${target?.card.nome ?? targetCreatureId}.';
      },
      invalidText: () =>
          'Jogada inválida: ${_relicName(state.match!, cardId)} '
          'não pôde ser equipada nesse alvo.',
    );
  }

  /// Sacrifica uma carta do pool por cristais (máx 1/turno).
  bool sacrifice(String cardId) {
    return _playerAction(
      Sacrifice(cardId),
      onApplied: (before, after) {
        final side = before.sideOf(state.playerSide);
        final relic = _relicInPool(side, cardId);
        if (relic != null) {
          return 'Você sacrificou ${relic.nome} '
              '(+$kSacrificeRelicCrystals cristal).';
        }
        final name = _creatureName(before, cardId);
        return 'Você sacrificou $name (+$kSacrificeCreatureCrystals cristais).';
      },
      invalidText: () => 'Sacrifício inválido (já sacrificou neste turno?).',
    );
  }

  /// Seleciona/deseleciona uma carta do pool (fluxo de 2 toques da UI).
  void selectCard(String? cardId) {
    if (state.phase != PveMatchPhase.playerTurn) return;
    if (cardId == null || cardId == state.selectedCardId) {
      state = state.copyWith(clearSelectedCard: true);
    } else {
      state = state.copyWith(selectedCardId: cardId);
    }
  }

  /// Núcleo comum das ações do jogador: valida fase, aplica no engine,
  /// detecta no-op por identidade e loga.
  bool _playerAction(
    GameAction action, {
    required String Function(MatchState before, MatchState after) onApplied,
    required String Function() invalidText,
  }) {
    if (_busy || state.phase != PveMatchPhase.playerTurn || state.playLocked) {
      return false;
    }
    final before = state.match;
    if (before == null ||
        before.isOver ||
        before.activeSide != state.playerSide) {
      return false;
    }

    final after = _engine.apply(before, action);
    if (identical(after, before)) {
      // Ação inválida = no-op do engine. Loga aviso, não muda a partida.
      state = state.copyWith(
        log: _appended(MatchLogEntry(
          text: invalidText(),
          kind: MatchLogKind.system,
          turn: before.turn,
        )),
      );
      return false;
    }

    state = state.copyWith(
      match: after,
      clearSelectedCard: true,
      log: _appended(MatchLogEntry(
        text: onApplied(before, after),
        kind: MatchLogKind.player,
        turn: before.turn,
      )),
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Fim do turno do jogador → ataque → turno do bot → vez do jogador
  // ---------------------------------------------------------------------------

  /// Encerra o turno do jogador: resolve a Fase de Ataque dele, narra os
  /// eventos, e roda o turno completo do bot (com pacing). Reentrância é
  /// bloqueada (`_busy`).
  Future<void> endPlayerTurn() async {
    if (_busy || state.phase != PveMatchPhase.playerTurn) return;
    final match = state.match;
    if (match == null || match.isOver) return;

    _busy = true;
    try {
      state = state.copyWith(
        phase: PveMatchPhase.resolving,
        clearSelectedCard: true,
      );

      // Fase de Ataque do jogador (replay passo a passo).
      final resolvedTurn = match.turn;
      final outcome = _engine.endTurnDetailed(match);
      await _replaySteps(outcome, resolvedTurn);
      if (!mounted) return;

      if (outcome.finalState.isOver) {
        if (state.phase != PveMatchPhase.finished) _finish(outcome.finalState);
        return;
      }
      if (_aborted) return; // forfeit durante o replay

      await _runBotTurn();
    } finally {
      _busy = false;
    }
  }

  /// Roda o turno COMPLETO do bot (lado ativo deve ser o bot): ações da Fase
  /// de Jogo com pacing + endTurn (Fase de Ataque do bot). Aborta em silêncio
  /// se o notifier for descartado ou a partida encerrada no meio.
  Future<void> _runBotTurn() async {
    if (_aborted) return;
    var match = state.match!;
    if (match.activeSide != state.botSideId) {
      // Defesa: nunca rodar o bot na vez do jogador.
      state = state.copyWith(phase: PveMatchPhase.playerTurn, playLocked: false);
      return;
    }
    state = state.copyWith(phase: PveMatchPhase.botTurn);

    final actions = _engine.botActions(match);
    for (final action in actions) {
      if (action is Pass) continue;
      final before = match;
      match = _engine.apply(match, action);
      if (identical(match, before)) continue; // bot tentou algo inválido: pula

      state = state.copyWith(
        match: match,
        log: _appended(MatchLogEntry(
          text: _botActionText(before, match, action),
          kind: MatchLogKind.bot,
          turn: match.turn,
        )),
      );

      if (_botStepDelay > Duration.zero) {
        await Future<void>.delayed(_botStepDelay);
      }
      if (_aborted) return;
    }

    // Fase de Ataque do bot (replay passo a passo).
    final resolvedTurn = match.turn;
    final outcome = _engine.endTurnDetailed(match);
    if (_aborted) return;
    await _replaySteps(outcome, resolvedTurn);
    if (!mounted) return;

    if (outcome.finalState.isOver) {
      if (state.phase != PveMatchPhase.finished) _finish(outcome.finalState);
    } else if (state.phase != PveMatchPhase.finished) {
      state = state.copyWith(phase: PveMatchPhase.playerTurn, playLocked: false);
    }
  }

  void _finish(MatchState match) {
    final won = match.winner == state.playerSide;
    state = state.copyWith(
      phase: PveMatchPhase.finished,
      playerWon: won,
      clearSelectedCard: true,
      clearHighlight: true,
      log: _appended(MatchLogEntry(
        text: won
            ? '— FIM — Vitória! A IA ficou sem criaturas.'
            : '— FIM — Derrota. Você ficou sem criaturas.',
        kind: MatchLogKind.system,
        turn: match.turn,
      )),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers de UI (puros, leem o estado atual)
  // ---------------------------------------------------------------------------

  SideId get playerSide => state.playerSide;
  SideId get botSide => state.botSideId;

  /// O jogador tem cristais para pagar [card]?
  bool canAfford(CreatureCard card) =>
      (state.playerBoard?.crystals ?? 0) >= card.cost;

  /// O jogador tem cristais para pagar a relíquia [relic]?
  bool canAffordRelic(RelicCard relic) =>
      (state.playerBoard?.crystals ?? 0) >= relic.cost;

  /// Índices das lanes LIVRES do jogador (0 = frente).
  List<int> freeLanes() {
    final board = state.playerBoard;
    if (board == null) return const <int>[];
    return <int>[
      for (var i = 0; i < board.lanes.length; i++)
        if (board.lanes[i] == null) i,
    ];
  }

  /// A criatura [card] pode ser jogada agora? Com lane livre, basta pagar o
  /// custo da carta. Tabuleiro CHEIO ainda permite a jogada de retorno (empurra
  /// a última pra mão), que custa `kReturnToHandCost` e encerra a vez.
  bool canPlayCreature(CreatureCard card) {
    if (state.phase != PveMatchPhase.playerTurn) return false;
    if (freeLanes().isNotEmpty) return canAfford(card);
    return (state.playerBoard?.crystals ?? 0) >= kReturnToHandCost;
  }

  /// Criaturas PRÓPRIAS em jogo compatíveis com a relíquia [relic].
  List<CreatureInPlay> compatibleTargets(RelicCard relic) {
    final board = state.playerBoard;
    if (board == null) return const <CreatureInPlay>[];
    return board.creaturesInPlay
        .where((c) => relic.isCompatibleWith(c.card))
        .toList(growable: false);
  }

  /// A relíquia [relic] pode ser jogada agora (vez do jogador, custo ok,
  /// pelo menos um alvo compatível em jogo)?
  bool canPlayRelic(RelicCard relic) =>
      state.phase == PveMatchPhase.playerTurn &&
      canAffordRelic(relic) &&
      compatibleTargets(relic).isNotEmpty;

  /// O jogador ainda pode sacrificar neste turno?
  bool get canSacrifice =>
      state.phase == PveMatchPhase.playerTurn &&
      !(state.playerBoard?.sacrificedThisTurn ?? true);

  // ---------------------------------------------------------------------------
  // Narração PT-BR
  // ---------------------------------------------------------------------------

  String _botActionText(MatchState before, MatchState after, GameAction action) {
    final side = before.sideOf(state.botSideId);
    switch (action) {
      case PlayCreature(:final cardId):
        final name = _creatureNameInPool(side, cardId) ?? cardId;
        final placed = _findCreature(after.sideOf(state.botSideId), cardId);
        final laneLabel = placed == null ? '' : ' na ${_laneLabel(placed.lane)}';
        return 'A IA jogou $name$laneLabel.';
      case PlayRelic(:final cardId, :final targetCreatureId):
        final relic = _relicInPool(side, cardId);
        final target = _findCreature(side, targetCreatureId);
        final verb = (relic?.isFlash ?? false) ? 'usou' : 'equipou';
        return 'A IA $verb ${relic?.nome ?? cardId} '
            'em ${target?.card.nome ?? targetCreatureId}.';
      case Sacrifice(:final cardId):
        final relic = _relicInPool(side, cardId);
        if (relic != null) {
          return 'A IA sacrificou ${relic.nome} '
              '(+$kSacrificeRelicCrystals cristal).';
        }
        final name = _creatureNameInPool(side, cardId) ?? cardId;
        return 'A IA sacrificou $name (+$kSacrificeCreatureCrystals cristais).';
      case ReturnToHand(:final creatureId):
        // O bot não usa esta ação no MVP; exaustividade do switch.
        final c = _findCreature(side, creatureId);
        return 'A IA recuou ${c?.card.nome ?? creatureId} pra mão.';
      case SwapPosition():
        // O bot não reposiciona no MVP; exaustividade do switch.
        return 'A IA reposicionou uma criatura.';
      case DrawCard():
        return 'A IA comprou uma carta (−$kExtraDrawCost cristal).';
      case Pass():
        return 'A IA passou.';
    }
  }

  /// Narra `lastTurnEvents` de [match] passo a passo: a cada evento, appenda
  /// a linha de log e publica um [CombatHighlight] para a tela animar, com
  /// `_eventStepDelay` entre eventos (ritmo tipo Card Monsters). Com pacing
  /// zero (testes), appenda tudo de uma vez — síncrono, sem highlight.
  ///
  /// O `MatchState` final já foi publicado ANTES do replay (HP/lanes finais);
  /// o replay só controla narração + animação, nunca o estado da partida.
  Future<void> _replaySteps(
      ({MatchState finalState, List<MatchReplayStep> steps}) outcome,
      int turn) async {
    final finalState = outcome.finalState;
    final steps = outcome.steps;

    // Modo síncrono (testes, pacing zero) OU nada a narrar: pula direto pro
    // estado final e appenda todos os logs de uma vez. Mantém os testes do
    // controller verdes (logs e estado final idênticos ao comportamento antigo).
    if (_eventStepDelay == Duration.zero || steps.isEmpty) {
      state = state.copyWith(
        match: finalState,
        log: _appendedAll(<MatchLogEntry>[
          for (final e in finalState.lastTurnEvents)
            MatchLogEntry(
                text: _eventText(e), kind: MatchLogKind.combat, turn: turn),
        ]),
      );
      return;
    }

    // Replay passo a passo: a cada step o TABULEIRO avança (HP cai, morto sai,
    // retaguarda avança) e o destaque visual anima o evento principal.
    for (final step in steps) {
      if (_aborted) {
        state = state.copyWith(match: finalState, clearHighlight: true);
        return;
      }
      final primary = _primaryEvent(step.events);
      final highlight = primary == null ? null : _highlightFor(primary);
      state = state.copyWith(
        match: step.state,
        highlight: highlight,
        clearHighlight: highlight == null,
        log: _appendedAll(<MatchLogEntry>[
          for (final e in step.events)
            MatchLogEntry(
                text: _eventText(e), kind: MatchLogKind.combat, turn: turn),
        ]),
      );
      await Future<void>.delayed(_eventStepDelay);
    }
    if (!mounted) return;
    // Crava o estado final exato (vira de turno / buffs) e limpa o destaque.
    state = state.copyWith(match: finalState, clearHighlight: true);
  }

  /// Evento "âncora" de um step para o destaque visual: prioriza ataque/evasão/
  /// cura (ancorados em atacante+alvo) sobre procs de habilidade.
  MatchEvent? _primaryEvent(List<MatchEvent> events) {
    if (events.isEmpty) return null;
    for (final e in events) {
      if (e is AttackResolved || e is AttackEvaded || e is HealResolved) {
        return e;
      }
    }
    return events.first;
  }

  /// Mapeia um [MatchEvent] para o destaque visual correspondente.
  /// Eventos sem ancoragem em criatura (penalidade, stall) não destacam.
  CombatHighlight? _highlightFor(MatchEvent e) {
    SideId opposite(SideId s) => s == SideId.a ? SideId.b : SideId.a;
    switch (e) {
      case AttackResolved():
        return CombatHighlight(
          attackerCardId: e.attackerCardId,
          targetCardId: e.targetCardId,
          attackerSide: e.attackerSide,
          targetSide: opposite(e.attackerSide),
          amount: e.damageDealt,
          targetDied: e.targetDied,
          damageType: e.damageType,
        );
      case AttackEvaded():
        return CombatHighlight(
          attackerCardId: e.attackerCardId,
          targetCardId: e.targetCardId,
          attackerSide: e.attackerSide,
          targetSide: opposite(e.attackerSide),
          evaded: true,
        );
      case HealResolved():
        return CombatHighlight(
          attackerCardId: e.healerCardId,
          targetCardId: e.targetCardId,
          attackerSide: e.side,
          targetSide: e.side,
          amount: e.amount,
          isHeal: true,
          damageType: DamageType.cura,
        );
      case AbilityTriggered():
        return CombatHighlight(
          attackerCardId: e.cardId,
          attackerSide: e.side,
          ability: e.ability,
        );
      case StatusDamageResolved():
        // DoT no início do turno: destaca a carta afetada sofrendo o dano.
        return CombatHighlight(
          attackerCardId: e.cardId,
          targetCardId: e.cardId,
          attackerSide: e.side,
          targetSide: e.side,
          amount: e.damage,
          targetDied: e.targetDied,
          ability: e.statusLabel,
        );
      case NoCreaturePenaltyApplied():
      case StallLimitReached():
        return null;
    }
  }

  String _eventText(MatchEvent e) {
    switch (e) {
      case AttackResolved():
        final b = StringBuffer(
            '${e.attackerName} atacou ${e.targetName}: ${e.rawDamage} de dano');
        if (e.damageDealt != e.rawDamage) {
          b.write(' (${e.damageDealt} após armadura)');
        }
        if (e.targetDied) {
          b.write(' — ${e.targetName} morreu!');
        } else {
          b.write(' — restou ${e.targetHpAfter} PV.');
        }
        return b.toString();
      case AttackEvaded():
        return '${e.targetName} EVADIU o ataque de ${e.attackerName} (Voo)!';
      case AbilityTriggered():
        return '${e.cardName} · ${e.ability}: ${e.detail}';
      case HealResolved():
        return '${e.healerName} curou ${e.targetName}: +${e.amount} PV.';
      case StatusDamageResolved():
        final b = StringBuffer(
            '${e.cardName} sofreu ${e.damage} de ${e.statusLabel}');
        b.write(e.targetDied
            ? ' — morreu!'
            : ' — restou ${e.targetHpAfter} PV.');
        return b.toString();
      case NoCreaturePenaltyApplied():
        final who = e.side == state.playerSide ? 'Você terminou' : 'A IA terminou';
        final kind = e.wasCreature ? 'criatura' : 'relíquia';
        return '$who o turno sem criaturas e perdeu ${e.lostCardName} ($kind).';
      case StallLimitReached():
        final who = e.winner == state.playerSide ? 'você' : 'a IA';
        return 'Limite de turnos atingido — desempate favorece $who.';
    }
  }

  // ---------------------------------------------------------------------------
  // Lookups de nomes/cartas
  // ---------------------------------------------------------------------------

  String _laneLabel(int lane) =>
      lane == 0 ? 'linha de frente' : 'linha ${lane + 1}';

  String _creatureName(MatchState match, String cardId) {
    final side = match.sideOf(state.playerSide);
    return _creatureNameInPool(side, cardId) ?? cardId;
  }

  String _relicName(MatchState match, String cardId) {
    final side = match.sideOf(state.playerSide);
    return _relicInPool(side, cardId)?.nome ?? cardId;
  }

  String? _creatureNameInPool(BoardSide side, String cardId) {
    for (final c in side.hand.whereType<CreatureCard>()) {
      if (c.id == cardId) return c.nome;
    }
    for (final c in side.deck.whereType<CreatureCard>()) {
      if (c.id == cardId) return c.nome;
    }
    final inPlay = _findCreature(side, cardId);
    return inPlay?.card.nome;
  }

  RelicCard? _relicInPool(BoardSide side, String cardId) {
    for (final r in side.hand.whereType<RelicCard>()) {
      if (r.id == cardId) return r;
    }
    for (final r in side.deck.whereType<RelicCard>()) {
      if (r.id == cardId) return r;
    }
    return null;
  }

  CreatureInPlay? _findCreature(BoardSide side, String instanceId) {
    for (final c in side.lanes) {
      if (c != null && c.instanceId == instanceId) return c;
    }
    return null;
  }

  List<MatchLogEntry> _appended(MatchLogEntry entry) =>
      List<MatchLogEntry>.unmodifiable(<MatchLogEntry>[...state.log, entry]);

  List<MatchLogEntry> _appendedAll(List<MatchLogEntry> entries) =>
      List<MatchLogEntry>.unmodifiable(<MatchLogEntry>[...state.log, ...entries]);
}

/// Provider da partida PvE. `autoDispose`: sair da tela descarta a partida
/// (o pacing do bot aborta via `mounted`).
final pveMatchControllerProvider =
    StateNotifierProvider.autoDispose<PveMatchController, PveMatchUiState>(
  (ref) => PveMatchController(),
);
