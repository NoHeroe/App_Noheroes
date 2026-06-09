/// Motor do Card Game "Modo Cartas ACDA". Lógica pura, determinística.
///
/// Contrato em `_ENGINE_SPEC_mvp.md`. Estado imutável (copyWith). Ações
/// inválidas são no-op (nunca lançam exceção que derrube a partida).
library;

import 'dart:math';

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
      sideA: BoardSide.initial(SideId.a, a),
      sideB: BoardSide.initial(SideId.b, b),
      activeSide: starter,
      turn: 1,
      phase: MatchPhase.jogo,
      rng: rng,
    );

    state = _beginTurn(state);
    return state;
  }

  /// Aplica o início do turno do lado ativo: cristais e reset de sacrifício.
  MatchState _beginTurn(MatchState s) {
    final side = s.active;
    final base = kCrystalsCarryOver ? side.crystals : 0;
    final newSide = side.copyWith(
      crystals: base + kCrystalsPerTurn,
      sacrificedThisTurn: false,
    );
    return s.withSide(side.id, newSide).copyWith(phase: MatchPhase.jogo);
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
      case Pass():
        return s; // no-op: fim da sequência é sinalizado via endTurn.
    }
  }

  MatchState _playCreature(MatchState s, PlayCreature a) {
    final side = s.active;
    final idx = side.poolCreatures.indexWhere((c) => c.id == a.cardId);
    if (idx < 0) return s; // não está no pool

    final card = side.poolCreatures[idx];
    if (card.cost > side.crystals) return s; // cristais insuficientes

    final lane = _resolveLane(side, a.lane);
    if (lane < 0) return s; // sem lane livre

    final newLanes = List<CreatureInPlay?>.from(side.lanes);
    newLanes[lane] = CreatureInPlay(
      card: card,
      currentHp: card.hp,
      lane: lane,
    );

    final newPool = List<CreatureCard>.from(side.poolCreatures)..removeAt(idx);

    final newSide = side.copyWith(
      lanes: newLanes,
      poolCreatures: newPool,
      crystals: side.crystals - card.cost,
    );
    return s.withSide(side.id, newSide);
  }

  /// Resolve a lane de posicionamento. Se [requested] for válida e livre, usa.
  /// Senão escolhe a lane livre mais à frente (menor índice). -1 = sem vaga.
  int _resolveLane(BoardSide side, int? requested) {
    if (requested != null) {
      if (requested < 0 || requested >= kLaneCount) return -1;
      return side.lanes[requested] == null ? requested : -1;
    }
    for (var i = 0; i < kLaneCount; i++) {
      if (side.lanes[i] == null) return i;
    }
    return -1;
  }

  MatchState _playRelic(MatchState s, PlayRelic a) {
    final side = s.active;
    final idx = side.poolRelics.indexWhere((r) => r.id == a.cardId);
    if (idx < 0) return s;

    final relic = side.poolRelics[idx];
    if (relic.cost > side.crystals) return s; // cristais insuficientes

    // Encontra a criatura alvo (própria, em jogo).
    final laneIdx =
        side.lanes.indexWhere((c) => c != null && c.instanceId == a.targetCreatureId);
    if (laneIdx < 0) return s;
    final target = side.lanes[laneIdx]!;

    // Compatibilidade: relíquia universal (neutro) OU compartilha ≥1 conceito.
    if (!relic.isCompatibleWith(target.card)) return s;

    final newPool = List<RelicCard>.from(side.poolRelics)..removeAt(idx);

    CreatureInPlay updated;
    if (relic.isFlash) {
      // Uso único: aplica efeito (cura) e descarta — não fica equipada.
      var hp = target.currentHp;
      final heal = relic.grants.heal;
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
      final heal = relic.grants.heal;
      if (heal != null) {
        hp = (hp + heal).clamp(0, target.maxHp);
      }
      updated = target.copyWith(relics: newRelics, currentHp: hp);
    }

    final newLanes = List<CreatureInPlay?>.from(side.lanes);
    newLanes[laneIdx] = updated;

    // Cobra o custo em cristais (vale para equipamento E flash).
    final newSide = side.copyWith(
      lanes: newLanes,
      poolRelics: newPool,
      crystals: side.crystals - relic.cost,
    );
    return s.withSide(side.id, newSide);
  }

  MatchState _sacrifice(MatchState s, Sacrifice a) {
    final side = s.active;
    if (side.sacrificedThisTurn) return s; // máx 1/turno

    // Tenta relíquia no pool.
    final rIdx = side.poolRelics.indexWhere((r) => r.id == a.cardId);
    if (rIdx >= 0) {
      final newPool = List<RelicCard>.from(side.poolRelics)..removeAt(rIdx);
      final newSide = side.copyWith(
        poolRelics: newPool,
        crystals: side.crystals + kSacrificeRelicCrystals,
        sacrificedThisTurn: true,
      );
      return s.withSide(side.id, newSide);
    }

    // Tenta criatura no pool.
    final cIdx = side.poolCreatures.indexWhere((c) => c.id == a.cardId);
    if (cIdx >= 0) {
      final newPool = List<CreatureCard>.from(side.poolCreatures)..removeAt(cIdx);
      final newSide = side.copyWith(
        poolCreatures: newPool,
        crystals: side.crystals + kSacrificeCreatureCrystals,
        sacrificedThisTurn: true,
      );
      return s.withSide(side.id, newSide);
    }

    return s; // carta não encontrada no pool
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
  MatchState endTurn(MatchState s) {
    if (s.isOver) return s;

    // Log estruturado da resolução deste endTurn.
    final events = <MatchEvent>[];

    // Fase de Ataque automática.
    var state = _resolveAttackPhase(s, events);
    final winAfterAttack = _checkVictory(state);
    if (winAfterAttack != null) {
      return state.copyWith(
        phase: MatchPhase.fim,
        winner: winAfterAttack,
        lastTurnEvents: List.unmodifiable(events),
      );
    }

    // Penalidade: terminar o turno sem criaturas no tabuleiro.
    state = _applyNoCreaturePenalty(state, events);
    final winAfterPenalty = _checkVictory(state);
    if (winAfterPenalty != null) {
      return state.copyWith(
        phase: MatchPhase.fim,
        winner: winAfterPenalty,
        lastTurnEvents: List.unmodifiable(events),
      );
    }

    // Trava anti-stall.
    if (state.turn >= kStallTurnLimit) {
      return _resolveStall(state, events);
    }

    // Passa o turno para o oponente e inicia o turno dele.
    final next = state.activeSide == SideId.a ? SideId.b : SideId.a;
    state = state.copyWith(activeSide: next, turn: state.turn + 1);
    state = _beginTurn(state);
    return state.copyWith(lastTurnEvents: List.unmodifiable(events));
  }

  /// Resolve a Fase de Ataque do lado ativo contra o oponente.
  /// Acumula em [events] um evento por ataque/cura efetivamente resolvido.
  MatchState _resolveAttackPhase(MatchState s, List<MatchEvent> events) {
    var attacker = s.active;
    var defender = s.opponent;

    // Ordem de lane (frente→retaguarda), fixada no início da fase.
    final order = attacker.creaturesInPlay.map((c) => c.instanceId).toList();

    for (final attackerId in order) {
      // Sem alvos → fase termina (já é vitória de fato).
      if (!defender.hasCreatureInPlay) break;

      // Releitura do atacante (pode ter mudado / morrido por cura alheia, não no MVP).
      final attackerLaneIdx = attacker.lanes
          .indexWhere((c) => c != null && c.instanceId == attackerId);
      if (attackerLaneIdx < 0) continue;
      final creature = attacker.lanes[attackerLaneIdx]!;
      if (!creature.isAlive) continue;

      final type = creature.effectiveDamageType;

      if (type == DamageType.cura) {
        attacker = _resolveHeal(attacker, creature, events);
        continue;
      }

      final targetId = _selectTarget(defender, type);
      if (targetId == null) continue;

      defender = _applyDamage(defender, targetId, creature, type, events);
    }

    var state = s.withSide(attacker.id, attacker);
    state = state.withSide(defender.id, defender);
    return state;
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

    final newLanes = List<CreatureInPlay?>.from(side.lanes);
    newLanes[laneIdx] = target.copyWith(currentHp: healed);
    return side.copyWith(lanes: newLanes);
  }

  /// Seleciona o alvo no lado [defender] conforme o padrão posicional do tipo.
  String? _selectTarget(BoardSide defender, DamageType type) {
    final inPlay = defender.creaturesInPlay;
    if (inPlay.isEmpty) return null;

    switch (type) {
      case DamageType.corpoACorpo:
      case DamageType.vitalismo:
        // Frente: menor lane ocupada.
        return inPlay.first.instanceId; // creaturesInPlay já vem ordenada
      case DamageType.aDistancia:
      case DamageType.magico:
        // Menor HP (desempate: menor lane).
        var best = inPlay.first;
        for (final c in inPlay) {
          if (c.currentHp < best.currentHp ||
              (c.currentHp == best.currentHp && c.lane < best.lane)) {
            best = c;
          }
        }
        return best.instanceId;
      case DamageType.cura:
        return null;
    }
  }

  /// Aplica dano a uma criatura do lado [side], respeitando armadura por tipo,
  /// e remove (avança lanes) se morrer. Emite `AttackResolved` em [events].
  BoardSide _applyDamage(BoardSide side, String targetId,
      CreatureInPlay attacker, DamageType type, List<MatchEvent> events) {
    final laneIdx =
        side.lanes.indexWhere((c) => c != null && c.instanceId == targetId);
    if (laneIdx < 0) return side;
    final target = side.lanes[laneIdx]!;

    final rawDamage = attacker.atk;
    var damage = rawDamage;
    final ignoresArmor =
        type == DamageType.magico || type == DamageType.vitalismo;
    if (!ignoresArmor) {
      damage = damage - target.armor;
      if (damage < 0) damage = 0;
    }

    final newHp = target.currentHp - damage;
    final newLanes = List<CreatureInPlay?>.from(side.lanes);
    if (newHp <= 0) {
      newLanes[laneIdx] = null; // morre
    } else {
      newLanes[laneIdx] = target.copyWith(currentHp: newHp);
    }

    // O lado dono do atacante é o oposto do lado defensor [side].
    events.add(AttackResolved(
      attackerSide: side.id == SideId.a ? SideId.b : SideId.a,
      attackerCardId: attacker.instanceId,
      attackerName: attacker.card.nome,
      targetCardId: target.instanceId,
      targetName: target.card.nome,
      damageType: type,
      rawDamage: rawDamage,
      damageDealt: damage,
      targetHpAfter: newHp <= 0 ? 0 : newHp,
      targetDied: newHp <= 0,
    ));

    var newSide = side.copyWith(lanes: newLanes);
    if (newHp <= 0) {
      newSide = _advanceLanes(newSide);
    }
    return newSide;
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
  /// `kNoCreaturePenaltyCards` carta(s) aleatória(s) do pool (rng).
  /// Emite `NoCreaturePenaltyApplied` em [events] por carta perdida.
  MatchState _applyNoCreaturePenalty(MatchState s, List<MatchEvent> events) {
    final side = s.active;
    if (side.hasCreatureInPlay) return s;

    var poolCreatures = List<CreatureCard>.from(side.poolCreatures);
    var poolRelics = List<RelicCard>.from(side.poolRelics);

    for (var i = 0; i < kNoCreaturePenaltyCards; i++) {
      final total = poolCreatures.length + poolRelics.length;
      if (total == 0) break;
      final pick = s.rng.nextInt(total);
      if (pick < poolCreatures.length) {
        final lost = poolCreatures.removeAt(pick);
        events.add(NoCreaturePenaltyApplied(
          side: side.id,
          lostCardId: lost.id,
          lostCardName: lost.nome,
          wasCreature: true,
        ));
      } else {
        final lost = poolRelics.removeAt(pick - poolCreatures.length);
        events.add(NoCreaturePenaltyApplied(
          side: side.id,
          lostCardId: lost.id,
          lostCardName: lost.nome,
          wasCreature: false,
        ));
      }
    }

    final newSide =
        side.copyWith(poolCreatures: poolCreatures, poolRelics: poolRelics);
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

    // 1. Preenche lanes vazias jogando criaturas que cabem (maior atk primeiro).
    var guard = 0;
    while (guard++ < 50) {
      final side = sim.active;
      final freeLane = side.lanes.contains(null);
      if (!freeLane) break;

      // Candidatas que cabem nos cristais.
      final affordable = side.poolCreatures
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

      final chosen = affordable.first;
      final act = PlayCreature(chosen.id);
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
        final relic = side.poolRelics
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

  /// Escolhe uma carta do pool para sacrificar visando habilitar uma jogada:
  /// prioriza relíquia sem criatura compatível; senão a criatura mais cara
  /// que não cabe. Retorna null se nada útil.
  String? _pickSacrificeToEnable(BoardSide side) {
    // Relíquia "morta": nenhuma criatura (pool ou jogo) é compatível com ela.
    final creatures = <CreatureCard>[
      ...side.poolCreatures,
      for (final c in side.creaturesInPlay) c.card,
    ];
    final deadRelic = side.poolRelics
        .where((r) => !creatures.any((c) => r.isCompatibleWith(c)))
        .firstOrNull;
    if (deadRelic != null) return deadRelic.id;

    // Senão, qualquer relíquia (vale +1 cristal).
    if (side.poolRelics.isNotEmpty) return side.poolRelics.first.id;

    // Senão, a criatura mais cara que não cabe (vale +2 cristais).
    final tooExpensive = side.poolCreatures
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
