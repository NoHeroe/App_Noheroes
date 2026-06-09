import '../../core/utils/guild_rank.dart';
import '../enums/mission_modality.dart';
import '../enums/mission_tab_origin.dart';
import '../enums/rank_codec.dart';
import 'reward_declared.dart';

/// Status calculado de [MissionProgress] — inferido dos timestamps
/// `completedAt` / `failedAt`.
enum MissionProgressStatus { pending, inProgress, completed, partial, failed }

/// Sprint 3.1 Bloco 3 — domain model da row `player_mission_progress`.
///
/// Wrappa a data class gerada pelo Drift (`PlayerMissionProgressData`)
/// convertendo primitivos brutos em tipos fortes:
///
///   - `completedAt` / `failedAt` / `startedAt`: `int?` ms → `DateTime?`
///   - `modality`: `String` → [MissionModality]
///   - `tabOrigin`: `String` → [MissionTabOrigin]
///   - `rank`: `String` → [GuildRank]
///   - `rewardJson`: `String` → [RewardDeclared]
///
/// A construção é via [MissionProgress.fromJson] (mapa simples com os
/// campos nomeados igual aos da tabela em snake_case) ou
/// [MissionProgress.fromRow] (diretamente de uma
/// `PlayerMissionProgressData`, útil pro Bloco 4 no Repository).
///
/// Status é calculado em [status] a partir dos timestamps:
///   - `failedAt != null` → `failed`
///   - `completedAt != null && currentValue == targetValue` → `completed`
///   - `completedAt != null && currentValue < targetValue` → `partial`
///   - `currentValue > 0 && completedAt == null && failedAt == null` → `inProgress`
///   - caso contrário → `pending`
class MissionProgress {
  final int id;
  final int playerId;
  final String missionKey;
  final MissionModality modality;
  final MissionTabOrigin tabOrigin;
  final GuildRank rank;
  final int targetValue;
  final int currentValue;
  final RewardDeclared reward;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final bool rewardClaimed;
  final String metaJson;

  const MissionProgress({
    required this.id,
    required this.playerId,
    required this.missionKey,
    required this.modality,
    required this.tabOrigin,
    required this.rank,
    required this.targetValue,
    required this.currentValue,
    required this.reward,
    required this.startedAt,
    required this.rewardClaimed,
    required this.metaJson,
    this.completedAt,
    this.failedAt,
  });

  MissionProgressStatus get status {
    if (failedAt != null) return MissionProgressStatus.failed;
    if (completedAt != null) {
      return currentValue >= targetValue
          ? MissionProgressStatus.completed
          : MissionProgressStatus.partial;
    }
    if (currentValue > 0) return MissionProgressStatus.inProgress;
    return MissionProgressStatus.pending;
  }

  double get progressPct =>
      targetValue <= 0 ? 0.0 : (currentValue / targetValue);

  /// Época 2 full-online (ADR-0024) — constrói o model a partir de uma row
  /// Supabase (Map snake_case já desserializado pelo PostgREST).
  ///
  /// Diferenças vs [fromJson] (que veio do mundo Drift int-playerId):
  ///   - `player_id` chega como **uuid (String)**; é normalizado pra int
  ///     determinístico via [_playerIdToInt] enquanto o campo `playerId`
  ///     do model continuar `int` (Stage A não migrou esta classe — ver
  ///     'unresolved' no relatório da Fase 3).
  ///   - `reward_claimed` chega como `bool` nativo (não int 0/1).
  ///   - timestamps continuam bigint ms-epoch (`int`).
  factory MissionProgress.fromMap(Map<String, dynamic> row) {
    final patched = Map<String, dynamic>.from(row);
    patched['player_id'] = _playerIdToInt(row['player_id']);
    if (row['reward_claimed'] is bool) {
      patched['reward_claimed'] = row['reward_claimed'] as bool;
    }
    return MissionProgress.fromJson(patched);
  }

  /// Ponte temporária uuid(String) -> int pro campo `playerId` legacy.
  /// `int` já vem cru; uuid usa hashCode estável da string. NÃO é o id
  /// real — o id canônico do jogador é o uuid. Ver 'unresolved'.
  static int _playerIdToInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? raw.hashCode;
    throw FormatException("MissionProgress.player_id inválido ($raw)");
  }

  factory MissionProgress.fromJson(Map<String, dynamic> json) {
    int? parseTs(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      throw FormatException("timestamp inválido: $v");
    }

    final id = json['id'];
    if (id is! int) {
      throw FormatException("MissionProgress.id inválido ($id)");
    }
    final playerId = json['player_id'];
    if (playerId is! int) {
      throw FormatException(
          "MissionProgress.player_id inválido ($playerId) em id=$id");
    }
    final missionKey = json['mission_key'];
    if (missionKey is! String || missionKey.isEmpty) {
      throw FormatException("MissionProgress.mission_key ausente em id=$id");
    }
    final modalityStr = json['modality'];
    if (modalityStr is! String) {
      throw FormatException(
          "MissionProgress.modality ausente em id=$id");
    }
    final tabStr = json['tab_origin'];
    if (tabStr is! String) {
      throw FormatException(
          "MissionProgress.tab_origin ausente em id=$id");
    }
    final rankStr = json['rank'];
    if (rankStr is! String) {
      throw FormatException("MissionProgress.rank ausente em id=$id");
    }
    final targetValue = json['target_value'];
    if (targetValue is! int) {
      throw FormatException(
          "MissionProgress.target_value inválido ($targetValue) em id=$id");
    }
    final currentValue = (json['current_value'] as int?) ?? 0;
    final rewardJsonStr = json['reward_json'];
    if (rewardJsonStr is! String) {
      throw FormatException(
          "MissionProgress.reward_json ausente em id=$id");
    }
    final startedAt = parseTs(json['started_at']);
    if (startedAt == null) {
      throw FormatException(
          "MissionProgress.started_at ausente em id=$id");
    }
    final completedAt = parseTs(json['completed_at']);
    final failedAt = parseTs(json['failed_at']);

    return MissionProgress(
      id: id,
      playerId: playerId,
      missionKey: missionKey,
      modality: MissionModalityCodec.fromStorage(modalityStr),
      tabOrigin: MissionTabOriginCodec.fromStorage(tabStr),
      rank: RankCodec.fromStorage(rankStr),
      targetValue: targetValue,
      currentValue: currentValue,
      reward: RewardDeclared.fromJsonString(rewardJsonStr),
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAt),
      completedAt: completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(completedAt),
      failedAt: failedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(failedAt),
      rewardClaimed: (json['reward_claimed'] as bool?) ??
          ((json['reward_claimed'] as int?) ?? 0) == 1,
      metaJson: (json['meta_json'] as String?) ?? '{}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'mission_key': missionKey,
        'modality': modality.storage,
        'tab_origin': tabOrigin.storage,
        'rank': RankCodec.storage(rank),
        'target_value': targetValue,
        'current_value': currentValue,
        'reward_json': reward.toJsonString(),
        'started_at': startedAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'failed_at': failedAt?.millisecondsSinceEpoch,
        'reward_claimed': rewardClaimed,
        'meta_json': metaJson,
      };
}
