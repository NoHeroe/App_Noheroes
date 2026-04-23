import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/datasources/local/extras_catalog_service.dart';
import 'package:noheroes_app/domain/models/extras_mission_spec.dart';

class _FakeBundle extends AssetBundle {
  final Map<String, String> contents;
  _FakeBundle(this.contents);

  @override
  Future<ByteData> load(String key) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(s)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return s;
  }
}

void main() {
  group('ExtrasCatalogService.loadAll', () {
    test('lê extras_catalog.json + lore_quests.json combinados', () async {
      final bundle = _FakeBundle({
        'assets/data/extras_catalog.json': jsonEncode({
          'extras': [
            {
              'key': 'NPC_X',
              'type': 'npc',
              'title': 'Teste NPC',
              'description': 'desc',
              'reward_xp': 100,
              'reward_gold': 50,
            },
          ],
        }),
        'assets/data/lore_quests.json': jsonEncode({
          'lore_quests': [
            {
              'id': 'lq_001',
              'title': 'Lore Um',
              'description': 'narrativa',
              'unlock_level': 1,
              'reward_xp': 120,
              'reward_gold': 50,
            },
          ],
        }),
      });
      final service = ExtrasCatalogService(bundle: bundle);
      final all = await service.loadAll();
      expect(all.length, 2);
      expect(all.any((e) => e.type == ExtraMissionType.npc), isTrue);
      expect(all.any((e) => e.type == ExtraMissionType.lore), isTrue);
    });

    test('asset ausente → lista vazia, sem lançar', () async {
      final bundle = _FakeBundle(const {});
      final service = ExtrasCatalogService(bundle: bundle);
      final all = await service.loadAll();
      expect(all, isEmpty);
    });

    test('fromJson valida campos obrigatórios (type inválido lança)',
        () async {
      final bundle = _FakeBundle({
        'assets/data/extras_catalog.json': jsonEncode({
          'extras': [
            {
              'key': 'BAD',
              'type': 'unknown_type',
              'title': 'x',
              'description': 'y',
            },
          ],
        }),
      });
      final service = ExtrasCatalogService(bundle: bundle);
      expect(() => service.loadAll(), throwsA(isA<FormatException>()));
    });
  });
}
