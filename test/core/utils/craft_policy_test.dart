import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/craft_policy.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/models/craft_result.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';

import '_recipe_fixtures.dart';

void main() {
  group('CraftPolicy.canCraft', () {
    const playerLv5E = PlayerSnapshot(level: 5, rank: GuildRank.e);
    const playerLv20S = PlayerSnapshot(level: 20, rank: GuildRank.s);
    const playerLv5NoRank = PlayerSnapshot(level: 5); // rank null

    test('receita não desbloqueada → recipeNotUnlocked', () {
      final r = makeRecipe(requiredLevel: 1);
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: false,
        currentMaterials: const {},
        currentCoins: 9999,
      );
      expect(reason, CraftRejectReason.recipeNotUnlocked);
    });

    test('rank insuficiente (player E, requer C) → rankTooLow', () {
      final r = makeRecipe(requiredRank: 'C');
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: true,
        currentMaterials: const {},
        currentCoins: 0,
      );
      expect(reason, CraftRejectReason.rankTooLow);
    });

    test('rank null no player + receita requer E → rankTooLow', () {
      final r = makeRecipe(requiredRank: 'E');
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5NoRank,
        recipeUnlocked: true,
        currentMaterials: const {},
        currentCoins: 0,
      );
      expect(reason, CraftRejectReason.rankTooLow);
    });

    test('rank suficiente (player S, requer E) → não rejeita por rank', () {
      final r = makeRecipe(
        requiredRank: 'E',
        materials: [
          {'item_key': 'IRON_INGOT', 'quantity': 1},
        ],
        costCoins: 10,
      );
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv20S,
        recipeUnlocked: true,
        currentMaterials: const {'IRON_INGOT': 10},
        currentCoins: 100,
      );
      expect(reason, isNull);
    });

    test('level insuficiente → levelTooLow', () {
      final r = makeRecipe(requiredLevel: 10);
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: true,
        currentMaterials: const {},
        currentCoins: 0,
      );
      expect(reason, CraftRejectReason.levelTooLow);
    });

    test('material faltando (tem 1, precisa 2) → notEnoughMaterials', () {
      final r = makeRecipe(
        materials: [
          {'item_key': 'IRON_INGOT', 'quantity': 2},
        ],
      );
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: true,
        currentMaterials: const {'IRON_INGOT': 1},
        currentCoins: 0,
      );
      expect(reason, CraftRejectReason.notEnoughMaterials);
    });

    test('material totalmente ausente → notEnoughMaterials', () {
      final r = makeRecipe(
        materials: [
          {'item_key': 'WOOD_STICK', 'quantity': 1},
        ],
      );
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: true,
        currentMaterials: const {},
        currentCoins: 0,
      );
      expect(reason, CraftRejectReason.notEnoughMaterials);
    });

    test('um material ok, outro faltando → notEnoughMaterials', () {
      final r = makeRecipe(
        materials: [
          {'item_key': 'IRON_INGOT', 'quantity': 2},
          {'item_key': 'WOOD_STICK', 'quantity': 1},
        ],
      );
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: true,
        currentMaterials: const {'IRON_INGOT': 2}, // falta WOOD_STICK
        currentCoins: 0,
      );
      expect(reason, CraftRejectReason.notEnoughMaterials);
    });

    test('materiais ok mas sem coins → notEnoughCoins', () {
      final r = makeRecipe(
        materials: [
          {'item_key': 'IRON_INGOT', 'quantity': 1},
        ],
        costCoins: 20,
      );
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: true,
        currentMaterials: const {'IRON_INGOT': 5},
        currentCoins: 10,
      );
      expect(reason, CraftRejectReason.notEnoughCoins);
    });

    test('tudo ok (materiais + coins + rank + level) → null', () {
      final r = makeRecipe(
        requiredRank: 'E',
        requiredLevel: 3,
        materials: [
          {'item_key': 'IRON_INGOT', 'quantity': 2},
          {'item_key': 'WOOD_STICK', 'quantity': 1},
        ],
        costCoins: 15,
      );
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: true,
        currentMaterials: const {'IRON_INGOT': 3, 'WOOD_STICK': 2},
        currentCoins: 20,
      );
      expect(reason, isNull);
    });

    test('receita sem rank nem level → passa com player novato', () {
      final r = makeRecipe();
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: const PlayerSnapshot(level: 1),
        recipeUnlocked: true,
        currentMaterials: const {},
        currentCoins: 0,
      );
      expect(reason, isNull);
    });

    test('ordem de rejeição: unlocked tem prioridade sobre rank/level/mats', () {
      // Tudo inválido ao mesmo tempo — deve reportar recipeNotUnlocked.
      final r = makeRecipe(
        requiredRank: 'S',
        requiredLevel: 99,
        materials: [
          {'item_key': 'X', 'quantity': 10},
        ],
        costCoins: 9999,
      );
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5NoRank,
        recipeUnlocked: false,
        currentMaterials: const {},
        currentCoins: 0,
      );
      expect(reason, CraftRejectReason.recipeNotUnlocked);
    });

    test('ordem de rejeição: rank antes de level', () {
      // Level 1 OK, rank null insuficiente.
      final r = makeRecipe(requiredRank: 'E', requiredLevel: 99);
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5NoRank,
        recipeUnlocked: true,
        currentMaterials: const {},
        currentCoins: 0,
      );
      expect(reason, CraftRejectReason.rankTooLow);
    });

    test('ordem de rejeição: materiais antes de coins', () {
      final r = makeRecipe(
        materials: [
          {'item_key': 'X', 'quantity': 1},
        ],
        costCoins: 1000,
      );
      final reason = CraftPolicy.canCraft(
        recipe: r,
        player: playerLv5E,
        recipeUnlocked: true,
        currentMaterials: const {}, // falta material
        currentCoins: 0,            // falta coins também
      );
      expect(reason, CraftRejectReason.notEnoughMaterials);
    });
  });

  group('CraftPolicy.calculateMaterialsNeeded', () {
    final recipe = makeRecipe(
      materials: [
        {'item_key': 'IRON_INGOT', 'quantity': 2},
        {'item_key': 'WOOD_STICK', 'quantity': 1},
      ],
    );

    test('quantidade 1 → materiais da receita', () {
      final needed = CraftPolicy.calculateMaterialsNeeded(recipe, 1);
      expect(needed, {'IRON_INGOT': 2, 'WOOD_STICK': 1});
    });

    test('quantidade 3 → materiais × 3', () {
      final needed = CraftPolicy.calculateMaterialsNeeded(recipe, 3);
      expect(needed, {'IRON_INGOT': 6, 'WOOD_STICK': 3});
    });

    test('quantidade 0 → mapa vazio (defensivo)', () {
      expect(CraftPolicy.calculateMaterialsNeeded(recipe, 0), isEmpty);
    });

    test('quantidade negativa → mapa vazio (defensivo)', () {
      expect(CraftPolicy.calculateMaterialsNeeded(recipe, -5), isEmpty);
    });

    test('receita sem materiais → mapa vazio', () {
      final r = makeRecipe(materials: const []);
      expect(CraftPolicy.calculateMaterialsNeeded(r, 5), isEmpty);
    });

    test('mesmo item_key repetido na receita soma', () {
      // Edge case defensivo: se receita tem 2 entries do mesmo material,
      // somam em vez de sobrescrever.
      final r = makeRecipe(
        materials: [
          {'item_key': 'IRON_INGOT', 'quantity': 2},
          {'item_key': 'IRON_INGOT', 'quantity': 3},
        ],
      );
      expect(CraftPolicy.calculateMaterialsNeeded(r, 1),
          {'IRON_INGOT': 5});
    });
  });

  group('RecipeSpec.fromJson tolerância', () {
    test('materials[].quantity como double (2.0) vira int (2)', () {
      final r = makeRecipe(
        materials: [
          {'item_key': 'X', 'quantity': 2.0},
        ],
      );
      expect(r.materials.single.quantity, 2);
    });

    test('required_rank em lowercase também é aceito', () {
      final r = makeRecipe(requiredRank: 'd');
      expect(r.requiredRank, GuildRank.d);
    });

    test('required_rank null é preservado', () {
      final r = makeRecipe();
      expect(r.requiredRank, isNull);
    });

    test('type inválido cai em craft (default)', () {
      final r = makeRecipe(type: 'xyz');
      expect(r.type.name, 'craft');
    });
  });
}
