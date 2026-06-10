/// Estado imutável da partida do Card Game "Modo Cartas ACDA".
///
/// Toda mutação é feita via `copyWith` retornando uma nova instância.
/// O `Random` (rng) é mantido por referência (objeto mutável de dart:math),
/// pois é a fonte determinística de aleatoriedade injetada por seed.
library;

import 'dart:math';

import 'abilities.dart';
import 'card_models.dart';
import 'engine_config.dart';
import 'match_events.dart';

/// Fase atual da partida.
enum MatchPhase { jogo, ataque, fim }

/// Identifica um dos dois lados.
enum SideId { a, b }

/// Uma criatura em jogo: a carta + estado dinâmico (hp, relíquias, lane,
/// buffs temporários de habilidades).
///
/// Buffs temporários (design dos campos):
/// - `inspirarBonus`: aplicado no início do turno do dono (`_beginTurn`),
///   expira no FIM do turno do dono (limpo pelo `endTurn` do dono, após a
///   Fase de Ataque).
/// - `investidaBonus`: aplicado no início do turno do dono, expira no fim do
///   turno do OPONENTE (limpo pelo `endTurn` do oponente) — dura a rodada.
/// Ambos só contam para ataque corpo a corpo (`effectiveAtk`). A expiração é
/// feita por varredura explícita no engine — sem vazamento entre turnos.
/// - `bonusMaxHp`: PERMANENTE (Roubo de PV soma PV atual e máximo).
class CreatureInPlay {
  const CreatureInPlay({
    required this.card,
    required this.currentHp,
    required this.lane,
    this.relics = const <RelicCard>[],
    this.bonusMaxHp = 0,
    this.inspirarBonus = 0,
    this.investidaBonus = 0,
  });

  final CreatureCard card;
  final int currentHp;

  /// Lane ocupada (0 = frente).
  final int lane;

  /// Relíquias equipadas (flash NÃO entra aqui — é consumida ao equipar).
  final List<RelicCard> relics;

  /// Bônus PERMANENTE de PV máximo (Roubo de PV).
  final int bonusMaxHp;

  /// Bônus temporário de ataque melee (Inspirar) — expira no fim do turno
  /// do dono.
  final int inspirarBonus;

  /// Bônus temporário de ataque melee (Investida) — expira no fim do turno
  /// do oponente.
  final int investidaBonus;

  String get instanceId => card.id;

  /// PV máximo: HP base da carta + `hpBonus` das relíquias + bônus permanente
  /// (Roubo de PV).
  int get maxHp {
    var total = card.hp + bonusMaxHp;
    for (final r in relics) {
      total += r.grants.hpBonus ?? 0;
    }
    return total;
  }

  bool get isAlive => currentHp > 0;

  /// Keywords de habilidade canônicas: inatas da carta + concedidas pelas
  /// relíquias equipadas. Variantes de grafia dos dados são normalizadas
  /// (ver `abilities.dart`); strings desconhecidas são ignoradas.
  Set<AbilityKeyword> get keywords {
    final result = <AbilityKeyword>{};
    for (final a in card.abilities) {
      final k = abilityKeywordFromString(a);
      if (k != null) result.add(k);
    }
    for (final r in relics) {
      for (final a in r.grants.abilities) {
        final k = abilityKeywordFromString(a);
        if (k != null) result.add(k);
      }
    }
    return result;
  }

  bool hasKeyword(AbilityKeyword k) => keywords.contains(k);

  /// Armadura derivada: soma das `armor` das relíquias equipadas + armadura
  /// inata de Escudo (🎚️ `kEscudoArmor`).
  int get armor {
    var total = 0;
    for (final r in relics) {
      total += r.grants.armor ?? 0;
    }
    if (hasKeyword(AbilityKeyword.escudo)) total += kEscudoArmor;
    return total;
  }

  /// Tipo de dano efetivo: a última relíquia equipada que concede `attackType`
  /// sobrescreve o tipo base da criatura.
  DamageType get effectiveDamageType {
    DamageType type = card.damageType;
    for (final r in relics) {
      final granted = r.grants.attackType;
      if (granted != null) type = granted;
    }
    return type;
  }

