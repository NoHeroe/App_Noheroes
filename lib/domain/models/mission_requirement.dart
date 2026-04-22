/// Sprint 3.1 Bloco 3 — sub-tarefa de uma missão da família `mixed`
/// (ADR 0014 §Família 4).
///
/// Uma missão mista declara um array de requirements, cada um
/// independente. A missão completa quando **todos** os requirements
/// estão concluídos. Cada requirement pode ser `internal` (EventBus) ou
/// `real` (marcação manual pelo jogador):
///
/// ```json
/// {
///   "requirements": [
///     {"type": "internal", "event": "ItemCrafted", "target": 3},
///     {"type": "real", "name": "Meditar", "target": 15, "unit": "min"}
///   ]
/// }
/// ```
///
/// Este model apenas **declara** o requirement — o estado atual
/// (current_value de cada) vive em
/// `PlayerMissionProgress.metaJson['requirements']` (Bloco 6 — strategy
/// mista preenche).
class MissionRequirement {
  /// `'internal'` ou `'real'` (strings pra evitar import recíproco com
  /// MissionModality; validado na construção).
  final String type;

  /// Só quando [type] == 'internal' — nome do evento do EventBus que
  /// incrementa o contador (ex: `ItemCrafted`).
  final String? event;

  /// Só quando [type] == 'real' — nome exibido ao jogador no card
  /// (ex: 'Meditar', 'Beber água').
  final String? name;

  /// Só quando [type] == 'real' — unidade de medida ('min', 'L', 'rep').
  final String? unit;

  final int target;

  const MissionRequirement({
    required this.type,
    required this.target,
    this.event,
    this.name,
    this.unit,
  });

  factory MissionRequirement.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type != 'internal' && type != 'real') {
      throw FormatException("MissionRequirement.type inválido: '$type'");
    }
    final target = json['target'];
    if (target is! int || target <= 0) {
      throw FormatException(
          "MissionRequirement.target inválido ($target) em type=$type");
    }
    final event = json['event'] as String?;
    final name = json['name'] as String?;
    if (type == 'internal' && (event == null || event.isEmpty)) {
      throw const FormatException(
          "MissionRequirement type='internal' precisa de campo 'event'");
    }
    if (type == 'real' && (name == null || name.isEmpty)) {
      throw const FormatException(
          "MissionRequirement type='real' precisa de campo 'name'");
    }
    return MissionRequirement(
      type: type as String,
      target: target,
      event: event,
      name: name,
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'target': target,
        if (event != null) 'event': event,
        if (name != null) 'name': name,
        if (unit != null) 'unit': unit,
      };
}
