import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/core/utils/item_source_policy.dart';
import 'package:noheroes_app/domain/enums/item_rarity.dart';
import 'package:noheroes_app/domain/enums/item_type.dart';
import 'package:noheroes_app/domain/enums/source_type.dart';
import '_item_spec_fixtures.dart';

void main() {
  group('ItemSourcePolicy.canAppearInShop — rejeita tipos proibidos', () {
    test('relic com shop em sources → false (defense-in-depth)', () {
      final item = makeItem(
        type: 'relic', isEquippable: false,
        sources: const [{'type': 'shop'}],
      );
      expect(ItemSourcePolicy.canAppearInShop(item), isFalse);
    });

    test('chest com shop em sources → false', () {
      final item = makeItem(
        type: 'chest', isEquippable: false,
        sources: const [{'type': 'shop'}],
      );
      expect(ItemSourcePolicy.canAppearInShop(item), isFalse);
    });

    test('title/cosmetic/lore/currency/key/dark_item → false', () {
      for (final t in const ['title', 'cosmetic', 'lore', 'currency', 'key', 'dark_item']) {
        final item = makeItem(
          type: t, isEquippable: false,
          sources: const [{'type': 'shop'}],
        );
        expect(ItemSourcePolicy.canAppearInShop(item), isFalse, reason: 'type=$t');
      }
    });
  });

  group('ItemSourcePolicy.canAppearInShop — rejeita por flags', () {
    test('is_secret=true com shop → false', () {
      final item = makeItem(
        isSecret: true, sources: const [{'type': 'shop'}],
      );
      expect(ItemSourcePolicy.canAppearInShop(item), isFalse);
    });

    test('is_unique=true com shop → false', () {
      final item = makeItem(
        isUnique: true, sources: const [{'type': 'shop'}],
      );
      expect(ItemSourcePolicy.canAppearInShop(item), isFalse);
    });

    test('is_evolving=true com shop → false', () {
      final item = makeItem(
        isEvolving: true, sources: const [{'type': 'shop'}],
      );
      expect(ItemSourcePolicy.canAppearInShop(item), isFalse);
    });
  });

  group('ItemSourcePolicy.canAppearInShop — aceita/rejeita por sources', () {
    test('weapon comum com shop em sources → true', () {
      final item = makeItem(
        type: 'weapon', rarity: 'common',
        sources: const [{'type': 'shop'}],
      );
      expect(ItemSourcePolicy.canAppearInShop(item), isTrue);
    });

    test('weapon comum SEM shop em sources → false', () {
      final item = makeItem(
        type: 'weapon', rarity: 'common',
        sources: const [{'type': 'loot_world'}],
      );
      expect(ItemSourcePolicy.canAppearInShop(item), isFalse);
    });
  });

  group('ItemSourcePolicy.defaultSourcesForType', () {
    test('weapon rank E → inclui shop', () {
      final srcs = ItemSourcePolicy.defaultSourcesForType(
        type: ItemType.weapon, rank: GuildRank.e, rarity: ItemRarity.common,
      );
      expect(srcs, contains(SourceType.shop));
      expect(srcs, contains(SourceType.lootWorld));
    });

    test('weapon rank S → nunca shop', () {
      final srcs = ItemSourcePolicy.defaultSourcesForType(
        type: ItemType.weapon, rank: GuildRank.s, rarity: ItemRarity.legendary,
      );
      expect(srcs, isNot(contains(SourceType.shop)));
      expect(srcs, contains(SourceType.achievement));
    });

    test('relic → nunca shop; inclui achievement/ritual', () {
      final srcs = ItemSourcePolicy.defaultSourcesForType(
        type: ItemType.relic, rarity: ItemRarity.epic,
      );
      expect(srcs, isNot(contains(SourceType.shop)));
      expect(srcs, contains(SourceType.achievement));
      expect(srcs, contains(SourceType.ritual));
    });

    test('is_dark_item=true → sources restritas', () {
      final srcs = ItemSourcePolicy.defaultSourcesForType(
        type: ItemType.accessory, rarity: ItemRarity.legendary, isDark: true,
      );
      expect(srcs, {SourceType.purchaseRealMoney, SourceType.achievement});
    });

    test('is_secret sobreescreve regras por tipo', () {
      final srcs = ItemSourcePolicy.defaultSourcesForType(
        type: ItemType.weapon, rank: GuildRank.e, rarity: ItemRarity.common,
        isSecret: true,
      );
      expect(srcs, {SourceType.secretMission, SourceType.achievement});
    });

    test('starter gear (rank null) → starter + shop', () {
      final srcs = ItemSourcePolicy.defaultSourcesForType(
        type: ItemType.weapon, rank: null, rarity: ItemRarity.common,
      );
      expect(srcs, contains(SourceType.starter));
      expect(srcs, contains(SourceType.shop));
    });
  });

  group('ItemSourcePolicy.validateCatalogEntry', () {
    test('item válido → lista vazia', () {
      final item = makeItem(
        type: 'weapon', rarity: 'common',
        sources: const [{'type': 'shop'}],
      );
      expect(ItemSourcePolicy.validateCatalogEntry(item), isEmpty);
    });

    test('relíquia com shop → 1+ erro', () {
      final item = makeItem(
        type: 'relic', isEquippable: false,
        sources: const [{'type': 'shop'}],
      );
      final errs = ItemSourcePolicy.validateCatalogEntry(item);
      expect(errs.length, greaterThan(0));
      expect(errs.first, contains('shop'));
    });

    test('item secret+unique+evolving com shop → erro de flags', () {
      final item = makeItem(
        isSecret: true, isUnique: true, isEvolving: true,
        sources: const [{'type': 'shop'}],
      );
      final errs = ItemSourcePolicy.validateCatalogEntry(item);
      expect(errs.any((e) => e.contains('is_secret')), isTrue);
    });
  });
}
