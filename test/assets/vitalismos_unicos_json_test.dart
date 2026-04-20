import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assets/data/vitalismos_unicos.json', () {
    late List<Map<String, dynamic>> entries;

    setUpAll(() {
      final raw = File('assets/data/vitalismos_unicos.json').readAsStringSync();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      entries = (data['vitalismos'] as List).cast<Map<String, dynamic>>();
    });

    test('tem exatamente 31 entries', () {
      expect(entries.length, 31);
    });

    test('distribuição por tier: 21 common + 9 rare + 1 special', () {
      final byTier = <String, int>{};
      for (final e in entries) {
        final t = e['tier'] as String;
        byTier[t] = (byTier[t] ?? 0) + 1;
      }
      expect(byTier['common'], 21);
      expect(byTier['rare'], 9);
      expect(byTier['special'], 1);
      expect(byTier.keys.toSet(), {'common', 'rare', 'special'});
    });

    test('todos os ids são únicos', () {
      final ids = entries.map((e) => e['id'] as String).toSet();
      expect(ids.length, 31, reason: 'ids duplicados no catálogo');
    });

    test('5 campos obrigatórios não-vazios em todos os entries', () {
      const fields = ['id', 'name', 'carrierName', 'tier', 'themeDescription'];
      for (final e in entries) {
        for (final f in fields) {
          final v = e[f];
          expect(v, isA<String>(),
              reason: 'campo "$f" ausente ou não-string em ${e['id']}');
          expect((v as String).trim().isNotEmpty, isTrue,
              reason: 'campo "$f" vazio em ${e['id']}');
        }
      }
    });

    test('o único "special" é life', () {
      final specials = entries.where((e) => e['tier'] == 'special').toList();
      expect(specials.length, 1);
      expect(specials.single['id'], 'life');
    });

    test('catálogo contém os 21 comuns canônicos', () {
      const expected = {
        'fire','water','wood','plant','hunt','sight','sun','moon','stars',
        'sword','space','theft','copy','mimic','metamorph','serpent',
        'poison','cloud','smoke','stone','wind',
      };
      final commons = entries
          .where((e) => e['tier'] == 'common')
          .map((e) => e['id'] as String)
          .toSet();
      expect(commons, expected);
    });

    test('catálogo contém os 9 raros canônicos', () {
      const expected = {
        'shadow','composition','decomposition','void','gravity',
        'time','light','frequency','ether',
      };
      final rares = entries
          .where((e) => e['tier'] == 'rare')
          .map((e) => e['id'] as String)
          .toSet();
      expect(rares, expected);
    });
  });
}
