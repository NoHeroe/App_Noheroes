import 'app_event.dart';

/// Sprint 3.1 Bloco 2 — eventos de seleção de classe e facção.

/// Classe escolhida pelo jogador no nível 5.
///
/// **Hook canônico pra calibração** (Bloco 9): `TutorialManager`
/// (`phase13_mission_calibration`) escuta esse evento pra navegar pra
/// `/mission_calibration`. Também dispara assign das missões diárias de
/// classe pelo `QuestAdmissionService` refatorado (Bloco 7).
class ClassSelected extends AppEvent {
  final int playerId;
  final String classId;

  ClassSelected({
    required this.playerId,
    required this.classId,
    super.at,
  });

  @override
  String toString() =>
      'ClassSelected(player=$playerId, class=$classId)';
}

/// Jogador entrou numa facção (admissão aprovada em `active_faction_quests`
/// ou migração de `pending:X` pra `X` em `players.faction_type`).
class FactionJoined extends AppEvent {
  final int playerId;
  final String factionId;

  FactionJoined({
    required this.playerId,
    required this.factionId,
    super.at,
  });

  @override
  String toString() =>
      'FactionJoined(player=$playerId, faction=$factionId)';
}

/// Jogador saiu de uma facção (acessível a partir do nível 7 conforme plano
/// §Admissão). Pode cascatear em `FactionJoined` se troca imediata.
class FactionLeft extends AppEvent {
  final int playerId;
  final String factionId;

  FactionLeft({
    required this.playerId,
    required this.factionId,
    super.at,
  });

  @override
  String toString() => 'FactionLeft(player=$playerId, faction=$factionId)';
}
