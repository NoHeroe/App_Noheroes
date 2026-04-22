import 'dart:convert';

/// Item declarado numa reward JSON — antes de passar pelo resolver do
/// Bloco 5. Mantém-se `RUNE_RANDOM_E` etc. — o resolver escolhe o item
/// concreto conforme ADR 0017.
class RewardItemDeclared {
  /// Chave no `items_catalog` ou chave random (ex: `RUNE_RANDOM_E`).
  final String key;
  final int quantity;

  /// 0..100 — probabilidade do item dropar. 100 = sempre.
  final int chancePct;

  const RewardItemDeclared({
    required this.key,
    required this.quantity,
    this.chancePct = 100,
  });

  factory RewardItemDeclared.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) {
      throw const FormatException("RewardItemDeclared.key ausente ou vazio");
    }
    final quantity = json['quantity'];
    if (quantity is! int) {
      throw FormatException(
          "RewardItemDeclared.quantity inválido ($quantity) em $key");
    }
    final chance = json['chance_pct'] ?? 100;
    if (chance is! int || chance < 0 || chance > 100) {
      throw FormatException(
          "RewardItemDeclared.chance_pct fora de 0..100 ($chance) em $key");
    }
    return RewardItemDeclared(
      key: key,
      quantity: quantity,
      chancePct: chance,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'quantity': quantity,
        'chance_pct': chancePct,
      };
}

/// Ajuste de reputação de facção embutido numa reward.
class FactionReputationDelta {
  final String factionId;
  final int delta;

  const FactionReputationDelta({required this.factionId, required this.delta});

  factory FactionReputationDelta.fromJson(Map<String, dynamic> json) {
    final id = json['faction_id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException(
          "FactionReputationDelta.faction_id ausente ou vazio");
    }
    final d = json['delta'];
    if (d is! int) {
      throw FormatException(
          "FactionReputationDelta.delta inválido ($d) em $id");
    }
    return FactionReputationDelta(factionId: id, delta: d);
  }

  Map<String, dynamic> toJson() => {
        'faction_id': factionId,
        'delta': delta,
      };
}

/// Sprint 3.1 Bloco 3 — reward **declarada** (como vem do JSON do
/// catálogo), antes de ser resolvida pelo `RewardResolveService` (Bloco 5).
///
/// Schema espelha ADR 0013 §1. Multiplicadores SOULSLIKE **não são**
/// aplicados aqui — o resolver aplica. Chaves random (`RUNE_RANDOM_E`)
/// **não são** sorteadas aqui.
///
/// Campos ausentes no JSON caem em defaults seguros (0, `[]`, `null`).
class RewardDeclared {
  final int xp;
  final int gold;
  final int gems;
  final int seivas;
  final List<RewardItemDeclared> items;
  final List<String> achievementsToCheck;
  final List<String> recipesToUnlock;
  final FactionReputationDelta? factionReputation;

  const RewardDeclared({
    this.xp = 0,
    this.gold = 0,
    this.gems = 0,
    this.seivas = 0,
    this.items = const [],
    this.achievementsToCheck = const [],
    this.recipesToUnlock = const [],
    this.factionReputation,
  });

  factory RewardDeclared.fromJson(Map<String, dynamic> json) {
    return RewardDeclared(
      xp: (json['xp'] as int?) ?? 0,
      gold: (json['gold'] as int?) ?? 0,
      gems: (json['gems'] as int?) ?? 0,
      seivas: (json['seivas'] as int?) ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .map((e) => RewardItemDeclared.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      achievementsToCheck:
          ((json['achievements_to_check'] as List?) ?? const [])
              .map((e) => e as String)
              .toList(growable: false),
      recipesToUnlock: ((json['recipes_to_unlock'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      factionReputation: json['faction_reputation'] == null
          ? null
          : FactionReputationDelta.fromJson(
              json['faction_reputation'] as Map<String, dynamic>),
    );
  }

  /// Desserializa a partir de uma string JSON (ex: coluna
  /// `player_mission_progress.reward_json`).
  factory RewardDeclared.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          "RewardDeclared.fromJsonString: JSON raiz não é objeto");
    }
    return RewardDeclared.fromJson(decoded);
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
    if (factionReputation != null) {
      m['faction_reputation'] = factionReputation!.toJson();
    }
    return m;
  }

  String toJsonString() => jsonEncode(toJson());
}
