/// Sprint 3.1 Bloco 3 — estilo de missão preferido (DESIGN_DOC §7,
/// pergunta P3 do quiz).
///
/// Controla qual família de modalidade predomina nas missões diárias
/// assignadas:
///
/// - `real`: só missões com marcação manual (flexões, água, leitura física)
/// - `internal`: só missões detectadas por EventBus (forjar, subir nível)
/// - `mixed`: combina 50/50
///
/// É um **subset** de [MissionModality] (não inclui `individual` — essa
/// é sempre opcional, criada pelo jogador em Extras, independe de P3).
///
/// | Enum       | Storage      | Display (PT-BR)  |
/// |------------|--------------|------------------|
/// | `real`     | `'real'`     | Tarefas reais    |
/// | `internal` | `'internal'` | Sistema interno  |
/// | `mixed`    | `'mixed'`    | Misto            |
enum MissionStyle { real, internal, mixed }

extension MissionStyleCodec on MissionStyle {
  String get storage => name;

  String get display => switch (this) {
        MissionStyle.real => 'Tarefas reais',
        MissionStyle.internal => 'Sistema interno',
        MissionStyle.mixed => 'Misto',
      };

  static MissionStyle? fromString(String value) {
    for (final s in MissionStyle.values) {
      if (s.name == value) return s;
    }
    return null;
  }

  static MissionStyle fromStorage(String value) {
    final s = fromString(value);
    if (s == null) {
      throw FormatException("Invalid MissionStyle '$value'");
    }
    return s;
  }
}
