import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noheroes_app/data/datasources/local/extras_catalog_service.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/models/extras_mission_spec.dart';
import 'package:noheroes_app/presentation/onboarding/screens/awakening_screen.dart';

/// Sprint 3.1 Bloco 14.6a — testes da lógica pura da cerimônia
/// ([AwakeningCeremony]). Isolada do widget pra permitir cobertura
/// comportamental sem infra de AnimationController + go_router.
void main() {
  group('AwakeningCeremony.compilePrimaryFocus', () {
    test('3 cenários concordam com a direta → direta vence (6 votos)', () {
      final result = AwakeningCeremony.compilePrimaryFocus(
        direct: MissionCategory.fisico,
        scenarios: const [
          MissionCategory.fisico,
          MissionCategory.fisico,
          MissionCategory.fisico,
        ],
      );
      expect(result, MissionCategory.fisico);
    });

    test(
        'cenários divergem da direta mas direta (2) + 1 cenário > outros → '
        'direta ainda vence', () {
      final result = AwakeningCeremony.compilePrimaryFocus(
        direct: MissionCategory.espiritual,
        scenarios: const [
          MissionCategory.espiritual,
          MissionCategory.fisico,
          MissionCategory.mental,
        ],
      );
      expect(result, MissionCategory.espiritual);
    });

    test(
        '3 cenários batem num pilar diferente (3 > 2) → cenários ganham da direta',
        () {
      final result = AwakeningCeremony.compilePrimaryFocus(
        direct: MissionCategory.fisico,
        scenarios: const [
          MissionCategory.mental,
          MissionCategory.mental,
          MissionCategory.mental,
        ],
      );
      expect(result, MissionCategory.mental);
    });

    test(
        'empate entre direta e um pilar de cenário → tiebreaker pela direta',
        () {
      // direta = fisico (2 votos); vitalismo recebe 2 votos de cenários.
      // empate 2x2 → direta vence.
      final result = AwakeningCeremony.compilePrimaryFocus(
        direct: MissionCategory.fisico,
        scenarios: const [
          MissionCategory.vitalismo,
          MissionCategory.vitalismo,
          MissionCategory.mental,
        ],
      );
      expect(result, MissionCategory.fisico);
    });
  });

  group('AwakeningCeremony.awakeningExtraFor (14.5)', () {
    test('cada pilar retorna uma ExtrasMissionSpec distinta + type npc', () {
      final specs = {
        for (final c in MissionCategory.values)
          c: AwakeningCeremony.awakeningExtraFor(c),
      };
      final keys = specs.values.map((s) => s.key).toSet();
      expect(keys.length, MissionCategory.values.length,
          reason: 'Cada pilar precisa de key única');
      for (final entry in specs.entries) {
        expect(entry.value.type.storage, 'npc',
            reason: 'Awakening extra doada pelo Vazio deve ser type=npc');
        expect(entry.value.title, isNotEmpty);
        expect(entry.value.description, isNotEmpty);
      }
    });

    test('spec.toJson round-trip via fromJson preserva campos', () {
      for (final c in MissionCategory.values) {
        final original = AwakeningCeremony.awakeningExtraFor(c);
        final roundTripped = ExtrasMissionSpec.fromJson(original.toJson());
        expect(roundTripped.key, original.key);
        expect(roundTripped.type, original.type);
        expect(roundTripped.title, original.title);
        expect(roundTripped.description, original.description);
      }
    });
  });

  group('ExtrasCatalogService.saveAwakeningExtra (14.5)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(const {});
    });

    test('save persiste JSON em SharedPreferences com key correta',
        () async {
      final service = ExtrasCatalogService();
      final spec = AwakeningCeremony.awakeningExtraFor(MissionCategory.fisico);
      await service.saveAwakeningExtra(42, spec);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('awakening_extra_42');
      expect(raw, isNotNull);
      expect(raw, contains('awakening_primeira_forja'));
      expect(raw, contains('A Primeira Forja'));
    });

    test('loadAllForPlayer retorna awakening extra no topo + estáticas',
        () async {
      final service = ExtrasCatalogService();
      final spec = AwakeningCeremony.awakeningExtraFor(
          MissionCategory.espiritual);
      await service.saveAwakeningExtra(7, spec);

      final all = await service.loadAllForPlayer(7);
      expect(all, isNotEmpty);
      expect(all.first.key, 'awakening_primeiro_silencio');
    });

    test('loadAllForPlayer sem awakening salvo retorna só estáticas',
        () async {
      final service = ExtrasCatalogService();
      final all = await service.loadAllForPlayer(999);
      // Não deve ter nenhuma key awakening_*
      expect(
        all.any((s) => s.key.startsWith('awakening_')),
        isFalse,
      );
    });
  });

  group('AwakeningCeremony.scenarios', () {
    test('cada cenário tem exatamente 4 opções, uma por pilar', () {
      expect(AwakeningCeremony.scenarios, hasLength(3));
      for (var i = 0; i < AwakeningCeremony.scenarios.length; i++) {
        final scenario = AwakeningCeremony.scenarios[i];
        final mapsTo = scenario.options.map((o) => o.mapsTo).toSet();
        expect(mapsTo, equals(MissionCategory.values.toSet()),
            reason: 'Cenário #$i precisa mapear os 4 pilares');
      }
    });
  });
}
