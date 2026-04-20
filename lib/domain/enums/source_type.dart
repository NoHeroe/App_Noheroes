// ADR 0010 — 22 fontes canônicas. Forward-compat: string desconhecida → null
// (call-site decide fallback). Alias aceita snake_case (formato do JSON).
enum SourceType {
  shop,
  factionShop,
  guildShop,
  chestCommon,
  chestRare,
  chestEpic,
  chestSecret,
  lootWorld,
  lootBoss,
  lootRegion,
  craft,
  forge,
  enchant,
  questReward,
  factionReward,
  achievement,
  event,
  secretMission,
  ritual,
  starter,
  dropPvp,
  purchaseRealMoney,
  uniqueReward,
}

extension SourceTypeExt on SourceType {
  String get label => switch (this) {
    SourceType.shop              => 'Loja',
    SourceType.factionShop       => 'Loja de Facção',
    SourceType.guildShop         => 'Loja da Guilda',
    SourceType.chestCommon       => 'Baú Comum',
    SourceType.chestRare         => 'Baú Raro',
    SourceType.chestEpic         => 'Baú Épico',
    SourceType.chestSecret       => 'Baú Secreto',
    SourceType.lootWorld         => 'Loot no Mundo',
    SourceType.lootBoss          => 'Loot de Boss',
    SourceType.lootRegion        => 'Loot de Região',
    SourceType.craft             => 'Craft',
    SourceType.forge             => 'Forja',
    SourceType.enchant           => 'Encantamento',
    SourceType.questReward       => 'Recompensa de Quest',
    SourceType.factionReward     => 'Recompensa de Facção',
    SourceType.achievement       => 'Conquista',
    SourceType.event             => 'Evento',
    SourceType.secretMission     => 'Missão Secreta',
    SourceType.ritual            => 'Ritual',
    SourceType.starter           => 'Inicial',
    SourceType.dropPvp           => 'Drop em PvP',
    SourceType.purchaseRealMoney => 'Compra Real',
    SourceType.uniqueReward      => 'Recompensa Única',
  };
}

class SourceTypeParser {
  SourceTypeParser._();

  static const Map<String, SourceType> _byString = {
    'shop':                 SourceType.shop,
    'faction_shop':         SourceType.factionShop,
    'factionShop':          SourceType.factionShop,
    'guild_shop':           SourceType.guildShop,
    'guildShop':            SourceType.guildShop,
    'chest_common':         SourceType.chestCommon,
    'chestCommon':          SourceType.chestCommon,
    'chest_rare':           SourceType.chestRare,
    'chestRare':            SourceType.chestRare,
    'chest_epic':           SourceType.chestEpic,
    'chestEpic':            SourceType.chestEpic,
    'chest_secret':         SourceType.chestSecret,
    'chestSecret':          SourceType.chestSecret,
    'loot_world':           SourceType.lootWorld,
    'lootWorld':            SourceType.lootWorld,
    'loot_boss':            SourceType.lootBoss,
    'lootBoss':             SourceType.lootBoss,
    'loot_region':          SourceType.lootRegion,
    'lootRegion':           SourceType.lootRegion,
    'craft':                SourceType.craft,
    'forge':                SourceType.forge,
    'enchant':              SourceType.enchant,
    'quest_reward':         SourceType.questReward,
    'questReward':          SourceType.questReward,
    'faction_reward':       SourceType.factionReward,
    'factionReward':        SourceType.factionReward,
    'achievement':          SourceType.achievement,
    'event':                SourceType.event,
    'secret_mission':       SourceType.secretMission,
    'secretMission':        SourceType.secretMission,
    'ritual':               SourceType.ritual,
    'starter':              SourceType.starter,
    'drop_pvp':             SourceType.dropPvp,
    'dropPvp':              SourceType.dropPvp,
    'purchase_real_money':  SourceType.purchaseRealMoney,
    'purchaseRealMoney':    SourceType.purchaseRealMoney,
    'unique_reward':        SourceType.uniqueReward,
    'uniqueReward':         SourceType.uniqueReward,
  };

  static SourceType? fromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return _byString[raw];
  }
}
