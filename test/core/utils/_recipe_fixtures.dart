// Fixtures pra testes de políticas de crafting.
import 'package:noheroes_app/domain/models/recipe_spec.dart';

RecipeSpec makeRecipe({
  String key = 'RECIPE_TEST',
  String name = 'Test Recipe',
  String type = 'craft',
  String? requiredRank,
  int requiredLevel = 1,
  String requiredStation = 'workshop',
  String resultItemKey = 'ITEM_RESULT',
  int resultQuantity = 1,
  List<Map<String, dynamic>> materials = const [],
  int costCoins = 0,
  int durationSec = 0,
  List<Map<String, dynamic>> unlockSources = const [],
}) {
  return RecipeSpec.fromJson({
    'key': key,
    'name': name,
    'description': '',
    'type': type,
    'required_rank': requiredRank,
    'required_level': requiredLevel,
    'required_station': requiredStation,
    'result_item_key': resultItemKey,
    'result_quantity': resultQuantity,
    'materials': materials,
    'cost_coins': costCoins,
    'duration_sec': durationSec,
    'unlock_sources': unlockSources,
  });
}
