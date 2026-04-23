import '../../core/events/app_event.dart';
import '../models/mission_context.dart';

/// Sprint 3.1 Bloco 6 — Strategy Pattern das 4 famílias de modalidade
/// (ADR 0014).
///
/// Cada família decide:
///   - [acceptsInput] se o input é relevante (filtra ruído)
///   - [computeStep] qual o próximo estado agregado da missão
///
/// **Puro**: nenhuma strategy toca DB, eventos ou tempo. Persistência +
/// emissão de eventos de conclusão vive no `MissionProgressService`
/// (dispatcher).

/// Input polimórfico. Sealed pra garantir exhaustive match em switch.
sealed class StrategyInput {
  const StrategyInput();
}

/// Evento do AppEventBus — consumido por [InternalModalityStrategy] e
/// pelas sub-requirements internal da [MixedModalityStrategy].
class EventStrategyInput extends StrategyInput {
  final AppEvent event;
  const EventStrategyInput(this.event);
}

/// Delta numérico vindo de botões da UI (-25/-10/-1/+1/+10/+25) —
/// consumido por [RealTaskModalityStrategy] e [IndividualModalityStrategy].
/// Mixed usa com [requirementIndex] pra rotear pra sub-req certa.
class UserDeltaStrategyInput extends StrategyInput {
  final int delta;

  /// Só em Mixed: aponta qual requirement (0-based) recebe o delta.
  /// Famílias simples deixam `null`.
  final int? requirementIndex;

  const UserDeltaStrategyInput(this.delta, {this.requirementIndex});
}

/// Resultado imutável de um passo — quem persiste é o dispatcher.
///
/// Unifica "novo currentValue + novo metaJson + flag shouldComplete" num
/// objeto só, evitando 2ª chamada redundante às strategies.
class StrategyStep {
  /// Novo valor agregado da missão.
  final int newCurrentValue;

  /// Novo `meta_json` da row (mudou ou não — strategies simples
  /// devolvem o metaJson original).
  final String newMetaJson;

  /// True quando a missão atingiu o target e deve ser marcada completed.
  /// Strategies não disparam grant — dispatcher faz isso.
  final bool shouldComplete;

  const StrategyStep({
    required this.newCurrentValue,
    required this.newMetaJson,
    required this.shouldComplete,
  });
}

/// Interface comum das 4 famílias.
abstract class MissionStrategy {
  /// Retorna true se este input é relevante pra missão. Dispatcher
  /// ignora quando false (não-op silencioso).
  bool acceptsInput(MissionContext ctx, StrategyInput input);

  /// Computa o próximo estado. **Só é chamado após [acceptsInput]
  /// retornar true** — strategies podem assumir precondições válidas.
  StrategyStep computeStep(MissionContext ctx, StrategyInput input);
}
