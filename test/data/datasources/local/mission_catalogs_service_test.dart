import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/datasources/local/mission_catalogs_service.dart';

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
  group('MissionCatalogsService', () {
    test('loadDaily parseia entries', () async {
      final bundle = _FakeBundle({
        'assets/data/missions_daily.json': jsonEncode({
          'missions': [
            {'key': 'D1', 'rank': 'e'},
            {'key': 'D2', 'rank': 'd'},
          ],
        }),
      });
      final service = MissionCatalogsService(bundle: bundle);
      final out = await service.loadDaily();
      expect(out.length, 2);
      expect(out.first['key'], 'D1');
    });

    test('loadClass filtra por class_key', () async {
      final bundle = _FakeBundle({
        'assets/data/missions_class.json': jsonEncode({
          'missions': [
            {'key': 'W1', 'class_key': 'warrior'},
            {'key': 'M1', 'class_key': 'monk'},
            {'key': 'W2', 'class_key': 'warrior'},
          ],
        }),
      });
      final service = MissionCatalogsService(bundle: bundle);
      final out = await service.loadClass('warrior');
      expect(out.length, 2);
      expect(out.every((e) => e['class_key'] == 'warrior'), isTrue);
    });

    test('asset ausente → lista vazia (tolerância)', () async {
      final bundle = _FakeBundle(const {});
      final service = MissionCatalogsService(bundle: bundle);
      expect(await service.loadDaily(), isEmpty);
      expect(await service.loadClass('any'), isEmpty);
    });
  });
}
