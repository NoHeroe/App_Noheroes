import 'dart:math';

import '../../core/utils/guild_rank.dart';
import '../../data/datasources/local/items_catalog_service.dart';
import '../balance/soulslike_balance.dart';
import '../enums/item_type.dart';
import '../models/player_snapshot.dart';
import '../models/reward_declared.dart';
import '../models/reward_resolved.dart';

/// Regex das chaves random: `{TYPE}_RANDOM_{RANK}` em uppercase.
/// Exemplos válidos: `RUNE_RANDOM_E`, `MATERIAL_RANDOM_D`,
/// `DARK_ITEM_RANDOM_B`.
final _randomKeyRegex = RegExp(r'^([A-Z][A-Z_]*)_RANDOM_([EDCBAS])$');

/// Sprint 3.1 Bloco 5 — resolve `RewardDeclared` (declarativa, vinda do
/// JSON) em `RewardResolved` (quantidades finais + items concretos).
///
/// **Puro** — só lê de `ItemsCatalogService` (cache imutável, carrega
/// do DB 1x na 1ª chamada). Sem writes, sem eventos. Random injetável.
///
/// Contratos aplicados:
///
///   - **ADR 0013 §3** SOULSLIKE multipliers (0.4/0.35/0.7/0.5/1.0)
///   - **ADR 0013 §4** fórmula 0-300% aplicada via [progressPct]
///   - **ADR 0017** rank fixo na key random (`RUNE_RANDOM_E` → rank E).
///     Pool cross-rank (tabela completa do ADR 0017) fica pros blocos 8
///     e 14 quando o consumer cross-rank for implementado;
///     [isLateGameBoostEligible] já está em balance.dart mas não entra
///     no sorteio simples de rank fixo.
class RewardResolveService {
  final ItemsCatalogService _catalog;
  final Random _random;

  /// Construtor. [random] é injetável pra testes determinísticos —
  /// `RewardResolveService(catalog, random: Random(42))` produz a mesma
  /// sequência de sorteios em cada run.
  RewardResolveService(this._catalog, {Random? random})
      : _random = random ?? Random();

  /// Resolve uma reward. Veja docstring da classe pros contratos.
  ///
  /// [progressPct] default 100 = total. Usado em Diárias (família `real`)
  /// pra suportar a fórmula 0-300% — outras abas (classe/facção) que não
  /// distribuem parcial devem passar 100 ou nada.
  Future<RewardResolved> resolve(
    RewardDeclared declared,
    PlayerSnapshot player, {
    int progressPct = 100,
  }) async {
    // 1. Fórmula 0-300% nas currencies.
    final xpAfterFormula =
        applyExtraFormula(declared.xp, progressPct);
    final goldAfterFormula =
        applyExtraFormula(declared.gold, progressPct);
    final gemsAfterFormula =
        applyExtraFormula(declared.gems, progressPct);
    final seivasAfterFormula =
        applyExtraFormula(declared.seivas, progressPct);

    // 2. SOULSLIKE multipliers.
    final finalCurrency = applySoulslikeCurrency(
      xp: xpAfterFormula,
      gold: goldAfterFormula,
      gems: gemsAfterFormula,
      seivas: seivasAfterFormula,
    );

    // 3. Items — roll chance_pct + resolver random.
    final resolvedItems = <RewardItemResolved>[];
    for (final declaredItem in declared.items) {
      // 3a. chance_pct — pode pular o item inteiro.
      if (declaredItem.chancePct < 100 &&
          _random.nextInt(100) >= declaredItem.chancePct) {
        continue;
      }

      // 3b. Se a key é RANDOM, sorteia um item concreto.
      final parsed = _parseRandomKey(declaredItem.key);
      if (parsed == null) {
        // Key literal — passa direto.
        resolvedItems.add(RewardItemResolved(
          key: declaredItem.key,
          quantity: declaredItem.quantity,
        ));
        continue;
      }

      final concreteKey = await _rollRandomItem(parsed.type, parsed.rank);
      if (concreteKey == null) {
        // Pool vazio — ignora silenciosamente (falha de design de
        // catálogo — reporta em debug log pra detectar cedo).
        // ignore: avoid_print
        print('[reward-resolve] pool vazio pra ${parsed.type.name}'
            '/${parsed.rank.name} em key ${declaredItem.key}');
        continue;
      }
      resolvedItems.add(RewardItemResolved(
        key: concreteKey,
        quantity: declaredItem.quantity,
      ));
    }

    return RewardResolved(
      xp: finalCurrency.xp,
      gold: finalCurrency.gold,
      gems: finalCurrency.gems,
      seivas: finalCurrency.seivas,
      items: resolvedItems,
      // Ambos campos abaixo passam intactos — resolver não decide se
      // achievement dispara ou recipe desbloqueia, só repassa pro grant.
      achievementsToCheck: declared.achievementsToCheck,
      recipesToUnlock: declared.recipesToUnlock,
      factionId: declared.factionReputation?.factionId,
      factionReputationDelta: declared.factionReputation?.delta,
    );
  }

  // ─── helpers privados ──────────────────────────────────────────────

  /// Tenta parsear key random. Retorna `null` se for key literal.
  /// Lança [FormatException] se parece random mas o type não mapeia pra
  /// nenhum [ItemType] conhecido — falha rápida aponta o catálogo
  /// malformado.
  ({ItemType type, GuildRank rank})? _parseRandomKey(String key) {
    final m = _randomKeyRegex.firstMatch(key);
    if (m == null) {
      // Não tem formato de random — mas pode ter `_RANDOM_` sem bater
      // o regex (ex: typo). Confere pra falhar rápido em typos.
      if (key.contains('_RANDOM_')) {
        throw FormatException(
            "Key random malformada: '$key' (esperado "
            "{TYPE}_RANDOM_{E|D|C|B|A|S})");
      }
      return null;
    }

    final typeName =
        m.group(1)!.toLowerCase().replaceAll('_', '');
    final rankLetter = m.group(2)!.toLowerCase();

    // Reuse-first — ItemType.fromString aceita snake_case; aqui já
    // normalizamos pra lowercase sem underscore. Comparação por name.
    final type = ItemType.values
        .where((t) => t.name.toLowerCase() == typeName)
        .firstOrNull;
    if (type == null) {
      throw FormatException(
          "Key random com type desconhecido: '$key' "
          "(type='$typeName' não é ItemType válido)");
    }

    final rank = GuildRank.values.firstWhere((r) => r.name == rankLetter);
    return (type: type, rank: rank);
  }

  /// Reuse-first: compõe com `ItemsCatalogService.findByRank` já
  /// existente, filtrando por type em memória. Não adiciona método
  /// novo no catalog (bloco aprovado assim pelo Raul).
  Future<String?> _rollRandomItem(ItemType type, GuildRank rank) async {
    final allOfRank = await _catalog.findByRank(rank);
    final pool = allOfRank.where((i) => i.type == type).toList();
    if (pool.isEmpty) return null;
    final picked = pool[_random.nextInt(pool.length)];
    return picked.key;
  }
}

/// Conveniência de leitura — extension interna.
extension _ListFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
