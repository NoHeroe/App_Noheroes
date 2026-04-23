import '../models/mission_context.dart';
import 'mission_strategy.dart';

/// Sprint 3.1 Bloco 6 — família Real (usuário marca via botões -25/+25).
///
/// Jogador pode ultrapassar até **300%** do target pra ganhar bônus da
/// fórmula 0-300% (ADR 0013 §4). Clamp em `[0, target × 3]`.
///
/// `shouldComplete` = true quando `newValue >= targetValue` (100%).
/// Se ultrapassa, mantém shouldComplete=true mas preserva o excedente
/// em currentValue pra o resolver calcular o bônus quando for grantar.
///
/// Usada por: Diárias.
class RealTaskModalityStrategy implements MissionStrategy {
  @override
  bool acceptsInput(MissionContext ctx, StrategyInput input) {
    // Só aceita delta numérico. Inputs com requirementIndex != null são
    // roteados pela MixedModalityStrategy, não chegam aqui como family
    // own — dispatcher só chama RealTask pra missões cuja modality é
    // exatamente `real`.
    if (input is! UserDeltaStrategyInput) return false;
    // Mixed delega com requirementIndex; real simples ignora.
    return input.requirementIndex == null;
  }

  @override
  StrategyStep computeStep(MissionContext ctx, StrategyInput input) {
    final delta = (input as UserDeltaStrategyInput).delta;
    final raw = ctx.currentValue + delta;
    final max = ctx.targetValue * 3; // ADR 0013 §4 limite 300%
    final clamped = raw < 0 ? 0 : (raw > max ? max : raw);
    return StrategyStep(
      newCurrentValue: clamped,
      newMetaJson: ctx.metaJson,
      shouldComplete: clamped >= ctx.targetValue,
    );
  }
}
