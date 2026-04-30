import '../services/achievement_trigger_types.dart';
import 'reward_declared.dart';

/// Sprint 3.1 Bloco 8 — entrada declarativa de uma conquista no catálogo
/// JSON (`assets/data/achievements.json`).
///
/// Schema espelha DESIGN_DOC_MISSOES §9. Triggers são sealed com 3 variantes
/// suportadas no MVP + fallback `UnknownAchievementTrigger` pra fail-safe
/// (tipos `sequence` e qualquer futuro vão parar no Unknown e o
/// `AchievementsService` ignora com warn, sem lançar). Bloco 14 amplia o
/// catálogo real e introduz `sequence`.
///
/// Rewards reusam `RewardDeclared` (Bloco 3) — mesma pipeline de resolver +
/// grant. `achievements_to_check` dentro de `reward` é o mecanismo de cascata
/// processado pelo `AchievementsService`.
class AchievementDefinition {
  /// Chave estável (ex: `ACH_FIRST_QUEST`). Mapeia 1-pra-1 com
  /// `player_achievements_completed.achievement_key`.
  final String key;
  final String name;
  final String description;

  /// Categoria livre (progression, meta, crafting, etc.). Bloco 8 não
  /// valida contra enum — Bloco 10 (UI) decide se precisa de enum.
  final String category;

  final AchievementTrigger trigger;

  /// Reward opcional. Se `null`, unlock emite `AchievementUnlocked` sem
  /// envolver `RewardGrantService`.
  final RewardDeclared? reward;

  /// `true` = conquista não aparece na UI até ser desbloqueada (Bloco 10
  /// respeita na listagem). Bloco 8 só carrega o campo; sem impacto em
  /// runtime neste bloco.
  final bool isSecret;

  /// Sprint 3.3 Etapa 2.1c-α — shell achievement: definição existe no
  /// catálogo mas mecânica subjacente ainda não está pronta. Service:
  ///   - Filtra fora dos caches `_dailyAchievements` / `_eventAchievements`
  ///   - Early-return em `_tryUnlock` (cobre cascata via
  ///     `achievementsToCheck`)
  /// UI (Etapa 2.5) pode renderizar como "?????" / "EM BREVE".
  final bool disabled;

  const AchievementDefinition({
    required this.key,
    required this.name,
    required this.description,
    required this.category,
    required this.trigger,
    this.reward,
    this.isSecret = false,
    this.disabled = false,
  });

