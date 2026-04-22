/// Sprint 3.1 Bloco 3 — 4 famílias de modalidade de missão (ADR 0014).
///
/// Mapeamento canônico dos valores persistidos em
/// `player_mission_progress.modality` e no JSON dos catálogos:
///
/// | Enum        | Storage      | Display (PT-BR) |
/// |-------------|--------------|-----------------|
/// | `internal`  | `'internal'` | Sistema         |
/// | `real`      | `'real'`     | Tarefa real     |
/// | `individual`| `'individual'`| Individual      |
/// | `mixed`     | `'mixed'`    | Mista           |
///
/// O display "Mista" é o termo PT-BR usado no DESIGN_DOC e UI; o storage
/// `'mixed'` alinha com os outros valores em inglês (`internal`, `real`,
/// `individual`).
enum MissionModality { internal, real, individual, mixed }

extension MissionModalityCodec on MissionModality {
  /// String canônica pra persistência (DB + JSON).
  String get storage => name;

  /// Label PT-BR pra UI.
  String get display => switch (this) {
        MissionModality.internal => 'Sistema',
        MissionModality.real => 'Tarefa real',
        MissionModality.individual => 'Individual',
        MissionModality.mixed => 'Mista',
      };

  /// Tolerante — retorna `null` se [value] não for um valor canônico.
  ///
  /// Use em *checks* defensivos (ex: "esse valor é uma modality válida?").
  /// Para parsing de JSON que precisa falhar rápido, use [fromStorage].
  static MissionModality? fromString(String value) {
    for (final m in MissionModality.values) {
      if (m.name == value) return m;
    }
    return null;
  }

  /// Estrito — lança [FormatException] com mensagem
  /// `"Invalid MissionModality '<value>'"` se [value] for inválido.
  ///
  /// Use em `fromJson` dos models. Um typo no JSON (ex: `"modality":
  /// "intrnal"`) derruba imediatamente com stack trace no campo, em vez
  /// de propagar `null` e quebrar 10 camadas depois em lugar não-óbvio.
  static MissionModality fromStorage(String value) {
    final m = fromString(value);
    if (m == null) {
      throw FormatException("Invalid MissionModality '$value'");
    }
    return m;
  }
}
