import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/vitalism_consumer.dart';

void main() {
  group('consumeSkillCost', () {
    test('vitalismo suficiente → consome só vitalismo, HP intocado', () {
      final r = consumeSkillCost(currentVitalism: 50, currentHp: 100, cost: 30);
      expect(r.newVitalism, 20);
      expect(r.newHp, 100);
    });

    test('vitalismo zerado desde o início → paga 99% do custo em HP', () {
      final r = consumeSkillCost(currentVitalism: 0, currentHp: 100, cost: 50);
      expect(r.newVitalism, 0);
      expect(r.newHp, 50); // 100 - (50 * 0.99).round() = 100 - 50
    });

    test('vitalismo parcial (exemplo do critério de aceite) → zera vitalismo + déficit em HP', () {
      final r = consumeSkillCost(currentVitalism: 30, currentHp: 100, cost: 50);
      expect(r.newVitalism, 0);
      expect(r.newHp, 80); // 100 - (20 * 0.99).round() = 100 - 20
    });

    test('custo zero não muda nada', () {
      final r = consumeSkillCost(currentVitalism: 50, currentHp: 100, cost: 0);
      expect(r.newVitalism, 50);
      expect(r.newHp, 100);
    });

    test('HP não fica negativo quando custo é absurdamente alto', () {
      final r = consumeSkillCost(currentVitalism: 0, currentHp: 10, cost: 1000);
      expect(r.newVitalism, 0);
      expect(r.newHp, 0);
    });

    test('vitalismo exatamente igual ao custo → zera vitalismo sem tocar HP', () {
      final r = consumeSkillCost(currentVitalism: 50, currentHp: 100, cost: 50);
      expect(r.newVitalism, 0);
      expect(r.newHp, 100);
    });
  });
}
