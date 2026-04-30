import 'app_event.dart';

/// Sprint 3.1 Bloco 2 — eventos de progressão e economia do jogador.

/// Jogador subiu de nível. `previousLevel` facilita diferenciais (ex:
/// milestone popup quando passa de 24 pra 25 libera vitalismo avançado).
class LevelUp extends AppEvent {
  @override
  final int playerId;
  final int newLevel;
  final int previousLevel;

  LevelUp({
    required this.playerId,
    required this.newLevel,
    required this.previousLevel,
    super.at,
  });

  @override
  String toString() =>
      'LevelUp(player=$playerId, $previousLevel→$newLevel)';
}

/// Fontes canônicas de gasto de moedas. String pra evitar acoplar events
/// aos enums de domínio (Bloco 3). Alinhado com ADR 0010 (fontes de
/// aquisição) — inverso aplica aqui como fontes de saída.
class GoldSink {
  static const shop = 'shop';
  static const forge = 'forge';
  static const enchant = 'enchant';
  static const ritual = 'ritual';
  static const individualDelete = 'individual_delete'; // Bloco 11
  static const ascension = 'ascension'; // custo de teste de rank (Bloco 7)
}

/// Ouro foi gasto. Emitido por services que debitam `players.gold` (shop,
/// forge, enchant, ritual, etc.). Strategies internal (Bloco 6) escutam
/// pra quests tipo "gaste 5000 ouro".
class GoldSpent extends AppEvent {
  @override
  final int playerId;
  final int amount;

  /// Fonte canônica — ver [GoldSink].
  final String source;

  GoldSpent({
    required this.playerId,
    required this.amount,
    required this.source,
    super.at,
  });

  @override
  String toString() =>
      'GoldSpent(player=$playerId, amount=$amount, source=$source)';
}

/// Gemas foram gastas. Fontes canônicas reaproveitam [GoldSink] mais:
class GemSink {
  static const shop = 'shop';
  static const enchant = 'enchant'; // custo de runa (Bloco 7a — EnchantService)
  static const recalibration = 'recalibration'; // refazer quiz (Bloco 9)
  static const individualDelete = 'individual_delete'; // Bloco 11
  static const ascension = 'ascension';
}

class GemsSpent extends AppEvent {
  @override
  final int playerId;
  final int amount;

  /// Fonte canônica — ver [GemSink].
  final String source;

  GemsSpent({
    required this.playerId,
    required this.amount,
    required this.source,
    super.at,
  });

  @override
  String toString() =>
      'GemsSpent(player=$playerId, amount=$amount, source=$source)';
}

/// Sprint 3.3 Etapa 2.1c-α — jogador gastou 1 ponto de atributo.
///
/// Emitido pelo caller do [PlayerDao.distributePoint] (UI da tela de
/// atributos / dev panel). PlayerDao mantém-se desacoplado do EventBus
/// (ADR 0016) — retorna o evento como dado, caller publica.
class AttributePointSpent extends AppEvent {
  @override
  final int playerId;

  /// Atributo escolhido — string EN: `'strength'`, `'dexterity'`,
  /// `'intelligence'`, `'constitution'`, `'spirit'`, `'charisma'`.
  /// Mesma string aceita por `PlayerDao.distributePoint`.
  final String attributeKey;

  /// Valor do atributo APÓS o spend.
  final int newValue;

  AttributePointSpent({
    required this.playerId,
    required this.attributeKey,
    required this.newValue,
    super.at,
  });

  @override
  String toString() =>
      'AttributePointSpent(player=$playerId, $attributeKey=$newValue)';
}

/// Sprint 3.3 Etapa 2.1c-α — métricas corporais (peso/altura) salvas.
///
/// Emitido pelo `BodyMetricsService.save` APÓS persistir.
/// [isFirstTime] = `true` quando ambos `weightKg` e `heightCm` estavam
/// `null` antes da save (primeira calibração — onboarding); `false` em
/// edições subsequentes via /perfil.
class BodyMetricsUpdated extends AppEvent {
  @override
  final int playerId;
  final bool isFirstTime;

  BodyMetricsUpdated({
    required this.playerId,
    required this.isFirstTime,
    super.at,
  });

  @override
  String toString() =>
      'BodyMetricsUpdated(player=$playerId, firstTime=$isFirstTime)';
}

/// Sprint 3.3 Etapa 2.1c-α — evento de coordenação interna entre
/// `PlayerCurrencyStatsService` (writer de `players.total_gems_spent`)
/// e `AchievementsService` (reader). Mesmo pattern do
/// `DailyStatsUpdated` (Etapa 2.1b).
///
/// **Não é evento público de domínio**. Stats publica APÓS commit;
/// achievements escuta pra checar trigger `event_gems_spent_total`.
/// Outros consumidores não devem assinar este evento sem revisar a
/// arquitetura.
class CurrencyStatsUpdated extends AppEvent {
  @override
  final int playerId;

  /// `'gems_spent'` no MVP — strings adicionais quando expandirmos
  /// (ex: `'gold_spent'` se shell #5 entrar).
  final String currencyKind;

  CurrencyStatsUpdated({
    required this.playerId,
    required this.currencyKind,
    super.at,
  });

  @override
  String toString() =>
      'CurrencyStatsUpdated(player=$playerId, $currencyKind)';
}
