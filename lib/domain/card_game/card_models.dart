/// Modelos puros do Card Game "Modo Cartas ACDA".
///
/// Dart puro, sem Flutter/rede. Stats vêm de fora (data-driven); o engine
/// nunca embute as 78 cartas reais. Veja `_ENGINE_SPEC_mvp.md`.
library;

/// Conceito (cor) de uma carta. Relíquia só equipa em criatura própria do
/// MESMO conceito.
enum CardConcept {
  vita,
  neutro,
  chrysalis,
  celestial,
  magico,
  corrompido,
}

/// Tipo de dano / comportamento de ataque de uma criatura.
enum DamageType {
  corpoACorpo,
  aDistancia,
  magico,
  vitalismo, // dano verdadeiro
  cura,
}

/// Carta de criatura. Imutável.
///
/// `abilities` é uma lista extensível (MVP: pode ser vazia). Mantida como
/// `List<String>` de identificadores para não acoplar o engine a efeitos
/// complexos ainda fora do MVP.
class CreatureCard {
  const CreatureCard({
    required this.id,
    required this.nome,
    required this.concept,
    required this.cost,
    required this.atk,
    required this.hp,
    required this.damageType,
    this.relicSlots = 1,
    this.abilities = const <String>[],
  });

  final String id;
  final String nome;
  final CardConcept concept;
  final int cost;
  final int atk;
  final int hp;
  final DamageType damageType;
  final int relicSlots;
  final List<String> abilities;

  @override
  String toString() => 'CreatureCard($id, $nome, $concept, cost=$cost, '
      'atk=$atk, hp=$hp, $damageType)';
}

/// O que uma relíquia concede ao equipar. Campos opcionais (null = não concede).
class RelicGrants {
  const RelicGrants({
    this.armor,
    this.attackType,
    this.heal,
    this.ability,
  });

  /// Redução flat de dano físico (corpoACorpo / aDistancia). null = nenhuma.
  final int? armor;

  /// Se não-nulo, sobrescreve o `damageType` da criatura equipada.
  final DamageType? attackType;

  /// Cura aplicada no momento do equipamento (efeito flash típico). null = nenhuma.
  final int? heal;

  /// Identificador de habilidade extra (MVP: não interpretada pelo engine).
  final String? ability;

  @override
  String toString() =>
      'RelicGrants(armor=$armor, attackType=$attackType, heal=$heal, ability=$ability)';
}

/// Carta de relíquia. Imutável.
///
/// `flash` = uso único: aplica o efeito e é descartada (não fica equipada).
class RelicCard {
  const RelicCard({
    required this.id,
    required this.nome,
    required this.concept,
    required this.grants,
    this.flash = false,
  });

  final String id;
  final String nome;
  final CardConcept concept;
  final RelicGrants grants;
  final bool flash;

  @override
  String toString() =>
      'RelicCard($id, $nome, $concept, flash=$flash, $grants)';
}

/// Conjunto de cartas de um jogador: exatamente 9 criaturas + 9 relíquias.
class CardLoadout {
  CardLoadout({
    required this.creatures,
    required this.relics,
  }) {
    if (creatures.length != 9) {
      throw ArgumentError(
          'CardLoadout requer exatamente 9 criaturas, recebeu ${creatures.length}');
    }
    if (relics.length != 9) {
      throw ArgumentError(
          'CardLoadout requer exatamente 9 relíquias, recebeu ${relics.length}');
    }
  }

  final List<CreatureCard> creatures;
  final List<RelicCard> relics;
}
