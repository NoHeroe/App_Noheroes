/// Estado imutável da partida do Card Game "Modo Cartas ACDA".
///
/// Toda mutação é feita via `copyWith` retornando uma nova instância.
/// O `Random` (rng) é mantido por referência (objeto mutável de dart:math),
/// pois é a fonte determinística de aleatoriedade injetada por seed.
library;

import 'dart:math';

import 'card_models.dart';
import 'engine_config.dart';
import 'match_events.dart';

/// Fase atual da partida.
enum MatchPhase { jogo, ataque, fim }

/// Identifica um dos dois lados.
enum SideId { a, b }

/// Uma criatura em jogo: a carta + estado dinâmico (hp, relíquias, lane).
class CreatureInPlay {
  const CreatureInPlay({
    required this.card,
    required this.currentHp,
    required this.lane,
    this.relics = const <RelicCard>[],
  });

  final CreatureCard card;
  final int currentHp;

  /// Lane ocupada (0 = frente).
  final int lane;

  /// Relíquias equipadas (flash NÃO entra aqui — é consumida ao equipar).
  final List<RelicCard> relics;

  String get instanceId => card.id;

  /// PV máximo: HP base da carta + soma dos `hpBonus` das relíquias equipadas.
  int get maxHp {
    var total = card.hp;
    for (final r in relics) {
      total += r.grants.hpBonus ?? 0;
    }
    return total;
  }

  bool get isAlive => currentHp > 0;

  /// Armadura derivada: soma das `armor` das relíquias equipadas.
  int get armor {
    var total = 0;
    for (final r in relics) {
      total += r.grants.armor ?? 0;
    }
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
  int get atk {
    var total = card.atk;
    for (final r in relics) {
      total += r.grants.atkBonus ?? 0;
    }
    return total;
  }

  CreatureInPlay copyWith({
    int? currentHp,
    int? lane,
    List<RelicCard>? relics,
  }) {
    return CreatureInPlay(
      card: card,
      currentHp: currentHp ?? this.currentHp,
      lane: lane ?? this.lane,
      relics: relics ?? this.relics,
    );
  }
}

/// Estado de um lado do tabuleiro.
class BoardSide {
  const BoardSide({
    required this.id,
    required this.lanes,
    required this.crystals,
    required this.poolCreatures,
    required this.poolRelics,
    required this.sacrificedThisTurn,
  });

  final SideId id;

  /// 3 lanes (0=frente). null = vazia.
  final List<CreatureInPlay?> lanes;

  final int crystals;

  /// Cartas ainda não jogadas.
  final List<CreatureCard> poolCreatures;
  final List<RelicCard> poolRelics;

  /// Se já usou o sacrifício do turno (máx 1/turno).
  final bool sacrificedThisTurn;

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

  /// Quantas das 9 criaturas ainda existem (em jogo OU no pool). Conta IDs
  /// distintos: cada carta é única no loadout MVP.
  int get remainingCreatureCount {
    final ids = <String>{};
    for (final c in poolCreatures) {
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
    List<CreatureCard>? poolCreatures,
    List<RelicCard>? poolRelics,
    bool? sacrificedThisTurn,
  }) {
    return BoardSide(
      id: id,
      lanes: lanes ?? this.lanes,
      crystals: crystals ?? this.crystals,
      poolCreatures: poolCreatures ?? this.poolCreatures,
      poolRelics: poolRelics ?? this.poolRelics,
      sacrificedThisTurn: sacrificedThisTurn ?? this.sacrificedThisTurn,
    );
  }

  static BoardSide initial(SideId id, CardLoadout loadout) {
    return BoardSide(
      id: id,
      lanes: List<CreatureInPlay?>.filled(kLaneCount, null),
      crystals: 0,
      poolCreatures: List<CreatureCard>.from(loadout.creatures),
      poolRelics: List<RelicCard>.from(loadout.relics),
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

  /// Eventos gerados pelo ÚLTIMO `endTurn` (Fase de Ataque, penalidade,
  /// stall). Substituído (não acumulado) a cada `endTurn`. Ações da Fase de
  /// Jogo (apply) não geram eventos.
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
