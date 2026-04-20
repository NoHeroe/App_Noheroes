import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/equipment_slot.dart';
import 'package:noheroes_app/domain/enums/item_rarity.dart';
import 'package:noheroes_app/domain/enums/item_type.dart';
import 'package:noheroes_app/domain/enums/source_type.dart';
import 'package:noheroes_app/domain/models/item_spec.dart';

void main() {
  group('ItemSpec.fromJson', () {
    test('parseia campos básicos + stats + effects + sources', () {
      final spec = ItemSpec.fromJson({
        'key': 'WEAPON_DAGGER_OLD_E',
        'name': 'Adaga antiga',
        'description': 'Rápida e eficiente.',
        'type': 'weapon',
        'subtype': 'dagger',
        'slot': 'main_hand',
        'rank': 'E',
        'required_rank': 'E',
        'rarity': 'common',
        'is_secret': false,
        'is_unique': false,
        'is_dark_item': false,
        'is_evolving': false,
        'required_level': 1,
        'allowed_classes': const ['rogue'],
        'allowed_factions': const <String>[],
        'stats': const {'atk': 6, 'agi': 8},
        'effects': const <String, dynamic>{},
        'sources': const [
          {'type': 'shop', 'shop_id': 'blacksmith_aureum'},
          {'type': 'loot_world'},
        ],
        'stack_max': 1,
        'is_stackable': false,
        'is_consumable': false,
        'is_equippable': true,
        'is_tradable': true,
        'is_sellable': true,
        'bind_on_pickup': false,
        'enchant_allowed': true,
        'image': 'default.png',
      });

      expect(spec.key, 'WEAPON_DAGGER_OLD_E');
      expect(spec.type, ItemType.weapon);
      expect(spec.slot, EquipmentSlot.mainHand);
      expect(spec.rank, GuildRank.e);
      expect(spec.requiredRank, GuildRank.e);
      expect(spec.rarity, ItemRarity.common);
      expect(spec.stats, {'atk': 6, 'agi': 8});
      expect(spec.allowedClasses, const ['rogue']);
      expect(spec.sources.length, 2);
      expect(spec.sources.first.type, SourceType.shop);
      expect(spec.sources.first.params['shop_id'], 'blacksmith_aureum');
    });

    test('source desconhecida vira type=null mas rawType preservado (forward-compat)', () {
      final spec = ItemSpec.fromJson({
        'key': 'X', 'name': 'x', 'type': 'weapon', 'rarity': 'common',
        'sources': const [{'type': 'future_guild_event'}],
      });
      expect(spec.sources.single.type, isNull);
      expect(spec.sources.single.rawType, 'future_guild_event');
    });

    test('type=dark_item mapeia pra ItemType.darkItem', () {
      final spec = ItemSpec.fromJson({
        'key': 'EBOOK', 'name': 'E-book', 'type': 'dark_item', 'rarity': 'rare',
      });
      expect(spec.type, ItemType.darkItem);
    });

    test('tipo desconhecido cai em ItemType.misc', () {
      final spec = ItemSpec.fromJson({
        'key': 'X', 'name': 'x', 'type': 'gibberish_type', 'rarity': 'common',
      });
      expect(spec.type, ItemType.misc);
    });

    test('evolution_stages parseado como map de EvolutionStage', () {
      final spec = ItemSpec.fromJson({
        'key': 'COLLAR_TEST', 'name': 'Colar', 'type': 'accessory',
        'rarity': 'rare',
        'evolution_stages': const {
          'stage_null': {'description': 'Sem aura.', 'stats': <String, num>{}},
          'stage_E': {'description': 'Aura tênue.', 'stats': {'hp': 5, 'mp': 5}},
        },
      });
      expect(spec.evolutionStages, isNotNull);
      expect(spec.evolutionStages!.length, 2);
      expect(spec.evolutionStages!['stage_E']!.stats, {'hp': 5, 'mp': 5});
    });
  });

  group('ItemSpec equality', () {
    test('itens com mesma key são iguais', () {
      final a = ItemSpec.fromJson({'key': 'K', 'name': 'A', 'type': 'weapon', 'rarity': 'common'});
      final b = ItemSpec.fromJson({'key': 'K', 'name': 'B', 'type': 'armor', 'rarity': 'rare'});
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('itens com keys diferentes NÃO são iguais', () {
      final a = ItemSpec.fromJson({'key': 'A', 'name': 'x', 'type': 'weapon', 'rarity': 'common'});
      final b = ItemSpec.fromJson({'key': 'B', 'name': 'x', 'type': 'weapon', 'rarity': 'common'});
      expect(a == b, isFalse);
    });
  });
}
