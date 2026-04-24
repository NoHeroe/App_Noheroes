/// Sprint 3.1 Bloco 11a — entrada declarativa de missão Extra
/// (DESIGN_DOC §8 aba Extras). Cobre os 5 sub-tipos:
///
///   - `npc`: NPCs dão missões (dispensers)
///   - `lore`: narrativas clássicas (reusa `lore_quests.json`)
///   - `secret`: só aparecem quando descobertas (trigger específico)
///   - `event`: futuro Unity — stub no 11a
///   - `individual`: sub-seção das criadas pelo jogador — **não entra
///     neste catálogo**, vem de `player_mission_progress` com
///     `metaJson['user_created']=true`
///
/// ## Organização (DESIGN_DOC §8)
///
/// Não ordenado por rank — por **nível mínimo** do jogador. Jogador
/// pode aceitar missões de nível mais alto sem limite (trade-off:
/// falha = penalidade brutal). Bloco 11b entrega o "aceitar" funcional.
/// Bloco 11a só renderiza o conteúdo.
enum ExtraMissionType { npc, lore, secret, event }

extension ExtraMissionTypeCodec on ExtraMissionType {
  String get storage => switch (this) {
        ExtraMissionType.npc => 'npc',
        ExtraMissionType.lore => 'lore',
        ExtraMissionType.secret => 'secret',
        ExtraMissionType.event => 'event',
      };

  String get display => switch (this) {
        ExtraMissionType.npc => 'NPC',
        ExtraMissionType.lore => 'Lore',
        ExtraMissionType.secret => 'Secreta',
        ExtraMissionType.event => 'Evento',
      };

  static ExtraMissionType? fromString(String raw) {
    for (final t in ExtraMissionType.values) {
      if (t.storage == raw) return t;
    }
    return null;
  }
}

class ExtrasMissionSpec {
  final String key;
  final ExtraMissionType type;
  final String title;
  final String description;

  /// Narrativa contextual (copy longa, aparece no card expandido).
  /// Opcional — algumas missões são só título+descrição.
  final String? narrative;

  /// Nível mínimo do jogador pra aparecer. `null` = qualquer nível.
  final int? unlockLevel;

  /// Secretas: `true` = invisível até trigger disparar.
  final bool isSecret;

  /// Rótulo de reward (display-only no 11a; grants reais ficam no 11b
  /// quando "aceitar" for funcional).
  final int rewardXp;
  final int rewardGold;

  const ExtrasMissionSpec({
    required this.key,
    required this.type,
    required this.title,
    required this.description,
    this.narrative,
    this.unlockLevel,
    this.isSecret = false,
    this.rewardXp = 0,
    this.rewardGold = 0,
  });

  factory ExtrasMissionSpec.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) {
      throw const FormatException("ExtrasMissionSpec.key ausente");
    }
    final typeStr = json['type'];
    if (typeStr is! String) {
      throw FormatException("ExtrasMissionSpec.type ausente em '$key'");
    }
    final type = ExtraMissionTypeCodec.fromString(typeStr);
    if (type == null) {
      throw FormatException(
          "ExtrasMissionSpec.type inválido ('$typeStr') em '$key'");
    }
    final title = json['title'];
    if (title is! String || title.isEmpty) {
      throw FormatException("ExtrasMissionSpec.title ausente em '$key'");
    }
    final description = json['description'];
    if (description is! String) {
      throw FormatException(
          "ExtrasMissionSpec.description ausente em '$key'");
    }
    return ExtrasMissionSpec(
      key: key,
      type: type,
      title: title,
      description: description,
      narrative: json['narrative'] as String?,
      unlockLevel: json['unlock_level'] as int?,
      isSecret: (json['is_secret'] as bool?) ?? false,
      rewardXp: (json['reward_xp'] as int?) ?? 0,
      rewardGold: (json['reward_gold'] as int?) ?? 0,
    );
  }

  /// Sprint 3.1 Bloco 14.5 — serialize pra SharedPreferences (awakening
  /// extra dinâmica por jogador). Round-trip via `fromJson` preservado
  /// (mesmas keys e tipos).
  Map<String, dynamic> toJson() => {
        'key': key,
        'type': type.storage,
        'title': title,
        'description': description,
        if (narrative != null) 'narrative': narrative,
        if (unlockLevel != null) 'unlock_level': unlockLevel,
        'is_secret': isSecret,
        'reward_xp': rewardXp,
        'reward_gold': rewardGold,
      };
}
