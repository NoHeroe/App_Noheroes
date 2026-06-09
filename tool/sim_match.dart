// Simulador de partida (lógica-first, sem UI). Carrega as cartas REAIS do ACDA
// via dart:io, monta 2 loadouts (9 criaturas + 9 relíquias compatíveis cada),
// roda o engine BOT vs BOT até o fim e imprime o log turno a turno.
//
//   dart run tool/sim_match.dart [seed]
//
// Valida ponta a ponta: dados reais + CardBattleEngine + bot, sem Flutter.

import 'dart:convert';
import 'dart:io';

import 'package:noheroes_app/domain/card_game/card_models.dart';
import 'package:noheroes_app/domain/card_game/card_battle_engine.dart';
import 'package:noheroes_app/domain/card_game/match_state.dart';

void main(List<String> args) {
  final seed = args.isNotEmpty ? int.tryParse(args.first) ?? 7 : 7;

  // Parse direto (sem card_catalog, que importa Flutter/rootBundle).
  final creatures = (jsonDecode(
              File('assets/data/card_game/creatures.json').readAsStringSync())
          as List<dynamic>)
      .map((e) => CreatureCard.fromJson(e as Map<String, dynamic>))
      .toList();
  final relics = (jsonDecode(
              File('assets/data/card_game/relics.json').readAsStringSync())
          as List<dynamic>)
      .map((e) => RelicCard.fromJson(e as Map<String, dynamic>))
      .toList();
  stdout.writeln('Catálogo: ${creatures.length} criaturas · ${relics.length} relíquias\n');

  // Monta um loadout: 9 criaturas a partir de `from`, + 9 relíquias compatíveis
  // (mesmo conceito de alguma criatura OU universal/neutro).
  CardLoadout buildLoadout(int from) {
    final picks = creatures.skip(from).take(9).toList();
    final concepts = picks.expand((c) => c.concepts).toSet();
    final compat = relics
        .where((r) => r.isUniversal || r.concepts.any(concepts.contains))
        .take(9)
        .toList();
    // Completa com universais se faltar (garante 9).
    if (compat.length < 9) {
      for (final r in relics.where((r) => r.isUniversal)) {
        if (compat.length >= 9) break;
        if (!compat.contains(r)) compat.add(r);
      }
    }
    return CardLoadout(creatures: picks, relics: compat.take(9).toList());
  }

  final a = buildLoadout(0);
  final b = buildLoadout(9);
  stdout.writeln('Lado A: ${a.creatures.map((c) => c.id).join(", ")}');
  stdout.writeln('Lado B: ${b.creatures.map((c) => c.id).join(", ")}\n');

  final engine = CardBattleEngine();
  var s = engine.start(a, b, seed: seed);

  var guard = 0;
  while (!s.isOver && guard++ < 200) {
    final actor = s.activeSide == SideId.a ? 'A' : 'B';
    final actions = engine.botActions(s);
    for (final act in actions) {
      s = engine.apply(s, act);
    }
    s = engine.endTurn(s);
    final av = s.sideA.creaturesInPlay.length;
    final bv = s.sideB.creaturesInPlay.length;
    final ar = s.sideA.remainingCreatureCount;
    final br = s.sideB.remainingCreatureCount;
    stdout.writeln('turno ${s.turn.toString().padLeft(2)} (jogou $actor, ${actions.length} ações) '
        '| A: $av em jogo / $ar vivas · B: $bv em jogo / $br vivas');
  }

  stdout.writeln('\n=== FIM ===');
  final w = s.winner;
  stdout.writeln(w == null
      ? 'Sem vencedor (guard/limite atingido em ${s.turn} turnos).'
      : 'Vencedor: Lado ${w == SideId.a ? "A" : "B"} no turno ${s.turn}.');
}