  factory AchievementDefinition.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) {
      throw const FormatException("AchievementDefinition.key ausente ou vazio");
    }
    final name = json['name'];
    if (name is! String || name.isEmpty) {
      throw FormatException("AchievementDefinition.name ausente em '$key'");
    }
    final description = json['description'];
    if (description is! String) {
      throw FormatException(
          "AchievementDefinition.description ausente em '$key'");
    }
    final category = json['category'];
    if (category is! String || category.isEmpty) {
      throw FormatException(
          "AchievementDefinition.category ausente em '$key'");
    }
    final triggerJson = json['trigger'];
    if (triggerJson is! Map<String, dynamic>) {
      throw FormatException(
          "AchievementDefinition.trigger ausente ou malformada em '$key'");
    }
    final rewardJson = json['reward'];
    final RewardDeclared? reward = rewardJson == null
        ? null
        : RewardDeclared.fromJson(rewardJson as Map<String, dynamic>);
    return AchievementDefinition(
      key: key,
      name: name,
      description: description,
      category: category,
      trigger: AchievementTrigger.fromJson(triggerJson, achievementKey: key),
      reward: reward,
      isSecret: (json['is_secret'] as bool?) ?? false,
      disabled: (json['disabled'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'description': description,
        'category': category,
        'trigger': trigger.toJson(),
        if (reward != null) 'reward': reward!.toJson(),
        'is_secret': isSecret,
        if (disabled) 'disabled': disabled,
      };
}

/// Sealed hierarchy dos 4 tipos de trigger (3 MVP + 1 fallback).
///
/// `UnknownAchievementTrigger` captura qualquer `type` fora do MVP (ex:
/// `sequence`, ou typos) — o service ignora com log warning em vez de
/// lançar. Tradeoff: catálogo malformado não quebra runtime, mas também
/// não grita. Justifica-se pelo ciclo curto Bloco 8 → Bloco 14.
sealed class AchievementTrigger {
  const AchievementTrigger();

  factory AchievementTrigger.fromJson(
    Map<String, dynamic> json, {
    required String achievementKey,
  }) {
    final type = json['type'];
    if (type is! String || type.isEmpty) {
      throw FormatException(
          "AchievementTrigger.type ausente em '$achievementKey'");
    }
    // Sprint 3.3 Etapa 2.1b — qualquer tipo `daily_*` reconhecido vira
    // `DailyMissionTrigger`. Schema unificado: `target` (int>0) + `params`
    // opcional pra subtypes que precisam (sub_task_key, window, use_best).
    if (AchievementTriggerTypes.allDaily.contains(type)) {
      final target = json['target'];
      if (target is! int || target <= 0) {
        throw FormatException(
            "$type.target inválido ($target) em '$achievementKey'");
      }
      final paramsRaw = json['params'];
      Map<String, dynamic>? params;
      if (paramsRaw != null) {
        if (paramsRaw is! Map<String, dynamic>) {
          throw FormatException(
              "$type.params deve ser objeto em '$achievementKey'");
        }
        params = paramsRaw;
      }
      return DailyMissionTrigger(
          subType: type, target: target, params: params);
    }
    // Sprint 3.3 Etapa 2.1c-α — tipos `event_*` (não-daily) viram
    // `EventTrigger`. Schema idêntico ao DailyMissionTrigger pra reuso
    // de parser/UI. `params` carrega `class_key`, `faction_id`,
    // `must_be_first_time`, etc. dependendo do subType.
    if (AchievementTriggerTypes.allEvents.contains(type)) {
      final target = json['target'];
      if (target is! int || target <= 0) {
        throw FormatException(
            "$type.target inválido ($target) em '$achievementKey'");
      }
      final paramsRaw = json['params'];
      Map<String, dynamic>? params;
      if (paramsRaw != null) {
        if (paramsRaw is! Map<String, dynamic>) {
          throw FormatException(
              "$type.params deve ser objeto em '$achievementKey'");
        }
        params = paramsRaw;
      }
      return EventTrigger(
          subType: type, target: target, params: params);
    }
    switch (type) {
      case 'event_count':
        final event = json['event'];
        if (event is! String || event.isEmpty) {
          throw FormatException(
              "event_count.event ausente em '$achievementKey'");
        }
        final count = json['count'];
        if (count is! int || count <= 0) {
          throw FormatException(
              "event_count.count inválido ($count) em '$achievementKey'");
        }
        return EventCountTrigger(eventName: event, count: count);
      case 'threshold_stat':
        final stat = json['stat'];
        if (stat is! String || stat.isEmpty) {
          throw FormatException(
              "threshold_stat.stat ausente em '$achievementKey'");
        }
        final value = json['value'];
        if (value is! int) {
          throw FormatException(
              "threshold_stat.value inválido ($value) em '$achievementKey'");
        }
        return ThresholdStatTrigger(stat: stat, value: value);
      case 'meta':
        final target = json['target_count'];
        if (target is! int || target <= 0) {
          throw FormatException(
              "meta.target_count inválido ($target) em '$achievementKey'");
        }
        return MetaTrigger(targetCount: target);
      default:
        return UnknownAchievementTrigger(rawType: type);
    }
  }

  Map<String, dynamic> toJson();
}

/// Conquista desbloqueia quando o contador associado a [eventName] atinge
/// [count]. No MVP do Bloco 8 os mapeamentos suportados são:
///   - `MissionCompleted` → `players.total_quests_completed`
///   - `AchievementUnlocked` → `PlayerAchievementsRepository.countCompleted`
///
/// Outros eventos caem em fail-safe (warn + return false). Bloco 14 expande.
class EventCountTrigger extends AchievementTrigger {
  final String eventName;
  final int count;
  const EventCountTrigger({required this.eventName, required this.count});

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'event_count', 'event': eventName, 'count': count};
}

