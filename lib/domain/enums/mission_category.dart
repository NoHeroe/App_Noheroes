/// Sprint 3.1 Bloco 3 — 4 categorias adaptadas de missão (CONTEXT Rodada 1
/// Q1). Substitui os 4 valores legacy (physical/mental/spiritual/order) —
/// "Ordem" foi consolidada em `mental` e `vitalismo` passa a ser a 4ª
/// categoria (disciplina conectiva entre pilares).
///
/// Aplicadas em:
///   - `missions_*.json` → campo `category`
///   - `player_individual_missions.category` (escolha do jogador ao criar)
///   - `MissionPreferences.primaryFocus`
///   - `SoulslikeBalance.categoryMultipliers` (ADR 0013)
///
/// | Enum        | Storage       | Display (PT-BR) | Multiplier reward |
/// |-------------|---------------|-----------------|-------------------|
/// | `fisico`    | `'fisico'`    | Físico          | 1.0               |
/// | `mental`    | `'mental'`    | Mental          | 1.1               |
/// | `espiritual`| `'espiritual'`| Espiritual      | 1.2               |
/// | `vitalismo` | `'vitalismo'` | Vitalismo       | 1.15              |
///
/// Storage em PT-BR por alinhamento com a narrativa do app (vs. modality
/// que usa EN por universalidade das famílias técnicas).
enum MissionCategory { fisico, mental, espiritual, vitalismo }

extension MissionCategoryCodec on MissionCategory {
  String get storage => name;

  String get display => switch (this) {
        MissionCategory.fisico => 'Físico',
        MissionCategory.mental => 'Mental',
        MissionCategory.espiritual => 'Espiritual',
        MissionCategory.vitalismo => 'Vitalismo',
      };

  /// Multiplicador de reward por categoria (ADR 0013). Usado pelo
  /// `MissionBalancerService` (Bloco 5/11) no cálculo de missões
  /// individuais.
  double get rewardMultiplier => switch (this) {
        MissionCategory.fisico => 1.0,
        MissionCategory.mental => 1.1,
        MissionCategory.espiritual => 1.2,
        MissionCategory.vitalismo => 1.15,
      };

  /// Tolerante — retorna `null` se [value] não for canônico.
  static MissionCategory? fromString(String value) {
    for (final c in MissionCategory.values) {
      if (c.name == value) return c;
    }
    return null;
  }

  /// Estrito — lança [FormatException] se inválido. Usar em `fromJson`.
  static MissionCategory fromStorage(String value) {
    final c = fromString(value);
    if (c == null) {
      throw FormatException("Invalid MissionCategory '$value'");
    }
    return c;
  }
}
