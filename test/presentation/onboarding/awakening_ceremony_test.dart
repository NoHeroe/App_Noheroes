import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/enums/mission_category.dart';
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

  group('AwakeningCeremony.initialMissionFor', () {
    test('cada pilar retorna uma spec distinta com targetValue > 0', () {
      final specs = {
        for (final c in MissionCategory.values)
          c: AwakeningCeremony.initialMissionFor(c),
      };
      final keys = specs.values.map((s) => s.missionKey).toSet();
      expect(keys.length, MissionCategory.values.length,
          reason: 'Cada pilar precisa de missionKey único');
      for (final entry in specs.entries) {
        expect(entry.value.targetValue, greaterThan(0),
            reason: '${entry.key.storage} precisa de targetValue positivo');
        expect(entry.value.goalLabel, isNotEmpty,
            reason: '${entry.key.storage} precisa de goalLabel não-vazio');
      }
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
