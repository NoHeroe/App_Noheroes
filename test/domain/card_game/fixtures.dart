/// Fixtures de cartas de EXEMPLO para os testes do Card Game.
/// NÃO usa as 78 cartas reais — stats inventados, controlados para os cenários.
library;

import 'dart:math';

import 'package:noheroes_app/domain/card_game/card_game.dart';

/// Random determinístico para montar estados em testes.
Random makeRng([int seed = 42]) => Random(seed);

CreatureCard creature({
  required String id,
  CardConcept concept = CardConcept.vitalismo,
  List<CardConcept>? concepts,
  int cost = 1,
  int atk = 2,
  int hp = 5,
  DamageType damageType = DamageType.corpoACorpo,
  Rarity rarity = Rarity.comum,
  int relicSlots = 1,
  List<String> abilities = const <String>[],
}) {
  return CreatureCard(
    id: id,
    nome: id,
    concepts: concepts ?? <CardConcept>[concept],
    cost: cost,
    atk: atk,
    hp: hp,
    damageType: damageType,
    rarity: rarity,
    relicSlots: relicSlots,
    abilities: abilities,
  );
}

RelicCard relic({
  required String id,
  CardConcept concept = CardConcept.vitalismo,
  List<CardConcept>? concepts,
  int cost = 0,
  int? atkBonus,
  int? hpBonus,
  int? armor,
  DamageType? attackType,
  int? heal,
  Rarity rarity = Rarity.comum,
  bool flash = false,
  List<String> abilities = const <String>[],
}) {
  return RelicCard(
    id: id,
    nome: id,
    concepts: concepts ?? <CardConcept>[concept],
    cost: cost,
    grants: RelicGrants(
      atkBonus: atkBonus,
      hpBonus: hpBonus,
      armor: armor,
      attackType: attackType,
      heal: heal,
      abilities: abilities,
      rawEffect: '',
    ),
    rarity: rarity,
    isFlash: flash,
  );
}

/// Loadout genérico de 9 criaturas + 9 relíquias do conceito [concept].
/// Stats fracos/baratos por padrão para partidas previsíveis.
CardLoadout makeLoadout({
  String prefix = 'X',
  CardConcept concept = CardConcept.vitalismo,
  int cost = 1,
  int atk = 2,
  int hp = 5,
  DamageType damageType = DamageType.corpoACorpo,
}) {
  final creatures = <CreatureCard>[
    for (var i = 0; i < 9; i++)
      creature(
        id: '${prefix}_c$i',
        concept: concept,
        cost: cost,
        atk: atk,
        hp: hp,
        damageType: damageType,
      ),
  ];
  final relics = <RelicCard>[
    for (var i = 0; i < 9; i++)
      relic(id: '${prefix}_r$i', concept: concept, armor: 1),
  ];
  return CardLoadout(creatures: creatures, relics: relics);
}
