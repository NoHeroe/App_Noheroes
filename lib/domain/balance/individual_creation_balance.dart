/// Sprint 3.1 Bloco 11a — constantes de balanceamento pra criação de
/// missões individuais (ADR 0014 §Família Individual + DESIGN_DOC §8).
///
/// Separado de `soulslike_balance.dart` pra manter aquele arquivo puro
/// (SOULSLIKE multipliers + fórmula 0-300% só). Separado também de
/// `individual_delete_cost.dart` — este trata de **criação**, aquele
/// de **delete**.
class IndividualCreationBalance {
  const IndividualCreationBalance._();

  /// Limite de missões individuais **ativas** (não completadas / não
  /// falhadas / não deletadas) por jogador no tier FREE. ADR 0014:
  /// FREE=5, PRO=ilimitado. PRO ainda não existe no schema — toda
  /// conta é FREE efetivamente.
  ///
  /// TODO(monetization-sprint): quando sistema de monetização chegar,
  /// adicionar `players.is_pro` e usar `kMaxActiveIndividualsPro` =
  /// `int.maxFinite` (ou desabilitar check) pra essas contas.
  static const int kMaxActiveIndividualsFree = 5;

  /// Penalidade aplicada à reward quando a missão individual é
  /// **repetível** (vira diária). Desincentiva oversupply por criar 5
  /// repetíveis simples e coletar reward infinita.
  ///
  /// `0.7` = 70% da reward base. Valor **placeholder** — ADR 0014 + ADR
  /// 0013 + Sprint_Missoes Bloco 11 não especificam penalidade exata.
  /// TODO(bloco15.5): reavaliar com dados de uso real e ajustar.
  static const double kRepetivelPenalty = 0.7;

  /// Mapeia `Intensity` → multiplicador da fórmula base do balancer.
  /// Só intensidades criáveis (leve/médio/pesado). Adaptativo é da
  /// calibração (Bloco 9), não entra em criação.
  ///
  /// Valores 1/2/3 alinham com progressão linear — pesado dá 3x mais
  /// reward que leve. SOULSLIKE multipliers em cima dão o ajuste final.
  static const int intensityMultiplierLight = 1;
  static const int intensityMultiplierMedium = 2;
  static const int intensityMultiplierHeavy = 3;
}
