import 'dart:convert';
import '../../core/utils/guild_rank.dart';
import '../../data/database/app_database.dart';
import '../enums/recipe_type.dart';
import 'item_spec.dart' show SourceSpec;
import 'material_requirement.dart';

// Representação imutável de uma receita de crafting. Construída via fromJson
// (asset JSON) ou fromRow (linha Drift — delega pra fromJson após parsear os
// campos JSON-string do banco).
class RecipeSpec {
  final String key;
  final String name;
  final String description;
  final RecipeType type;
  final GuildRank? requiredRank;
  final int requiredLevel;
  final String requiredStation; // 'workshop' | 'forge' | 'anvil'
  final String resultItemKey;
  final int resultQuantity;
  final List<MaterialRequirement> materials;
  final int costCoins;
  final int durationSec;
  final List<SourceSpec> unlockSources;
  final String? icon;

  const RecipeSpec._({
    required this.key,
    required this.name,
    required this.description,
    required this.type,
    required this.requiredRank,
    required this.requiredLevel,
    required this.requiredStation,
    required this.resultItemKey,
    required this.resultQuantity,
    required this.materials,
    required this.costCoins,
    required this.durationSec,
    required this.unlockSources,
    required this.icon,
  });

  factory RecipeSpec.fromJson(Map<String, dynamic> json) {
    final matsRaw = (json['materials'] as List?) ?? const [];
    final materials = [
      for (final m in matsRaw)
        if (m is Map<String, dynamic>) MaterialRequirement.fromJson(m),
    ];
    final unlocksRaw = (json['unlock_sources'] as List?) ?? const [];
    final unlocks = [
      for (final s in unlocksRaw)
        if (s is Map<String, dynamic>) SourceSpec.fromJson(s),
    ];

    return RecipeSpec._(
      key:           json['key'] as String,
      name:          json['name'] as String,
      description:   json['description'] as String? ?? '',
      type: RecipeTypeX.fromString(json['type'] as String?) ??
          RecipeType.craft,
      requiredRank:  _parseRank(json['required_rank'] as String?),
      requiredLevel: _intOrNull(json['required_level']) ?? 1,
      requiredStation:
          json['required_station'] as String? ?? 'workshop',
      resultItemKey: json['result_item_key'] as String,
      resultQuantity: _intOrNull(json['result_quantity']) ?? 1,
      materials: materials,
      costCoins:   _intOrNull(json['cost_coins']) ?? 0,
      durationSec: _intOrNull(json['duration_sec']) ?? 0,
      unlockSources: unlocks,
      icon: json['icon'] as String?,
    );
  }

  factory RecipeSpec.fromRow(RecipesCatalogTableData row) {
    return RecipeSpec.fromJson({
      'key': row.key,
      'name': row.name,
      'description': row.description,
      'type': row.type,
      'required_rank': row.requiredRank,
      'required_level': row.requiredLevel,
      'required_station': row.requiredStation,
      'result_item_key': row.resultItemKey,
      'result_quantity': row.resultQuantity,
      'materials': jsonDecode(row.materials),
      'cost_coins': row.costCoins,
      'duration_sec': row.durationSec,
      'unlock_sources': jsonDecode(row.unlockSources),
      'icon': row.icon,
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is RecipeSpec && other.key == key);

  @override
  int get hashCode => key.hashCode;
}

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

GuildRank? _parseRank(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  switch (raw.toUpperCase()) {
    case 'E': return GuildRank.e;
    case 'D': return GuildRank.d;
    case 'C': return GuildRank.c;
    case 'B': return GuildRank.b;
    case 'A': return GuildRank.a;
    case 'S': return GuildRank.s;
  }
  return null;
}
