import '../enums/mission_category.dart';
import 'reward_declared.dart';

/// Frequência de repetição declarada pelo jogador ao criar a missão.
enum IndividualMissionFrequency { daily, weekly, monthly, oneShot }

extension IndividualMissionFrequencyCodec on IndividualMissionFrequency {
  String get storage => switch (this) {
        IndividualMissionFrequency.daily => 'daily',
        IndividualMissionFrequency.weekly => 'weekly',
        IndividualMissionFrequency.monthly => 'monthly',
        IndividualMissionFrequency.oneShot => 'one-shot',
      };

  static IndividualMissionFrequency? fromString(String value) {
    for (final f in IndividualMissionFrequency.values) {
      if (f.storage == value) return f;
    }
    return null;
  }

  static IndividualMissionFrequency fromStorage(String value) {
    final f = fromString(value);
    if (f == null) {
      throw FormatException("Invalid IndividualMissionFrequency '$value'");
    }
    return f;
  }
}

/// Sprint 3.1 Bloco 4 — domain model de `player_individual_missions`.
///
/// Gap identificado no planejamento do Bloco 3 e preenchido aqui junto do
/// Repository que o consome. Mesmo padrão dos demais models do Bloco 3:
/// fromJson/toJson, FormatException nos enums, fromRow helper pra row
/// Drift.
///
/// `intensityIndex` é 1..4 (leve, médio, pesado, extremo) — validado na
/// construção.
class IndividualMissionSpec {
  final int id;
  final int playerId;
  final String name;
  final String? description;
  final MissionCategory category;
  final int intensityIndex;
  final IndividualMissionFrequency frequency;
  final bool repeats;
  final RewardDeclared reward;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final int completionCount;
  final int failureCount;

  const IndividualMissionSpec({
    required this.id,
    required this.playerId,
    required this.name,
    required this.category,
    required this.intensityIndex,
    required this.frequency,
    required this.reward,
    required this.createdAt,
    this.description,
    this.repeats = true,
    this.deletedAt,
    this.completionCount = 0,
    this.failureCount = 0,
  });

  bool get isDeleted => deletedAt != null;

  factory IndividualMissionSpec.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw FormatException("IndividualMissionSpec.id inválido ($id)");
    }
    final playerId = json['player_id'];
    if (playerId is! int) {
      throw FormatException(
          "IndividualMissionSpec.player_id inválido em id=$id");
    }
    final name = json['name'];
    if (name is! String || name.isEmpty) {
      throw FormatException(
          "IndividualMissionSpec.name ausente ou vazio em id=$id");
    }
    final categoryStr = json['category'];
    if (categoryStr is! String) {
      throw FormatException(
          "IndividualMissionSpec.category ausente em id=$id");
    }
    final intensity = json['intensity_index'];
    if (intensity is! int || intensity < 1 || intensity > 4) {
      throw FormatException(
          "IndividualMissionSpec.intensity_index fora de 1..4 "
          "($intensity) em id=$id");
    }
    final freqStr = json['frequency'];
    if (freqStr is! String) {
      throw FormatException(
          "IndividualMissionSpec.frequency ausente em id=$id");
    }
    final rewardJson = json['reward_json'];
    if (rewardJson is! String) {
      throw FormatException(
          "IndividualMissionSpec.reward_json ausente em id=$id");
    }
    final createdAt = json['created_at'];
    if (createdAt is! int) {
      throw FormatException(
          "IndividualMissionSpec.created_at inválido em id=$id");
    }
    final deletedAt = json['deleted_at'];
    if (deletedAt != null && deletedAt is! int) {
      throw FormatException(
          "IndividualMissionSpec.deleted_at inválido ($deletedAt) em id=$id");
    }
    return IndividualMissionSpec(
      id: id,
      playerId: playerId,
      name: name,
      description: json['description'] as String?,
      category: MissionCategoryCodec.fromStorage(categoryStr),
      intensityIndex: intensity,
      frequency: IndividualMissionFrequencyCodec.fromStorage(freqStr),
      reward: RewardDeclared.fromJsonString(rewardJson),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      deletedAt: deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAt as int),
      repeats: (json['repeats'] as bool?) ?? true,
      completionCount: (json['completion_count'] as int?) ?? 0,
      failureCount: (json['failure_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'name': name,
        'description': description,
        'category': category.storage,
        'intensity_index': intensityIndex,
        'frequency': frequency.storage,
        'repeats': repeats,
        'reward_json': reward.toJsonString(),
        'created_at': createdAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
        'completion_count': completionCount,
        'failure_count': failureCount,
      };
}
