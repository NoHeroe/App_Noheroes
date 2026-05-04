/// Sprint 3.4 Etapa C — buffs de facção em runtime.
///
/// 7 multipliers (3 econômicos + 3 atributos base + 1 status derivado).
/// Aplicação:
/// - Econômicos (`xp`, `gold`, `gems`): aplicados em `RewardGrantService`
///   ANTES do clamp SOULSLIKE. `xpMult` é universal — também aplica em
///   reputação ganha via `FactionReputationService.adjustReputation`.
/// - Atributos (`strength`, `dexterity`, `intelligence`, `maxHp`):
///   aplicados VIRTUALMENTE em runtime via
///   `FactionBuffService.getEffectiveAttributes`. DB persiste valores
///   BASE; ao trocar de facção nada precisa ser revertido.
///
/// Debuff de saída (`hasDebuff=true`):
/// - `xpMult` e `goldMult` viram `0.7` (override completo dos buffs da
///   facção atual).
/// - `gemsMult` e atributos permanecem `1.0` (debuff só afeta fluxo de
///   progressão/economia, não atributos).
class FactionBuffMultipliers {
  final double xpMult;
  final double goldMult;
  final double gemsMult;

  final double strengthMult;
  final double dexterityMult;
  final double intelligenceMult;
  final double maxHpMult;

  final bool hasDebuff;
  final DateTime? debuffEndsAt;

  const FactionBuffMultipliers({
    required this.xpMult,
    required this.goldMult,
    required this.gemsMult,
    required this.strengthMult,
    required this.dexterityMult,
    required this.intelligenceMult,
    required this.maxHpMult,
    required this.hasDebuff,
    required this.debuffEndsAt,
  });

  static const FactionBuffMultipliers neutral = FactionBuffMultipliers(
    xpMult: 1.0,
    goldMult: 1.0,
    gemsMult: 1.0,
    strengthMult: 1.0,
    dexterityMult: 1.0,
    intelligenceMult: 1.0,
    maxHpMult: 1.0,
    hasDebuff: false,
    debuffEndsAt: null,
  );

  /// Returns true if any economic mult differs from 1.0 OR debuff is active.
  /// Atributos isolados não contam aqui — UI separa em "ATRIBUTOS EFETIVOS".
  bool get hasAnyEconomicBuff =>
      xpMult != 1.0 || goldMult != 1.0 || gemsMult != 1.0;

  bool get hasAnyAttributeBuff =>
      strengthMult != 1.0 ||
      dexterityMult != 1.0 ||
      intelligenceMult != 1.0 ||
      maxHpMult != 1.0;
}

/// Snapshot da leitura de buffs — usado por UI/dev panel pra exibir
/// applied (runtime hoje) + pending (descrição narrativa de buffs futuros).
class FactionBuffSnapshot {
  final List<FactionBuffEntry> applied;
  final List<FactionBuffEntry> pending;
  final FactionBuffMultipliers multipliers;

  const FactionBuffSnapshot({
    required this.applied,
    required this.pending,
    required this.multipliers,
  });

  static const FactionBuffSnapshot empty = FactionBuffSnapshot(
    applied: [],
    pending: [],
    multipliers: FactionBuffMultipliers.neutral,
  );
}

class FactionBuffEntry {
  /// "applied" ou "pending"
  final String category;

  /// Texto formatado pra UI: "+10% XP universal", "+15% Defesa (futuro)" etc.
  final String label;

  const FactionBuffEntry({required this.category, required this.label});
}

/// Atributos efetivos do jogador APÓS aplicação dos multipliers da facção.
///
/// Computed virtualmente em `FactionBuffService.getEffectiveAttributes`.
/// `base` = valor real em `players` (pré-buff). `effective` = valor após
/// `floor(base × mult)` (CEO confirmou floor pra atributos — conservador).
/// `delta` = diferença pronta pra UI ("Força: 12 → 13 (+1)").
class EffectiveAttributes {
  final int strengthBase;
  final int strengthEffective;

  final int dexterityBase;
  final int dexterityEffective;

  final int intelligenceBase;
  final int intelligenceEffective;

  final int maxHpBase;
  final int maxHpEffective;

  const EffectiveAttributes({
    required this.strengthBase,
    required this.strengthEffective,
    required this.dexterityBase,
    required this.dexterityEffective,
    required this.intelligenceBase,
    required this.intelligenceEffective,
    required this.maxHpBase,
    required this.maxHpEffective,
  });

  static const EffectiveAttributes empty = EffectiveAttributes(
    strengthBase: 0,
    strengthEffective: 0,
    dexterityBase: 0,
    dexterityEffective: 0,
    intelligenceBase: 0,
    intelligenceEffective: 0,
    maxHpBase: 0,
    maxHpEffective: 0,
  );

  int get strengthDelta => strengthEffective - strengthBase;
  int get dexterityDelta => dexterityEffective - dexterityBase;
  int get intelligenceDelta => intelligenceEffective - intelligenceBase;
  int get maxHpDelta => maxHpEffective - maxHpBase;

  bool get hasAnyDelta =>
      strengthDelta != 0 ||
      dexterityDelta != 0 ||
      intelligenceDelta != 0 ||
      maxHpDelta != 0;
}
