/// Trial (step) materializado do ciclo de ascensão da Guilda (Época 2,
/// full-online — ADR-0024).
///
/// Substitui o `GuildAscensionTableData` (Drift) como o objeto em memória
/// devolvido por `GuildAscensionService.getMissions`. `fromMap` lê a row do
/// Postgres (`guild_ascension_progress`, chaves snake_case via PostgREST).
///
/// `id` é a PK de LINHA (bigserial → int); `playerId` é o uuid do jogador
/// (String). Espelha a MESMA API de getters (camelCase) que a UI já lia em
/// `GuildAscensionTableData`.
class GuildAscensionTrial {
  final int id;
  final String playerId;
  final String rankFrom;
  final String rankTo;
  final int step;
  final String questKey;
  final String title;
  final String description;
  final String checkType;
  final String checkParamsJson;
  final int unlockLevel;
  final int xpReward;
  final int goldReward;
  final bool completed;
  final int progress;
  final int progressTarget;

  const GuildAscensionTrial({
    required this.id,
    required this.playerId,
    required this.rankFrom,
    required this.rankTo,
    required this.step,
    required this.questKey,
    required this.title,
    required this.description,
    required this.checkType,
    required this.checkParamsJson,
    required this.unlockLevel,
    required this.xpReward,
    required this.goldReward,
    required this.completed,
    required this.progress,
    required this.progressTarget,
  });

  static int _int(Object? v, [int fallback = 0]) =>
      v == null ? fallback : (v as num).toInt();

  /// Constrói a partir de uma row do Postgres (chaves snake_case).
  factory GuildAscensionTrial.fromMap(Map<String, dynamic> m) =>
      GuildAscensionTrial(
        id: _int(m['id']),
        playerId: m['player_id'] as String,
        rankFrom: m['rank_from'] as String,
        rankTo: m['rank_to'] as String,
        step: _int(m['step']),
        questKey: m['quest_key'] as String,
        title: m['title'] as String,
        description: (m['description'] as String?) ?? '',
        checkType: m['check_type'] as String,
        checkParamsJson: (m['check_params_json'] as String?) ?? '{}',
        unlockLevel: _int(m['unlock_level']),
        xpReward: _int(m['xp_reward']),
        goldReward: _int(m['gold_reward']),
        completed: (m['completed'] as bool?) ?? false,
        progress: _int(m['progress']),
        progressTarget: _int(m['progress_target'], 1),
      );
}