  /// Ataque efetivo: ATK base + soma dos `atkBonus` das relíquias equipadas.
  /// NÃO inclui buffs temporários — ver [effectiveAtk].
  int get atk {
    var total = card.atk;
    for (final r in relics) {
      total += r.grants.atkBonus ?? 0;
    }
    return total;
  }

  /// Ataque usado na Fase de Ataque: [atk] + buffs temporários de melee
  /// (Inspirar/Investida só valem para ataque corpo a corpo).
  int get effectiveAtk {
    var total = atk;
    if (effectiveDamageType == DamageType.corpoACorpo) {
      total += inspirarBonus + investidaBonus;
    }
    return total;
  }

  CreatureInPlay copyWith({
    int? currentHp,
    int? lane,
    List<RelicCard>? relics,
    int? bonusMaxHp,
    int? inspirarBonus,
    int? investidaBonus,
  }) {
    return CreatureInPlay(
      card: card,
      currentHp: currentHp ?? this.currentHp,
      lane: lane ?? this.lane,
      relics: relics ?? this.relics,
      bonusMaxHp: bonusMaxHp ?? this.bonusMaxHp,
      inspirarBonus: inspirarBonus ?? this.inspirarBonus,
      investidaBonus: investidaBonus ?? this.investidaBonus,
    );
  }
}

/// Estado de um lado do tabuleiro.
///
/// Modelo de MÃO (Card Monsters): o loadout de 18 cartas vira um [deck]
/// embaralhado; a [hand] são as ≤ `kHandSize` cartas visíveis/jogáveis; jogar
/// uma carta COMPRA a próxima do topo do deck repondo a mão. Cartas na mão/deck
/// são `CreatureCard` ou `RelicCard` misturadas (mesmo padrão `Object`+`is` da
/// UI) — use os helpers `cardId`/`cardCost` de `card_models.dart`.
class BoardSide {
  const BoardSide({
    required this.id,
    required this.lanes,
    required this.crystals,
    required this.hand,
    required this.deck,
    required this.sacrificedThisTurn,
    this.pendingCrystals = 0,
  });

  final SideId id;

  /// 3 lanes (0=frente). null = vazia.
  final List<CreatureInPlay?> lanes;

  final int crystals;

  /// MÃO: cartas visíveis/jogáveis (≤ `kHandSize`), criaturas e relíquias
  /// misturadas, em ordem de compra.
  final List<Object> hand;

  /// DECK: pilha de compra restante (índice 0 = topo = próxima a comprar).
  final List<Object> deck;

  /// Se já usou o sacrifício do turno (máx 1/turno).
  final bool sacrificedThisTurn;

  /// Cristais pendentes (Cristal de Drenagem): ganhos durante a Fase de
  /// Ataque, creditados no início do PRÓXIMO turno deste lado (cristais não
  /// fazem carry-over, então o crédito imediato seria perdido no reset).
  final int pendingCrystals;

  /// Criaturas vivas no tabuleiro, em ordem de lane (frente→retaguarda).
  List<CreatureInPlay> get creaturesInPlay {
    final result = <CreatureInPlay>[];
    for (final c in lanes) {
      if (c != null && c.isAlive) result.add(c);
    }
    result.sort((a, b) => a.lane.compareTo(b.lane));
    return result;
  }

  bool get hasCreatureInPlay => creaturesInPlay.isNotEmpty;

  /// Criaturas na MÃO (subconjunto jogável agora).
  List<CreatureCard> get handCreatures =>
      hand.whereType<CreatureCard>().toList(growable: false);

  /// Relíquias na MÃO.
  List<RelicCard> get handRelics =>
      hand.whereType<RelicCard>().toList(growable: false);

  /// Próxima carta a comprar (preview); null se o deck acabou.
  Object? get nextCard => deck.isEmpty ? null : deck.first;

  /// Quantas das 9 criaturas ainda existem (em jogo, na mão OU no deck). Conta
  /// IDs distintos: cada carta é única no loadout MVP.
  int get remainingCreatureCount {
    final ids = <String>{};
    for (final c in hand.whereType<CreatureCard>()) {
      ids.add(c.id);
    }
    for (final c in deck.whereType<CreatureCard>()) {
      ids.add(c.id);
    }
    for (final c in creaturesInPlay) {
      ids.add(c.card.id);
    }
    return ids.length;
  }

