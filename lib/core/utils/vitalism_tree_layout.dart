// Layout canônico fictício das árvores de Vitalismo Único no Sprint 1.2.
// 5 nós em diamante: entry → 2 ramos → convergência → ponta final.
// Placeholders — habilidades reais entram em sprints de conteúdo após engine.

class TreeNodeSpec {
  final int index;        // 0..4
  final int row;          // linha vertical no diamante (0=topo, 3=base)
  final int col;          // coluna (0=esq, 1=centro, 2=dir)
  final int requiredLevel;

  const TreeNodeSpec({
    required this.index,
    required this.row,
    required this.col,
    required this.requiredLevel,
  });

  String nodeIdFor(String vitalismId) => '${vitalismId}_node_$index';
  String get placeholderName => 'Nó Vitalista ${index + 1}';
  static const String placeholderDescription =
      'Habilidade a ser definida em sprint de conteúdo.';
}

class VitalismTreeLayout {
  VitalismTreeLayout._();

  // Layout fixo do diamante. Requisitos progressivos (25→45).
  //
  //         [0]  (25)
  //        /   \
  //      [1]   [2]  (30, 35)
  //        \   /
  //         [3]  (40)
  //          |
  //         [4]  (45)
  static const List<TreeNodeSpec> diamond = [
    TreeNodeSpec(index: 0, row: 0, col: 1, requiredLevel: 25),
    TreeNodeSpec(index: 1, row: 1, col: 0, requiredLevel: 30),
    TreeNodeSpec(index: 2, row: 1, col: 2, requiredLevel: 35),
    TreeNodeSpec(index: 3, row: 2, col: 1, requiredLevel: 40),
    TreeNodeSpec(index: 4, row: 3, col: 1, requiredLevel: 45),
  ];

  // Conexões entre nós (pairs of indices).
  static const List<(int, int)> edges = [
    (0, 1),
    (0, 2),
    (1, 3),
    (2, 3),
    (3, 4),
  ];
}
