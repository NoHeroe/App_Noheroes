/// Modelos puros do Card Game "Modo Cartas ACDA".
///
/// Dart puro, sem Flutter/rede. Stats vêm de fora (data-driven); o engine
/// nunca embute as cartas reais — elas vivem em `assets/data/card_game/*.json`
/// e são carregadas via `card_catalog.dart`. Veja `_ENGINE_SPEC_mvp.md`.
library;

/// Conceito (cor) de uma carta. Valores batem EXATAMENTE o frontmatter das
/// cartas reais do ACDA.
///
/// `neutro` ("Natural") é universal: relíquia neutra equipa em qualquer
/// criatura e abriga os Flash. Por regra de design não há criaturas neutras
/// (exceção documentada nos dados: ver `card_catalog.dart`).
enum CardConcept {
  vitalismo,
  neutro,
  chrysalis,
  celestial,
  magico,
  corrompido,
}

/// Parse de um conceito a partir do texto do frontmatter. Lança se desconhecido
/// (queremos falhar alto na geração, não fabricar).
CardConcept cardConceptFromString(String raw) {
  switch (raw.trim()) {
    case 'vitalismo':
      return CardConcept.vitalismo;
    case 'neutro':
      return CardConcept.neutro;
    case 'chrysalis':
      return CardConcept.chrysalis;
    case 'celestial':
      return CardConcept.celestial;
    case 'magico':
      return CardConcept.magico;
    case 'corrompido':
      return CardConcept.corrompido;
    default:
      throw ArgumentError('CardConcept desconhecido: "$raw"');
  }
}

String cardConceptToString(CardConcept c) => c.name;

/// Raridade de uma carta. Valores batem o frontmatter (`comum`/`rara`/...).
enum Rarity {
  comum,
  rara,
  epica,
  lendaria,
  elite,
}

Rarity rarityFromString(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'comum':
      return Rarity.comum;
    case 'rara':
      return Rarity.rara;
    case 'epica':
    case 'épica':
      return Rarity.epica;
    case 'lendaria':
    case 'lendária':
      return Rarity.lendaria;
    case 'elite':
      return Rarity.elite;
    default:
      throw ArgumentError('Rarity desconhecida: "$raw"');
  }
}

String rarityToString(Rarity r) => r.name;

/// Tipo de dano / comportamento de ataque de uma criatura.
enum DamageType {
  corpoACorpo,
  aDistancia,
  magico,
  vitalismo, // dano verdadeiro
  cura,
}

/// Parse do `tipo_dano` do frontmatter (snake_case).
DamageType damageTypeFromString(String raw) {
  switch (raw.trim()) {
    case 'corpo_a_corpo':
      return DamageType.corpoACorpo;
    case 'a_distancia':
      return DamageType.aDistancia;
    case 'magico':
      return DamageType.magico;
    case 'vitalismo':
      return DamageType.vitalismo;
    case 'cura':
      return DamageType.cura;
    default:
      throw ArgumentError('DamageType desconhecido: "$raw"');
  }
}

/// Chave snake_case do `tipo_dano` (round-trip com o JSON gerado).
String damageTypeToString(DamageType t) {
  switch (t) {
    case DamageType.corpoACorpo:
      return 'corpo_a_corpo';
    case DamageType.aDistancia:
      return 'a_distancia';
    case DamageType.magico:
      return 'magico';
    case DamageType.vitalismo:
      return 'vitalismo';
    case DamageType.cura:
      return 'cura';
  }
}

/// Carta de criatura. Imutável.
///
/// `concepts`: 1 conceito (normal) ou até 2 (elite). `abilities` é uma lista
/// extensível (pode ser vazia) de identificadores; o engine MVP não as
/// interpreta.
class CreatureCard {
  const CreatureCard({
    required this.id,
    required this.nome,
    required this.concepts,
    required this.cost,
    required this.atk,
    required this.hp,
    required this.damageType,
    required this.rarity,
    this.relicSlots = 1,
    this.abilities = const <String>[],
  });

  final String id;
  final String nome;
  final List<CardConcept> concepts;
  final int cost;
  final int atk;
  final int hp;
  final DamageType damageType;
  final Rarity rarity;
  final int relicSlots;
  final List<String> abilities;

