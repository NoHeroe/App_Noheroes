import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/enchant_policy.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/models/enchant_result.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';

import '_enchant_fixtures.dart';
import '_item_spec_fixtures.dart';

// Testes da EnchantPolicy (Sprint 2.3 Bloco 3). Padrão idêntico a
// craft_policy_test / item_equip_policy_test: fixtures via helpers, ordem
// de rejeição determinística, assertions focadas em .reason / .allowed.
void main() {
  group('EnchantPolicy.canApply', () {
    const playerLv10E = PlayerSnapshot(
      level: 10,
      rank: GuildRank.e,
      classKey: 'warrior',
    );
    const playerLv20A = PlayerSnapshot(
      level: 20,
      rank: GuildRank.a,
      classKey: 'warrior',
    );
    const playerRogueE = PlayerSnapshot(
      level: 10,
      rank: GuildRank.e,
      classKey: 'rogue',
    );
    const playerShadowWeaverE = PlayerSnapshot(
      level: 10,
      rank: GuildRank.e,
      classKey: 'shadowWeaver',
    );
    const playerNoClassE = PlayerSnapshot(
      level: 10,
      rank: GuildRank.e,
    );

    test('runa de fogo rank E em arma rank E + gems OK → allowed', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(requiredRank: 'E', costGems: 100),
        item: makeItem(type: 'weapon', requiredRank: 'E'),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
      expect(result.appliedEnchant, isNotNull);
      expect(result.replacedEnchant, isNull);
    });

    test('runa em material → itemNotEnchantable', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(),
        item: makeItem(type: 'material', isEquippable: false),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isFalse);
      expect(result.reason, EnchantRejectReason.itemNotEnchantable);
    });

    test('runa em consumable → itemNotEnchantable', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(),
        item: makeItem(type: 'consumable', isEquippable: false),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.reason, EnchantRejectReason.itemNotEnchantable);
    });

    test('runa no Colar da Guilda → itemNotEnchantable (sagrado)', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(),
        item: makeItem(key: 'COLLAR_GUILD', type: 'accessory'),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.reason, EnchantRejectReason.itemNotEnchantable);
    });

    test('runa não está no inventário → enchantNotInInventory', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(),
        item: makeItem(type: 'weapon'),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: false,
      );
      expect(result.reason, EnchantRejectReason.enchantNotInInventory);
    });

    test('runa rank D em item rank E → rankInsufficient', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(requiredRank: 'D'),
        item: makeItem(type: 'weapon', requiredRank: 'E'),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.reason, EnchantRejectReason.rankInsufficient);
    });

    test('runa rank E em item rank A → allowed (rank é piso)', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(requiredRank: 'E'),
        item: makeItem(type: 'weapon', requiredRank: 'A'),
        player: playerLv20A,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test('gems insuficientes → insufficientGems', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(costGems: 500),
        item: makeItem(type: 'weapon'),
        player: playerLv10E,
        playerGems: 100,
        enchantInInventory: true,
      );
      expect(result.reason, EnchantRejectReason.insufficientGems);
    });

    test('runa allowedClasses=[warrior] + player rogue → classRestricted', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(allowedClasses: const ['warrior']),
        item: makeItem(type: 'weapon'),
        player: playerRogueE,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.reason, EnchantRejectReason.classRestricted);
    });

    test('runa allowedClasses=[warrior] + shadowWeaver → allowed (exceção)',
        () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(allowedClasses: const ['warrior']),
        item: makeItem(type: 'weapon'),
        player: playerShadowWeaverE,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test('runa sem allowedClasses aceita qualquer player → allowed', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(allowedClasses: const []),
        item: makeItem(type: 'weapon'),
        player: playerRogueE,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test('slot já ocupado → alreadyEnchantedSameSlot (soft-gate)', () {
      final existing = makeEnchant(key: 'RUNE_OLD');
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(key: 'RUNE_NEW'),
        item: makeItem(type: 'weapon'),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
        currentRuneOnItem: existing,
      );
      expect(result.reason, EnchantRejectReason.alreadyEnchantedSameSlot);
    });

    test('costGems null → custo 0, passa sem gems no bolso', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(costGems: null),
        item: makeItem(type: 'weapon'),
        player: playerLv10E,
        playerGems: 0,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test(
        'ordem determinística: item não-encantável supera rank insuficiente',
        () {
      // Material + rank D (player E) → deveria falhar nos 2, mas retorna
      // itemNotEnchantable (1ª na ordem).
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(requiredRank: 'D'),
        item: makeItem(type: 'material', requiredRank: 'E',
            isEquippable: false),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.reason, EnchantRejectReason.itemNotEnchantable);
    });

    test('runa em armor → allowed', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(),
        item: makeItem(type: 'armor'),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test('runa em shield → allowed', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(),
        item: makeItem(type: 'shield'),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test('runa em accessory (não-Colar) → allowed', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(),
        item: makeItem(key: 'RING_X', type: 'accessory'),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test('rank null da runa → isRankSufficient trata como sempre ok', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(requiredRank: null),
        item: makeItem(type: 'weapon', requiredRank: null),
        player: playerLv10E,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test('player sem classe + runa sem restrição → allowed', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(allowedClasses: const []),
        item: makeItem(type: 'weapon'),
        player: playerNoClassE,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.allowed, isTrue);
    });

    test(
        'player sem classe + runa com allowedClasses → classRestricted '
        '(null-check falha)', () {
      final result = EnchantPolicy.canApply(
        enchant: makeEnchant(allowedClasses: const ['warrior']),
        item: makeItem(type: 'weapon'),
        player: playerNoClassE,
        playerGems: 500,
        enchantInInventory: true,
      );
      expect(result.reason, EnchantRejectReason.classRestricted);
    });
  });
}
