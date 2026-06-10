/// Eventos estruturados gerados pela resolução do `endTurn` do Card Game
/// "Modo Cartas ACDA" (Fase de Ataque, penalidade sem criaturas e trava
/// anti-stall).
///
/// A UI consome `MatchState.lastTurnEvents` para narrar o que aconteceu —
/// o engine continua puro e determinístico; os eventos são só descrição
/// imutável do que foi resolvido. Ações da Fase de Jogo (apply) NÃO geram
/// eventos: a UI já sabe o que ela mesma fez.
library;

import 'card_models.dart';
import 'match_state.dart';

/// Evento imutável de resolução de turno. Sealed: AttackResolved /
/// AttackEvaded / HealResolved / AbilityTriggered / NoCreaturePenaltyApplied /
/// StallLimitReached.
///
/// DECISÃO (evasão por Voo): adotamos um evento PRÓPRIO `AttackEvaded` em vez
/// de um flag `evaded` em `AttackResolved` — `AttackResolved` mantém o
/// invariante "houve resolução de dano" (rawDamage/damageDealt/hpAfter sempre
/// significativos) e a UI distingue narrativa de evasão sem caso especial.
sealed class MatchEvent {
  const MatchEvent();
}

/// Um ataque resolvido na Fase de Ataque.
///
/// `rawDamage` = ATK efetivo do atacante (antes de armadura).
/// `damageDealt` = dano após armadura (mín 0); tipos `magico` e `vitalismo`
/// ignoram armadura (damageDealt == rawDamage).
/// `targetHpAfter` = HP do alvo após o golpe (0 se morreu).
class AttackResolved extends MatchEvent {
  const AttackResolved({
    required this.attackerSide,
    required this.attackerCardId,
    required this.attackerName,
    required this.targetCardId,
    required this.targetName,
    required this.damageType,
    required this.rawDamage,
    required this.damageDealt,
    required this.targetHpAfter,
    required this.targetDied,
  });

  final SideId attackerSide;
  final String attackerCardId;
  final String attackerName;
  final String targetCardId;
  final String targetName;
  final DamageType damageType;
  final int rawDamage;
  final int damageDealt;
  final int targetHpAfter;
  final bool targetDied;

  @override
  String toString() =>
      'AttackResolved(${attackerSide.name}:$attackerName -> $targetName, '
      '${damageTypeToString(damageType)}, raw=$rawDamage, dealt=$damageDealt, '
      'hpAfter=$targetHpAfter${targetDied ? ', MORREU' : ''})';
}

/// Um ataque EVADIDO por Voo (dano 0; nenhum proc on-hit dispara).
/// Emitido tanto para o ataque principal quanto para o hit extra de
/// Ataque Duplo, quando o alvo voa e o atacante não.
class AttackEvaded extends MatchEvent {
  const AttackEvaded({
    required this.attackerSide,
    required this.attackerCardId,
    required this.attackerName,
    required this.targetCardId,
    required this.targetName,
  });

  final SideId attackerSide;
  final String attackerCardId;
  final String attackerName;
  final String targetCardId;
  final String targetName;

  @override
  String toString() =>
      'AttackEvaded(${attackerSide.name}:$attackerName -> $targetName, Voo)';
}

/// Proc narrável de habilidade (1 evento por proc): Ataque Duplo (hit extra),
/// Pisotear (overflow), Roubo de PV, Cristal de Drenagem, Inspirar/Investida
/// (início do turno), Silêncio (bloqueio de mágico/cura inimigo).
///
/// `ability` é o nome CANÔNICO da keyword (ex.: "Ataque Duplo", "Silêncio") —
/// ver `abilityKeywordLabel` em `abilities.dart`. `detail` é texto curto
/// legível com o efeito concreto (a UI pode narrar direto).
class AbilityTriggered extends MatchEvent {
  const AbilityTriggered({
    required this.side,
    required this.cardId,
    required this.cardName,
    required this.ability,
    required this.detail,
  });

  /// Lado DONO da criatura cuja habilidade disparou.
  final SideId side;
  final String cardId;
  final String cardName;
  final String ability;
  final String detail;

  @override
  String toString() =>
      'AbilityTriggered(${side.name}:$cardName [$ability] $detail)';
}

/// Uma cura efetiva resolvida na Fase de Ataque (curador `cura`).
/// Só é emitida quando `amount > 0` (sem alvo ferido = sem evento).
class HealResolved extends MatchEvent {
  const HealResolved({
    required this.side,
    required this.healerCardId,
    required this.healerName,
    required this.targetCardId,
    required this.targetName,
    required this.amount,
  });

  final SideId side;
  final String healerCardId;
  final String healerName;
  final String targetCardId;
  final String targetName;
  final int amount;

  @override
  String toString() => 'HealResolved(${side.name}:$healerName -> $targetName, '
      '+$amount HP)';
}

/// Penalidade aplicada por terminar o turno sem criaturas em jogo: o lado
/// perde uma carta aleatória do pool. Um evento por carta perdida.
class NoCreaturePenaltyApplied extends MatchEvent {
  const NoCreaturePenaltyApplied({
    required this.side,
    required this.lostCardId,
    required this.lostCardName,
    required this.wasCreature,
  });

  final SideId side;
  final String lostCardId;
  final String lostCardName;

  /// true = criatura perdida; false = relíquia perdida.
  final bool wasCreature;

  @override
  String toString() =>
      'NoCreaturePenaltyApplied(${side.name} perdeu $lostCardName '
      '[${wasCreature ? 'criatura' : 'relíquia'}])';
}

/// Trava anti-stall (turno limite) atingida: partida encerrada por desempate.
class StallLimitReached extends MatchEvent {
  const StallLimitReached({required this.winner});

  final SideId winner;

  @override
  String toString() => 'StallLimitReached(vencedor: ${winner.name})';
}
