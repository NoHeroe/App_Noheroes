/// Motor do Card Game "Modo Cartas ACDA". Lógica pura, determinística.
///
/// Contrato em `_ENGINE_SPEC_mvp.md`. Estado imutável (copyWith). Ações
/// inválidas são no-op (nunca lançam exceção que derrube a partida).
library;

import 'dart:math';

import 'abilities.dart';
import 'card_models.dart';
import 'engine_config.dart';
import 'game_action.dart';
import 'match_events.dart';
import 'match_state.dart';

class CardBattleEngine {
  const CardBattleEngine();

  // ---------------------------------------------------------------------------
  // start
  // ---------------------------------------------------------------------------

  /// Cria a partida: moeda (rng) decide quem começa; aplica o início de turno
  /// do lado ativo (+cristais). Fase resultante = `jogo`.
  MatchState start(CardLoadout a, CardLoadout b, {int seed = 0}) {
    final rng = Random(seed);
    final starter = rng.nextBool() ? SideId.a : SideId.b;

    var state = MatchState(
      sideA: BoardSide.initial(SideId.a, a, rng),
      sideB: BoardSide.initial(SideId.b, b, rng),
      activeSide: starter,
      turn: 1,
      phase: MatchPhase.jogo,
      rng: rng,
    );

    // No start não há criaturas em jogo: nenhum proc de início de turno
    // possível — a lista de eventos é descartável.
    state = _beginTurn(state, <MatchEvent>[]);
    return state;
  }

  /// Aplica o início do turno do lado ativo: cristais (+ `pendingCrystals`
  /// do Cristal de Drenagem), reset de sacrifício e buffs de início de turno
  /// (Inspirar/Investida). Procs narráveis vão para [events].
  MatchState _beginTurn(MatchState s, List<MatchEvent> events) {
    final side = s.active;
    final base = kCrystalsCarryOver ? side.crystals : 0;
    var newSide = side.copyWith(
      crystals: base + kCrystalsPerTurn + side.pendingCrystals,
      pendingCrystals: 0,
      sacrificedThisTurn: false,
    );
    newSide = _applyStartOfTurnBuffs(newSide, events);
    var state = s.withSide(side.id, newSide).copyWith(phase: MatchPhase.jogo);
    // Auras de início de turno que debuffam o INIMIGO (Lote 3b): Desmoralizar /
    // Suprimir Magia. Reduzem o atk do oponente até a rodada dele.
    state = _applyEnemyAuras(state, side.id, events);
    return state;
  }

  /// Aplica as auras do lado [auraOwner] que reduzem o ataque do INIMIGO:
  /// Desmoralizar (melee) e Suprimir Magia (mágico). Só o maior aplica (bônus
  /// fixo → aplica 1× se houver ≥1 com a aura, ignorando quem está doente).
  /// O debuff dura até a rodada do inimigo (limpo em `_expireEndOfTurnBuffs`).
  MatchState _applyEnemyAuras(
      MatchState s, SideId auraOwner, List<MatchEvent> events) {
    final owner = s.sideOf(auraOwner);
    final enemyId = auraOwner == SideId.a ? SideId.b : SideId.a;
    final enemy = s.sideOf(enemyId);

    final desmoralizers = owner.creaturesInPlay
        .where((c) => c.functionalKeyword(AbilityKeyword.desmoralizar))
        .toList();
    final suppressors = owner.creaturesInPlay
        .where((c) => c.functionalKeyword(AbilityKeyword.suprimirMagia))
        .toList();
    if (desmoralizers.isEmpty && suppressors.isEmpty) return s;

    final melee = desmoralizers.isNotEmpty ? kDesmoralizarReduction : 0;
    final magic = suppressors.isNotEmpty ? kSuprimirReduction : 0;

    final lanes = List<CreatureInPlay?>.from(enemy.lanes);
    var changed = false;
    for (var i = 0; i < lanes.length; i++) {
      final c = lanes[i];
      if (c == null) continue;
      if (c.desmoralizadoMelee != melee || c.suprimidoMagico != magic) {
        lanes[i] = c.copyWith(desmoralizadoMelee: melee, suprimidoMagico: magic);
        changed = true;
      }
    }

    for (final d in desmoralizers) {
      events.add(AbilityTriggered(
        side: auraOwner,
        cardId: d.instanceId,
        cardName: d.card.nome,
        ability: abilityKeywordLabel(AbilityKeyword.desmoralizar),
        detail: '-$kDesmoralizarReduction de ataque melee nos inimigos',
      ));
    }
    for (final sup in suppressors) {
      events.add(AbilityTriggered(
        side: auraOwner,
        cardId: sup.instanceId,
        cardName: sup.card.nome,
        ability: abilityKeywordLabel(AbilityKeyword.suprimirMagia),
        detail: '-$kSuprimirReduction de ataque mágico nos inimigos',
      ));
    }

    return changed ? s.withSide(enemyId, enemy.copyWith(lanes: lanes)) : s;
  }

