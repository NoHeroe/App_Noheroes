/// Sprint 3.2 Etapa 1.2 — status de uma missão diária.
///
/// Transições:
/// - `pending` → `completed` (3/3 sub-tarefas atingiram a escala alvo)
/// - `pending` → `partial` (rollover; 1-2 sub-tarefas completas; reward parcial)
/// - `pending` → `failed` (rollover; 0 sub-tarefas; sem reward)
enum DailyMissionStatus {
  pending,
  partial,
  completed,
  failed,
}

extension DailyMissionStatusCodec on DailyMissionStatus {
  String get storage => name;

  static DailyMissionStatus fromStorage(String value) {
    for (final s in DailyMissionStatus.values) {
      if (s.name == value) return s;
    }
    throw FormatException("Invalid DailyMissionStatus '$value'");
  }
}
