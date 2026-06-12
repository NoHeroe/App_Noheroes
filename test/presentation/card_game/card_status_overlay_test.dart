// Lote 4 — guarda do builder de overlay de status: sem status = null (carta
// limpa); com qualquer status ativo = não-null.
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';
import 'package:noheroes_app/presentation/card_game/widgets/game_card_face.dart';

import '../../domain/card_game/fixtures.dart';

CreatureInPlay _c({
  List<String> abilities = const [],
  int bleedStacks = 0,
  bool poisoned = false,
  int diseaseStacks = 0,
  bool stunned = false,
  bool entangled = false,
  int desmoralizadoMelee = 0,
}) =>
    CreatureInPlay(
      card: creature(id: 'x', hp: 10, abilities: abilities),
      currentHp: 10,
      lane: 0,
      bleedStacks: bleedStacks,
      poisoned: poisoned,
      diseaseStacks: diseaseStacks,
      stunned: stunned,
      entangled: entangled,
      desmoralizadoMelee: desmoralizadoMelee,
    );

void main() {
  group('buildCardStatusOverlay', () {
    test('sem status nem armadura → null (carta limpa)', () {
      expect(buildCardStatusOverlay(_c()), isNull);
    });

    test('armadura inata (Escudo) → overlay presente', () {
      expect(buildCardStatusOverlay(_c(abilities: ['Escudo'])), isNotNull);
    });

    test('cada status ativo gera overlay', () {
      expect(buildCardStatusOverlay(_c(bleedStacks: 1)), isNotNull);
      expect(buildCardStatusOverlay(_c(poisoned: true)), isNotNull);
      expect(buildCardStatusOverlay(_c(diseaseStacks: 2)), isNotNull);
      expect(buildCardStatusOverlay(_c(stunned: true)), isNotNull);
      expect(buildCardStatusOverlay(_c(entangled: true)), isNotNull);
      expect(buildCardStatusOverlay(_c(desmoralizadoMelee: 1)), isNotNull);
    });
  });
}
