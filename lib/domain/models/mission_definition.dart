import '../../core/utils/guild_rank.dart';
import '../enums/mission_category.dart';
import '../enums/mission_modality.dart';
import '../enums/mission_tab_origin.dart';
import '../enums/rank_codec.dart';
import 'mission_requirement.dart';
import 'reward_declared.dart';

/// Sprint 3.1 Bloco 3 — entrada declarativa de uma missão num catálogo
/// JSON (`missions_daily.json`, `missions_class.json`, etc.).
///
/// Este é o **template** lido de disco (ou depois do Supabase). Quando o
/// `MissionAssignmentService` (Bloco 14) assigna a missão a um jogador,
/// cria uma linha em `player_mission_progress` carregando estes dados +
/// estado (current_value, started_at, etc.).
///
/// Ver `MissionProgress` pro wrapper da row persistida.
class MissionDefinition {
  /// Chave estável e única dentro do catálogo (ex: `DAILY_PUSHUPS_E`).
  final String key;

  final String title;
  final String description;
  final MissionModality modality;
  final MissionCategory category;
  final MissionTabOrigin tabOrigin;
  final GuildRank rank;

  /// Valor alvo para a família `real`/`individual`/`internal` simples.
  /// Em missões `mixed`, o target agregado é a soma dos requirements —
  /// este campo pode vir como 1 (representa "todos requirements").
  final int targetValue;

  final RewardDeclared reward;

  /// Citação temática (itálico na UI do card expandido). Opcional.
  final String? quote;

  /// Só para família `mixed` — sub-tarefas.
  final List<MissionRequirement> requirements;

  const MissionDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.modality,
    required this.category,
    required this.tabOrigin,
    required this.rank,
    required this.targetValue,
    required this.reward,
    this.quote,
    this.requirements = const [],
  });

  factory MissionDefinition.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) {
      throw const FormatException("MissionDefinition.key ausente ou vazio");
    }
    final title = json['title'];
    if (title is! String || title.isEmpty) {
      throw FormatException("MissionDefinition.title ausente em '$key'");
    }
    final description = json['description'];
    if (description is! String) {
      throw FormatException(
          "MissionDefinition.description ausente em '$key'");
    }
    final modalityStr = json['modality'];
    if (modalityStr is! String) {
      throw FormatException(
          "MissionDefinition.modality ausente em '$key'");
    }
    final categoryStr = json['category'];
    if (categoryStr is! String) {
      throw FormatException(
          "MissionDefinition.category ausente em '$key'");
    }
    final tabStr = json['tab_origin'];
    if (tabStr is! String) {
      throw FormatException(
          "MissionDefinition.tab_origin ausente em '$key'");
    }
    final rankStr = json['rank'];
    if (rankStr is! String) {
      throw FormatException("MissionDefinition.rank ausente em '$key'");
    }
    final target = json['target_value'];
    if (target is! int || target <= 0) {
      throw FormatException(
          "MissionDefinition.target_value inválido ($target) em '$key'");
    }
    final rewardJson = json['reward'];
    if (rewardJson is! Map<String, dynamic>) {
      throw FormatException(
          "MissionDefinition.reward ausente ou malformada em '$key'");
    }
    final modality = MissionModalityCodec.fromStorage(modalityStr);
    final requirements = ((json['requirements'] as List?) ?? const [])
        .map((e) =>
            MissionRequirement.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    if (modality == MissionModality.mixed && requirements.isEmpty) {
      throw FormatException(
          "MissionDefinition '$key' é mixed mas não declara requirements");
    }
    return MissionDefinition(
      key: key,
      title: title,
      description: description,
      modality: modality,
      category: MissionCategoryCodec.fromStorage(categoryStr),
      tabOrigin: MissionTabOriginCodec.fromStorage(tabStr),
      rank: RankCodec.fromStorage(rankStr),
      targetValue: target,
      reward: RewardDeclared.fromJson(rewardJson),
      quote: json['quote'] as String?,
      requirements: requirements,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'description': description,
        'modality': modality.storage,
        'category': category.storage,
        'tab_origin': tabOrigin.storage,
        'rank': RankCodec.storage(rank),
        'target_value': targetValue,
        'reward': reward.toJson(),
        if (quote != null) 'quote': quote,
        if (requirements.isNotEmpty)
          'requirements':
              requirements.map((r) => r.toJson()).toList(growable: false),
      };
}
