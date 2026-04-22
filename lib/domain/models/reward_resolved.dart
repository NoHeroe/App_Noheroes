import 'dart:convert';

/// Item concreto escolhido após resolução (ex: `RUNE_FIRE_E` em vez de
/// `RUNE_RANDOM_E`).
class RewardItemResolved {
  final String key;
  final int quantity;

  const RewardItemResolved({required this.key, required this.quantity});

  factory RewardItemResolved.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) {
      throw const FormatException("RewardItemResolved.key ausente");
    }
    final quantity = json['quantity'];
    if (quantity is! int) {
      throw FormatException(
          "RewardItemResolved.quantity inválido ($quantity) em $key");
    }
    return RewardItemResolved(key: key, quantity: quantity);
  }

  Map<String, dynamic> toJson() => {'key': key, 'quantity': quantity};
}

/// Sprint 3.1 Bloco 3 — output canônico do `RewardResolveService` (Bloco 5).
///
/// Representa a reward **após**:
///   - SOULSLIKE multipliers aplicados (xp 0.4, gold 0.35, gems 0.7,
///     seivas 0.5, items 1.0 — ADR 0013)
///   - chaves random resolvidas (ex: `RUNE_RANDOM_E` → `RUNE_FIRE_E`
///     via rank pool do ADR 0017)
///   - chance_pct rolado per-item (itens com roll falho não entram)
///   - fórmula 0-300% aplicada em caso de missão Diária com parcial ou
///     excedente (ADR 0013 §4)
///
/// É o que o `RewardGrantService` (Bloco 5) credita na transação atômica.
/// É também o que viaja no payload do evento `RewardGranted` (Bloco 2).
class RewardResolved {
  final int xp;
  final int gold;
  final int gems;
  final int seivas;
  final List<RewardItemResolved> items;

  /// Chaves de achievement que devem ser checadas em cascata após grant
  /// (achievement triggers tipo `meta`, ADR §Bloco 8).
  final List<String> achievementsToCheck;

  /// Recipes desbloqueadas por esta reward (se houver).
  final List<String> recipesToUnlock;

  /// Delta já aplicado / a aplicar em `player_faction_reputation`. `null`
  /// se reward não mexe em reputação.
  final String? factionId;
  final int? factionReputationDelta;

  const RewardResolved({
    this.xp = 0,
    this.gold = 0,
    this.gems = 0,
    this.seivas = 0,
    this.items = const [],
    this.achievementsToCheck = const [],
    this.recipesToUnlock = const [],
    this.factionId,
    this.factionReputationDelta,
  });

  factory RewardResolved.fromJson(Map<String, dynamic> json) {
    final factionId = json['faction_id'] as String?;
    final factionDelta = json['faction_reputation_delta'] as int?;
    // Consistência: os dois juntos ou nenhum.
    if ((factionId == null) != (factionDelta == null)) {
      throw const FormatException(
          "RewardResolved.faction_id e faction_reputation_delta devem "
          "coexistir ou ambos ausentes");
    }
    return RewardResolved(
      xp: (json['xp'] as int?) ?? 0,
      gold: (json['gold'] as int?) ?? 0,
      gems: (json['gems'] as int?) ?? 0,
      seivas: (json['seivas'] as int?) ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .map((e) => RewardItemResolved.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      achievementsToCheck:
          ((json['achievements_to_check'] as List?) ?? const [])
              .map((e) => e as String)
              .toList(growable: false),
      recipesToUnlock: ((json['recipes_to_unlock'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      factionId: factionId,
      factionReputationDelta: factionDelta,
    );
  }

  factory RewardResolved.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          "RewardResolved.fromJsonString: JSON raiz não é objeto");
    }
    return RewardResolved.fromJson(decoded);
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'xp': xp,
      'gold': gold,
      'gems': gems,
      'seivas': seivas,
      'items': items.map((e) => e.toJson()).toList(growable: false),
      'achievements_to_check': achievementsToCheck,
      'recipes_to_unlock': recipesToUnlock,
    };
    if (factionId != null) {
      m['faction_id'] = factionId;
      m['faction_reputation_delta'] = factionReputationDelta;
    }
    return m;
  }

  String toJsonString() => jsonEncode(toJson());
}
