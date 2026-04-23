import 'dart:convert';

import '../../core/utils/requirements_helper.dart';
import '../models/mission_context.dart';
import 'mission_strategy.dart';

/// Sprint 3.1 Bloco 14.6b — família Individual com requirements múltiplos
/// (fidelidade v0.28.2, ADR 0014 §Família 3).
///
/// Missão individual é um **hábito composto**: a row `player_mission_progress`
/// guarda no `metaJson` um campo `requirements` serializado via
/// [RequirementsHelper]. Cada item é `{label, target, unit, done}`.
///
/// ## Input esperado
///
/// `UserDeltaStrategyInput` com `requirementIndex != null`. Tenta
/// aplicar delta em `requirements[idx].done`, clampa em `[0, target * 3]`
/// (bônus 0-300% do ADR 0013 §4 vale por sub-req), re-serializa. A
/// progressão agregada da row (`currentValue`) vira a soma de todos os
/// `done`.
///
/// ## Sem sub-requirements no metaJson
///
/// Rows sem `metaJson.requirements` (ou malformadas) **não aceitam**
/// input — a strategy retorna `acceptsInput = false`. No reset brutal
/// do Bloco 1 não há individuais legacy; missões assignadas pelo
/// Awakening (14.6a) usam modality `real`, não `individual`.
class IndividualModalityStrategy implements MissionStrategy {
  @override
  bool acceptsInput(MissionContext ctx, StrategyInput input) {
    if (input is! UserDeltaStrategyInput) return false;
    if (input.requirementIndex == null) return false;
    final reqs = _parseRequirements(ctx.metaJson);
    if (reqs == null) return false;
    final idx = input.requirementIndex!;
    return idx >= 0 && idx < reqs.length;
  }

  @override
  StrategyStep computeStep(MissionContext ctx, StrategyInput input) {
    final u = input as UserDeltaStrategyInput;
    final idx = u.requirementIndex!;
    final meta = _parseMeta(ctx.metaJson);
    final reqs = _parseRequirements(ctx.metaJson)!;

    final r = reqs[idx];
    final max = r.target * 3; // ADR 0013 §4 — 300% por sub-req
    final raw = r.done + u.delta;
    final clamped = raw < 0 ? 0 : (raw > max ? max : raw);
    reqs[idx] = RequirementItem(
      label: r.label,
      target: r.target,
      unit: r.unit,
      done: clamped,
    );

    final newCurrent = reqs.fold<int>(0, (s, r) => s + r.done);
    final newMeta = {
      ...meta,
      'requirements': RequirementsHelper.serialize(reqs),
    };

    return StrategyStep(
      newCurrentValue: newCurrent,
      newMetaJson: jsonEncode(newMeta),
      shouldComplete: newCurrent >= ctx.targetValue,
    );
  }

  Map<String, dynamic> _parseMeta(String raw) {
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.cast<String, dynamic>();
    } catch (_) {
      return const {};
    }
  }

  List<RequirementItem>? _parseRequirements(String metaJson) {
    final meta = _parseMeta(metaJson);
    final raw = meta['requirements'];
    if (raw is! String || raw.isEmpty) return null;
    final parsed = RequirementsHelper.parse(raw);
    if (parsed.isEmpty) return null;
    return parsed;
  }
}