  factory CreatureCard.fromJson(Map<String, dynamic> json) {
    return CreatureCard(
      id: json['id'] as String,
      nome: json['nome'] as String,
      concepts: (json['concepts'] as List<dynamic>)
          .map((e) => cardConceptFromString(e as String))
          .toList(growable: false),
      cost: json['cost'] as int,
      atk: json['atk'] as int,
      hp: json['hp'] as int,
      damageType: damageTypeFromString(json['damage_type'] as String),
      rarity: rarityFromString(json['rarity'] as String),
      relicSlots: json['relic_slots'] as int? ?? 1,
      abilities: (json['abilities'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'nome': nome,
        'concepts': concepts.map(cardConceptToString).toList(),
        'cost': cost,
        'atk': atk,
        'hp': hp,
        'damage_type': damageTypeToString(damageType),
        'rarity': rarityToString(rarity),
        'relic_slots': relicSlots,
        'abilities': abilities,
      };

  @override
  String toString() => 'CreatureCard($id, $nome, $concepts, cost=$cost, '
      'atk=$atk, hp=$hp, $damageType, $rarity)';
}

/// O que uma relíquia concede ao equipar. Campos opcionais (null = não concede).
///
/// `rawEffect` é SEMPRE o texto original da carta, preservado mesmo quando
/// nenhum campo estruturado casou (parsing best-effort).
class RelicGrants {
  const RelicGrants({
    this.atkBonus,
    this.hpBonus,
    this.armor,
    this.heal,
    this.attackType,
    this.abilities = const <String>[],
    required this.rawEffect,
  });

  /// Bônus flat de ataque (ex.: "+2 de ataque"). null = nenhum.
  final int? atkBonus;

  /// Bônus flat de PV máximo (ex.: "+2 PV"). null = nenhum.
  final int? hpBonus;

  /// Redução flat de dano físico (corpoACorpo / aDistancia). null = nenhuma.
  final int? armor;

  /// Cura aplicada no momento do equipamento (efeito flash típico). null = nenhuma.
  final int? heal;

  /// Se não-nulo, sobrescreve o `damageType` da criatura equipada.
  final DamageType? attackType;

  /// Keywords de habilidade (ex.: Furtividade, Investida, Inspirar). Pode vazia.
  final List<String> abilities;

  /// Texto original do campo "Efeito" da carta. Sempre preservado.
  final String rawEffect;

  factory RelicGrants.fromJson(Map<String, dynamic> json) {
    final at = json['attack_type'] as String?;
    return RelicGrants(
      atkBonus: json['atk_bonus'] as int?,
      hpBonus: json['hp_bonus'] as int?,
      armor: json['armor'] as int?,
      heal: json['heal'] as int?,
      attackType: at == null ? null : damageTypeFromString(at),
      abilities: (json['abilities'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      rawEffect: json['raw_effect'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (atkBonus != null) 'atk_bonus': atkBonus,
        if (hpBonus != null) 'hp_bonus': hpBonus,
        if (armor != null) 'armor': armor,
        if (heal != null) 'heal': heal,
        if (attackType != null) 'attack_type': damageTypeToString(attackType!),
        'abilities': abilities,
        'raw_effect': rawEffect,
      };

  @override
  String toString() =>
      'RelicGrants(atk=$atkBonus, hp=$hpBonus, armor=$armor, heal=$heal, '
      'attackType=$attackType, abilities=$abilities, raw="$rawEffect")';
}

/// Carta de relíquia. Imutável.
///
/// `isFlash` = uso único (`tipo: flash`): aplica o efeito e é descartada (não
/// fica equipada). Relíquia `neutro` é universal (equipa em qualquer criatura).
class RelicCard {
  const RelicCard({
    required this.id,
    required this.nome,
    required this.concepts,
    required this.grants,
    required this.rarity,
    this.cost = 0,
    this.isFlash = false,
  });

  final String id;
  final String nome;
  final List<CardConcept> concepts;

  /// Custo em cristais para jogar (equipar/usar) a relíquia. Vem do
  /// frontmatter `custo:` das cartas reais (default 0 só para fixtures).
  final int cost;

  final RelicGrants grants;
  final Rarity rarity;
  final bool isFlash;

  /// Universal: equipa em qualquer criatura, independente de conceito.
  bool get isUniversal => concepts.contains(CardConcept.neutro);

  /// Regra de compatibilidade: a relíquia equipa numa criatura se for universal
  /// (neutro) OU se compartilharem pelo menos um conceito.
  bool isCompatibleWith(CreatureCard creature) {
    if (isUniversal) return true;
    for (final c in concepts) {
      if (creature.concepts.contains(c)) return true;
    }
    return false;
  }

  factory RelicCard.fromJson(Map<String, dynamic> json) {
    return RelicCard(
      id: json['id'] as String,
      nome: json['nome'] as String,
      concepts: (json['concepts'] as List<dynamic>)
          .map((e) => cardConceptFromString(e as String))
          .toList(growable: false),
      cost: json['cost'] as int? ?? 0,
      grants: RelicGrants.fromJson(json['grants'] as Map<String, dynamic>),
      rarity: rarityFromString(json['rarity'] as String),
      isFlash: json['is_flash'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'nome': nome,
        'concepts': concepts.map(cardConceptToString).toList(),
        'cost': cost,
        'grants': grants.toJson(),
        'rarity': rarityToString(rarity),
        'is_flash': isFlash,
      };

  @override
  String toString() => 'RelicCard($id, $nome, $concepts, cost=$cost, '
      'flash=$isFlash, $rarity, $grants)';
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
