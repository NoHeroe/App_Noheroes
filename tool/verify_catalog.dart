// Valida que creatures.json/relics.json parseiam 100% pelos modelos reais.
import 'dart:convert';
import 'dart:io';
import 'package:noheroes_app/domain/card_game/card_models.dart';

void main() {
  final cri = (jsonDecode(
          File('assets/data/card_game/creatures.json').readAsStringSync())
      as List);
  final rel = (jsonDecode(
          File('assets/data/card_game/relics.json').readAsStringSync())
      as List);
  var ok = 0;
  for (final j in cri) {
    CreatureCard.fromJson(j as Map<String, dynamic>);
    ok++;
  }
  stdout.writeln('Criaturas OK: $ok');
  ok = 0;
  for (final j in rel) {
    RelicCard.fromJson(j as Map<String, dynamic>);
    ok++;
  }
  stdout.writeln('Relíquias OK: $ok');

  // Distintos abilities tokens (p/ conferir o que a engine precisa reconhecer).
  final toks = <String>{};
  for (final j in cri) {
    for (final a in (j['abilities'] as List)) {
      toks.add(a as String);
    }
  }
  for (final j in rel) {
    for (final a in ((j['grants'] as Map)['abilities'] as List)) {
      toks.add(a as String);
    }
  }
  final sorted = toks.toList()..sort();
  stdout.writeln('\nTokens de habilidade distintos (${sorted.length}):');
  stdout.writeln(sorted.join(', '));
}
