import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/vitalism_tree_layout.dart';

void main() {
  group('VitalismTreeLayout', () {
    test('diamante tem exatamente 5 nós', () {
      expect(VitalismTreeLayout.diamond.length, 5);
    });

    test('índices são 0..4 em ordem', () {
      expect(
        VitalismTreeLayout.diamond.map((n) => n.index).toList(),
        [0, 1, 2, 3, 4],
      );
    });

    test('requisitos de nível são 25, 30, 35, 40, 45', () {
      expect(
        VitalismTreeLayout.diamond.map((n) => n.requiredLevel).toList(),
        [25, 30, 35, 40, 45],
      );
    });

    test('nodeId derivado inclui vitalismId + index', () {
      final node0 = VitalismTreeLayout.diamond[0];
      expect(node0.nodeIdFor('shadow'), 'shadow_node_0');
      expect(VitalismTreeLayout.diamond[4].nodeIdFor('life'), 'life_node_4');
    });

    test('edges conectam apenas índices válidos do diamante', () {
      const max = 4;
      for (final (a, b) in VitalismTreeLayout.edges) {
        expect(a >= 0 && a <= max, isTrue);
        expect(b >= 0 && b <= max, isTrue);
      }
    });

    test('topologia do diamante (5 edges: 0-1, 0-2, 1-3, 2-3, 3-4)', () {
      expect(VitalismTreeLayout.edges.toSet(), {
        (0, 1), (0, 2), (1, 3), (2, 3), (3, 4),
      });
    });
  });
}
