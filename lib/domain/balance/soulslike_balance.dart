import '../../core/utils/guild_rank.dart';
import '../models/player_snapshot.dart';

/// Sprint 3.1 Bloco 5 — constantes e funções puras do balanceamento
/// soulslike das rewards (ADR 0013 + ADR 0017).
///
/// **Puro**: nenhuma função aqui toca DB, eventos, ou tempo. Entrada +
/// saída. Testáveis sem mocks.
class SoulslikeBalance {
  const SoulslikeBalance._();

  // ─── Multipliers SOULSLIKE (ADR 0013 §3) ─────────────────────────────
  static const double xpMultiplier = 0.4;
  static const double goldMultiplier = 0.35;
  static const double gemsMultiplier = 0.7;
  static const double seivasMultiplier = 0.5;
  // Items entram na íntegra — já são raros (ADR 0013).
  static const double itemsMultiplier = 1.0;

  // ─── Fórmula 0-300% (ADR 0013 §4) ───────────────────────────────────
  /// Bonus aplicado sobre o excedente de 100% até 300%.
  static const double extraBonusMultiplier = 0.45;

  /// Limite superior do progressPct (300%).
  static const int maxProgressPct = 300;

  // ─── Late-game (ADR 0017) ────────────────────────────────────────────
  /// Nível mínimo pra boost late-game (+5% items S+).
  static const int lateGameMinLevel = 91;

  /// Boost aplicado em pool rank S pra players lvl 91-99.
  static const double lateGameSPlusBonus = 0.05;
}

/// Clampa [pct] em [0, 300]. `maxProgressPct` do ADR 0013.
int clampProgressPct(int pct) {
  if (pct < 0) return 0;
  if (pct > SoulslikeBalance.maxProgressPct) {
    return SoulslikeBalance.maxProgressPct;
  }
  return pct;
}

/// Fórmula 0-300% do ADR 0013 §4.
///
///   - `pct ≤ 100`:   base * (pct / 100) — linear
///   - `100 < pct ≤ 300`: base + base * 0.45 * ((pct - 100) / 100)
///   - `pct > 300`:   clampado em 300 antes de aplicar
///
/// Exemplo (baseAmount=10):
///   -  50% →  5
///   - 100% → 10
///   - 150% → 10 + 10 * 0.45 * 0.5 = 12.25 → 12 (round)
///   - 300% → 10 + 10 * 0.45 * 2.0 = 19
int applyExtraFormula(int baseAmount, int progressPct) {
  if (baseAmount <= 0) return 0;
  final pct = clampProgressPct(progressPct);
  if (pct <= 100) {
    return (baseAmount * pct / 100).round();
  }
  final base = baseAmount.toDouble();
  final excedente = (pct - 100) / 100.0;
  return (base + base * SoulslikeBalance.extraBonusMultiplier * excedente)
      .round();
}

/// Aplica SOULSLIKE multipliers nas 4 currencies de uma vez. Arredonda
/// cada uma pra int individualmente (fidelidade aos exemplos do ADR).
({int xp, int gold, int gems, int seivas}) applySoulslikeCurrency({
  required int xp,
  required int gold,
  required int gems,
  required int seivas,
}) {
  return (
    xp: (xp * SoulslikeBalance.xpMultiplier).round(),
    gold: (gold * SoulslikeBalance.goldMultiplier).round(),
    gems: (gems * SoulslikeBalance.gemsMultiplier).round(),
    seivas: (seivas * SoulslikeBalance.seivasMultiplier).round(),
  );
}

/// Decide se o player é elegível ao boost late-game (ADR 0017): rank S
/// E nível ≥ 91. Usado pra aumentar chance de items S+ no random
/// resolver.
bool isLateGameBoostEligible(PlayerSnapshot player) {
  return player.rank == GuildRank.s &&
      player.level >= SoulslikeBalance.lateGameMinLevel;
}
