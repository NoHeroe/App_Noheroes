import 'dart:convert';

import '../enums/mission_category.dart';
import 'daily_mission_status.dart';
import 'daily_sub_task_instance.dart';

/// Sprint 3.2 Etapa 1.2 — uma missão diária com 3 sub-tarefas.
///
/// Persiste em `daily_missions` (schema 27). [subTarefas] é serializada
/// pra TEXT em `sub_tarefas_json` — cardinalidade fixa em 3 por missão.
class DailyMission {
  final int id;
  final int playerId;
  final String data; // YYYY-MM-DD
  final MissionCategory modalidade;

  /// `null` quando [modalidade] == Vitalismo.
  final String? subCategoria;

  final String tituloKey;
  final String tituloResolvido;
  final String quoteResolvida;
  final List<DailySubTaskInstance> subTarefas;
  final DailyMissionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool rewardClaimed;

  const DailyMission({
    required this.id,
    required this.playerId,
    required this.data,
    required this.modalidade,
    required this.subCategoria,
    required this.tituloKey,
    required this.tituloResolvido,
    required this.quoteResolvida,
    required this.subTarefas,
    required this.status,
    required this.createdAt,
    required this.completedAt,
    required this.rewardClaimed,
  });

  DailyMission copyWith({
    List<DailySubTaskInstance>? subTarefas,
    DailyMissionStatus? status,
    DateTime? completedAt,
    bool? rewardClaimed,
  }) =>
      DailyMission(
        id: id,
        playerId: playerId,
        data: data,
        modalidade: modalidade,
        subCategoria: subCategoria,
        tituloKey: tituloKey,
        tituloResolvido: tituloResolvido,
        quoteResolvida: quoteResolvida,
        subTarefas: subTarefas ?? this.subTarefas,
        status: status ?? this.status,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
        rewardClaimed: rewardClaimed ?? this.rewardClaimed,
      );

  /// Serializa só as sub-tarefas (campo TEXT no schema).
  String encodeSubTarefas() =>
      jsonEncode(subTarefas.map((s) => s.toJson()).toList());

  static List<DailySubTaskInstance> decodeSubTarefas(String raw) {
    final decoded = jsonDecode(raw) as List;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(DailySubTaskInstance.fromJson)
        .toList();
  }

  /// Quantas sub-tarefas estão `completed=true`. Usado pelo
  /// [DailyMissionRolloverService] pra decidir partial vs failed.
  int get completedSubCount => subTarefas.where((s) => s.completed).length;

  /// `true` quando todas as sub-tarefas ultrapassaram a meta
  /// (progresso > escalaAlvo). Habilita o bônus de excedência.
  bool get allExceeded =>
      subTarefas.isNotEmpty &&
      subTarefas.every((s) => s.progressoAtual > s.escalaAlvo);
}
