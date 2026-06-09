/// Catálogo das cartas reais do ACDA (Modo Cartas).
///
/// Carrega os dois JSON gerados por `tool/gen_card_data.dart` via `rootBundle`
/// e devolve as listas tipadas. Os JSON são a fonte de verdade em runtime; o
/// gerador é a fonte reproduzível a partir dos `.md` do vault.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'card_models.dart';

class CardCatalog {
  const CardCatalog({
    required this.creatures,
    required this.relics,
  });

  final List<CreatureCard> creatures;
  final List<RelicCard> relics;

  static const String creaturesAsset = 'assets/data/card_game/creatures.json';
  static const String relicsAsset = 'assets/data/card_game/relics.json';

  /// Carrega ambos os catálogos a partir dos assets registrados no pubspec.
  static Future<CardCatalog> load() async {
    final creaturesRaw = await rootBundle.loadString(creaturesAsset);
    final relicsRaw = await rootBundle.loadString(relicsAsset);
    return CardCatalog(
      creatures: parseCreatures(creaturesRaw),
      relics: parseRelics(relicsRaw),
    );
  }

  /// Parse puro (sem Flutter) — útil para testes que leem o arquivo via dart:io.
  static List<CreatureCard> parseCreatures(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => CreatureCard.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  static List<RelicCard> parseRelics(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => RelicCard.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
