/// Fixtures de cartas de EXEMPLO para os testes do Card Game.
/// NÃO usa as 78 cartas reais — stats inventados, controlados para os cenários.
library;

import 'dart:math';

import 'package:noheroes_app/domain/card_game/card_game.dart';

/// Random determinístico para montar estados em testes.
Random makeRng([int seed = 42]) => Random(seed);

CreatureCard creature({
  required String id,
  CardConcept concept = CardConcept.vita,
  int cost = 1,
  int atk = 2,
  int hp = 5,
  DamageType damageType = DamageType.corpoACorpo,
  int relicSlots = 1,
}) {
  return CreatureCard(
    id: id,
    nome: id,
    concept: concept,
    cost: cost,
    atk: atk,
    hp: hp,
    damageType: damageType,
    relicSlots: relicSlots,
  );
}

RelicCard relic({
  required String id,
  CardConcept concept = CardConcept.vita,
  int? armor,
  DamageType? attackType,
  int? heal,
  bool flash = false,
}) {
  return RelicCard(
    id: id,
    nome: id,
    concept: concept,
    grants: RelicGrants(armor: armor, attackType: attackType, heal: heal),
    flash: flash,
  );
}

/// Loadout genérico de 9 criaturas + 9 relíquias do conceito [concept].
/// Stats fracos/baratos por padrão para partidas previsíveis.
CardLoadout makeLoadout({
  String prefix = 'X',
  CardConcept concept = CardConcept.vita,
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
