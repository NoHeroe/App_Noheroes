import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_definition.dart';

/// Fixture inline — JSON mínimo porém completo de uma missão Diária Real.
Map<String, dynamic> _dailyRealFixture() => {
      'key': 'DAILY_PUSHUPS_E',
      'title': 'Forjando Aço',
      'description': 'Treine flexões, abdominais e caminhada.',
      'modality': 'real',
      'category': 'fisico',
      'tab_origin': 'daily',
      'rank': 'e',
      'target_value': 20,
      'quote': 'Treine como se sua sobrevivência dependesse disso.',
      'reward': {
        'xp': 100,
        'gold': 50,
      },
    };

Map<String, dynamic> _mixedFixture() => {
      'key': 'MIX_FORGE_AND_MEDITATE',
      'title': 'Bigorna e Silêncio',
      'description': 'Forje 3 itens e medite 15min.',
      'modality': 'mixed',
      'category': 'vitalismo',
      'tab_origin': 'extras',
      'rank': 'd',
      'target_value': 1,
      'reward': {'xp': 80, 'gold': 30},
      'requirements': [
        {'type': 'internal', 'event': 'ItemCrafted', 'target': 3},
        {
          'type': 'real',
          'name': 'Meditar',
          'target': 15,
          'unit': 'min',
        },
      ],
    };

void main() {
  group('MissionDefinition — família Real (diária)', () {
    test('fromJson completo', () {
      final m = MissionDefinition.fromJson(_dailyRealFixture());
      expect(m.key, 'DAILY_PUSHUPS_E');
      expect(m.modality, MissionModality.real);
      expect(m.category, MissionCategory.fisico);
      expect(m.tabOrigin, MissionTabOrigin.daily);
      expect(m.rank, GuildRank.e);
      expect(m.targetValue, 20);
      expect(m.reward.xp, 100);
      expect(m.quote, isNotNull);
      expect(m.requirements, isEmpty);
    });

    test('round-trip toJson / fromJson', () {
      final original = MissionDefinition.fromJson(_dailyRealFixture());
      final back = MissionDefinition.fromJson(original.toJson());
      expect(back.toJson(), original.toJson());
    });
  });

  group('MissionDefinition — família Mixed', () {
    test('fromJson com requirements', () {
      final m = MissionDefinition.fromJson(_mixedFixture());
      expect(m.modality, MissionModality.mixed);
      expect(m.requirements, hasLength(2));
      expect(m.requirements[0].type, 'internal');
      expect(m.requirements[0].event, 'ItemCrafted');
      expect(m.requirements[1].type, 'real');
      expect(m.requirements[1].name, 'Meditar');
    });

    test('mixed sem requirements lança FormatException', () {
      final bad = _mixedFixture()..remove('requirements');
      expect(
        () => MissionDefinition.fromJson(bad),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('MIX_FORGE_AND_MEDITATE'),
        )),
      );
    });
  });

  group('MissionDefinition — validações', () {
    test('campo obrigatório ausente lança apontando o campo/key', () {
      final bad = _dailyRealFixture()..remove('title');
      expect(
        () => MissionDefinition.fromJson(bad),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('title'), contains('DAILY_PUSHUPS_E')),
        )),
      );
    });

    test('modality inválido propaga FormatException do codec', () {
      final bad = _dailyRealFixture()..['modality'] = 'intrnal';
      expect(
        () => MissionDefinition.fromJson(bad),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid MissionModality 'intrnal'"),
        )),
      );
    });

    test('rank "E" uppercase rejeitado (storage é lowercase)', () {
      final bad = _dailyRealFixture()..['rank'] = 'E';
      expect(
        () => MissionDefinition.fromJson(bad),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid GuildRank 'E'"),
        )),
      );
    });

    test('target_value 0 ou negativo lança', () {
      final bad = _dailyRealFixture()..['target_value'] = 0;
      expect(
        () => MissionDefinition.fromJson(bad),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
