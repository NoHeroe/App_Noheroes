import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/vitalism_unique_policy.dart';
import 'package:noheroes_app/domain/enums/affinity_tier.dart';

void main() {
  group('VitalismUniquePolicy', () {
    group('calculateLifePointsFromAffinities (placeholders v0.27.0: common=10, rare=50)', () {
      test('lista vazia → 0', () {
        expect(
          VitalismUniquePolicy.calculateLifePointsFromAffinities(const []),
          0,
        );
      });

      test('3 raros mínimos do ritual → 150', () {
        expect(
          VitalismUniquePolicy.calculateLifePointsFromAffinities(
              [AffinityTier.rare, AffinityTier.rare, AffinityTier.rare]),
          150,
        );
      });

      test('3 raros + 5 comuns → 200 (exemplo do vault)', () {
        final affinities = [
          ...List.filled(3, AffinityTier.rare),
          ...List.filled(5, AffinityTier.common),
        ];
        expect(
          VitalismUniquePolicy.calculateLifePointsFromAffinities(affinities),
          200,
        );
      });

      test('8 raros + 10 comuns → 500 (exemplo do vault)', () {
        final affinities = [
          ...List.filled(8, AffinityTier.rare),
          ...List.filled(10, AffinityTier.common),
        ];
        expect(
          VitalismUniquePolicy.calculateLifePointsFromAffinities(affinities),
          500,
        );
      });

      test('special (Vida) conta como 0 — defesa contra entrada inválida', () {
        expect(
          VitalismUniquePolicy.calculateLifePointsFromAffinities(
              [AffinityTier.special]),
          0,
        );
      });
    });

    group('shouldDestroyInsteadOfSteal', () {
      test('winner é Vitalista da Vida → destrói', () {
        expect(
          VitalismUniquePolicy.shouldDestroyInsteadOfSteal(
              winnerIsVitalistaDaVida: true),
          isTrue,
        );
      });

      test('winner comum → rouba normalmente', () {
        expect(
          VitalismUniquePolicy.shouldDestroyInsteadOfSteal(
              winnerIsVitalistaDaVida: false),
          isFalse,
        );
      });
    });

    group('canPerformLifeRitual', () {
      test('3 raros + sem Vida → true', () {
        expect(
          VitalismUniquePolicy.canPerformLifeRitual(
            currentAffinities: [
              AffinityTier.rare,
              AffinityTier.rare,
              AffinityTier.rare,
            ],
            alreadyHasLife: false,
          ),
          isTrue,
        );
      });

      test('2 raros + sem Vida → false', () {
        expect(
          VitalismUniquePolicy.canPerformLifeRitual(
            currentAffinities: [AffinityTier.rare, AffinityTier.rare],
            alreadyHasLife: false,
          ),
          isFalse,
        );
      });

      test('5 raros + já tem Vida → false (intransferível)', () {
        expect(
          VitalismUniquePolicy.canPerformLifeRitual(
            currentAffinities: List.filled(5, AffinityTier.rare),
            alreadyHasLife: true,
          ),
          isFalse,
        );
      });

      test('0 afinidades → false', () {
        expect(
          VitalismUniquePolicy.canPerformLifeRitual(
            currentAffinities: const [],
            alreadyHasLife: false,
          ),
          isFalse,
        );
      });

      test('3 raros + comuns → true (comuns não atrapalham)', () {
        expect(
          VitalismUniquePolicy.canPerformLifeRitual(
            currentAffinities: [
              AffinityTier.rare, AffinityTier.rare, AffinityTier.rare,
              AffinityTier.common, AffinityTier.common,
            ],
            alreadyHasLife: false,
          ),
          isTrue,
        );
      });
    });

    group('validateLifeRitualSacrifices', () {
      final owned = <String, AffinityTier>{
        'shadow': AffinityTier.rare,
        'void':   AffinityTier.rare,
        'time':   AffinityTier.rare,
        'light':  AffinityTier.rare,
        'fire':   AffinityTier.common,
      };

      test('3 raros distintos em posse → true', () {
        expect(
          VitalismUniquePolicy.validateLifeRitualSacrifices(
            sacrificedIds: ['shadow', 'void', 'time'],
            ownedByTier: owned,
          ),
          isTrue,
        );
      });

      test('2 ids só → false', () {
        expect(
          VitalismUniquePolicy.validateLifeRitualSacrifices(
            sacrificedIds: ['shadow', 'void'],
            ownedByTier: owned,
          ),
          isFalse,
        );
      });

      test('4 ids → false', () {
        expect(
          VitalismUniquePolicy.validateLifeRitualSacrifices(
            sacrificedIds: ['shadow', 'void', 'time', 'light'],
            ownedByTier: owned,
          ),
          isFalse,
        );
      });

      test('um dos ids não está em posse → false', () {
        expect(
          VitalismUniquePolicy.validateLifeRitualSacrifices(
            sacrificedIds: ['shadow', 'void', 'ether'],
            ownedByTier: owned,
          ),
          isFalse,
        );
      });

      test('um dos ids é comum (não raro) → false', () {
        expect(
          VitalismUniquePolicy.validateLifeRitualSacrifices(
            sacrificedIds: ['shadow', 'void', 'fire'],
            ownedByTier: owned,
          ),
          isFalse,
        );
      });

      test('ids duplicados (mesmo raro 2x) → false', () {
        expect(
          VitalismUniquePolicy.validateLifeRitualSacrifices(
            sacrificedIds: ['shadow', 'shadow', 'void'],
            ownedByTier: owned,
          ),
          isFalse,
        );
      });
    });

    group('pickRandomFromPool', () {
      test('pool vazio → null', () {
        expect(
          VitalismUniquePolicy.pickRandomFromPool(const [], Random(42)),
          isNull,
        );
      });

      test('pool com 1 → sempre retorna ele', () {
        expect(
          VitalismUniquePolicy.pickRandomFromPool(['fire'], Random(42)),
          'fire',
        );
      });

      test('pool com N → retorna algum do pool (seed determinístico)', () {
        final pool = ['fire', 'water', 'wind', 'stone'];
        final rng = Random(1);
        final picked = VitalismUniquePolicy.pickRandomFromPool(pool, rng);
        expect(pool.contains(picked), isTrue);
      });

      test('mesma seed produz mesmo resultado (determinismo)', () {
        final pool = ['fire', 'water', 'wind', 'stone'];
        final a = VitalismUniquePolicy.pickRandomFromPool(pool, Random(7));
        final b = VitalismUniquePolicy.pickRandomFromPool(pool, Random(7));
        expect(a, b);
      });
    });
  });
}