  /// Inspirar: aliados (não o inspirador) ganham 🎚️ `kInspirarBonus` de
  /// ataque melee até o fim do turno. Com vários Inspirar, só o maior se
  /// aplica — com bônus fixo igual, aplica 1× (não acumula).
  /// Investida: a própria criatura ganha 🎚️ `kInvestidaBonus` de ataque melee
  /// até o fim do turno do OPONENTE.
  BoardSide _applyStartOfTurnBuffs(BoardSide side, List<MatchEvent> events) {
    final living = side.creaturesInPlay;
    if (living.isEmpty) return side;

    final inspirers = living
        .where((c) => c.functionalKeyword(AbilityKeyword.inspirar))
        .toList();

    final lanes = List<CreatureInPlay?>.from(side.lanes);
    var changed = false;
    for (var i = 0; i < lanes.length; i++) {
      final c = lanes[i];
      if (c == null || !c.isAlive) continue;
      // "aliados (não ele)": só inspira se existir OUTRO inspirador vivo.
      final inspired =
          inspirers.any((o) => o.instanceId != c.instanceId);
      final inspirarB = inspired ? kInspirarBonus : 0;
      final investidaB =
          c.hasKeyword(AbilityKeyword.investida) ? kInvestidaBonus : 0;
      // Cooldown de Atordoar decai 1 por turno do dono.
      final newCd = c.atordoarCooldown > 0 ? c.atordoarCooldown - 1 : 0;
      if (c.inspirarBonus != inspirarB ||
          c.investidaBonus != investidaB ||
          c.atordoarCooldown != newCd) {
        lanes[i] = c.copyWith(
          inspirarBonus: inspirarB,
          investidaBonus: investidaB,
          atordoarCooldown: newCd,
        );
        changed = true;
      }
    }

    // Eventos: 1 por proc (1 por inspirador com alvo; 1 por Investida).
    for (final ins in inspirers) {
      if (living.length > 1) {
        events.add(AbilityTriggered(
          side: side.id,
          cardId: ins.instanceId,
          cardName: ins.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.inspirar),
          detail: '+$kInspirarBonus de ataque corpo a corpo para aliados '
              'até o fim do turno',
        ));
      }
    }
    for (final c in living) {
      if (c.hasKeyword(AbilityKeyword.investida)) {
        events.add(AbilityTriggered(
          side: side.id,
          cardId: c.instanceId,
          cardName: c.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.investida),
          detail: '+$kInvestidaBonus de ataque corpo a corpo até o fim do '
              'turno do oponente',
        ));
      }
    }

    return changed ? side.copyWith(lanes: lanes) : side;
  }

  /// Expira buffs temporários no fim do turno do lado [ending]:
  /// - Inspirar do próprio lado (durou "até o fim do turno" do dono);
  /// - Investida do lado OPOSTO (aplicada no turno anterior dele, durou "até
  ///   o fim do turno do oponente" — que é exatamente o turno que termina).
  MatchState _expireEndOfTurnBuffs(MatchState s, SideId ending) {
    BoardSide clear(BoardSide side,
        {required bool inspirar,
        required bool investida,
        required bool debuff}) {
      final lanes = List<CreatureInPlay?>.from(side.lanes);
      var changed = false;
      for (var i = 0; i < lanes.length; i++) {
        final c = lanes[i];
        if (c == null) continue;
        final newInspirar = inspirar ? 0 : c.inspirarBonus;
        final newInvestida = investida ? 0 : c.investidaBonus;
        // Debuffs de aura (Desmoralizar/Suprimir) expiram no fim do turno do
        // lado debuffado — após ele já ter atacado com o atk reduzido.
        final newDesmo = debuff ? 0 : c.desmoralizadoMelee;
        final newSupr = debuff ? 0 : c.suprimidoMagico;
        if (c.inspirarBonus != newInspirar ||
            c.investidaBonus != newInvestida ||
            c.desmoralizadoMelee != newDesmo ||
            c.suprimidoMagico != newSupr) {
          lanes[i] = c.copyWith(
            inspirarBonus: newInspirar,
            investidaBonus: newInvestida,
            desmoralizadoMelee: newDesmo,
            suprimidoMagico: newSupr,
          );
          changed = true;
        }
      }
      return changed ? side.copyWith(lanes: lanes) : side;
    }

    final other = ending == SideId.a ? SideId.b : SideId.a;
    var state = s.withSide(ending,
        clear(s.sideOf(ending), inspirar: true, investida: false, debuff: true));
    state = state.withSide(
        other,
        clear(state.sideOf(other),
            inspirar: false, investida: true, debuff: false));
    return state;
  }

  // ---------------------------------------------------------------------------
  // apply (Fase de Jogo)
  // ---------------------------------------------------------------------------

  /// Valida e aplica uma ação da Fase de Jogo. Ação inválida → estado inalterado
  /// (no-op). `Pass` é tratado como no-op aqui (o avanço de turno é `endTurn`).
  MatchState apply(MatchState s, GameAction action) {
    if (s.isOver || s.phase != MatchPhase.jogo) return s;

    switch (action) {
      case PlayCreature():
        return _playCreature(s, action);
      case PlayRelic():
        return _playRelic(s, action);
      case Sacrifice():
        return _sacrifice(s, action);
      case ReturnToHand():
        return _returnToHand(s, action);
      case SwapPosition():
        return _swapPosition(s, action);
      case Pass():
        return s; // no-op: fim da sequência é sinalizado via endTurn.
    }
  }

  /// Troca a posição de duas criaturas PRÓPRIAS — a selecionada vai pra trás
  /// (movimento só pra trás: `targetId` precisa estar ATRÁS da `creatureId`).
  /// Custa `kReturnVoluntaryCost` cristais e NÃO encerra a vez.
  MatchState _swapPosition(MatchState s, SwapPosition a) {
    final side = s.active;
    if (side.crystals < kReturnVoluntaryCost) return s;
    final packed = side.creaturesInPlay.toList();
    final i = packed.indexWhere((c) => c.instanceId == a.creatureId);
    final j = packed.indexWhere((c) => c.instanceId == a.targetId);
    if (i < 0 || j < 0 || i == j) return s;
    if (j <= i) return s; // só pra trás: alvo precisa estar mais atrás (lane maior).
    final tmp = packed[i];
    packed[i] = packed[j];
    packed[j] = tmp;
    final newSide = side.copyWith(
      lanes: _packedToLanes(packed),
      crystals: side.crystals - kReturnVoluntaryCost,
    );
    return s.withSide(side.id, newSide);
  }

  /// Recua uma criatura PRÓPRIA em jogo de volta pra mão por `kReturnVoluntaryCost`
  /// cristais (NÃO encerra a vez). A fila re-compacta; relíquias equipadas são
  /// descartadas (MVP). No-op se a criatura não está em jogo ou faltam cristais.
  MatchState _returnToHand(MatchState s, ReturnToHand a) {
    final side = s.active;
    if (side.crystals < kReturnVoluntaryCost) return s;
    final target = side.creaturesInPlay
        .where((c) => c.instanceId == a.creatureId)
        .firstOrNull;
    if (target == null) return s;

    final packed = side.creaturesInPlay
        .where((c) => c.instanceId != a.creatureId)
        .toList();
    final hand = List<Object>.from(side.hand)..add(target.card);
    final newSide = side.copyWith(
      lanes: _packedToLanes(packed),
      hand: hand,
      crystals: side.crystals - kReturnVoluntaryCost,
    );
    return s.withSide(side.id, newSide);
  }

  /// Mímico: monta a carta a jogar copiando stats (atk/PV/tipo) e keywords de um
  /// alvo em jogo. Alvo = `targetId` (aliado ou inimigo), senão o de maior ATK
  /// em jogo. Mantém id/nome/custo/conceito do mímico. Sem alvo, retorna [mimic].
  CreatureCard _mimicCard(MatchState s, CreatureCard mimic, String? targetId) {
    final all = <CreatureInPlay>[
      ...s.sideA.creaturesInPlay,
      ...s.sideB.creaturesInPlay,
    ];
    CreatureInPlay? target;
    if (targetId != null) {
      for (final c in all) {
        if (c.instanceId == targetId) {
          target = c;
          break;
        }
      }
    }
    if (target == null) {
      for (final c in all) {
        if (target == null || c.card.atk > target.card.atk) target = c;
      }
    }
    if (target == null) return mimic; // nada em jogo pra copiar
    final tc = target.card;
    return mimic.copyWith(
      atk: tc.atk,
      hp: tc.hp,
      damageType: tc.damageType,
      abilities: tc.abilities,
    );
  }

  MatchState _playCreature(MatchState s, PlayCreature a) {
    final side = s.active;
    final idx =
        side.hand.indexWhere((c) => c is CreatureCard && c.id == a.cardId);
    if (idx < 0) return s; // não está na mão
    final card = side.hand[idx] as CreatureCard;

    // FRONT-PACKED: o tabuleiro nunca tem buraco na frente. As criaturas vivas
    // formam uma fila compacta (frente→retaguarda); a lane pedida é só a
    // INTENÇÃO de posição e é clampada ao tamanho da fila (não dá pra colocar
    // no slot 3 com o slot 1 vazio — vai pra frente).
    final packed = side.creaturesInPlay; // já ordenado por lane, só vivas
    final count = packed.length;

    final int requested;
    if (a.lane != null) {
      if (a.lane! < 0 || a.lane! >= kLaneCount) return s;
      requested = a.lane!;
    } else {
      requested = count; // auto/bot sem lane: encaixa após a última
    }

    // Mímico (Lote 5): ao entrar, copia stats+keywords de um alvo (aliado ou
    // inimigo). Alvo marcado em `a.mimicTargetId`; sem marca, auto-escolhe o
    // mais forte em jogo. Sem alvo possível, entra como a própria carta.
    final isMimic = card.abilities
        .any((x) => abilityKeywordFromString(x) == AbilityKeyword.mimico);
    final playCard = isMimic ? _mimicCard(s, card, a.mimicTargetId) : card;
    final placed =
        CreatureInPlay(card: playCard, currentHp: playCard.hp, lane: 0);

    if (count < kLaneCount) {
      // Há vaga: encaixe front-packed (paga o custo da carta).
      if (card.cost > side.crystals) return s; // cristais insuficientes
      final insertPos = requested < count ? requested : count; // clamp à fila
      final list = List<CreatureInPlay>.from(packed)..insert(insertPos, placed);
      final hand = List<Object>.from(side.hand)..removeAt(idx);
      var newSide = side.copyWith(
        lanes: _packedToLanes(list),
        hand: hand,
        crystals: side.crystals - card.cost,
      );
      newSide = _refillHand(newSide); // compra automática
      return s.withSide(side.id, newSide);
    }

    // Tabuleiro CHEIO: insere front-packed empurrando a última criatura pra
    // mão. Custa kReturnToHandCost e ENCERRA a vez (o controller dispara o
    // endTurn ao detectar este caso). Sem compra (a mão troca 1 por 1).
    if (side.crystals < kReturnToHandCost) return s;
    final insertPos = requested < kLaneCount ? requested : kLaneCount - 1;
    final list = List<CreatureInPlay>.from(packed)..insert(insertPos, placed);
    final displaced = list.removeLast(); // a que caiu do slot de trás
    final hand = List<Object>.from(side.hand)..removeAt(idx);
    hand.add(displaced.card); // relíquias equipadas são descartadas (MVP)
    final newSide = side.copyWith(
      lanes: _packedToLanes(list),
      hand: hand,
      crystals: side.crystals - kReturnToHandCost,
    );
    return s.withSide(side.id, newSide);
  }

  /// Converte uma fila PACKED (frente→retaguarda) em lanes indexadas: o item i
  /// vai pro lane i (re-atribuindo `lane`); os lanes restantes ficam nulos.
  /// Garante a invariante "sem buraco na frente".
  List<CreatureInPlay?> _packedToLanes(List<CreatureInPlay> packed) {
    final lanes = List<CreatureInPlay?>.filled(kLaneCount, null);
    for (var i = 0; i < packed.length && i < kLaneCount; i++) {
      lanes[i] = packed[i].copyWith(lane: i);
    }
    return lanes;
  }

  /// Compra automática: repõe a mão do topo do deck até `kHandSize`.
  BoardSide _refillHand(BoardSide side) {
    if (side.hand.length >= kHandSize || side.deck.isEmpty) return side;
    final hand = List<Object>.from(side.hand);
    final deck = List<Object>.from(side.deck);
    while (hand.length < kHandSize && deck.isNotEmpty) {
      hand.add(deck.removeAt(0));
    }
    return side.copyWith(hand: hand, deck: deck);
  }

  /// Esta jogada de criatura é o caso especial "tabuleiro cheio → carta volta
  /// pra mão" (custa 3 e encerra a vez)? O controller usa isto pra disparar o
  /// fim do turno automaticamente. Puro: depende só do estado ANTES da jogada.
  bool isFullBoardReturnPlay(MatchState s, String cardId, int lane) {
    final side = s.active;
    if (lane < 0 || lane >= kLaneCount) return false;
    if (!side.hand.any((c) => c is CreatureCard && c.id == cardId)) return false;
    // Front-packed: só é caso "volta pra mão" quando a fila já está CHEIA
    // (3 criaturas). Com vaga, qualquer posição pedida encaixa empurrando sem
    // expulsar ninguém.
    return side.creaturesInPlay.length >= kLaneCount;
  }

  MatchState _playRelic(MatchState s, PlayRelic a) {
    final side = s.active;
    final idx =
        side.hand.indexWhere((c) => c is RelicCard && c.id == a.cardId);
    if (idx < 0) return s;

    final relic = side.hand[idx] as RelicCard;
    if (relic.cost > side.crystals) return s; // cristais insuficientes

    // Encontra a criatura alvo (própria, em jogo).
    final laneIdx =
        side.lanes.indexWhere((c) => c != null && c.instanceId == a.targetCreatureId);
    if (laneIdx < 0) return s;
    final target = side.lanes[laneIdx]!;

    // Compatibilidade: relíquia universal (neutro) OU compartilha ≥1 conceito.
    if (!relic.isCompatibleWith(target.card)) return s;

    final newHand = List<Object>.from(side.hand)..removeAt(idx);

    CreatureInPlay updated;
    if (relic.isFlash) {
      // Uso único: aplica efeito (cura) e descarta — não fica equipada.
      var hp = target.currentHp;
      final heal = relic.grants.heal == null ? null : relic.scaledHeal;
      if (heal != null) {
        hp = (hp + heal).clamp(0, target.maxHp);
      }
      updated = target.copyWith(currentHp: hp);
    } else {
      // Permanente: respeita relicSlots; se cheio, substitui a mais antiga.
      final newRelics = List<RelicCard>.from(target.relics);
      if (newRelics.length >= target.card.relicSlots && newRelics.isNotEmpty) {
        newRelics.removeAt(0); // descarta a antiga
      }
      newRelics.add(relic);

      // Cura instantânea concedida também aplica ao equipar.
      var hp = target.currentHp;
      final heal = relic.grants.heal == null ? null : relic.scaledHeal;
      if (heal != null) {
        hp = (hp + heal).clamp(0, target.maxHp);
      }
      updated = target.copyWith(relics: newRelics, currentHp: hp);
    }

    final newLanes = List<CreatureInPlay?>.from(side.lanes);
    newLanes[laneIdx] = updated;

    // Cobra o custo em cristais (vale para equipamento E flash) e compra.
    var newSide = side.copyWith(
      lanes: newLanes,
      hand: newHand,
      crystals: side.crystals - relic.cost,
    );
    newSide = _refillHand(newSide); // compra automática
    return s.withSide(side.id, newSide);
  }

  MatchState _sacrifice(MatchState s, Sacrifice a) {
    final side = s.active;
    if (side.sacrificedThisTurn) return s; // máx 1/turno

    // A carta a sacrificar tem que estar na MÃO.
    final idx = side.hand.indexWhere((c) => cardId(c) == a.cardId);
    if (idx < 0) return s; // carta não está na mão

    final card = side.hand[idx];
    final gain = card is RelicCard
        ? kSacrificeRelicCrystals
        : kSacrificeCreatureCrystals;

    final newHand = List<Object>.from(side.hand)..removeAt(idx);
    var newSide = side.copyWith(
      hand: newHand,
      crystals: side.crystals + gain,
      sacrificedThisTurn: true,
    );
    newSide = _refillHand(newSide); // compra automática
    return s.withSide(side.id, newSide);
  }

  // ---------------------------------------------------------------------------
  // endTurn (Fase de Ataque + penalidade + passa turno + checa fim)
  // ---------------------------------------------------------------------------

  /// Encerra a Fase de Jogo do lado ativo, resolve a Fase de Ataque automática,
  /// aplica penalidade de "sem criaturas", checa vitória/stall e passa o turno.
  ///
  /// Os eventos gerados durante a resolução (ataques, curas, penalidade,
  /// stall) são devolvidos em `lastTurnEvents` — substituindo (não acumulando)
  /// os do `endTurn` anterior.
  ///
  /// Wrapper fino sobre [endTurnDetailed]: descarta os `steps` do replay e
  /// devolve só o estado final. Usado por testes e bot-vs-bot.
  MatchState endTurn(MatchState s) => endTurnDetailed(s).finalState;

  /// Como [endTurn], mas também devolve a LINHA DO TEMPO da resolução: uma lista
  /// de [MatchReplayStep] em ordem, cada um com o snapshot do tabuleiro logo após
  /// aquele passo e a fatia de eventos correspondente. A UI usa os steps pra
  /// animar a Fase de Ataque passo a passo (o tabuleiro avança a cada golpe/morte
  /// em vez de pular pro final). `finalState` é idêntico ao retorno de [endTurn].
  ({MatchState finalState, List<MatchReplayStep> steps}) endTurnDetailed(
      MatchState s) {
    if (s.isOver) {
      return (finalState: s, steps: const <MatchReplayStep>[]);
    }

    // Log estruturado da resolução deste endTurn + keyframes do replay.
    final events = <MatchEvent>[];
    final steps = <MatchReplayStep>[];

    // Snapshota a fatia de eventos [from..] num step ancorado em [snapState].
    void record(MatchState snapState, int from) {
      if (events.length <= from) return;
      steps.add(MatchReplayStep(
        state: snapState,
        events: List<MatchEvent>.unmodifiable(events.sublist(from)),
      ));
    }

    // DoT (Sangramento/Veneno) ANTES da Fase de Ataque: dispara quando o dono
    // da carta afetada clica "encerrar turno" (início do processamento deste
    // endTurn), não durante as ações dele. Atinge as criaturas DESTE lado.
    final beforeDot = events.length;
    var state = _resolveStatusTicks(s, events);
    record(state, beforeDot);
    final winAfterDot = _checkVictory(state);
    if (winAfterDot != null) {
      final fin = state.copyWith(
        phase: MatchPhase.fim,
        winner: winAfterDot,
        lastTurnEvents: List.unmodifiable(events),
      );
      return (finalState: fin, steps: steps);
    }

    // Fase de Ataque automática (grava 1 step por ação de ataque/cura).
    state = _resolveAttackPhase(state, events, steps);
    final winAfterAttack = _checkVictory(state);
    if (winAfterAttack != null) {
      final fin = state.copyWith(
        phase: MatchPhase.fim,
        winner: winAfterAttack,
        lastTurnEvents: List.unmodifiable(events),
      );
      return (finalState: fin, steps: steps);
    }

    // Penalidade: terminar o turno sem criaturas no tabuleiro.
    final beforePenalty = events.length;
    state = _applyNoCreaturePenalty(state, events);
    record(state, beforePenalty);
    final winAfterPenalty = _checkVictory(state);
    if (winAfterPenalty != null) {
      final fin = state.copyWith(
        phase: MatchPhase.fim,
        winner: winAfterPenalty,
        lastTurnEvents: List.unmodifiable(events),
      );
      return (finalState: fin, steps: steps);
    }

    // Trava anti-stall.
    if (state.turn >= kStallTurnLimit) {
      final beforeStall = events.length;
      final fin = _resolveStall(state, events);
      record(fin, beforeStall);
      return (finalState: fin, steps: steps);
    }

    // Expira buffs temporários (Inspirar do lado que termina; Investida do
    // oponente — aplicada no turno anterior dele, valeu a rodada inteira).
    final ending = state.activeSide;
    state = _expireEndOfTurnBuffs(state, ending);

    // Passa o turno para o oponente e inicia o turno dele. Procs de início
    // de turno (Inspirar/Investida do novo lado ativo) entram nos MESMOS
    // lastTurnEvents deste endTurn — semântica documentada em MatchState.
    final next = ending == SideId.a ? SideId.b : SideId.a;
    state = state.copyWith(activeSide: next, turn: state.turn + 1);
    final beforeBegin = events.length;
    state = _beginTurn(state, events);
    final fin = state.copyWith(lastTurnEvents: List.unmodifiable(events));
    record(fin, beforeBegin);
    return (finalState: fin, steps: steps);
  }

  /// Rótulo do DoT ativo de uma criatura (para narração do tick).
  String _dotLabel(CreatureInPlay c) {
    if (c.bleedStacks > 0 && c.poisoned) return 'Sangramento+Veneno';
    if (c.poisoned) return abilityKeywordLabel(AbilityKeyword.veneno);
    return abilityKeywordLabel(AbilityKeyword.sangramento);
  }

  /// Tick de DoT (Sangramento/Veneno) nas criaturas do lado ATIVO, no início do
  /// seu endTurn. Dano VERDADEIRO (ignora armadura). Sangramento decai 1 turno
  /// por tick (e zera os acúmulos ao expirar); Veneno persiste. Inabalável ainda
  /// salva de morte por DoT (consistente com os demais death sites).
  MatchState _resolveStatusTicks(MatchState s, List<MatchEvent> events) {
    final side = s.active;
    final lanes = List<CreatureInPlay?>.from(side.lanes);
    var anyDeath = false;
    var changed = false;
    final zombies = <CreatureInPlay>[]; // mortos por DoT com Carta Zumbi
    for (var i = 0; i < lanes.length; i++) {
      final c = lanes[i];
      if (c == null || !c.isAlive || !c.hasDot) continue;
      final dmg = c.dotDamage;
      final label = _dotLabel(c);
      final lethal = _resolveLethal(c, c.currentHp - dmg);
      var updated = lethal.creature;
      if (updated != null) {
        // Decai Sangramento (Veneno não tem duração).
        final newBleedTurns = c.bleedTurns > 0 ? c.bleedTurns - 1 : 0;
        updated = updated.copyWith(
          bleedTurns: newBleedTurns,
          bleedStacks: newBleedTurns == 0 ? 0 : c.bleedStacks,
        );
        // Transformar: o tick pode derrubar o PV abaixo do limiar.
        updated = _maybeTransform(updated, side.id, events);
      }
      lanes[i] = updated;
      changed = true;
      if (lethal.died) {
        anyDeath = true;
        // Carta Zumbi: morto por DoT volta enfraquecido pra mão.
        zombies.add(c);
      }
      events.add(StatusDamageResolved(
        side: side.id,
        cardId: c.instanceId,
        cardName: c.card.nome,
        statusLabel: label,
        damage: dmg,
        targetHpAfter: updated?.currentHp ?? 0,
        targetDied: lethal.died,
      ));
      if (lethal.revived) {
        events.add(AbilityTriggered(
          side: side.id,
          cardId: c.instanceId,
          cardName: c.card.nome,
          ability: abilityKeywordLabel(lethal.revivedBy!),
          detail: 'resistiu à destruição (DoT) e voltou em jogo',
        ));
      }
    }
    if (!changed) return s;
    var newSide = side.copyWith(lanes: lanes);
    for (final z in zombies) {
      final card = _zombieCard(z);
      if (card != null) newSide = _addZombieToHand(newSide, card, events);
    }
    if (anyDeath) newSide = _advanceLanes(newSide);
    return s.withSide(side.id, newSide);
  }

  /// Resolve a Fase de Ataque do lado ativo contra o oponente — combate
  /// POSICIONAL fiel a `tipos_de_dano.md`:
  /// - `corpoACorpo` só ataca da linha de frente (Alcance libera a retaguarda;
  ///   "Golpe/Charge" também liberaria, mas não existe nos dados → sem runtime);
  /// - `aDistancia` só ataca da retaguarda ("Tiro Corpo a Corpo" liberaria a
  ///   frente — não existe nos dados → sem runtime);
  /// - `magico`/`vitalismo` atacam de qualquer posição;
  /// - `cura` cura de qualquer posição.
  /// Criatura fora de posição simplesmente NÃO age neste turno.
  /// Silêncio (aura inimiga) bloqueia `magico` e `cura`.
  MatchState _resolveAttackPhase(
      MatchState s, List<MatchEvent> events, List<MatchReplayStep>? steps) {
    var attacker = s.active;
    var defender = s.opponent;

    // Snapshot PRÉ-ataque (feel Card Monsters): o estado de cada step é o de
    // ANTES do golpe (preAtk/preDef), mas carrega os eventos GERADOS por ele.
    // Assim a UI anima o golpe com o alvo AINDA VIVO na posição (mostra dano e
    // morte sobre ele) e só avança/compacta o tabuleiro no passo SEGUINTE — em
    // vez de já mostrar o resultado resolvido (que fazia o golpe "cair" na carta
    // errada por causa do avanço da retaguarda).
    var snappedUpTo = 0;
    void snapPre(BoardSide preAtk, BoardSide preDef) {
      if (steps == null || events.length <= snappedUpTo) return;
      final slice = List<MatchEvent>.unmodifiable(events.sublist(snappedUpTo));
      snappedUpTo = events.length;
      final snapState =
          s.withSide(preAtk.id, preAtk).withSide(preDef.id, preDef);
      steps.add(MatchReplayStep(state: snapState, events: slice));
    }

    // Ordem de lane (frente→retaguarda), fixada no início da fase.
    final order = attacker.creaturesInPlay.map((c) => c.instanceId).toList();

    // Atordoamento / Enredamento: criaturas presas PULAM esta Fase de Ataque e
    // limpam o status (Enredar devolve o Voo ao limpar). Narrado num passo.
    final skipped = <String>{};
    {
      final lanes = List<CreatureInPlay?>.from(attacker.lanes);
      var changed = false;
      for (var i = 0; i < lanes.length; i++) {
        final c = lanes[i];
        if (c == null || !c.isAlive || !c.skipsAttack) continue;
        skipped.add(c.instanceId);
        events.add(AbilityTriggered(
          side: attacker.id,
          cardId: c.instanceId,
          cardName: c.card.nome,
          ability: c.stunned
              ? abilityKeywordLabel(AbilityKeyword.atordoar)
              : abilityKeywordLabel(AbilityKeyword.enredar),
          detail: 'presa: pulou a Fase de Ataque',
        ));
        lanes[i] = c.copyWith(stunned: false, entangled: false);
        changed = true;
      }
      if (changed) {
        attacker = attacker.copyWith(lanes: lanes);
        snapPre(attacker, defender); // flush dos eventos de "presa" num passo.
      }
    }

    for (final attackerId in order) {
      if (skipped.contains(attackerId)) continue; // presa neste turno.
      // Sem alvos → fase termina (já é vitória de fato).
      if (!defender.hasCreatureInPlay) break;

      // Lista de ataques FIXADA no início da vez desta criatura (multi-ataque:
      // 1 por tipo de dano). Cada ataque é resolvido separadamente, com mira/
      // posição própria, e vira seu próprio passo animado.
      final lane0 = attacker.lanes
          .indexWhere((c) => c != null && c.instanceId == attackerId);
      if (lane0 < 0) continue;
      final creature0 = attacker.lanes[lane0]!;
      if (!creature0.isAlive) continue;
      final atkList = creature0.attacks;

      for (final atk in atkList) {
        if (!defender.hasCreatureInPlay) break;

        // Estado ANTES deste golpe — é o que o step mostra enquanto a UI anima.
        final preAtk = attacker;
        final preDef = defender;

        // Re-localiza (mortes do defensor compactam lanes; atacante pode ter
        // mudado de estado entre golpes via Roubo de PV).
        final attackerLaneIdx = attacker.lanes
            .indexWhere((c) => c != null && c.instanceId == attackerId);
        if (attackerLaneIdx < 0) break;
        final creature = attacker.lanes[attackerLaneIdx]!;
        if (!creature.isAlive) break;

        final type = atk.type;

        // Silêncio (aura): enquanto o INIMIGO tiver criatura com Silêncio viva,
        // este lado não usa ataque mágico nem cura.
        if (type == DamageType.magico || type == DamageType.cura) {
          final silencer = defender.creaturesInPlay
              .where((c) => c.hasKeyword(AbilityKeyword.silencio))
              .firstOrNull;
          if (silencer != null) {
            events.add(AbilityTriggered(
              side: defender.id,
              cardId: silencer.instanceId,
              cardName: silencer.card.nome,
              ability: abilityKeywordLabel(AbilityKeyword.silencio),
              detail: 'bloqueou ${creature.card.nome} '
                  '(${type == DamageType.cura ? 'cura' : 'ataque mágico'})',
            ));
            snapPre(preAtk, preDef);
            continue;
          }
        }

        if (type == DamageType.cura) {
          attacker = _resolveHeal(attacker, creature, events);
          snapPre(preAtk, preDef);
          continue;
        }

        // ---- Elegibilidade posicional (POR ATAQUE — regra purista do CEO) ----
        // Linha de frente do PRÓPRIO lado = menor lane ocupada.
        final myFront = attacker.creaturesInPlay.first.lane;
        final atFront = creature.lane == myFront;

        if (type == DamageType.corpoACorpo &&
            !atFront &&
            !creature.hasKeyword(AbilityKeyword.alcance)) {
          continue; // melee fora de posição não dispara ESTE ataque.
        }
        if (type == DamageType.aDistancia && atFront) {
          continue; // à distância na frente não dispara ESTE ataque.
        }
        if (type == DamageType.vitalismo &&
            !kVitalismoAttacksAnywhere &&
            !atFront) {
          continue;
        }

        final result = _resolveAttack(
          s,
          attacker,
          defender,
          attackerLaneIdx,
          type,
          atk.value,
          meleeFromFront: type == DamageType.corpoACorpo && atFront,
          events: events,
        );
        attacker = result.$1;
        defender = result.$2;
        snapPre(preAtk, preDef);
      }
    }

    var state = s.withSide(attacker.id, attacker);
    state = state.withSide(defender.id, defender);
    return state;
  }

  /// Resolve UM ataque (alvo, evasão de Voo, dano e procs on-hit: Roubo de PV,
  /// Cristal de Drenagem, Pisotear, Ataque Duplo). Retorna (atacante, defensor)
  /// atualizados. Lanes do defensor são compactadas no fim, uma única vez.
  /// Aplica `newHp` a uma criatura considerando **Inabalável**: se for morrer
  /// (newHp ≤ 0) mas tiver Inabalável ainda não-usado, ela NÃO morre —
  /// ressuscita com vida cheia e marca o uso (1×/partida). Retorna a criatura
  /// resultante (null se morreu de verdade) + se morreu/reviveu.
  ({CreatureInPlay? creature, bool died, bool revived, AbilityKeyword? revivedBy})
      _resolveLethal(CreatureInPlay c, int newHp) {
    if (newHp > 0) {
      return (
        creature: c.copyWith(currentHp: newHp),
        died: false,
        revived: false,
        revivedBy: null,
      );
    }
    // Inabalável: revive com VIDA CHEIA (1×).
    if (c.hasKeyword(AbilityKeyword.inabalavel) && !c.inabalavelUsed) {
      return (
        creature: c.copyWith(currentHp: c.maxHp, inabalavelUsed: true),
        died: false,
        revived: true,
        revivedBy: AbilityKeyword.inabalavel,
      );
    }
    // Ressurreição: revive com PV REDUZIDO (1×). Cede vez à Inabalável acima.
    if (c.hasKeyword(AbilityKeyword.ressurreicao) && !c.ressureicaoUsed) {
      final hp = (c.maxHp * kRessurreicaoPercent).floor().clamp(1, c.maxHp);
      return (
        creature: c.copyWith(currentHp: hp, ressureicaoUsed: true),
        died: false,
        revived: true,
        revivedBy: AbilityKeyword.ressurreicao,
      );
    }
    return (creature: null, died: true, revived: false, revivedBy: null);
  }

  /// Transformar: ao cair a ≤ `kTransformarTrigger` do PV máximo (e viva, não
  /// transformada), ativa a 2ª forma — bônus permanente de ataque + PV máximo,
  /// curando ao novo máximo. 1×. Aplicada onde a criatura toma dano e sobrevive.
  CreatureInPlay _maybeTransform(
      CreatureInPlay c, SideId side, List<MatchEvent> events) {
    if (!c.isAlive ||
        c.transformed ||
        !c.hasKeyword(AbilityKeyword.transformar)) {
      return c;
    }
    if (c.currentHp > (c.maxHp * kTransformarTrigger)) return c;
    var nc = c.copyWith(
      permanentAtkBonus: c.permanentAtkBonus + kTransformarAtkBonus,
      bonusMaxHp: c.bonusMaxHp + kTransformarHpBonus,
      transformed: true,
    );
    nc = nc.copyWith(currentHp: nc.maxHp); // cura ao novo máximo
    events.add(AbilityTriggered(
      side: side,
      cardId: c.instanceId,
      cardName: c.card.nome,
      ability: abilityKeywordLabel(AbilityKeyword.transformar),
      detail: 'ativou a 2ª forma (+$kTransformarAtkBonus ataque, '
          '+$kTransformarHpBonus PV máximo)',
    ));
    return nc;
  }

  /// Carta Zumbi: ao morrer, devolve a CARTA enfraquecida (−`kZumbiAtkPenalty`
  /// atk / −`kZumbiHpPenalty` PV) e SEM a keyword Zumbi (1×). null se [c] não é
  /// Zumbi. (Relíquias são descartadas — a carta volta "nua".)
  CreatureCard? _zombieCard(CreatureInPlay c) {
    if (!c.hasKeyword(AbilityKeyword.zumbi)) return null;
    final base = c.card;
    final atk = (base.atk - kZumbiAtkPenalty).clamp(0, base.atk);
    final hp = (base.hp - kZumbiHpPenalty).clamp(1, base.hp);
    final abilities = base.abilities
        .where((a) => abilityKeywordFromString(a) != AbilityKeyword.zumbi)
        .toList(growable: false);
    return base.copyWith(atk: atk, hp: hp, abilities: abilities);
  }

  /// Adiciona uma carta à MÃO do lado (ou ao topo do deck se a mão está cheia),
  /// narrando o retorno do Zumbi.
  BoardSide _addZombieToHand(
      BoardSide side, CreatureCard card, List<MatchEvent> events) {
    events.add(AbilityTriggered(
      side: side.id,
      cardId: card.id,
      cardName: card.nome,
      ability: abilityKeywordLabel(AbilityKeyword.zumbi),
      detail: 'voltou pra mão enfraquecida',
    ));
    if (side.hand.length < kHandSize) {
      return side.copyWith(hand: List<Object>.from(side.hand)..add(card));
    }
    return side.copyWith(deck: List<Object>.from(side.deck)..insert(0, card));
  }

  (BoardSide, BoardSide) _resolveAttack(
    MatchState s,
    BoardSide atkSide,
    BoardSide defSide,
    int attackerLaneIdx,
    DamageType type,
    int value, {
    required bool meleeFromFront,
    required List<MatchEvent> events,
  }) {
    var attacker = atkSide.lanes[attackerLaneIdx]!;

    final targetId = _selectTarget(attacker, defSide, type);
    if (targetId == null) return (atkSide, defSide);

    final defLanes = List<CreatureInPlay?>.from(defSide.lanes);
    final targetLaneIdx =
        defLanes.indexWhere((c) => c != null && c.instanceId == targetId);
    if (targetLaneIdx < 0) return (atkSide, defSide);
    final target = defLanes[targetLaneIdx]!;

    // ---- Voo: evasão do ataque principal ----
    if (_rollEvade(s, attacker, target, type)) {
      events.add(AttackEvaded(
        attackerSide: atkSide.id,
        attackerCardId: attacker.instanceId,
        attackerName: attacker.card.nome,
        targetCardId: target.instanceId,
        targetName: target.card.nome,
      ));
      return (atkSide, defSide); // dano 0, nenhum proc on-hit.
    }

    var pendingGain = 0;
    var anyDeath = false;

    // ---- Reflexo Mágico: ao ser atingida por MÁGICO, IGNORA o dano e devolve-o
    // ao atacante (100%). (Suprimido por Doença via functionalKeyword.) ----
    final magicReflected = type == DamageType.magico &&
        target.functionalKeyword(AbilityKeyword.reflexoMagico);

    // ---- Dano principal ---- (valor deste ataque específico — multi-ataque)
    final raw = value;
    var damage = raw;
    final physical =
        type == DamageType.corpoACorpo || type == DamageType.aDistancia;
    if (physical) {
      damage = damage - target.armor; // Escudo / Escudo Sagrado
    } else if (type == DamageType.magico) {
      damage = damage - target.magicArmor; // Escudo Espelhado / Escudo Sagrado
    }
    if (damage < 0) damage = 0;
    if (magicReflected) damage = 0; // o alvo IGNORA o dano (reflete abaixo).
    final hpBefore = target.currentHp;
    // Inabalável: se morreria, ressuscita com vida cheia (1×/partida).
    final lethalT = _resolveLethal(target, hpBefore - damage);
    final died = lethalT.died;
    defLanes[targetLaneIdx] = lethalT.creature;
    if (lethalT.revived) {
      events.add(AbilityTriggered(
        side: defSide.id,
        cardId: target.instanceId,
        cardName: target.card.nome,
        ability: abilityKeywordLabel(lethalT.revivedBy!),
        detail: lethalT.revivedBy == AbilityKeyword.inabalavel
            ? 'resistiu à destruição e voltou com vida cheia'
            : 'ressuscitou com PV reduzido',
      ));
    }
    if (died) anyDeath = true;

    events.add(AttackResolved(
      attackerSide: atkSide.id,
      attackerCardId: attacker.instanceId,
      attackerName: attacker.card.nome,
      targetCardId: target.instanceId,
      targetName: target.card.nome,
      damageType: type,
      rawDamage: raw,
      damageDealt: damage,
      targetHpAfter: lethalT.creature?.currentHp ?? 0,
      targetDied: died,
    ));

    // ---- Lote 3a: status aplicados pelo ATACANTE ao acertar (alvo vivo) ----
    // Ataque mágico REFLETIDO não "acerta" — pula os procs on-hit do atacante.
    final survivor = defLanes[targetLaneIdx];
    if (survivor != null && !magicReflected) {
      var t = survivor;
      // Sangramento: só dano físico; +1 acúmulo e reseta a duração.
      if (physical && attacker.hasKeyword(AbilityKeyword.sangramento)) {
        t = t.copyWith(
          bleedStacks: t.bleedStacks + 1,
          bleedTurns: kSangramentoTurns,
        );
        events.add(AbilityTriggered(
          side: atkSide.id,
          cardId: attacker.instanceId,
          cardName: attacker.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.sangramento),
          detail: '${t.bleedStacks} acúmulo(s) em ${t.card.nome}',
        ));
      }
      // Veneno: qualquer acerto; aplica se ainda não envenenada.
      if (attacker.hasKeyword(AbilityKeyword.veneno) && !t.poisoned) {
        t = t.copyWith(poisoned: true);
        events.add(AbilityTriggered(
          side: atkSide.id,
          cardId: attacker.instanceId,
          cardName: attacker.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.veneno),
          detail: 'envenenou ${t.card.nome}',
        ));
      }
      // Atordoar: só melee, 100% ao acertar, respeitando o cooldown da atacante.
      if (type == DamageType.corpoACorpo &&
          attacker.hasKeyword(AbilityKeyword.atordoar) &&
          attacker.atordoarCooldown == 0 &&
          !t.stunned) {
        t = t.copyWith(stunned: true);
        // +1: o decremento do início do próximo turno do dono ainda bloqueia
        // aquela Fase de Ataque (net: pula `kAtordoarCooldownTurns` turno).
        attacker =
            attacker.copyWith(atordoarCooldown: kAtordoarCooldownTurns + 1);
        events.add(AbilityTriggered(
          side: atkSide.id,
          cardId: attacker.instanceId,
          cardName: attacker.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.atordoar),
          detail: 'atordoou ${t.card.nome}',
        ));
      }
      // Enredar: só alvo com Voo; chance; remove o Voo e prende.
      if (attacker.hasKeyword(AbilityKeyword.enredar) &&
          t.canFly &&
          !t.entangled &&
          s.rng.nextDouble() < kEnredarChance) {
        t = t.copyWith(entangled: true);
        events.add(AbilityTriggered(
          side: atkSide.id,
          cardId: attacker.instanceId,
          cardName: attacker.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.enredar),
          detail: 'enredou ${t.card.nome} (perdeu Voo, pula o próximo ataque)',
        ));
      }

      // ---- Doença / Surto (Lote 3b): só em dano físico/verdadeiro ----
      final physicalOrTrue = physical || type == DamageType.vitalismo;
      if (physicalOrTrue) {
        // Surto detona a Doença EXISTENTE antes de aplicar uma nova: remove a
        // Doença e reduz o PV MÁXIMO (permanente) por acúmulo.
        if (attacker.hasKeyword(AbilityKeyword.surto) && t.diseaseStacks > 0) {
          final reduce = t.diseaseStacks * kSurtoMaxHpPerStack;
          var nt = t.copyWith(
            diseaseStacks: 0,
            bonusMaxHp: t.bonusMaxHp - reduce,
          );
          if (nt.currentHp > nt.maxHp) nt = nt.copyWith(currentHp: nt.maxHp);
          final surtoKilled = !nt.isAlive;
          events.add(AbilityTriggered(
            side: atkSide.id,
            cardId: attacker.instanceId,
            cardName: attacker.card.nome,
            ability: abilityKeywordLabel(AbilityKeyword.surto),
            detail: '-$reduce de PV máximo em ${nt.card.nome}'
                '${surtoKilled ? ' (destruída)' : ''}',
          ));
          t = nt;
          if (surtoKilled) anyDeath = true;
        }
        // Doença: aplica/empilha se o alvo ainda está vivo.
        if (t.isAlive && attacker.hasKeyword(AbilityKeyword.doenca)) {
          t = t.copyWith(diseaseStacks: t.diseaseStacks + 1);
          events.add(AbilityTriggered(
            side: atkSide.id,
            cardId: attacker.instanceId,
            cardName: attacker.card.nome,
            ability: abilityKeywordLabel(AbilityKeyword.doenca),
            detail: '${t.diseaseStacks} acúmulo(s) de Doença em ${t.card.nome}',
          ));
        }
      }

      // ---- Transformar (Lote 5): caiu a ≤ limiar → ativa a 2ª forma ----
      t = _maybeTransform(t, defSide.id, events);

      if (!identical(t, survivor)) {
        defLanes[targetLaneIdx] = t.isAlive ? t : null;
      }
    }

    // ---- Roubo de PV: ao ACERTAR (dano > 0), +PV atual e máx ----
    if (damage > 0 && attacker.hasKeyword(AbilityKeyword.rouboDePv)) {
      attacker = attacker.copyWith(
        bonusMaxHp: attacker.bonusMaxHp + kRouboDePvAmount,
        currentHp: attacker.currentHp + kRouboDePvAmount,
      );
      events.add(AbilityTriggered(
        side: atkSide.id,
        cardId: attacker.instanceId,
        cardName: attacker.card.nome,
        ability: abilityKeywordLabel(AbilityKeyword.rouboDePv),
        detail: '+$kRouboDePvAmount PV atual e máximo',
      ));
    }

    void gainDrainCrystal(String victimName) {
      pendingGain += kCristalDeDrenagemCrystals;
      events.add(AbilityTriggered(
        side: atkSide.id,
        cardId: attacker.instanceId,
        cardName: attacker.card.nome,
        ability: abilityKeywordLabel(AbilityKeyword.cristalDeDrenagem),
        detail: 'destruiu $victimName: +$kCristalDeDrenagemCrystals cristal '
            'no início do próximo turno',
      ));
    }

    // Carta Zumbi: se o alvo principal morreu, volta enfraquecido pra mão dele.
    final mainZombie = died ? _zombieCard(target) : null;

    if (died) {
      // Cristal de Drenagem: destruiu com seu ataque (vale também para as
      // mortes por Pisotear/Ataque Duplo abaixo — regra uniforme documentada).
      if (attacker.hasKeyword(AbilityKeyword.cristalDeDrenagem)) {
        gainDrainCrystal(target.card.nome);
      }

      // Andorinha: ao destruir uma criatura, ganho PERMANENTE (todos os ataques
      // + PV máximo).
      if (attacker.hasKeyword(AbilityKeyword.andorinha)) {
        attacker = attacker.copyWith(
          permanentAtkBonus: attacker.permanentAtkBonus + kAndorinhaGain,
          bonusMaxHp: attacker.bonusMaxHp + kAndorinhaGain,
          currentHp: attacker.currentHp + kAndorinhaGain,
        );
        events.add(AbilityTriggered(
          side: atkSide.id,
          cardId: attacker.instanceId,
          cardName: attacker.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.andorinha),
          detail: '+$kAndorinhaGain permanente em ataque e PV máximo',
        ));
      }

      // ---- Pisotear: dano FÍSICO excedente transborda para a próxima
      // criatura inimiga na ordem de lanes (1 transbordo, não encadeia) ----
      final overflow = damage - hpBefore;
      if (physical &&
          overflow > 0 &&
          attacker.hasKeyword(AbilityKeyword.pisotear)) {
        var nextIdx = -1;
        for (var i = targetLaneIdx + 1; i < defLanes.length; i++) {
          final c = defLanes[i];
          if (c != null && c.isAlive) {
            nextIdx = i;
            break;
          }
        }
        if (nextIdx >= 0) {
          final next = defLanes[nextIdx]!;
          // Transbordo é dano físico: armadura do novo alvo reduz.
          // Sem evasão de Voo no transbordo (não é um "ataque" mirado).
          var spill = overflow - next.armor;
          if (spill < 0) spill = 0;
          final lethalN = _resolveLethal(next, next.currentHp - spill);
          final nextDied = lethalN.died;
          defLanes[nextIdx] = lethalN.creature;
          if (nextDied) anyDeath = true;
          events.add(AbilityTriggered(
            side: atkSide.id,
            cardId: attacker.instanceId,
            cardName: attacker.card.nome,
            ability: abilityKeywordLabel(AbilityKeyword.pisotear),
            detail: 'transbordou $spill de dano em ${next.card.nome}'
                '${nextDied ? ' (destruída)' : ''}',
          ));
          if (nextDied &&
              attacker.hasKeyword(AbilityKeyword.cristalDeDrenagem)) {
            gainDrainCrystal(next.card.nome);
          }
        }
      }
    }

    // ---- Ataque Duplo: melee DA FRENTE que acerta (não evadido) causa dano
    // VERDADEIRO extra (= atk efetivo) a um inimigo ALEATÓRIO da retaguarda ----
    if (meleeFromFront && attacker.hasKeyword(AbilityKeyword.ataqueDuplo)) {
      // Retaguarda inimiga ATUAL (pós-dano principal): lanes vivas atrás da
      // menor lane ocupada.
      final occupied = <int>[];
      for (var i = 0; i < defLanes.length; i++) {
        final c = defLanes[i];
        if (c != null && c.isAlive) occupied.add(i);
      }
      if (occupied.length > 1) {
        final backline = occupied.sublist(1); // tudo atrás da frente.
        final pickIdx = backline[s.rng.nextInt(backline.length)];
        final extraTarget = defLanes[pickIdx]!;
        // O hit extra é melee para fins de Voo (50%).
        if (_rollEvade(s, attacker, extraTarget, DamageType.corpoACorpo)) {
          events.add(AttackEvaded(
            attackerSide: atkSide.id,
            attackerCardId: attacker.instanceId,
            attackerName: attacker.card.nome,
            targetCardId: extraTarget.instanceId,
            targetName: extraTarget.card.nome,
          ));
        } else {
          // Dano verdadeiro: ignora armadura. Extra = valor DESTE ataque melee
          // (multi-ataque: o ataque que disparou o Ataque Duplo).
          final extraDmg = value;
          final lethalE = _resolveLethal(extraTarget, extraTarget.currentHp - extraDmg);
          final extraDied = lethalE.died;
          defLanes[pickIdx] = lethalE.creature;
          if (extraDied) anyDeath = true;
          events.add(AbilityTriggered(
            side: atkSide.id,
            cardId: attacker.instanceId,
            cardName: attacker.card.nome,
            ability: abilityKeywordLabel(AbilityKeyword.ataqueDuplo),
            detail: '$extraDmg de dano verdadeiro em '
                '${extraTarget.card.nome}${extraDied ? ' (destruída)' : ''}',
          ));
          if (extraDied &&
              attacker.hasKeyword(AbilityKeyword.cristalDeDrenagem)) {
            gainDrainCrystal(extraTarget.card.nome);
          }
        }
      }
    }

    // ---- Retaliação do alvo melee: Espinhos + Contra-Ataque ----
    // Disparam quando o alvo foi atingido por melee (não evadido). Espinhos
    // dispara mesmo se o alvo morreu (você se espeta ao acertá-lo); Contra-
    // Ataque só se o alvo SOBREVIVEU (precisa estar vivo pra revidar).
    var attackerDied = false;
    if (type == DamageType.corpoACorpo) {
      final targetAlive = defLanes[targetLaneIdx] != null;

      if (target.hasKeyword(AbilityKeyword.espinhos)) {
        final res = _resolveLethal(attacker, attacker.currentHp - kEspinhosDamage);
        events.add(AbilityTriggered(
          side: defSide.id,
          cardId: target.instanceId,
          cardName: target.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.espinhos),
          detail: '$kEspinhosDamage de dano verdadeiro em '
              '${attacker.card.nome}${res.died ? ' (destruída)' : ''}',
        ));
        if (res.died) {
          attackerDied = true;
        } else {
          attacker = res.creature!;
        }
      }

      if (!attackerDied &&
          targetAlive &&
          target.hasKeyword(AbilityKeyword.contraAtaque) &&
          s.rng.nextDouble() < kContraAtaqueChance) {
        var cdmg = target.atk - attacker.armor; // contra-ataque melee → armadura reduz
        if (cdmg < 0) cdmg = 0;
        final res = _resolveLethal(attacker, attacker.currentHp - cdmg);
        events.add(AbilityTriggered(
          side: defSide.id,
          cardId: target.instanceId,
          cardName: target.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.contraAtaque),
          detail: 'contra-atacou ${attacker.card.nome} '
              '($cdmg de dano)${res.died ? ' (destruída)' : ''}',
        ));
        if (res.died) {
          attackerDied = true;
        } else {
          attacker = res.creature!;
        }
      }
    }

    // ---- Reflexo Mágico: devolve o dano mágico ao atacante. Se o ATACANTE
    // também reflete, vira LOOP (quica entre os dois, +kReflexoLoopGain/loop);
    // após kReflexoLoopLimit loops é lançado ALEATORIAMENTE num dos dois. ----
    if (magicReflected && !attackerDied) {
      final attackerReflects =
          attacker.functionalKeyword(AbilityKeyword.reflexoMagico);
      if (!attackerReflects) {
        // Caso simples: o atacante toma o dano refletido (raw).
        final res = _resolveLethal(attacker, attacker.currentHp - raw);
        events.add(AbilityTriggered(
          side: defSide.id,
          cardId: target.instanceId,
          cardName: target.card.nome,
          ability: abilityKeywordLabel(AbilityKeyword.reflexoMagico),
          detail: 'refletiu $raw de dano mágico em '
              '${attacker.card.nome}${res.died ? ' (destruída)' : ''}',
        ));
        if (res.died) {
          attackerDied = true;
        } else {
          attacker = res.creature!;
        }
      } else {
        // LOOP: os dois refletem. +1/loop até o limite; depois, aleatório.
        final loopDmg = raw + (kReflexoLoopLimit - 1) * kReflexoLoopGain;
        final hitAttacker = s.rng.nextBool();
        if (hitAttacker) {
          final res = _resolveLethal(attacker, attacker.currentHp - loopDmg);
          events.add(AbilityTriggered(
            side: defSide.id,
            cardId: target.instanceId,
            cardName: target.card.nome,
            ability: abilityKeywordLabel(AbilityKeyword.reflexoMagico),
            detail: 'loop de reflexo ($kReflexoLoopLimit loops): $loopDmg em '
                '${attacker.card.nome}${res.died ? ' (destruída)' : ''}',
          ));
          if (res.died) {
            attackerDied = true;
          } else {
            attacker = res.creature!;
          }
        } else {
          // o ALVO (o outro refletor) toma o dano acumulado.
          final tgt = defLanes[targetLaneIdx];
          if (tgt != null) {
            final res = _resolveLethal(tgt, tgt.currentHp - loopDmg);
            defLanes[targetLaneIdx] = res.creature;
            if (res.died) anyDeath = true;
            events.add(AbilityTriggered(
              side: defSide.id,
              cardId: target.instanceId,
              cardName: target.card.nome,
              ability: abilityKeywordLabel(AbilityKeyword.reflexoMagico),
              detail: 'loop de reflexo ($kReflexoLoopLimit loops): $loopDmg em '
                  '${tgt.card.nome}${res.died ? ' (destruída)' : ''}',
            ));
          }
        }
      }
    }

    // ---- Consolida lados ----
    final atkLanes = List<CreatureInPlay?>.from(atkSide.lanes);
    atkLanes[attackerLaneIdx] = attackerDied ? null : attacker;
    var newAtkSide = atkSide.copyWith(
      lanes: atkLanes,
      pendingCrystals: atkSide.pendingCrystals + pendingGain,
    );
    // Carta Zumbi: atacante morto por retaliação (Espinhos/Contra-Ataque) volta
    // enfraquecido pra mão do dono.
    if (attackerDied) {
      final z = _zombieCard(attacker);
      if (z != null) newAtkSide = _addZombieToHand(newAtkSide, z, events);
      newAtkSide = _advanceLanes(newAtkSide);
    }

    var newDefSide = defSide.copyWith(lanes: defLanes);
    if (mainZombie != null) {
      newDefSide = _addZombieToHand(newDefSide, mainZombie, events);
    }
    if (anyDeath) newDefSide = _advanceLanes(newDefSide);

    return (newAtkSide, newDefSide);
  }

  /// Voo: o alvo evade se tiver Voo e o atacante NÃO tiver — 🎚️ 50% vs melee
  /// (incl. hit extra de Ataque Duplo), 🎚️ 25% vs à distância. Mágico e
  /// vitalismo não são evadidos. Consome o rng do MatchState (determinístico
  /// por seed).
  bool _rollEvade(MatchState s, CreatureInPlay attacker, CreatureInPlay target,
      DamageType type) {
    if (!target.canFly) return false; // sem Voo ou enredada (Voo removido).
    if (attacker.hasKeyword(AbilityKeyword.voo)) return false;
    final double chance;
    switch (type) {
      case DamageType.corpoACorpo:
        chance = kVooMeleeEvadeChance;
      case DamageType.aDistancia:
        chance = kVooRangedEvadeChance;
      case DamageType.magico:
      case DamageType.vitalismo:
      case DamageType.cura:
        return false;
    }
    if (chance <= 0) return false;
    return s.rng.nextDouble() < chance;
  }

  /// Seleciona o alvo no lado [defender] conforme o padrão posicional do tipo
  /// (🎚️ `kMeleeTargeting`/`kRangedTargeting`/`kMagicoTargeting`/
  /// `kVitalismoTargeting`) e os modificadores, NESTA ordem:
  /// 1. Provocar — ataques `aDistancia`/`magico` são redirecionados para o
  ///    provocador vivo de menor lane (melee/vitalismo não mudam);
  /// 2. Furtividade — criatura na retaguarda com Furtividade não pode ser
  ///    alvo de `aDistancia`/`magico`: pula para a próxima opção válida;
  ///    se todas inválidas, mira a frente (Furtividade não protege a frente).
  String? _selectTarget(
      CreatureInPlay attacker, BoardSide defender, DamageType type) {
    final alive = defender.creaturesInPlay; // ordenada por lane.
    if (alive.isEmpty) return null;
    final frontLane = alive.first.lane;

    final TargetPattern pattern;
    switch (type) {
      case DamageType.corpoACorpo:
        pattern = kMeleeTargeting;
      case DamageType.aDistancia:
        pattern = kRangedTargeting;
      case DamageType.magico:
        pattern = kMagicoTargeting;
      case DamageType.vitalismo:
        pattern = kVitalismoTargeting;
      case DamageType.cura:
        return null;
    }

    final candidates = _candidatesFor(pattern, attacker, defender, alive);

    // Provocar/Furtividade só modificam aDistancia e magico.
    final redirectable =
        type == DamageType.aDistancia || type == DamageType.magico;
    if (!redirectable) return candidates.first.instanceId;

    bool hidden(CreatureInPlay c) =>
        c.lane != frontLane && c.hasKeyword(AbilityKeyword.furtividade);

    // 1) Provocar (o de menor lane se vários). Se o provocador estiver
    // furtivo na retaguarda, o redirecionamento falha e cai no padrão.
    final taunter =
        alive.where((c) => c.hasKeyword(AbilityKeyword.provocar)).firstOrNull;
    if (taunter != null && !hidden(taunter)) return taunter.instanceId;

    // 2) Furtividade: pula candidatos furtivos na retaguarda.
    for (final c in candidates) {
      if (!hidden(c)) return c.instanceId;
    }
    // Todos inválidos → mira a frente (nunca protegida por Furtividade).
    return alive.first.instanceId;
  }

  /// Lista ordenada de candidatos do padrão [pattern] (sem modificadores).
  List<CreatureInPlay> _candidatesFor(TargetPattern pattern,
      CreatureInPlay attacker, BoardSide defender, List<CreatureInPlay> alive) {
    switch (pattern) {
      case TargetPattern.front:
        return alive; // já em ordem de lane: frente primeiro.
      case TargetPattern.oppositeThenFront:
        final result = <CreatureInPlay>[];
        if (attacker.lane >= 0 && attacker.lane < defender.lanes.length) {
          final opp = defender.lanes[attacker.lane];
          if (opp != null && opp.isAlive) result.add(opp);
        }
        for (final c in alive) {
          if (!result.any((x) => x.instanceId == c.instanceId)) result.add(c);
        }
        return result;
      case TargetPattern.lowestHp:
        final sorted = List<CreatureInPlay>.from(alive)
          ..sort((a, b) {
            final d = a.currentHp.compareTo(b.currentHp);
            return d != 0 ? d : a.lane.compareTo(b.lane);
          });
        return sorted;
    }
  }

  /// Cura: alvo = própria criatura mais ferida (não cura acima do hp máx).
  /// Emite `HealResolved` em [events] apenas se curou de fato (>0).
  BoardSide _resolveHeal(
      BoardSide side, CreatureInPlay healer, List<MatchEvent> events) {
    CreatureInPlay? target;
    var bestMissing = 0;
    for (final c in side.creaturesInPlay) {
      final missing = c.maxHp - c.currentHp;
      if (missing > bestMissing) {
        bestMissing = missing;
        target = c;
      }
    }
    if (target == null || bestMissing == 0) return side;

    final laneIdx =
        side.lanes.indexWhere((c) => c != null && c.instanceId == target!.instanceId);
    if (laneIdx < 0) return side;

    final healed = (target.currentHp + healer.atk).clamp(0, target.maxHp);
    final amount = healed - target.currentHp;
    if (amount <= 0) return side; // atk 0 / sem efeito: nem muda, nem narra.

    events.add(HealResolved(
      side: side.id,
      healerCardId: healer.instanceId,
      healerName: healer.card.nome,
      targetCardId: target.instanceId,
      targetName: target.card.nome,
      amount: amount,
    ));

    // Cura LIMPA DoT (Sangramento, Veneno) e Doença do alvo (regra do CEO).
    final cleansed = target.hasDot || target.diseaseStacks > 0;
    if (cleansed) {
      events.add(AbilityTriggered(
        side: side.id,
        cardId: healer.instanceId,
        cardName: healer.card.nome,
        ability: 'Cura',
        detail: 'limpou os efeitos de ${target.card.nome}',
      ));
    }

    var healedC = target.copyWith(
      currentHp: healed,
      bleedStacks: 0,
      bleedTurns: 0,
      poisoned: false,
      diseaseStacks: 0,
    );

    // Crescimento (Lote 5): após ser CURADA, ganho PERMANENTE (todos os ataques
    // + PV máximo).
    if (healedC.hasKeyword(AbilityKeyword.crescimento)) {
      healedC = healedC.copyWith(
        permanentAtkBonus: healedC.permanentAtkBonus + kCrescimentoGain,
        bonusMaxHp: healedC.bonusMaxHp + kCrescimentoGain,
        currentHp: healedC.currentHp + kCrescimentoGain,
      );
      events.add(AbilityTriggered(
        side: side.id,
        cardId: target.instanceId,
        cardName: target.card.nome,
        ability: abilityKeywordLabel(AbilityKeyword.crescimento),
        detail: '+$kCrescimentoGain permanente em ataque e PV máximo',
      ));
    }

    final newLanes = List<CreatureInPlay?>.from(side.lanes);
    newLanes[laneIdx] = healedC;
    return side.copyWith(lanes: newLanes);
  }

  /// Ao morrer a da frente, as de trás avançam (3→2→1, índices 2→1→0).
  /// Compacta as criaturas vivas para as lanes da frente preservando ordem.
  BoardSide _advanceLanes(BoardSide side) {
    final alive = <CreatureInPlay>[];
    for (final c in side.lanes) {
      if (c != null && c.isAlive) alive.add(c);
    }
    alive.sort((a, b) => a.lane.compareTo(b.lane));

    final newLanes = List<CreatureInPlay?>.filled(kLaneCount, null);
    for (var i = 0; i < alive.length && i < kLaneCount; i++) {
      newLanes[i] = alive[i].copyWith(lane: i);
    }
    return side.copyWith(lanes: newLanes);
  }

  /// Penalidade: se o lado ATIVO terminou o turno sem criaturas em jogo, perde
  /// `kNoCreaturePenaltyCards` carta(s) aleatória(s) do conjunto mão+deck (rng).
  /// Emite `NoCreaturePenaltyApplied` em [events] por carta perdida.
  MatchState _applyNoCreaturePenalty(MatchState s, List<MatchEvent> events) {
    final side = s.active;
    if (side.hasCreatureInPlay) return s;

    final hand = List<Object>.from(side.hand);
    final deck = List<Object>.from(side.deck);

    for (var i = 0; i < kNoCreaturePenaltyCards; i++) {
      final total = hand.length + deck.length;
      if (total == 0) break;
      final pick = s.rng.nextInt(total);
      final Object lost =
          pick < hand.length ? hand.removeAt(pick) : deck.removeAt(pick - hand.length);
      events.add(NoCreaturePenaltyApplied(
        side: side.id,
        lostCardId: cardId(lost),
        lostCardName:
            lost is CreatureCard ? lost.nome : (lost as RelicCard).nome,
        wasCreature: lost is CreatureCard,
      ));
    }

    var newSide = side.copyWith(hand: hand, deck: deck);
    newSide = _refillHand(newSide); // se perdeu da mão, repõe do deck
    return s.withSide(side.id, newSide);
  }

  // ---------------------------------------------------------------------------
  // Vitória / Stall
  // ---------------------------------------------------------------------------

  /// Lado que fica sem nenhuma das 9 criaturas (em jogo E no pool) perde.
  /// Retorna o VENCEDOR, ou null se ninguém perdeu ainda.
  SideId? _checkVictory(MatchState s) {
    final aOut = s.sideA.remainingCreatureCount == 0;
    final bOut = s.sideB.remainingCreatureCount == 0;
    if (aOut && bOut) {
      // Sem empate: critério de stall decide.
      return _stallWinner(s);
    }
    if (aOut) return SideId.b;
    if (bOut) return SideId.a;
    return null;
  }

  /// Trava do turno 40: encerra. Desempate MVP: mais criaturas vivas; se igual,
  /// mais HP total em jogo; se ainda igual, quem começou (sideA) — sem empate.
  /// Emite `StallLimitReached` em [events].
  MatchState _resolveStall(MatchState s, List<MatchEvent> events) {
    final winner = _stallWinner(s);
    events.add(StallLimitReached(winner: winner));
    return s.copyWith(
      phase: MatchPhase.fim,
      winner: winner,
      lastTurnEvents: List.unmodifiable(events),
    );
  }

  SideId _stallWinner(MatchState s) {
    final aAlive = s.sideA.creaturesInPlay.length;
    final bAlive = s.sideB.creaturesInPlay.length;
    if (aAlive != bAlive) return aAlive > bAlive ? SideId.a : SideId.b;

    final aHp = s.sideA.totalHpInPlay;
    final bHp = s.sideB.totalHpInPlay;
    if (aHp != bHp) return aHp > bHp ? SideId.a : SideId.b;

    // Último critério (sem empate): sideA.
    return SideId.a;
  }

  // ---------------------------------------------------------------------------
  // Bot (IA gulosa determinística)
  // ---------------------------------------------------------------------------

  /// Gera a sequência de ações da Fase de Jogo para o lado ATIVO.
  /// Heurística gulosa, determinística (não usa rng; depende só do estado).
  /// A última ação é sempre `Pass`.
  List<GameAction> botActions(MatchState s) {
    final actions = <GameAction>[];
    if (s.isOver || s.phase != MatchPhase.jogo) {
      return const [Pass()];
    }

    // Simula localmente para encadear decisões coerentes.
    var sim = s;
    final engine = this;

    // 1. Preenche lanes vazias jogando criaturas que cabem, POSICIONANDO por
    // tipo: melee busca a frente (lane vazia de menor índice); ranged a
    // retaguarda (maior índice); mágico/cura/vitalismo preferem retaguarda.
    // Evita deixar ranged sozinho na frente quando há alternativa.
    var guard = 0;
    while (guard++ < 50) {
      final side = sim.active;
      final freeLane = side.lanes.contains(null);
      if (!freeLane) break;

      // Candidatas na MÃO que cabem nos cristais (maior atk primeiro).
      final affordable = side.handCreatures
          .where((c) => c.cost <= side.crystals)
          .toList()
        ..sort((a, b) => b.atk.compareTo(a.atk));

      if (affordable.isEmpty) {
        // Tenta destravar via sacrifício (1×/turno) se isso permitir jogar.
        if (!side.sacrificedThisTurn) {
          final sac = _pickSacrificeToEnable(side);
          if (sac != null) {
            final act = Sacrifice(sac);
            final after = engine.apply(sim, act);
            if (!identical(after, sim)) {
              actions.add(act);
              sim = after;
              continue;
            }
          }
        }
        break;
      }

      // Tabuleiro vazio: ranged jogada sozinha ocuparia a "frente" (a lane
      // ocupada de menor índice é sempre a frente) e não atacaria — se houver
      // alternativa não-ranged pagável, joga ela primeiro.
      var chosen = affordable.first;
      if (!side.hasCreatureInPlay &&
          chosen.damageType == DamageType.aDistancia) {
        final alternative = affordable
            .where((c) => c.damageType != DamageType.aDistancia)
            .firstOrNull;
        if (alternative != null) chosen = alternative;
      }

      final act = PlayCreature(chosen.id, lane: _botLaneFor(side, chosen));
      final after = engine.apply(sim, act);
      if (identical(after, sim)) break; // segurança contra loop
      actions.add(act);
      sim = after;
    }

    // 2. Equipa relíquias compatíveis na criatura mais forte.
    guard = 0;
    while (guard++ < 50) {
      final side = sim.active;
      final inPlay = side.creaturesInPlay;
      if (inPlay.isEmpty) break;

      // Procura uma relíquia PAGÁVEL (cristais da simulação local) que case
      // com o conceito de alguma criatura — nunca propõe ação inválida.
      PlayRelic? candidate;
      // Criatura mais forte (maior atk) elegível primeiro.
      final ordered = List<CreatureInPlay>.from(inPlay)
        ..sort((a, b) => b.atk.compareTo(a.atk));

      for (final creature in ordered) {
        final relic = side.handRelics
            .where((r) =>
                r.cost <= side.crystals && r.isCompatibleWith(creature.card))
            .firstOrNull;
        if (relic != null) {
          candidate = PlayRelic(relic.id, creature.instanceId);
          break;
        }
      }
      if (candidate == null) break;

      final after = engine.apply(sim, candidate);
      if (identical(after, sim)) break;
      actions.add(candidate);
      sim = after;
    }

    actions.add(const Pass());
    return actions;
  }

  /// Posição (front-packed) que o bot pede para [card]: melee fura na FRENTE
  /// (índice 0, empurrando os demais pra trás); demais (ranged/mágico/cura/
  /// vitalismo) encaixam na RETAGUARDA (logo após a última criatura). A engine
  /// clampa o índice ao tamanho da fila. Retorna null com o tabuleiro cheio
  /// (chamadores só jogam com vaga).
  int? _botLaneFor(BoardSide side, CreatureCard card) {
    final count = side.creaturesInPlay.length;
    if (count >= kLaneCount) return null;
    return card.damageType == DamageType.corpoACorpo ? 0 : count;
  }

  /// Escolhe uma carta do pool para sacrificar visando habilitar uma jogada:
  /// prioriza relíquia sem criatura compatível; senão a criatura mais cara
  /// que não cabe. Retorna null se nada útil.
  String? _pickSacrificeToEnable(BoardSide side) {
    // Relíquia "morta": nenhuma criatura (mão ou jogo) é compatível com ela.
    final creatures = <CreatureCard>[
      ...side.handCreatures,
      for (final c in side.creaturesInPlay) c.card,
    ];
    final deadRelic = side.handRelics
        .where((r) => !creatures.any((c) => r.isCompatibleWith(c)))
        .firstOrNull;
    if (deadRelic != null) return deadRelic.id;

    // Senão, qualquer relíquia (vale +1 cristal).
    if (side.handRelics.isNotEmpty) return side.handRelics.first.id;

    // Senão, a criatura mais cara que não cabe (vale +2 cristais).
    final tooExpensive = side.handCreatures
        .where((c) => c.cost > side.crystals)
        .toList()
      ..sort((a, b) => b.cost.compareTo(a.cost));
    if (tooExpensive.isNotEmpty) return tooExpensive.first.id;

    return null;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
