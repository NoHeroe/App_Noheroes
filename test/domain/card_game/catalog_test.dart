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
    test('contagens: 80 criaturas, 178 relíquias', () {
      expect(_loadCreatures().length, 80);
      // 176 originais + emblema_do_suporte + trevo_de_quatro_folhas (round 3).
      expect(_loadRelics().length, 178);
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

    test('criatura neutra só pode existir se for Elite (regra de conceitos.md)',
        () {
      // Regra (conceitos.md): criaturas comum→lendária = 1 conceito (não-neutro);
      // criaturas ELITE podem ser neutras. Ex.: yuna_lannatary.
      final neutrasNaoElite = _loadCreatures()
          .where((c) => c.concepts.contains(CardConcept.neutro))
          .where((c) => c.rarity != Rarity.elite)
          .map((c) => c.id)
          .toList();
      expect(neutrasNaoElite, isEmpty,
          reason: 'criatura neutra não-Elite encontrada: $neutrasNaoElite');
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

    test('contagem de flash = 48', () {
      final flash = _loadRelics().where((r) => r.isFlash).length;
      expect(flash, 48);
    });

    test('toda relíquia tem cost >= 0 (custo em cristais do frontmatter)', () {
      final relics = _loadRelics();
      for (final r in relics) {
        expect(r.cost, greaterThanOrEqualTo(0), reason: r.id);
      }
      // Os custos vêm dos dados reais — a maioria é > 0 (não default fabricado).
      expect(relics.where((r) => r.cost > 0).length, greaterThan(100));
    });

    test('rawEffect sempre preservado em toda relíquia', () {
      for (final r in _loadRelics()) {
        // Toda carta real tem uma linha de Efeito não-vazia.
        expect(r.grants.rawEffect, isNotEmpty, reason: r.id);
      }
    });
  });

  group('balanceamento round 3 (CEO 2026-06-14)', () {
    test('teto de custo: nenhuma criatura custa > 5 (≥6 viraram 5)', () {
      for (final c in _loadCreatures()) {
        expect(c.cost, lessThanOrEqualTo(5), reason: '${c.id} cost=${c.cost}');
      }
    });

    test('nerf: nenhum dano melee/vitalismo (base ou extra) > 4', () {
      const nerfTypes = {DamageType.corpoACorpo, DamageType.vitalismo};
      for (final c in _loadCreatures()) {
        if (nerfTypes.contains(c.damageType)) {
          expect(c.atk, lessThanOrEqualTo(4),
              reason: '${c.id} atk=${c.atk} (${c.damageType})');
        }
        c.extraAttacks.forEach((type, value) {
          if (nerfTypes.contains(type)) {
            expect(value, lessThanOrEqualTo(4),
                reason: '${c.id} extra[$type]=$value');
          }
        });
      }
    });

    test('todas as criaturas têm exatamente 1 slot de relíquia base', () {
      for (final c in _loadCreatures()) {
        expect(c.relicSlots, 1, reason: '${c.id} relic_slots=${c.relicSlots}');
      }
    });

    test('Azuos: 4/4 (vitalismo + corpo-a-corpo) + ganha Transformar', () {
      final azuos = _loadCreatures().firstWhere((c) => c.id == 'azuos');
      expect(azuos.atk, 4);
      expect(azuos.extraAttacks[DamageType.corpoACorpo], 4);
      expect(azuos.abilities.contains('transformar'), isTrue);
    });

    test('Emblema do Suporte: neutro, lendária, custo 2, suporte + magnetismo',
        () {
      final r =
          _loadRelics().firstWhere((r) => r.id == 'emblema_do_suporte');
      expect(r.concepts, [CardConcept.neutro]);
      expect(r.rarity, Rarity.lendaria);
      expect(r.cost, 2);
      expect(r.grants.abilities, containsAll(['suporte', 'magnetismo']));
    });

    test('Trevo de Quatro Folhas: neutro, custo 3, armadura 1 + cura 1 + sorte',
        () {
      final r =
          _loadRelics().firstWhere((r) => r.id == 'trevo_de_quatro_folhas');
      expect(r.concepts, [CardConcept.neutro]);
      expect(r.cost, 3);
      expect(r.grants.armor, 1);
      expect(r.grants.heal, 1);
      expect(r.grants.abilities, contains('sorte'));
    });
  });
}
