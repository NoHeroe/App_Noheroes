/// Sprint 3.1 Bloco 3 — intensidade do perfil de missões (DESIGN_DOC §7,
/// pergunta P2 do quiz de calibração).
///
/// Afeta o pool de missões diárias assignadas: `light` restringe rank
/// máximo, `heavy` libera mais missões/dia de rank variado, `adaptive`
/// deixa o `MissionAssignmentService` (Bloco 14) ajustar sozinho com base
/// em performance.
///
/// | Enum       | Storage      | Display (PT-BR)         |
/// |------------|--------------|-------------------------|
/// | `light`    | `'light'`    | Leve                    |
/// | `medium`   | `'medium'`   | Médio                   |
/// | `heavy`    | `'heavy'`    | Pesado                  |
/// | `adaptive` | `'adaptive'` | Adaptativo              |
enum Intensity { light, medium, heavy, adaptive }

extension IntensityCodec on Intensity {
  String get storage => name;

  String get display => switch (this) {
        Intensity.light => 'Leve',
        Intensity.medium => 'Médio',
        Intensity.heavy => 'Pesado',
        Intensity.adaptive => 'Adaptativo',
      };

  static Intensity? fromString(String value) {
    for (final i in Intensity.values) {
      if (i.name == value) return i;
    }
    return null;
  }

  static Intensity fromStorage(String value) {
    final i = fromString(value);
    if (i == null) {
      throw FormatException("Invalid Intensity '$value'");
    }
    return i;
  }
}
