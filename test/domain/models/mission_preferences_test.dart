import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_style.dart';
import 'package:noheroes_app/domain/models/mission_preferences.dart';

Map<String, dynamic> _fixture() => {
      'player_id': 42,
      'primary_focus': 'vitalismo',
      'intensity': 'medium',
      'mission_style': 'mixed',
      'physical_subfocus': ['forca', 'cardio'],
      'mental_subfocus': ['leitura'],
      'spiritual_subfocus': ['meditacao', 'journaling'],
      'time_daily_minutes': 45,
      'created_at': 1700000000000,
      'updated_at': 1700000500000,
      'updates_count': 2,
    };

void main() {
  group('MissionPreferences — fromJson (formato API)', () {
    test('round-trip completo', () {
      final p = MissionPreferences.fromJson(_fixture());
      expect(p.playerId, 42);
      expect(p.primaryFocus, MissionCategory.vitalismo);
      expect(p.intensity, Intensity.medium);
      expect(p.missionStyle, MissionStyle.mixed);
      expect(p.physicalSubfocus, ['forca', 'cardio']);
      expect(p.mentalSubfocus, ['leitura']);
      expect(p.spiritualSubfocus, ['meditacao', 'journaling']);
      expect(p.timeDailyMinutes, 45);
      expect(p.updatesCount, 2);

      final back = MissionPreferences.fromJson(p.toJson());
      expect(back.toJson(), p.toJson());
    });

    test('subfocus ausentes viram []', () {
      final fix = _fixture()
        ..remove('physical_subfocus')
        ..remove('mental_subfocus')
        ..remove('spiritual_subfocus');
      final p = MissionPreferences.fromJson(fix);
      expect(p.physicalSubfocus, isEmpty);
      expect(p.mentalSubfocus, isEmpty);
      expect(p.spiritualSubfocus, isEmpty);
    });

    test('time_daily_minutes ausente vira 30 (default)', () {
      final fix = _fixture()..remove('time_daily_minutes');
      final p = MissionPreferences.fromJson(fix);
      expect(p.timeDailyMinutes, 30);
    });
  });

  group('MissionPreferences — fromJson (formato Drift row)', () {
    test('subfocus vindo como JSON string é parseado', () {
      final fix = _fixture()
        ..['physical_subfocus'] = jsonEncode(['forca', 'cardio'])
        ..['mental_subfocus'] = '[]'
        ..['spiritual_subfocus'] = '[]';
      final p = MissionPreferences.fromJson(fix);
      expect(p.physicalSubfocus, ['forca', 'cardio']);
      expect(p.mentalSubfocus, isEmpty);
    });

    test('toRow serializa subfocus como string JSON', () {
      final p = MissionPreferences.fromJson(_fixture());
      final row = p.toRow();
      expect(row['physical_subfocus'], '["forca","cardio"]');
      expect(row['mental_subfocus'], '["leitura"]');
      expect(row['spiritual_subfocus'], '["meditacao","journaling"]');
      expect(row['primary_focus'], 'vitalismo');
    });
  });

  group('MissionPreferences — validações', () {
    test('primary_focus inválido propaga FormatException do codec', () {
      final fix = _fixture()..['primary_focus'] = 'wrong';
      expect(
        () => MissionPreferences.fromJson(fix),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid MissionCategory 'wrong'"),
        )),
      );
    });

    test('player_id inválido lança', () {
      final fix = _fixture()..['player_id'] = 'abc';
      expect(
        () => MissionPreferences.fromJson(fix),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('MissionPreferences — copyWith', () {
    test('muda intensity preservando o resto', () {
      final p = MissionPreferences.fromJson(_fixture());
      final updated = p.copyWith(
        intensity: Intensity.heavy,
        updatesCount: p.updatesCount + 1,
      );
      expect(updated.intensity, Intensity.heavy);
      expect(updated.updatesCount, 3);
      expect(updated.primaryFocus, p.primaryFocus);
      expect(updated.createdAt, p.createdAt,
          reason: 'createdAt é imutável — copyWith não altera');
    });
  });
}
