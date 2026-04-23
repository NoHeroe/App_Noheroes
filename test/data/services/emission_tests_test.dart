import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/crafting_events.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/data/datasources/local/crafting_service.dart';
import 'package:noheroes_app/data/datasources/local/enchant_service.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/domain/models/craft_result.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';

/// Sprint 3.1 Bloco 7a — testes de emission/rollback nos services
/// refatorados.
///
/// **Importante**: estes testes rodam com AppDatabase in-memory onde os
/// seeders de items/recipes não carregam (assets não existem em
/// `flutter_test`). Por isso testamos SÓ o contrato: "evento é emitido
/// quando o caminho de sucesso é alcançado; evento NÃO é emitido quando
/// o service retorna rejected".
///
/// Testes específicos de crafting/enchant com catálogo real ficam pra
/// integração manual no Dev Panel (Bloco 15).

Future<int> _seedPlayer(AppDatabase db) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp) "
    "VALUES (?, ?, 'Sombra', 1, 0, 100, 500, 100, 1, 1, 1, 1, 1, 1, "
    "0, 0, 0, 0)",
    variables: [
      Variable.withString('e@t.com'),
      Variable.withString('h'),
    ],
  );
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('CraftingService — emission contract', () {
    test('craft com recipeKey inexistente NÃO emite eventos', () async {
      final playerId = await _seedPlayer(db);
      final catalog = ItemsCatalogService(db);
      final service = CraftingService(
        db,
        RecipesCatalogService(db),
        PlayerRecipesService(db, RecipesCatalogService(db)),
        catalog,
        PlayerInventoryService(db, catalog),
        PlayerDao(db),
        bus,
      );

      final crafted = <ItemCrafted>[];
      final spent = <GoldSpent>[];
      final s1 = bus.on<ItemCrafted>().listen(crafted.add);
      final s2 = bus.on<GoldSpent>().listen(spent.add);

      final result = await service.craft(
        playerId: playerId,
        recipeKey: 'NONEXISTENT',
        player: const PlayerSnapshot(level: 1, rank: GuildRank.e),
      );
      await pumpEventQueue();

      expect(result.isOk, isFalse);
      expect(result.reason, CraftRejectReason.recipeNotFound);
      expect(crafted, isEmpty,
          reason: 'rollback/reject não emite ItemCrafted');
      expect(spent, isEmpty, reason: 'rollback/reject não emite GoldSpent');

      await s1.cancel();
      await s2.cancel();
    });
  });

  group('EnchantService — emission contract', () {
    test('enchant com runeKey inexistente NÃO emite eventos', () async {
      final playerId = await _seedPlayer(db);
      final catalog = ItemsCatalogService(db);
      final service = EnchantService(
        db,
        catalog,
        PlayerInventoryService(db, catalog),
        bus,
      );

      final enchanted = <ItemEnchanted>[];
      final gems = <GemsSpent>[];
      final s1 = bus.on<ItemEnchanted>().listen(enchanted.add);
      final s2 = bus.on<GemsSpent>().listen(gems.add);

      final result = await service.applyEnchantToItem(
        playerId: playerId,
        inventoryItemId: 1,
        enchantKey: 'NONEXISTENT_RUNE',
        player: const PlayerSnapshot(level: 1, rank: GuildRank.e),
        playerGems: 100,
      );
      await pumpEventQueue();

      expect(result.allowed, isFalse);
      expect(enchanted, isEmpty);
      expect(gems, isEmpty);

      await s1.cancel();
      await s2.cancel();
    });
  });

  group('PlayerDao.addXp — retorna LevelUp quando level muda', () {
    test('xp insuficiente pra level-up → retorna null', () async {
      final playerId = await _seedPlayer(db);
      final dao = PlayerDao(db);
      final evt = await dao.addXp(playerId, 50); // xpToNext=100
      expect(evt, isNull);
    });

    test('xp suficiente pra level-up → retorna LevelUp', () async {
      final playerId = await _seedPlayer(db);
      final dao = PlayerDao(db);
      final evt = await dao.addXp(playerId, 100); // xpToNext=100 exato
      expect(evt, matcherIsNotNull);
      expect(evt!.playerId, playerId);
      expect(evt.previousLevel, 1);
      expect(evt.newLevel, 2);
    });

    test('xp gigante → multi level-up em 1 chamada', () async {
      final playerId = await _seedPlayer(db);
      final dao = PlayerDao(db);
      final evt = await dao.addXp(playerId, 10000);
      expect(evt, matcherIsNotNull);
      expect(evt!.previousLevel, 1);
      expect(evt.newLevel, greaterThan(2),
          reason: '10000 xp deve levar além do nível 2');
    });

    test('caller canônico publica evt no bus', () async {
      final playerId = await _seedPlayer(db);
      final dao = PlayerDao(db);

      LevelUp? captured;
      final sub = bus.on<LevelUp>().listen((e) => captured = e);

      final evt = await dao.addXp(playerId, 500);
      if (evt != null) bus.publish(evt);
      await pumpEventQueue();

      expect(captured, matcherIsNotNull);
      expect(captured!.newLevel, greaterThan(captured!.previousLevel));

      await sub.cancel();
    });
  });
}

const matcherIsNotNull = isNotNull;
