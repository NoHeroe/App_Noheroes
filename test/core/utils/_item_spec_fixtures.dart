// Fixtures compartilhadas pra testes das políticas de item.
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/models/inventory_entry_with_spec.dart';
import 'package:noheroes_app/domain/models/item_spec.dart';

// Constrói um ItemSpec mínimo via fromJson, permitindo overrides.
ItemSpec makeItem({
  String key = 'TEST',
  String name = 'Test',
  String type = 'weapon',
  String rarity = 'common',
  String? rank,
  String? requiredRank,
  bool isSecret = false,
  bool isUnique = false,
  bool isDarkItem = false,
  bool isEvolving = false,
  int requiredLevel = 1,
  List<String> allowedClasses = const [],
  List<String> allowedFactions = const [],
  Map<String, num> stats = const {},
  List<Map<String, dynamic>> sources = const [],
  bool isEquippable = true,
  String? slot,
  Map<String, dynamic>? evolutionStages,
}) {
  return ItemSpec.fromJson({
    'key': key,
    'name': name,
    'description': '',
    'type': type,
    'rarity': rarity,
    'rank': rank,
    'required_rank': requiredRank,
    'is_secret': isSecret,
    'is_unique': isUnique,
    'is_dark_item': isDarkItem,
    'is_evolving': isEvolving,
    'required_level': requiredLevel,
    'allowed_classes': allowedClasses,
    'allowed_factions': allowedFactions,
    'stats': stats,
    'effects': const <String, dynamic>{},
    'sources': sources,
    'stack_max': 1,
    'is_stackable': false,
    'is_consumable': false,
    'is_equippable': isEquippable,
    'slot': slot,
    'evolution_stages': evolutionStages,
    'image': '',
  });
}

// Monta um InventoryEntryWithSpec pra testes de aggregate/equip — o spec
// vem de makeItem, a entry é um PlayerInventoryTableData mínimo.
InventoryEntryWithSpec makeEntry({
  required ItemSpec spec,
  int id = 1,
  int playerId = 1,
  int quantity = 1,
  String? evolutionStage,
  bool isEquipped = true,
}) {
  return InventoryEntryWithSpec(
    entry: PlayerInventoryTableData(
      id: id,
      playerId: playerId,
      itemKey: spec.key,
      quantity: quantity,
      durabilityCurrent: null,
      acquiredAt: 0,
      acquiredVia: 'starter',
      evolutionStage: evolutionStage,
      isEquipped: isEquipped,
    ),
    spec: spec,
  );
}
