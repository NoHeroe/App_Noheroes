import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assets/data/recipes.json', () {
    late List<Map<String, dynamic>> recipes;
    late Map<String, Map<String, dynamic>> items;

    setUpAll(() {
      final rawR = File('assets/data/recipes.json').readAsStringSync();
      final dataR = jsonDecode(rawR) as Map<String, dynamic>;
      recipes = (dataR['recipes'] as List).cast<Map<String, dynamic>>();

      final rawI = File('assets/data/items_unified.json').readAsStringSync();
      final dataI = jsonDecode(rawI) as Map<String, dynamic>;
      items = {
        for (final i in (dataI['items'] as List).cast<Map<String, dynamic>>())
          i['key'] as String: i,
      };
    });

    test('tem exatamente 40 receitas', () {
      expect(recipes.length, 40);
    });

    test('todas as keys são únicas', () {
      final keys = recipes.map((r) => r['key'] as String).toSet();
      expect(keys.length, recipes.length,
          reason: 'keys duplicadas em recipes.json');
    });

    test('campos obrigatórios presentes e não-vazios', () {
      const required = [
        'key', 'name', 'type', 'result_item_key', 'materials',
        'unlock_sources', 'required_station',
      ];
      for (final r in recipes) {
        for (final f in required) {
          expect(r.containsKey(f), isTrue,
              reason: 'campo "$f" ausente em ${r['key']}');
          expect(r[f], isNotNull, reason: '"$f" null em ${r['key']}');
        }
      }
    });

    test('type é craft ou forge', () {
      for (final r in recipes) {
        expect(['craft', 'forge'].contains(r['type']), isTrue,
            reason: 'type inválido em ${r['key']}: ${r['type']}');
      }
    });

    test('required_rank é E..S ou null', () {
      const valid = {'E', 'D', 'C', 'B', 'A', 'S'};
      for (final r in recipes) {
        final rr = r['required_rank'];
        expect(rr == null || valid.contains(rr), isTrue,
            reason: 'required_rank inválido em ${r['key']}: $rr');
      }
    });

    test('todos result_item_key existem em items_catalog', () {
      final missing = <String>[];
      for (final r in recipes) {
        final k = r['result_item_key'] as String;
        if (!items.containsKey(k)) {
          missing.add('${r['key']} → $k');
        }
      }
      expect(missing, isEmpty,
          reason: 'result_item_key não existem:\n${missing.join("\n")}');
    });

    test('todos material.item_key existem em items_catalog', () {
      final missing = <String>[];
      for (final r in recipes) {
        final mats = (r['materials'] as List).cast<Map<String, dynamic>>();
        for (final m in mats) {
          final k = m['item_key'] as String;
          if (!items.containsKey(k)) {
            missing.add('${r['key']} → $k');
          }
        }
      }
      expect(missing, isEmpty,
          reason: 'material.item_key não existem:\n${missing.join("\n")}');
    });

    test('nenhuma receita com materials vazio', () {
      for (final r in recipes) {
        final mats = r['materials'] as List;
        expect(mats.isNotEmpty, isTrue,
            reason: 'receita ${r['key']} tem materials vazio');
      }
    });

    test('materials têm quantidades positivas', () {
      for (final r in recipes) {
        final mats = (r['materials'] as List).cast<Map<String, dynamic>>();
        for (final m in mats) {
          expect(m['quantity'], isA<int>());
          expect((m['quantity'] as int) > 0, isTrue,
              reason: 'quantity <= 0 em ${r['key']}/${m['item_key']}');
        }
      }
    });

    test('nenhuma receita referencia item is_secret ou is_unique', () {
      final violations = <String>[];
      for (final r in recipes) {
        final result = items[r['result_item_key']]!;
        if (result['is_secret'] == true) {
          violations.add('${r['key']} → result ${result['key']} is_secret=true');
        }
        if (result['is_unique'] == true) {
          violations.add('${r['key']} → result ${result['key']} is_unique=true');
        }
      }
      expect(violations, isEmpty,
          reason: 'receitas inválidas:\n${violations.join("\n")}');
    });

    test('unlock_sources tem ao menos 1 entry válida', () {
      const validTypes = {
        'starter', 'quest', 'shop', 'drop',
        'achievement', 'npc',
      };
      for (final r in recipes) {
        final srcs = (r['unlock_sources'] as List).cast<Map<String, dynamic>>();
        expect(srcs.isNotEmpty, isTrue,
            reason: '${r['key']} tem unlock_sources vazio');
        for (final s in srcs) {
          expect(validTypes.contains(s['type']), isTrue,
              reason: 'unlock type inválido em ${r['key']}: ${s['type']}');
        }
      }
    });

    test('pelo menos 15 receitas têm unlock starter', () {
      final starters = recipes.where((r) {
        final srcs = (r['unlock_sources'] as List).cast<Map<String, dynamic>>();
        return srcs.any((s) => s['type'] == 'starter');
      }).toList();
      expect(starters.length, greaterThanOrEqualTo(15),
          reason: 'esperamos ~20 starter (15 equipamento + 5 materiais)');
    });

    test('required_station é um valor canônico', () {
      const valid = {'workshop', 'forge', 'anvil'};
      for (final r in recipes) {
        final s = r['required_station'] as String;
        expect(valid.contains(s), isTrue,
            reason: 'station inválida em ${r['key']}: $s');
      }
    });

    test('result_quantity e cost_coins e duration_sec são >= 0', () {
      for (final r in recipes) {
        expect((r['result_quantity'] as int) > 0, isTrue);
        expect((r['cost_coins'] as int) >= 0, isTrue);
        expect((r['duration_sec'] as int) >= 0, isTrue);
      }
    });
  });
}
