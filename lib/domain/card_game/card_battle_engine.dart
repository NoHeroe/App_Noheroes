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
      sideA: BoardSide.initial(SideId.a, a),
      sideB: BoardSide.initial(SideId.b, b),
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
    return s.withSide(side.id, newSide).copyWith(phase: MatchPhase.jogo);
  }

  /// Inspirar: aliados (não o inspirador) ganham 🎚️ `kInspirarBonus` de
  /// ataque melee até o fim do turno. Com vários Inspirar, só o maior se
  /// aplica — com bônus fixo igual, aplica 1× (não acumula).
  /// Investida: a própria criatura ganha 🎚️ `kInvestidaBonus` de ataque melee
  /// até o fim do turno do OPONENTE.
  BoardSide _applyStartOfTurnBuffs(BoardSide side, List<MatchEvent> events) {
    final living = side.creaturesInPlay;
    if (living.isEmpty) return side;

    final inspirers =
        living.where((c) => c.hasKeyword(AbilityKeyword.inspirar)).toList();

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
      if (c.inspirarBonus != inspirarB || c.investidaBonus != investidaB) {
        lanes[i] =
            c.copyWith(inspirarBonus: inspirarB, investidaBonus: investidaB);
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
    BoardSide clear(BoardSide side, {required bool inspirar, required bool investida}) {
      final lanes = List<CreatureInPlay?>.from(side.lanes);
      var changed = false;
      for (var i = 0; i < lanes.length; i++) {
        final c = lanes[i];
        if (c == null) continue;
        final newInspirar = inspirar ? 0 : c.inspirarBonus;
        final newInvestida = investida ? 0 : c.investidaBonus;
        if (c.inspirarBonus != newInspirar ||
            c.investidaBonus != newInvestida) {
          lanes[i] = c.copyWith(
              inspirarBonus: newInspirar, investidaBonus: newInvestida);
          changed = true;
        }
      }
      return changed ? side.copyWith(lanes: lanes) : side;
    }

    final other = ending == SideId.a ? SideId.b : SideId.a;
    var state = s.withSide(
        ending, clear(s.sideOf(ending), inspirar: true, investida: false));
    state = state.withSide(
        other, clear(state.sideOf(other), inspirar: false, investida: true));
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

    // Expira buffs temporários (Inspirar do lado que termina; Investida do
    // oponente — aplicada no turno anterior dele, valeu a rodada inteira).
    final ending = state.activeSide;
    state = _expireEndOfTurnBuffs(state, ending);

    // Passa o turno para o oponente e inicia o turno dele. Procs de início
    // de turno (Inspirar/Investida do novo lado ativo) entram nos MESMOS
    // lastTurnEvents deste endTurn — semântica documentada em MatchState.
    final next = ending == SideId.a ? SideId.b : SideId.a;
    state = state.copyWith(activeSide: next, turn: state.turn + 1);
    state = _beginTurn(state, events);
    return state.copyWith(lastTurnEvents: List.unmodifiable(events));
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
  MatchState _resolveAttackPhase(MatchState s, List<MatchEvent> events) {
    var attacker = s.active;
    var defender = s.opponent;

    // Ordem de lane (frente→retaguarda), fixada no início da fase.
    final order = attacker.creaturesInPlay.map((c) => c.instanceId).toList();

    for (final attackerId in order) {
      // Sem alvos → fase termina (já é vitória de fato).
      if (!defender.hasCreatureInPlay) break;

      final attackerLaneIdx = attacker.lanes
          .indexWhere((c) => c != null && c.instanceId == attackerId);
      if (attackerLaneIdx < 0) continue;
      final creature = attacker.lanes[attackerLaneIdx]!;
      if (!creature.isAlive) continue;

      final type = creature.effectiveDamageType;

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
          continue;
        }
      }

      if (type == DamageType.cura) {
        attacker = _resolveHeal(attacker, creature, events);
        continue;
      }

      // ---- Elegibilidade posicional ----
      // Linha de frente do PRÓPRIO lado = menor lane ocupada.
      final myFront = attacker.creaturesInPlay.first.lane;
      final atFront = creature.lane == myFront;

      if (type == DamageType.corpoACorpo &&
          !atFront &&
          !creature.hasKeyword(AbilityKeyword.alcance)) {
        continue; // melee fora de posição não ataca.
      }
      if (type == DamageType.aDistancia && atFront) {
        continue; // ranged na frente não ataca.
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
        meleeFromFront: type == DamageType.corpoACorpo && atFront,
        events: events,
      );
      attacker = result.$1;
      defender = result.$2;
    }

    var state = s.withSide(attacker.id, attacker);
    state = state.withSide(defender.id, defender);
    return state;
  }

  /// Resolve UM ataque (alvo, evasão de Voo, dano e procs on-hit: Roubo de PV,
  /// Cristal de Drenagem, Pisotear, Ataque Duplo). Retorna (atacante, defensor)
  /// atualizados. Lanes do defensor são compactadas no fim, uma única vez.
  (BoardSide, BoardSide) _resolveAttack(
    MatchState s,
    BoardSide atkSide,
    BoardSide defSide,
    int attackerLaneIdx,
    DamageType type, {
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

    // ---- Dano principal ----
    final raw = attacker.effectiveAtk;
    var damage = raw;
    final physical =
        type == DamageType.corpoACorpo || type == DamageType.aDistancia;
    if (physical) {
      damage = damage - target.armor;
      if (damage < 0) damage = 0;
    }
    final hpBefore = target.currentHp;
    final newHp = hpBefore - damage;
    final died = newHp <= 0;
    defLanes[targetLaneIdx] = died ? null : target.copyWith(currentHp: newHp);
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
      targetHpAfter: died ? 0 : newHp,
      targetDied: died,
    ));

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

    if (died) {
      // Cristal de Drenagem: destruiu com seu ataque (vale também para as
      // mortes por Pisotear/Ataque Duplo abaixo — regra uniforme documentada).
      if (attacker.hasKeyword(AbilityKeyword.cristalDeDrenagem)) {
        gainDrainCrystal(target.card.nome);
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
          final nextHp = next.currentHp - spill;
          final nextDied = nextHp <= 0;
          defLanes[nextIdx] =
              nextDied ? null : next.copyWith(currentHp: nextHp);
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
          // Dano verdadeiro: ignora armadura. 🎚️ kAtaqueDuploDamage = atk
          // efetivo do atacante.
          final extraDmg = attacker.effectiveAtk;
          final extraHp = extraTarget.currentHp - extraDmg;
          final extraDied = extraHp <= 0;
          defLanes[pickIdx] =
              extraDied ? null : extraTarget.copyWith(currentHp: extraHp);
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

    // ---- Consolida lados ----
    final atkLanes = List<CreatureInPlay?>.from(atkSide.lanes);
    atkLanes[attackerLaneIdx] = attacker;
    var newAtkSide = atkSide.copyWith(
      lanes: atkLanes,
      pendingCrystals: atkSide.pendingCrystals + pendingGain,
    );

    var newDefSide = defSide.copyWith(lanes: defLanes);
    if (anyDeath) newDefSide = _advanceLanes(newDefSide);

    return (newAtkSide, newDefSide);
  }

  /// Voo: o alvo evade se tiver Voo e o atacante NÃO tiver — 🎚️ 50% vs melee
  /// (incl. hit extra de Ataque Duplo), 🎚️ 25% vs à distância. Mágico e
  /// vitalismo não são evadidos. Consome o rng do MatchState (determinístico
  /// por seed).
  bool _rollEvade(MatchState s, CreatureInPlay attacker, CreatureInPlay target,
      DamageType type) {
    if (!target.hasKeyword(AbilityKeyword.voo)) return false;
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

    final newLanes = List<CreatureInPlay?>.from(side.lanes);
    newLanes[laneIdx] = target.copyWith(currentHp: healed);
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

    // 1. Preenche lanes vazias jogando criaturas que cabem, POSICIONANDO por
    // tipo: melee busca a frente (lane vazia de menor índice); ranged a
    // retaguarda (maior índice); mágico/cura/vitalismo preferem retaguarda.
    // Evita deixar ranged sozinho na frente quando há alternativa.
    var guard = 0;
    while (guard++ < 50) {
      final side = sim.active;
      final freeLane = side.lanes.contains(null);
      if (!freeLane) break;

      // Candidatas que cabem nos cristais (maior atk primeiro).
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

  /// Lane que o bot pede para posicionar [card]: melee → lane livre de MENOR
  /// índice (frente); demais (ranged/mágico/cura/vitalismo) → lane livre de
  /// MAIOR índice (retaguarda). Retorna null se não houver lane livre (o
  /// apply rejeitará — chamadores garantem que há).
  int? _botLaneFor(BoardSide side, CreatureCard card) {
    final free = <int>[
      for (var i = 0; i < side.lanes.length; i++)
        if (side.lanes[i] == null) i,
    ];
    if (free.isEmpty) return null;
    return card.damageType == DamageType.corpoACorpo ? free.first : free.last;
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
