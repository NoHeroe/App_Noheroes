import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_style.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/enums/rank_codec.dart';

/// Sprint 3.1 Bloco 3 — cobertura dos 6 enums + codec.
///
/// Cada grupo cobre:
///   - fromString retorna enum em value canônico
///   - fromString retorna null em value inválido
///   - fromStorage retorna enum em canônico
///   - fromStorage lança FormatException("Invalid <EnumName> '<value>'")
///   - storage/display não vazios
///   - round-trip storage → fromStorage preserva valor
void main() {
  group('MissionModality', () {
    test('fromString em values canônicos', () {
      for (final m in MissionModality.values) {
        expect(MissionModalityCodec.fromString(m.name), m);
      }
    });
    test('fromString em value inválido → null', () {
      expect(MissionModalityCodec.fromString('intrnal'), isNull);
      expect(MissionModalityCodec.fromString(''), isNull);
      expect(MissionModalityCodec.fromString('MIXED'), isNull,
          reason: 'case sensitive');
    });
    test('fromStorage em canônico retorna enum', () {
      expect(MissionModalityCodec.fromStorage('mixed'), MissionModality.mixed);
    });
    test('fromStorage em inválido lança FormatException com mensagem', () {
      expect(
        () => MissionModalityCodec.fromStorage('intrnal'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid MissionModality 'intrnal'"),
        )),
      );
    });
    test('storage + display não vazios', () {
      for (final m in MissionModality.values) {
        expect(m.storage, isNotEmpty);
        expect(m.display, isNotEmpty);
      }
    });
    test('round-trip storage → fromStorage', () {
      for (final m in MissionModality.values) {
        expect(MissionModalityCodec.fromStorage(m.storage), m);
      }
    });
  });

  group('MissionTabOrigin', () {
    test('storage ≠ enum.name para classTab', () {
      // Cobre o caso especial `classTab → 'class'`.
      expect(MissionTabOrigin.classTab.storage, 'class');
    });
    test('fromString em values canônicos', () {
      final pairs = {
        'daily': MissionTabOrigin.daily,
        'class': MissionTabOrigin.classTab,
        'faction': MissionTabOrigin.faction,
        'extras': MissionTabOrigin.extras,
        'admission': MissionTabOrigin.admission,
        'individual': MissionTabOrigin.individual,
      };
      for (final entry in pairs.entries) {
        expect(MissionTabOriginCodec.fromString(entry.key), entry.value);
      }
    });
    test('fromString em inválido → null', () {
      expect(MissionTabOriginCodec.fromString('classTab'), isNull,
          reason: 'storage é "class", não "classTab"');
      expect(MissionTabOriginCodec.fromString('extra'), isNull,
          reason: 'é "extras" plural');
    });
    test('fromStorage lança com mensagem', () {
      expect(
        () => MissionTabOriginCodec.fromStorage('extra'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid MissionTabOrigin 'extra'"),
        )),
      );
    });
    test('round-trip', () {
      for (final t in MissionTabOrigin.values) {
        expect(MissionTabOriginCodec.fromStorage(t.storage), t);
      }
    });
  });

  group('MissionCategory', () {
    test('4 categorias canônicas', () {
      expect(MissionCategory.values, hasLength(4));
      expect(
          MissionCategory.values.map((c) => c.storage).toSet(),
          {'fisico', 'mental', 'espiritual', 'vitalismo'});
    });
    test('rewardMultiplier por categoria (ADR 0013)', () {
      expect(MissionCategory.fisico.rewardMultiplier, 1.0);
      expect(MissionCategory.mental.rewardMultiplier, 1.1);
      expect(MissionCategory.espiritual.rewardMultiplier, 1.2);
      expect(MissionCategory.vitalismo.rewardMultiplier, 1.15);
    });
    test('fromString tolerante', () {
      expect(MissionCategoryCodec.fromString('fisico'), MissionCategory.fisico);
      expect(MissionCategoryCodec.fromString('physical'), isNull,
          reason: 'storage é PT-BR');
    });
    test('fromStorage estrito', () {
      expect(
        () => MissionCategoryCodec.fromStorage('physical'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid MissionCategory 'physical'"),
        )),
      );
    });
  });

  group('Intensity', () {
    test('4 valores', () {
      expect(Intensity.values, hasLength(4));
      expect(Intensity.values.map((i) => i.storage).toSet(),
          {'light', 'medium', 'heavy', 'adaptive'});
    });
    test('fromString / fromStorage', () {
      expect(IntensityCodec.fromString('heavy'), Intensity.heavy);
      expect(IntensityCodec.fromString('hard'), isNull);
      expect(IntensityCodec.fromStorage('adaptive'), Intensity.adaptive);
      expect(
        () => IntensityCodec.fromStorage('hard'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid Intensity 'hard'"),
        )),
      );
    });
  });

  group('MissionStyle', () {
    test('3 valores (subset de modality)', () {
      expect(MissionStyle.values, hasLength(3));
      expect(MissionStyle.values.map((s) => s.storage).toSet(),
          {'real', 'internal', 'mixed'});
    });
    test('fromString / fromStorage', () {
      expect(MissionStyleCodec.fromString('mixed'), MissionStyle.mixed);
      expect(MissionStyleCodec.fromString('individual'), isNull,
          reason: 'individual não é MissionStyle (é só MissionModality)');
      expect(
        () => MissionStyleCodec.fromStorage('individual'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid MissionStyle 'individual'"),
        )),
      );
    });
  });

  group('RankCodec (reusa GuildRank)', () {
    test('mesma instância de GuildRank em fromString', () {
      for (final r in GuildRank.values) {
        expect(RankCodec.fromString(r.name), r);
      }
    });
    test('fromString em inválido → null', () {
      expect(RankCodec.fromString('z'), isNull);
      expect(RankCodec.fromString('E'), isNull,
          reason: 'storage é lowercase; GuildRankSystem.fromString aceita '
              'upper mas este codec é case-sensitive por design');
    });
    test('fromStorage lança com "Invalid GuildRank \'<value>\'"', () {
      expect(
        () => RankCodec.fromStorage('z'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains("Invalid GuildRank 'z'"),
        )),
      );
    });
    test('storage + display', () {
      expect(RankCodec.storage(GuildRank.e), 'e');
      expect(RankCodec.display(GuildRank.e), 'Rank E');
    });
    test('não quebra GuildRankSystem.fromString legacy', () {
      // Contrato do GuildRankSystem: fromString inválido cai em .e silencioso.
      // Este teste garante que o Bloco 3 NÃO alterou esse comportamento.
      expect(GuildRankSystem.fromString('z'), GuildRank.e);
    });
  });
}
