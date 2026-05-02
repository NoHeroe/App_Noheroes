import '../../../domain/balance/soulslike_balance.dart';
import '../../../domain/models/reward_declared.dart';

/// Sprint 3.3 Etapa Final-B — converte uma `RewardDeclared` (valor cru
/// declarado em `tier_definitions`) em valores **prontos pra display**
/// aplicando os multipliers SOULSLIKE (ADR 0013 §3): xp×0.4, gold×0.35,
/// gems×0.7. Items passam crus (já são raros).
///
/// Uso típico em UI da tela `/achievements` e popup de unlock — alinha
/// o que jogador vê com o que ele realmente vai receber em
/// `claimReward`. Antes desta etapa, a tela mostrava `RewardDeclared`
/// puro e player ganhava ~40% disso → CEO reportou rewards "quebradas"
/// (na verdade era display issue documentado em débito do hotfix 2.2).
///
/// `progressPct=100` fixo: card mostra "como se completasse 100%". A
/// fórmula 0-300% aplica em `RewardResolveService.resolve` runtime
/// quando há overshoot real — display só compromete consistência se
/// tentasse refletir isso, e overshoot é exceção, não regra.
class RewardDisplay {
  final int xp;
  final int gold;
  final int gems;
  final int seivas;
  final List<RewardItemDeclared> items;

  const RewardDisplay({
    required this.xp,
    required this.gold,
    required this.gems,
    required this.seivas,
    required this.items,
  });

  /// Aplica multipliers SOULSLIKE sobre `decl`. `progressPct=100`
  /// (display "como se completasse").
  factory RewardDisplay.fromDeclared(RewardDeclared decl) {
    final after = applySoulslikeCurrency(
      xp: applyExtraFormula(decl.xp, 100),
      gold: applyExtraFormula(decl.gold, 100),
      gems: applyExtraFormula(decl.gems, 100),
      seivas: applyExtraFormula(decl.seivas, 100),
    );
    return RewardDisplay(
      xp: after.xp,
      gold: after.gold,
      gems: after.gems,
      seivas: after.seivas,
      items: decl.items,
    );
  }

  bool get isEmpty =>
      xp == 0 && gold == 0 && gems == 0 && seivas == 0 && items.isEmpty;
}
