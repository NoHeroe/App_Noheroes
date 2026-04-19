import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/vitalism_calculator.dart';
import 'package:noheroes_app/domain/enums/class_type.dart';

void main() {
  group('VitalismCalculator.calculateMaxVitalism', () {
    const hp = 100;

    group('nível 5 (percentual base sem bônus de curva)', () {
      test('hunter → hp * 1.90 = 190', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.hunter, level: 5,
          ),
          190,
        );
      });

      test('rogue → hp * 2.10 = 210', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.rogue, level: 5,
          ),
          210,
        );
      });

      test('warrior → hp * 2.20 = 220', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.warrior, level: 5,
          ),
          220,
        );
      });

      test('colossus → hp * 2.80 = 280', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.colossus, level: 5,
          ),
          280,
        );
      });

      test('shadowWeaver → hp * 3.00 = 300', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.shadowWeaver, level: 5,
          ),
          300,
        );
      });
    });

    group('nível 25 (percentual base + 20 * 0.02 = +0.40)', () {
      test('hunter → hp * 2.30 = 230', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.hunter, level: 25,
          ),
          230,
        );
      });

      test('rogue → hp * 2.50 = 250', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.rogue, level: 25,
          ),
          250,
        );
      });

      test('warrior → hp * 2.60 = 260', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.warrior, level: 25,
          ),
          260,
        );
      });

      test('colossus → hp * 3.20 = 320', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.colossus, level: 25,
          ),
          320,
        );
      });

      test('shadowWeaver → hp * 3.40 = 340', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.shadowWeaver, level: 25,
          ),
          340,
        );
      });
    });

    group('mana-users retornam 0', () {
      test('druid nível 5 → 0', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.druid, level: 5,
          ),
          0,
        );
      });

      test('monk nível 25 → 0', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.monk, level: 25,
          ),
          0,
        );
      });

      test('mage nível 50 → 0', () {
        expect(
          VitalismCalculator.calculateMaxVitalism(
            hp: hp, classType: ClassType.mage, level: 50,
          ),
          0,
        );
      });
    });

    test('critério de aceite do sprint: shadowWeaver nível 10 → hp * 3.10 = 310', () {
      expect(
        VitalismCalculator.calculateMaxVitalism(
          hp: hp, classType: ClassType.shadowWeaver, level: 10,
        ),
        310,
      );
    });

    test('abaixo do nível 5 não aplica bônus negativo (clamp em 0)', () {
      expect(
        VitalismCalculator.calculateMaxVitalism(
          hp: hp, classType: ClassType.hunter, level: 1,
        ),
        190,
      );
    });

    test('multiplicador 1.5 escala o resultado', () {
      expect(
        VitalismCalculator.calculateMaxVitalism(
          hp: hp, classType: ClassType.warrior, level: 5, multiplier: 1.5,
        ),
        330,
      );
    });
  });
}
