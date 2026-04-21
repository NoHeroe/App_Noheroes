import '../../domain/enums/item_rarity.dart';
import '../../domain/enums/item_type.dart';
import '../../domain/enums/source_type.dart';
import '../../domain/models/item_spec.dart';
import 'guild_rank.dart';

// Política canônica de fontes de aquisição — ADR 0010.
//
// - canAppearInShop: defense-in-depth. Mesmo que o seed tenha 'shop' em sources
//   pra tipo proibido, o runtime rejeita. Rejeita também por flags (secret,
//   unique, evolving). E exige que 'shop' efetivamente esteja em sources.
// - defaultSourcesForType: mapa estratégico usado por geração de conteúdo.
// - validateCatalogEntry: lista de strings de erro pra auditoria do catálogo.
class ItemSourcePolicy {
  ItemSourcePolicy._();

  // Tipos que NUNCA podem ter 'shop' em sources (lore/ADR 0010).
  static const Set<ItemType> _forbiddenInShopByType = {
    ItemType.relic,
    ItemType.chest,
    ItemType.key,
    ItemType.title,
    ItemType.cosmetic,
    ItemType.lore,
    ItemType.currency,
    ItemType.darkItem,
  };

  static bool canAppearInShop(ItemSpec item) {
    if (_forbiddenInShopByType.contains(item.type)) return false;
    if (item.isSecret || item.isUnique || item.isEvolving) return false;
    return item.sources.any((s) => s.type == SourceType.shop);
  }

  // Sources padrão pra um tipo/rank/rarity/flags (ADR 0010, tabela canônica).
  // Usado por geração de conteúdo e validação; não substitui sources explícitas.
  static List<SourceType> defaultSourcesForType({
    required ItemType type,
    GuildRank? rank,
    required ItemRarity rarity,
    bool isSecret = false,
    bool isUnique = false,
    bool isDark = false,
  }) {
    // Flags sobreescrevem regras por tipo.
    if (isDark) {
      return const [SourceType.purchaseRealMoney, SourceType.achievement];
    }
    if (isUnique) {
      return const [SourceType.uniqueReward, SourceType.questReward];
    }
    if (isSecret) {
      return const [SourceType.secretMission, SourceType.achievement];
    }

    switch (type) {
      case ItemType.weapon:
      case ItemType.armor:
      case ItemType.accessory:
      case ItemType.shield:
      case ItemType.tome:
        return _sourcesForGearByRank(rank);

      case ItemType.relic:
        return const [
          SourceType.achievement, SourceType.secretMission,
          SourceType.ritual, SourceType.uniqueReward,
        ];
      case ItemType.chest:
        return const [SourceType.lootBoss, SourceType.event, SourceType.questReward];
      case ItemType.key:
        return const [SourceType.lootRegion, SourceType.questReward];
      case ItemType.title:
        return const [
          SourceType.achievement, SourceType.questReward, SourceType.factionReward,
        ];
      case ItemType.cosmetic:
        return const [
          SourceType.achievement, SourceType.factionReward, SourceType.event,
          SourceType.factionShop, SourceType.guildShop,
        ];
      case ItemType.lore:
        return const [
          SourceType.secretMission, SourceType.questReward, SourceType.achievement,
        ];
      case ItemType.currency:
        return const [SourceType.event, SourceType.achievement, SourceType.questReward];
      case ItemType.darkItem:
        return const [SourceType.purchaseRealMoney, SourceType.achievement];

      case ItemType.consumable:
        if (rarity.index <= ItemRarity.uncommon.index) {
          return const [SourceType.shop, SourceType.lootWorld, SourceType.chestCommon];
        }
        return const [
          SourceType.shop, SourceType.chestRare, SourceType.craft, SourceType.questReward,
        ];

      case ItemType.material:
        if (rarity.index <= ItemRarity.uncommon.index) {
          return const [SourceType.lootWorld, SourceType.craft];
        }
        return const [
          SourceType.lootBoss, SourceType.chestRare, SourceType.craft, SourceType.lootRegion,
        ];

      // Sprint 2.3 — runas: drop via world/boss + quest reward. Fragment rare
      // em B via chest_rare. Sem shop direct (gemstore usa shop_price_gems).
      case ItemType.rune:
        if (rarity.index <= ItemRarity.uncommon.index) {
          return const [SourceType.lootWorld, SourceType.questReward];
        }
        return const [
          SourceType.lootBoss, SourceType.chestRare, SourceType.questReward,
        ];

      case ItemType.misc:
        return const [SourceType.shop, SourceType.lootWorld];
    }
  }

  static List<SourceType> _sourcesForGearByRank(GuildRank? rank) {
    if (rank == null) {
      // Starter gear — antes da Guilda.
      return const [SourceType.starter, SourceType.shop];
    }
    switch (rank) {
      case GuildRank.e:
      case GuildRank.d:
        return const [
          SourceType.shop, SourceType.lootWorld,
          SourceType.chestCommon, SourceType.craft,
        ];
      case GuildRank.c:
      case GuildRank.b:
        return const [
          SourceType.shop, SourceType.lootBoss, SourceType.chestRare,
          SourceType.craft, SourceType.forge, SourceType.questReward,
        ];
      case GuildRank.a:
        return const [
          SourceType.lootBoss, SourceType.chestEpic, SourceType.forge,
          SourceType.questReward, SourceType.factionReward,
        ];
      case GuildRank.s:
        return const [
          SourceType.achievement, SourceType.secretMission,
          SourceType.ritual, SourceType.uniqueReward,
        ];
    }
  }

  // Auditoria de catálogo — retorna lista de erros pra cada violação.
  static List<String> validateCatalogEntry(ItemSpec item) {
    final errors = <String>[];

    // 1. Tipos proibidos com 'shop' em sources.
    if (_forbiddenInShopByType.contains(item.type)) {
      final hasShop = item.sources.any((s) => s.type == SourceType.shop);
      if (hasShop) {
        errors.add('${item.key}: type=${item.type.name} não pode ter '
            "'shop' em sources (ADR 0010)");
      }
    }

    // 2. Flags que proíbem shop.
    if ((item.isSecret || item.isUnique || item.isEvolving) &&
        item.sources.any((s) => s.type == SourceType.shop)) {
      final flags = <String>[
        if (item.isSecret)   'is_secret',
        if (item.isUnique)   'is_unique',
        if (item.isEvolving) 'is_evolving',
      ].join('+');
      errors.add('${item.key}: flags [$flags] não podem coexistir com '
          "'shop' em sources (ADR 0010)");
    }

    // 3. Dark items têm sources restritas.
    if (item.isDarkItem) {
      for (final s in item.sources) {
        final t = s.type;
        if (t != SourceType.purchaseRealMoney &&
            t != SourceType.achievement &&
            t != null) {
          errors.add('${item.key}: is_dark_item=true só aceita '
              "sources purchase_real_money/achievement (recebido: ${s.rawType})");
        }
      }
    }

    return errors;
  }
}
