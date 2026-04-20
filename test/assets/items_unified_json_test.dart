import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assets/data/items_unified.json', () {
    late List<Map<String, dynamic>> items;

    setUpAll(() {
      final raw = File('assets/data/items_unified.json').readAsStringSync();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      items = (data['items'] as List).cast<Map<String, dynamic>>();
    });

    test('tem exatamente 181 entries', () {
      expect(items.length, 181);
    });

    test('todas as keys são únicas', () {
      final keys = items.map((e) => e['key'] as String).toSet();
      expect(keys.length, 181, reason: 'keys duplicadas no catálogo');
    });

    test('campos obrigatórios (key, name, type, rarity) presentes e não-vazios', () {
      for (final item in items) {
        for (final field in ['key', 'name', 'type', 'rarity']) {
          final v = item[field];
          expect(v, isA<String>(),
              reason: 'campo "$field" ausente/não-string em ${item['key']}');
          expect((v as String).trim().isNotEmpty, isTrue,
              reason: 'campo "$field" vazio em ${item['key']}');
        }
      }
    });

    test('distribuição canônica por tipo', () {
      final byType = <String, int>{};
      for (final item in items) {
        final t = item['type'] as String;
        byType[t] = (byType[t] ?? 0) + 1;
      }
      // Valores confirmados pela inspeção do JSON.
      expect(byType, {
        'armor':      57,
        'weapon':     34,
        'consumable': 24,
        'accessory':  18,
        'relic':      18,
        'material':   10,
        'cosmetic':    6,
        'chest':       3,
        'key':         2,
        'title':       2,
        'lore':        2,
        'dark_item':   2,
        'shield':      1,
        'tome':        1,
        'currency':    1,
      });
    });

    test('distribuição canônica por rank (inclui 2 sem rank = null)', () {
      final byRank = <String, int>{};
      for (final item in items) {
        final r = (item['rank'] as String?) ?? '__null__';
        byRank[r] = (byRank[r] ?? 0) + 1;
      }
      expect(byRank, {
        'E':        80,
        'D':        57,
        'C':         7,
        'B':         4,
        'A':         7,
        'S':        24,
        '__null__':  2,
      });
    });

    test('COLLAR_GUILD tem flags is_unique + is_dark_item + is_evolving', () {
      final collar = items.firstWhere((e) => e['key'] == 'COLLAR_GUILD');
      expect(collar['is_unique'], true);
      expect(collar['is_dark_item'], true);
      expect(collar['is_evolving'], true);
    });

    test('COLLAR_GUILD.evolution_stages tem 7 estágios (null + E-S)', () {
      final collar = items.firstWhere((e) => e['key'] == 'COLLAR_GUILD');
      final stages = collar['evolution_stages'] as Map<String, dynamic>;
      expect(stages.length, 7);
      expect(stages.keys.toSet(), {
        'stage_null', 'stage_E', 'stage_D',
        'stage_C', 'stage_B', 'stage_A', 'stage_S',
      });
    });

    test('ADR 0010: tipos proibidos nunca têm shop em sources', () {
      const forbidden = {
        'relic', 'chest', 'key', 'title', 'cosmetic',
        'lore', 'currency', 'dark_item',
      };
      final violations = <String>[];
      for (final item in items) {
        final type = item['type'] as String;
        if (!forbidden.contains(type)) continue;
        final sources = (item['sources'] as List?) ?? [];
        for (final s in sources) {
          if (s is Map && s['type'] == 'shop') {
            violations.add('${item['key']} (tipo=$type)');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'ADR 0010 violada em: $violations');
    });

    test('21 itens com is_secret=true', () {
      final secrets = items.where((e) => e['is_secret'] == true).toList();
      expect(secrets.length, 21);
    });

    test('pelo menos 1 item com is_unique=true (Colar da Guilda)', () {
      final uniques = items.where((e) => e['is_unique'] == true).toList();
      expect(uniques.length, greaterThanOrEqualTo(1));
      expect(
        uniques.any((e) => e['key'] == 'COLLAR_GUILD'),
        isTrue,
        reason: 'Colar da Guilda deve estar entre os uniques',
      );
    });

    test('starter items (acquired_via/sources starter) têm rank E ou null', () {
      // Heurística: item tem "starter" em alguma source → precisa ser rank E ou null.
      for (final item in items) {
        final sources = (item['sources'] as List?) ?? [];
        final isStarter = sources.any(
          (s) => s is Map && s['type']?.toString().toLowerCase() == 'starter',
        );
        if (!isStarter) continue;
        final rank = item['rank'] as String?;
        expect(
          rank == null || rank == 'E',
          isTrue,
          reason: 'starter ${item['key']} tem rank=$rank — esperado E ou null',
        );
      }
    });
  });
}
