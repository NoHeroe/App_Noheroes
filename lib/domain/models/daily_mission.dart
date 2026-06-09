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

  /// Época 2 (ADR-0024) — uuid do jogador (auth.users.id). Era `int` no
  /// modelo Drift; PK de LINHA ([id]) continua `int` (bigserial).
  final String playerId;
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

  /// Sprint 3.3 Etapa 2.1c-β — `true` quando o rollover detectou modo
  /// automático ativo + 100% em todas as sub-tarefas e fechou via
  /// `applyAutoCompleted`. Confirmações manuais (`confirmCompletion`)
  /// ou parciais (`applyPartialReward`) sempre `false`.
  final bool wasAutoConfirmed;

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
    this.wasAutoConfirmed = false,
  });

  DailyMission copyWith({
    List<DailySubTaskInstance>? subTarefas,
    DailyMissionStatus? status,
    DateTime? completedAt,
    bool? rewardClaimed,
    bool? wasAutoConfirmed,
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
        wasAutoConfirmed: wasAutoConfirmed ?? this.wasAutoConfirmed,
      );

  /// `true` quando todas as sub-tarefas atingiram a meta (`progressoAtual
  /// >= escalaAlvo`). Usado pelo `DailyMissionRolloverService` pra
  /// decidir auto-confirm. Mais robusto que `completedSubCount` —
  /// independe do flag `completed` (que pode estar dessincronizado em
  /// caminhos legacy).
  bool get allSubsAtTarget =>
      subTarefas.isNotEmpty &&
      subTarefas.every((s) =>
          s.escalaAlvo > 0 && s.progressoAtual >= s.escalaAlvo);

  /// Época 2 (ADR-0024) — constrói a partir de uma row do Postgres
  /// (chaves snake_case via PostgREST/Supabase). `player_id` é uuid
  /// (String). `created_at`/`completed_at` são bigint em ms epoch.
  /// `sub_tarefas_json` é TEXT contendo um array JSON.
  factory DailyMission.fromMap(Map<String, dynamic> m) => DailyMission(
        id: (m['id'] as num).toInt(),
        playerId: m['player_id'] as String,
        data: m['data'] as String,
        modalidade: MissionCategoryCodec.fromStorage(m['modalidade'] as String),
        subCategoria: m['sub_categoria'] as String?,
        tituloKey: m['titulo_key'] as String,
        tituloResolvido: m['titulo_resolvido'] as String,
        quoteResolvida: m['quote_resolvida'] as String,
        subTarefas: decodeSubTarefas(m['sub_tarefas_json'] as String),
        status: DailyMissionStatusCodec.fromStorage(m['status'] as String),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((m['created_at'] as num).toInt()),
        completedAt: m['completed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (m['completed_at'] as num).toInt()),
        rewardClaimed: (m['reward_claimed'] as bool?) ?? false,
        wasAutoConfirmed: (m['was_auto_confirmed'] as bool?) ?? false,
      );

  /// Serializa pra INSERT no Postgres (snake_case). `id` é omitido
  /// (bigserial gerado pelo banco). `created_at`/`completed_at` em ms.
  Map<String, dynamic> toInsertMap() => {
        'player_id': playerId,
        'data': data,
        'modalidade': modalidade.storage,
        'sub_categoria': subCategoria,
        'titulo_key': tituloKey,
        'titulo_resolvido': tituloResolvido,
        'quote_resolvida': quoteResolvida,
        'sub_tarefas_json': encodeSubTarefas(),
        'status': status.storage,
        'created_at': createdAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'reward_claimed': rewardClaimed,
        'was_auto_confirmed': wasAutoConfirmed,
      };

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
