import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/domain/card_game/card_catalog.dart';
import 'package:noheroes_app/domain/card_game/card_game.dart';

/// Carrega os JSON gerados diretamente do disco (dart:io) — não depende do
/// rootBundle, que não enxerga assets fora de um app Flutter rodando.
List<CreatureCard> _loadCreatures() =>
    CardCatalog.parseCreatures(File('assets/data/card_game/creatures.json')
        .readAsStringSync());

List<RelicCard> _loadRelics() => CardCatalog.parseRelics(
    File('assets/data/card_game/relics.json').readAsStringSync());

void main() {
  group('catálogo de cartas reais (ACDA)', () {
    test('contagens: 80 criaturas, 176 relíquias', () {
      expect(_loadCreatures().length, 80);
      expect(_loadRelics().length, 176);
    });

    test('todos os conceitos das criaturas são válidos (∈ os 6)', () {
      final valid = CardConcept.values.toSet();
      for (final c in _loadCreatures()) {
        expect(c.concepts, isNotEmpty, reason: '${c.id} sem conceito');
        for (final concept in c.concepts) {
          expect(valid.contains(concept), isTrue);
        }
        // 1 conceito (normal) ou até 2 (elite).
        expect(c.concepts.length, lessThanOrEqualTo(2));
      }
    });

    test('todos os conceitos das relíquias são válidos (∈ os 6)', () {
      final valid = CardConcept.values.toSet();
      for (final r in _loadRelics()) {
        expect(r.concepts, isNotEmpty, reason: '${r.id} sem conceito');
        for (final concept in r.concepts) {
          expect(valid.contains(concept), isTrue);
        }
      }
    });

    test('tipo_dano de toda criatura é válido', () {
      final valid = DamageType.values.toSet();
      for (final c in _loadCreatures()) {
        expect(valid.contains(c.damageType), isTrue);
      }
    });

    test(
        'criaturas com conceito neutro: regra de design (esperado 0) — '
        'exceção documentada nos dados', () {
      final neutras = _loadCreatures()
          .where((c) => c.concepts.contains(CardConcept.neutro))
          .map((c) => c.id)
          .toList();
      // A regra de design diz que não há criaturas neutras. Os dados reais do
      // vault contêm UMA exceção (yuna_lannatary, conceito [neutro] no
      // frontmatter). Não fabricamos/alteramos o dado: travamos exatamente essa
      // exceção conhecida para flagrar se OUTRA criatura neutra aparecer.
      expect(neutras, <String>['yuna_lannatary']);
    });

    test('relíquia neutro é universal (equipa em qualquer criatura)', () {
      final relics = _loadRelics();
      final creatures = _loadCreatures();
      final neutra =
          relics.firstWhere((r) => r.concepts.contains(CardConcept.neutro));
      expect(neutra.isUniversal, isTrue);
      // Compatível com criaturas de qualquer conceito.
      for (final c in creatures) {
        expect(neutra.isCompatibleWith(c), isTrue);
      }
    });

    test('relíquia não-neutra só é compatível por interseção de conceito', () {
      final relics = _loadRelics();
      // Pega uma relíquia puramente celestial e prova a regra de interseção.
      final celestial = relics.firstWhere((r) =>
          r.concepts.length == 1 && r.concepts.first == CardConcept.celestial);
      const celCreature = CreatureCard(
        id: 't',
        nome: 't',
        concepts: [CardConcept.celestial],
        cost: 1,
        atk: 1,
        hp: 1,
        damageType: DamageType.corpoACorpo,
        rarity: Rarity.comum,
      );
      const magCreature = CreatureCard(
        id: 't2',
        nome: 't2',
        concepts: [CardConcept.magico],
        cost: 1,
        atk: 1,
        hp: 1,
        damageType: DamageType.corpoACorpo,
        rarity: Rarity.comum,
      );
      expect(celestial.isCompatibleWith(celCreature), isTrue);
      expect(celestial.isCompatibleWith(magCreature), isFalse);
    });

    test('contagem de flash = 47', () {
      final flash = _loadRelics().where((r) => r.isFlash).length;
      expect(flash, 47);
    });

    test('rawEffect sempre preservado em toda relíquia', () {
      for (final r in _loadRelics()) {
        // Toda carta real tem uma linha de Efeito não-vazia.
        expect(r.grants.rawEffect, isNotEmpty, reason: r.id);
      }
    });
  });
}