/// Conquista desbloqueia quando o stat do jogador atinge [value]. No MVP
/// só `stat: "level"` é suportado (lê `players.level`). Outros stats caem
/// em fail-safe. Bloco 14 adiciona `total_quests_completed`, `gold`, etc.
class ThresholdStatTrigger extends AchievementTrigger {
  final String stat;
  final int value;
  const ThresholdStatTrigger({required this.stat, required this.value});

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'threshold_stat', 'stat': stat, 'value': value};
}

/// Conquista desbloqueia quando o jogador tem [targetCount] ou mais
/// conquistas completadas (consultado via `countCompleted`).
class MetaTrigger extends AchievementTrigger {
  final int targetCount;
  const MetaTrigger({required this.targetCount});

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'meta', 'target_count': targetCount};
}

/// Sprint 3.3 Etapa 2.1b — captura todos os 15 tipos `daily_*` num
/// schema unificado. Preserva `subType` (uma das constants em
/// [AchievementTriggerTypes]) pra discriminação interna do
/// `AchievementsService._validateDailyTrigger`.
///
/// `params` opcional carrega configuração extra:
///   - `sub_task_key` (String) — usado por `daily_subtask_volume`
///   - `window` (`'before_8am'` | `'after_10pm'`) — usado por
///     `daily_confirmed_time_window`
///   - `use_best` (bool) — usado por `daily_no_fail_streak` e
///     `daily_consecutive_days_active` pra alternar entre contador
///     atual e recorde all-time
///
/// Triggers daily com schema malformado (ex: window faltando) caem em
/// fail-safe (warn + return false) — não lançam.
class DailyMissionTrigger extends AchievementTrigger {
  final String subType;
  final int target;
  final Map<String, dynamic>? params;

  const DailyMissionTrigger({
    required this.subType,
    required this.target,
    this.params,
  });

  /// Helper pra acesso null-safe.
  T? param<T>(String key) {
    final v = params?[key];
    return v is T ? v : null;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': subType,
        'target': target,
        if (params != null) 'params': params,
      };
}

/// Sprint 3.3 Etapa 2.1c-α — captura os 5 tipos `event_*` num schema
/// unificado paralelo a [DailyMissionTrigger]. Discriminação interna do
/// `AchievementsService._validateEventTrigger` via `subType`.
///
/// `params` opcional carrega configuração extra:
///   - `class_key` (String) — usado por `event_class_selected`
///   - `faction_id` (String) — usado por `event_faction_joined`
///   - `must_be_first_time` (bool) — usado por
///     `event_body_metrics_updated` pra distinguir 1ª calibração de
///     edição posterior
///
/// Triggers com schema malformado caem em fail-safe (warn + false).
class EventTrigger extends AchievementTrigger {
  final String subType;
  final int target;
  final Map<String, dynamic>? params;

  const EventTrigger({
    required this.subType,
    required this.target,
    this.params,
  });

  /// Helper pra acesso null-safe.
  T? param<T>(String key) {
    final v = params?[key];
    return v is T ? v : null;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': subType,
        'target': target,
        if (params != null) 'params': params,
      };
}

/// Trigger de tipo não reconhecido. Preserva o `rawType` pra log/debug. O
/// `AchievementsService` trata como trigger sempre-false + warn.
class UnknownAchievementTrigger extends AchievementTrigger {
  final String rawType;
  const UnknownAchievementTrigger({required this.rawType});

  @override
  Map<String, dynamic> toJson() => {'type': rawType};
}
