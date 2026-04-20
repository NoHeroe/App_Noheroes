import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/core/utils/item_equip_policy.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import '_item_spec_fixtures.dart';

void main() {
  group('ItemEquipPolicy.parseRank', () {
    test("'none' → null", () {
      expect(ItemEquipPolicy.parseRank('none'), isNull);
    });

    test("null → null", () {
      expect(ItemEquipPolicy.parseRank(null), isNull);
    });

    test("'E'..'S' uppercase → GuildRank correspondente", () {
      expect(ItemEquipPolicy.parseRank('E'), GuildRank.e);
      expect(ItemEquipPolicy.parseRank('S'), GuildRank.s);
    });

    test("'e' minúsculo → null (espera uppercase após migration)", () {
      expect(ItemEquipPolicy.parseRank('e'), isNull);
    });

    test("string inválida → null", () {
      expect(ItemEquipPolicy.parseRank('Z'), isNull);
      expect(ItemEquipPolicy.parseRank(''), isNull);
    });
  });

  group('ItemEquipPolicy.isRankSufficient', () {
    test('required=null → sempre true', () {
      expect(ItemEquipPolicy.isRankSufficient(null, null), isTrue);
      expect(ItemEquipPolicy.isRankSufficient(GuildRank.e, null), isTrue);
    });

    test('player=null + required!=null → false', () {
      expect(ItemEquipPolicy.isRankSufficient(null, GuildRank.e), isFalse);
    });

    test('player < required → false', () {
      expect(ItemEquipPolicy.isRankSufficient(GuildRank.e, GuildRank.d), isFalse);
    });

    test('player > required → true', () {
      expect(ItemEquipPolicy.isRankSufficient(GuildRank.d, GuildRank.e), isTrue);
    });

    test('player == required → true (S=S)', () {
      expect(ItemEquipPolicy.isRankSufficient(GuildRank.s, GuildRank.s), isTrue);
    });
  });

  group('ItemEquipPolicy.canEquipItem', () {
    const playerLv1 = PlayerSnapshot(level: 1);
    const playerLv10RankE = PlayerSnapshot(level: 10, rank: GuildRank.e);
    const playerLv10RankD = PlayerSnapshot(level: 10, rank: GuildRank.d);
    const warrior = PlayerSnapshot(level: 10, rank: GuildRank.d, classKey: 'warrior');
    const rogue = PlayerSnapshot(level: 10, rank: GuildRank.d, classKey: 'rogue');
    const moonClan = PlayerSnapshot(level: 10, rank: GuildRank.d,
        classKey: 'warrior', factionKey: 'moon_clan');

    test('item não equipável → notEquippable', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(isEquippable: false),
        player: playerLv10RankE,
      );
      expect(r.isOk, isFalse);
      expect(r.reason, RejectReason.notEquippable);
    });

    test('level insuficiente → tooLowLevel', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(requiredLevel: 5),
        player: playerLv1,
      );
      expect(r.reason, RejectReason.tooLowLevel);
    });

    test('player rank null, item requer E → tooLowRank', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(requiredRank: 'E'),
        player: playerLv1,
      );
      expect(r.reason, RejectReason.tooLowRank);
    });

    test('player rank E, item requer D → tooLowRank', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(requiredRank: 'D'),
        player: playerLv10RankE,
      );
      expect(r.reason, RejectReason.tooLowRank);
    });

    test('classe não permitida → classRestricted', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(allowedClasses: const ['warrior']),
        player: rogue,
      );
      expect(r.reason, RejectReason.classRestricted);
    });

    test('classe permitida → ok', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(allowedClasses: const ['warrior']),
        player: warrior,
      );
      expect(r.isOk, isTrue);
    });

    test('allowedClasses vazio → qualquer classe passa', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(),
        player: rogue,
      );
      expect(r.isOk, isTrue);
    });

    test('facção não permitida → factionRestricted', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(allowedFactions: const ['sun_clan']),
        player: moonClan,
      );
      expect(r.reason, RejectReason.factionRestricted);
    });

    test('tudo ok → ok', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(
          requiredLevel: 10,
          requiredRank: 'E',
          allowedClasses: const ['warrior'],
          allowedFactions: const ['moon_clan'],
        ),
        player: moonClan,
      );
      expect(r.isOk, isTrue);
    });

    test('ordem dos checks: level falha antes de rank', () {
      // Player sem rank + lvl baixo: deveria falhar em level primeiro.
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(requiredLevel: 5, requiredRank: 'E'),
        player: playerLv1,
      );
      expect(r.reason, RejectReason.tooLowLevel);
    });

    test('player rank D equipa item que exige rank E → ok', () {
      final r = ItemEquipPolicy.canEquipItem(
        item: makeItem(requiredRank: 'E'),
        player: playerLv10RankD,
      );
      expect(r.isOk, isTrue);
    });
  });

  group('ItemEquipPolicy.aggregateStatsFromEquipment', () {
    test('lista vazia → {}', () {
      expect(ItemEquipPolicy.aggregateStatsFromEquipment(const []), isEmpty);
    });

    test('2 itens com atk=5 + atk=3 → {atk: 8}', () {
      final items = [
        makeItem(key: 'A', stats: const {'atk': 5}),
        makeItem(key: 'B', stats: const {'atk': 3}),
      ];
      expect(ItemEquipPolicy.aggregateStatsFromEquipment(items),
          {'atk': 8});
    });

    test('stats heterogêneos acumulam por chave', () {
      final items = [
        makeItem(key: 'A', stats: const {'atk': 5, 'def': 2}),
        makeItem(key: 'B', stats: const {'atk': 3, 'mp': 10}),
      ];
      expect(
        ItemEquipPolicy.aggregateStatsFromEquipment(items),
        {'atk': 8, 'def': 2, 'mp': 10},
      );
    });
  });

  group('ItemEquipPolicy.aggregateStatsFromEquippedEntries', () {
    // Colar da Guilda mock: is_evolving + 3 stages (null/E/S).
    final collarSpec = makeItem(
      key: 'COLLAR_GUILD',
      type: 'accessory',
      rarity: 'unique',
      isEvolving: true,
      isUnique: true,
      evolutionStages: const {
        'stage_null': {'description': 'Sem aura.', 'stats': <String, num>{}},
        'stage_E':    {'description': 'Aura tênue.',
                       'stats': {'hp': 5, 'mp': 5}},
        'stage_S':    {'description': 'Lenda.',
                       'stats': {'hp': 120, 'mp': 120, 'spi': 25,
                                 'atk': 20, 'def': 20}},
      },
    );

    test('item não-evolving usa spec.stats normal', () {
      final sword = makeItem(key: 'SWORD', stats: const {'atk': 7, 'agi': 3});
      final entry = makeEntry(spec: sword);
      expect(
        ItemEquipPolicy.aggregateStatsFromEquippedEntries([entry]),
        {'atk': 7, 'agi': 3},
      );
    });

    test('Colar com evolution_stage=stage_E usa stats do stage_E', () {
      final entry = makeEntry(spec: collarSpec, evolutionStage: 'stage_E');
      expect(
        ItemEquipPolicy.aggregateStatsFromEquippedEntries([entry]),
        {'hp': 5, 'mp': 5},
      );
    });

    test('Colar com evolution_stage=stage_S usa stats do stage_S (maior)', () {
      final entry = makeEntry(spec: collarSpec, evolutionStage: 'stage_S');
      expect(
        ItemEquipPolicy.aggregateStatsFromEquippedEntries([entry]),
        {'hp': 120, 'mp': 120, 'spi': 25, 'atk': 20, 'def': 20},
      );
    });

    test('Colar com evolution_stage=stage_null usa stage_null (vazio)', () {
      final entry = makeEntry(spec: collarSpec, evolutionStage: 'stage_null');
      expect(
        ItemEquipPolicy.aggregateStatsFromEquippedEntries([entry]),
        isEmpty,
      );
    });

    test('Colar com evolution_stage inválido cai em spec.stats (fallback)', () {
      // collarSpec.stats é {} (só os stages têm stats) — fallback vira vazio.
      final entry =
          makeEntry(spec: collarSpec, evolutionStage: 'stage_gibberish');
      expect(
        ItemEquipPolicy.aggregateStatsFromEquippedEntries([entry]),
        isEmpty,
      );
    });

    test('soma Colar (stage_E) + espada normal', () {
      final sword = makeItem(key: 'SWORD', stats: const {'atk': 7});
      final entries = [
        makeEntry(spec: collarSpec, id: 1, evolutionStage: 'stage_E'),
        makeEntry(spec: sword,       id: 2),
      ];
      expect(
        ItemEquipPolicy.aggregateStatsFromEquippedEntries(entries),
        {'hp': 5, 'mp': 5, 'atk': 7},
      );
    });
  });
}
