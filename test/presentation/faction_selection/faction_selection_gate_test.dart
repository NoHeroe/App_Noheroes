import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/presentation/faction_selection/faction_selection_gate.dart';

/// Hotfix pós-validação Sprint 3.4 — cobre BUG 2 (gate de nível na
/// seleção de facção) e BUG 4 (subtítulo redundante de nível 7).
void main() {
  group('FactionSelectionGate.canSelect (BUG 2)', () {
    test('facção ideológica bloqueada abaixo do nível 7', () {
      for (var lvl = 1; lvl < 7; lvl++) {
        expect(
          FactionSelectionGate.canSelect(factionId: 'error', level: lvl),
          isFalse,
          reason: 'nível $lvl não deveria poder entrar em facção ideológica',
        );
      }
    });

    test('facção ideológica liberada no nível 7 e acima', () {
      for (final lvl in [7, 8, 15, 50]) {
        expect(
          FactionSelectionGate.canSelect(
              factionId: 'sombras', level: lvl),
          isTrue,
          reason: 'nível $lvl deveria poder entrar em facção ideológica',
        );
      }
    });

    test('Facção Guilda (guild) ignora o gate de nível 7', () {
      // Guilda é gated por guild_rank (Aventureiro, lvl 6), não por este
      // gate. Mesmo nível 6 (ou abaixo) passa aqui — a restrição real
      // mora no filtro de _loadFactions (guild_rank != 'none').
      expect(
          FactionSelectionGate.canSelect(factionId: 'guild', level: 6),
          isTrue);
      expect(
          FactionSelectionGate.canSelect(factionId: 'guild', level: 1),
          isTrue);
    });
  });

  group('FactionSelectionGate.canSelectLoneWolf (ITEM 1)', () {
    test('Lobo Solitário bloqueado abaixo do nível 7', () {
      for (var lvl = 1; lvl < 7; lvl++) {
        expect(FactionSelectionGate.canSelectLoneWolf(lvl), isFalse,
            reason: 'nível $lvl não deveria liberar o Lobo Solitário');
      }
    });

    test('Lobo Solitário liberado no nível 7 e acima', () {
      for (final lvl in [7, 8, 20, 99]) {
        expect(FactionSelectionGate.canSelectLoneWolf(lvl), isTrue,
            reason: 'nível $lvl deveria liberar o Lobo Solitário');
      }
    });
  });

  group('FactionSelectionGate.headerSubtitle (ITEM 4 — neutro)', () {
    test('subtítulo é neutro e NÃO menciona nível em qualquer nível', () {
      for (final lvl in [5, 7, 8, 30]) {
        final msg = FactionSelectionGate.headerSubtitle(lvl);
        expect(msg, contains('escolha um lado'));
        expect(msg, isNot(contains('nível')),
            reason: 'nível $lvl não deveria mencionar nível no subtítulo');
        expect(msg, isNot(contains('atingiu')));
      }
    });
  });
}
