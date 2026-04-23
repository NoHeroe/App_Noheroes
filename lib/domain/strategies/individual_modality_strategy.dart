import 'real_task_modality_strategy.dart';

/// Sprint 3.1 Bloco 6 — família Individual (criada pelo jogador + marca).
///
/// Comportamento idêntico ao [RealTaskModalityStrategy] no que diz
/// respeito ao delta e clamp 0..300%. A diferença semântica está na
/// **falha** (impacto Sombra 200% do padrão, ADR 0014 §Família 3) e no
/// fluxo de criação/delete (FREE=5, custo pra delete repetível) — mas
/// essas regras vivem na UI (Bloco 11) e no reward resolver (Bloco 5),
/// não na strategy em si.
///
/// Estendo [RealTaskModalityStrategy] e sobrescrevo só o que difere
/// (nada por enquanto — o gancho fica aberto pro Bloco 11).
class IndividualModalityStrategy extends RealTaskModalityStrategy {}
