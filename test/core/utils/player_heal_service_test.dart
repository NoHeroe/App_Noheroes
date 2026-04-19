import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/data/datasources/local/player_heal_service.dart';

void main() {
  group('computeHealResult', () {
    group('mana-user (vitalismMax=0)', () {
      test('só o HP muda; currentVitalism intocado', () {
        final r = computeHealResult(
          currentHp: 60, currentVitalism: 0, hpGained: 20,
          hpMax: 100, vitalismMax: 0,
        );
        expect(r.newHp, 80);
        expect(r.newCurrentVitalism, 0);
      });
    });

    group('vitalista', () {
      test('cura 20 em HP=80/100 com vitalismMax=220 → vitalismo sobe 44', () {
        // percGanho = 20/100 = 0.20 ; vitalismoGanho = round(220 * 0.20) = 44
        final r = computeHealResult(
          currentHp: 80, currentVitalism: 0, hpGained: 20,
          hpMax: 100, vitalismMax: 220,
        );
        expect(r.newHp, 100);
        expect(r.newCurrentVitalism, 44);
      });

      test('cura que excede hpMax → hpGainedReal é clampado, vitalismo proporcional ao real', () {
        // currentHp=90, hpGained=30 → newHp=100, hpGainedReal=10
        // percGanho = 10/100 = 0.10 ; vitalismoGanho = round(300 * 0.10) = 30
        final r = computeHealResult(
          currentHp: 90, currentVitalism: 0, hpGained: 30,
          hpMax: 100, vitalismMax: 300,
        );
        expect(r.newHp, 100);
        expect(r.newCurrentVitalism, 30);
      });

      test('vitalismo já perto do teto → clamp em vitalismMax', () {
        // currentVitalism=200, vitalismMax=220, hpGained=20, hpMax=100
        // vitalismoGanho = round(220 * 0.2) = 44 ; 200+44 = 244 → clamp 220
        final r = computeHealResult(
          currentHp: 80, currentVitalism: 200, hpGained: 20,
          hpMax: 100, vitalismMax: 220,
        );
        expect(r.newHp, 100);
        expect(r.newCurrentVitalism, 220);
      });

      test('HP já cheio → hpGainedReal=0, vitalismo não sobe', () {
        final r = computeHealResult(
          currentHp: 100, currentVitalism: 50, hpGained: 30,
          hpMax: 100, vitalismMax: 220,
        );
        expect(r.newHp, 100);
        expect(r.newCurrentVitalism, 50);
      });

      test('cura pequena não zera ganho de vitalismo (round corrige)', () {
        // percGanho = 1/100 = 0.01 ; vitalismoGanho = round(220 * 0.01) = round(2.2) = 2
        final r = computeHealResult(
          currentHp: 99, currentVitalism: 0, hpGained: 1,
          hpMax: 100, vitalismMax: 220,
        );
        expect(r.newHp, 100);
        expect(r.newCurrentVitalism, 2);
      });
    });

    group('edge cases', () {
      test('hpGained=0 → nada muda', () {
        final r = computeHealResult(
          currentHp: 80, currentVitalism: 10, hpGained: 0,
          hpMax: 100, vitalismMax: 220,
        );
        expect(r.newHp, 80);
        expect(r.newCurrentVitalism, 10);
      });

      test('hpMax=0 (estado degenerado) → sem divisão por zero, vitalismo intocado', () {
        final r = computeHealResult(
          currentHp: 0, currentVitalism: 10, hpGained: 5,
          hpMax: 0, vitalismMax: 100,
        );
        expect(r.newHp, 0);
        expect(r.newCurrentVitalism, 10);
      });
    });
  });
}
