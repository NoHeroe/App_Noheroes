/// Sprint 3.2 Etapa 1.1 — tipos de unidade pra sub-tarefas das missões diárias.
///
/// Mapeamento canônico (.md → enum):
/// - `x`           → contagem
/// - `min`         → tempoMinutos
/// - `s`           → tempoSegundos
/// - `h`           → tempoHoras
/// - `km`          → distanciaKm
/// - `ml`          → volumeMl
/// - `g`           → pesoG
/// - `bool`        → boolean (X/1)
/// - `pg/pal/xícara/porção` → porcao (genérico contável)
enum DailyUnitType {
  contagem,
  tempoMinutos,
  tempoSegundos,
  tempoHoras,
  distanciaKm,
  volumeMl,
  pesoG,
  boolean,
  porcao,
}

extension DailyUnitTypeCodec on DailyUnitType {
  String get storage => name;

  static DailyUnitType fromStorage(String value) {
    for (final t in DailyUnitType.values) {
      if (t.name == value) return t;
    }
    throw FormatException("Invalid DailyUnitType '$value'");
  }
}