  int get totalHpInPlay {
    var total = 0;
    for (final c in creaturesInPlay) {
      total += c.currentHp;
    }
    return total;
  }

  BoardSide copyWith({
    List<CreatureInPlay?>? lanes,
    int? crystals,
    List<Object>? hand,
    List<Object>? deck,
    bool? sacrificedThisTurn,
    int? pendingCrystals,
  }) {
    return BoardSide(
      id: id,
      lanes: lanes ?? this.lanes,
      crystals: crystals ?? this.crystals,
      hand: hand ?? this.hand,
      deck: deck ?? this.deck,
      sacrificedThisTurn: sacrificedThisTurn ?? this.sacrificedThisTurn,
      pendingCrystals: pendingCrystals ?? this.pendingCrystals,
    );
  }

  /// Monta o lado inicial: deck = 18 cartas (criaturas+relíquias); mão = as
  /// primeiras `kHandSize`. Com [rng] (partida real) o deck é embaralhado
  /// determinístico por seed; sem rng (testes que montam estados controlados)
  /// mantém a ordem do loadout.
  static BoardSide initial(SideId id, CardLoadout loadout, [Random? rng]) {
    final pile = <Object>[...loadout.creatures, ...loadout.relics];
    if (rng != null) pile.shuffle(rng);
    final handCount = pile.length < kHandSize ? pile.length : kHandSize;
    return BoardSide(
      id: id,
      lanes: List<CreatureInPlay?>.filled(kLaneCount, null),
      crystals: 0,
      hand: List<Object>.from(pile.sublist(0, handCount)),
      deck: List<Object>.from(pile.sublist(handCount)),
      sacrificedThisTurn: false,
    );
  }
}

/// Estado completo e imutável da partida.
class MatchState {
  const MatchState({
    required this.sideA,
    required this.sideB,
    required this.activeSide,
    required this.turn,
    required this.phase,
    required this.rng,
    this.winner,
    this.lastTurnEvents = const <MatchEvent>[],
  });

  final BoardSide sideA;
  final BoardSide sideB;
  final SideId activeSide;
  final int turn;
  final MatchPhase phase;
  final SideId? winner;

  /// Eventos gerados pelo ÚLTIMO `endTurn`. Semântica (documentada — a UI
  /// narra a partir daqui): cobre TUDO entre o fim da Fase de Jogo do lado
  /// que chamou `endTurn` e o início do turno seguinte, nesta ordem:
  /// Fase de Ataque (ataques/evasões/curas/procs de habilidade), penalidade
  /// sem criaturas, stall, e os procs de INÍCIO do turno seguinte
  /// (Inspirar/Investida do novo lado ativo). Substituído (não acumulado) a
  /// cada `endTurn`. Ações da Fase de Jogo (apply) não geram eventos.
  final List<MatchEvent> lastTurnEvents;

  /// Fonte determinística de aleatoriedade (injetada por seed).
  final Random rng;

  bool get isOver => phase == MatchPhase.fim;

  BoardSide get active => activeSide == SideId.a ? sideA : sideB;
  BoardSide get opponent => activeSide == SideId.a ? sideB : sideA;

  BoardSide sideOf(SideId id) => id == SideId.a ? sideA : sideB;

  MatchState copyWith({
    BoardSide? sideA,
    BoardSide? sideB,
    SideId? activeSide,
    int? turn,
    MatchPhase? phase,
    SideId? winner,
    bool clearWinner = false,
    List<MatchEvent>? lastTurnEvents,
  }) {
    return MatchState(
      sideA: sideA ?? this.sideA,
      sideB: sideB ?? this.sideB,
      activeSide: activeSide ?? this.activeSide,
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      winner: clearWinner ? null : (winner ?? this.winner),
      lastTurnEvents: lastTurnEvents ?? this.lastTurnEvents,
      rng: rng,
    );
  }

  /// Retorna novo estado substituindo o lado `id`.
  MatchState withSide(SideId id, BoardSide side) {
    if (id == SideId.a) return copyWith(sideA: side);
    return copyWith(sideB: side);
  }
}
