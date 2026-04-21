// Fixtures compartilhadas pra testes da EnchantPolicy.
// Mesmo padrão do _item_spec_fixtures.dart / _recipe_fixtures.dart.
import 'package:noheroes_app/domain/models/enchant_spec.dart';

EnchantSpec makeEnchant({
  String key = 'RUNE_TEST_E',
  String name = 'Runa Teste',
  String type = 'rune',
  String rarity = 'common',
  // Default null pra testes que não se importam com rank — rank gating é
  // validado explicitamente em testes dedicados.
  String? requiredRank,
  int? costGems = 100,
  int? sapChargesMax,
  Map<String, dynamic> effects = const {'damage_fire': 10},
  List<String> allowedClasses = const [],
  List<Map<String, dynamic>> sources = const [],
  bool isSecret = false,
  bool isUnique = false,
}) {
  return EnchantSpec.fromJson({
    'key': key,
    'name': name,
    'description': '',
    'enchant_type': type,
    'rarity': rarity,
    'required_rank': requiredRank,
    'cost_gems': costGems,
    'sap_charges_max': sapChargesMax,
    'effects': effects,
    'allowed_classes': allowedClasses,
    'sources': sources,
    'is_secret': isSecret,
    'is_unique': isUnique,
  });
}
