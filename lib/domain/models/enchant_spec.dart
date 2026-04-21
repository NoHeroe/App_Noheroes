import '../../core/utils/guild_rank.dart';
import '../enums/enchant_type.dart';
import 'enchant_effect.dart';
import 'item_spec.dart';

// Sprint 2.3 — EnchantSpec é montado via fromJson (legacy enchants.json já
// removido) ou via EnchantSpec.fromItemSpec(ItemSpec) — runas vivem no
// items_catalog como ItemType.rune (fix D.2/D.3).
class EnchantSpec {
  final String key;
  final String name;
  final String description;
  final EnchantType type;
  final String rarity;
  final GuildRank? requiredRank;
  final int? costGems;
  final int? sapChargesMax;
  final List<EnchantEffect> effects;
  final List<String> allowedClasses;
  final List<Map<String, dynamic>> sources;
  final bool isSecret;
  final bool isUnique;

  const EnchantSpec({
    required this.key,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.requiredRank,
    required this.costGems,
    required this.sapChargesMax,
    required this.effects,
    required this.allowedClasses,
    required this.sources,
    required this.isSecret,
    required this.isUnique,
  });

  factory EnchantSpec.fromJson(Map<String, dynamic> j) {
    return EnchantSpec(
      key:         j['key'] as String,
      name:        j['name'] as String,
      description: j['description'] as String? ?? '',
      type: EnchantTypeParser.tryParse(j['enchant_type'] as String?)
          ?? EnchantType.rune,
      rarity:      j['rarity'] as String? ?? 'common',
      requiredRank: _parseRank(j['required_rank'] as String?),
      costGems:      _intOrNull(j['cost_gems']),
      sapChargesMax: _intOrNull(j['sap_charges_max']),
      effects: EnchantEffect.fromMap(
          (j['effects'] as Map?)?.cast<String, dynamic>() ?? const {}),
      allowedClasses: ((j['allowed_classes'] as List?) ?? const [])
          .map((e) => e.toString()).toList(),
      sources: ((j['sources'] as List?) ?? const [])
          .cast<Map<String, dynamic>>(),
      isSecret: j['is_secret'] as bool? ?? false,
      isUnique: j['is_unique'] as bool? ?? false,
    );
  }

  // Sprint 2.3 fix — converte ItemSpec (type: rune do items_catalog) em
  // EnchantSpec. Usado pelo EnchantService após a migração D.2 (runas
  // vivem no items_catalog, não mais em enchants_catalog). Só runas até
  // Sprint 2.4 introduzir seivas — type hardcoded como EnchantType.rune.
  factory EnchantSpec.fromItemSpec(ItemSpec item) {
    // Filtra só entries numéricas dos effects (comportamento de
    // EnchantEffect.fromMap já faz isso, mas explicitamos pra clareza).
    final numericEffects = <String, dynamic>{
      for (final e in item.effects.entries)
        if (e.value is num) e.key: e.value,
    };
    return EnchantSpec(
      key:            item.key,
      name:           item.name,
      description:    item.description,
      type:           EnchantType.rune,
      rarity:         item.rarity.name,
      requiredRank:   item.requiredRank,
      costGems:       item.shopPriceGems,
      sapChargesMax:  null,
      effects:        EnchantEffect.fromMap(numericEffects),
      allowedClasses: item.allowedClasses,
      sources: item.sources
          .map((s) => <String, dynamic>{
                'type': s.rawType ?? s.type?.name ?? '',
              })
          .toList(),
      isSecret: item.isSecret,
      isUnique: item.isUnique,
    );
  }

  // Sprint 2.3 fix (D.3) — factory fromRow(EnchantsCatalogTableData) removida
  // pois a tabela enchants_catalog foi dropada na migration 22→23. Runas
  // agora vêm via EnchantSpec.fromItemSpec(ItemSpec) do items_catalog.

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnchantSpec && other.key == key);

  @override
  int get hashCode => key.hashCode;
}

// Tolerante a int/double — JSON writers podem emitir 100.0 onde queremos 100.
// Mesmo helper de ItemSpec / ItemsCatalogSeeder.
int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

// Aceita 'E'..'S' (case-insensitive). Mesmo pattern de ItemSpec._parseRank.
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
