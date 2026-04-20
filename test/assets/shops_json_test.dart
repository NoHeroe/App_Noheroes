import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/models/shop_spec.dart';

void main() {
  group('assets/data/shops.json', () {
    late List<ShopSpec> shops;
    late Set<String> catalogKeys;

    setUpAll(() {
      final rawShops = File('assets/data/shops.json').readAsStringSync();
      final data = jsonDecode(rawShops) as Map<String, dynamic>;
      shops = (data['shops'] as List)
          .cast<Map<String, dynamic>>()
          .map(ShopSpec.fromJson)
          .toList();

      // Carrega keys do catálogo pra validar referências.
      final rawCatalog =
          File('assets/data/items_unified.json').readAsStringSync();
      final cat = jsonDecode(rawCatalog) as Map<String, dynamic>;
      catalogKeys = (cat['items'] as List)
          .cast<Map<String, dynamic>>()
          .map((e) => e['key'] as String)
          .toSet();
    });

    test('tem pelo menos 3 lojas', () {
      expect(shops.length, greaterThanOrEqualTo(3));
    });

    test('keys das lojas são únicas', () {
      final keys = shops.map((s) => s.key).toSet();
      expect(keys.length, shops.length);
    });

    test('todas as lojas canônicas existem', () {
      final keys = shops.map((s) => s.key).toSet();
      expect(keys, containsAll([
        'blacksmith_aureum',
        'general_store_aureum',
        'guild_shop',
      ]));
    });

    test('todos os itemKeys em shops referenciam o catálogo', () {
      final missing = <String>[];
      for (final shop in shops) {
        for (final entry in shop.items) {
          if (!catalogKeys.contains(entry.itemKey)) {
            missing.add('${shop.key} → ${entry.itemKey}');
          }
        }
      }
      expect(missing, isEmpty, reason: 'refs inexistentes: $missing');
    });

    test('todas as entries têm price_coins ou price_gems', () {
      final invalid = <String>[];
      for (final shop in shops) {
        for (final entry in shop.items) {
          if (entry.priceCoins == null && entry.priceGems == null) {
            invalid.add('${shop.key} → ${entry.itemKey} (sem preço)');
          }
        }
      }
      expect(invalid, isEmpty);
    });

    test('preços positivos', () {
      for (final shop in shops) {
        for (final entry in shop.items) {
          if (entry.priceCoins != null) {
            expect(entry.priceCoins!, greaterThan(0),
                reason: '${shop.key} → ${entry.itemKey}');
          }
          if (entry.priceGems != null) {
            expect(entry.priceGems!, greaterThan(0));
          }
        }
      }
    });

    test('loja da guilda exige rank (accepts_ranks não-vazio)', () {
      final guild = shops.firstWhere((s) => s.key == 'guild_shop');
      expect(guild.acceptedRanks, isNotEmpty);
    });

    test('lojas gerais têm accepts_ranks vazio (abertas pra todos)', () {
      final blacksmith =
          shops.firstWhere((s) => s.key == 'blacksmith_aureum');
      final general = shops.firstWhere((s) => s.key == 'general_store_aureum');
      expect(blacksmith.acceptedRanks, isEmpty);
      expect(general.acceptedRanks, isEmpty);
    });
  });
}
