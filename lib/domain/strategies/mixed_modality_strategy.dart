import 'dart:convert';

import '../models/mission_context.dart';
import '../models/reward_declared.dart';
import 'internal_modality_strategy.dart';
import 'mission_strategy.dart';
import 'real_task_modality_strategy.dart';

/// Sprint 3.1 Bloco 6 — família Mixed (combo internal + real, ADR 0014
/// §Família 4).
///
/// Estado por sub-requirement mora em `metaJson` da row:
///
/// ```json
/// {
///   "requirements_progress": [3, 5],
///   "requirements_meta": [
///     {"internal_event": "ItemCrafted", "target": 3},
///     {"target": 15}
///   ]
/// }
/// ```
///
/// Invariantes:
///   - `requirements_progress` é array paralelo ao
///     `MissionDefinition.requirements`
///   - `currentValue` da row = # de requirements completados (0..N)
///   - `targetValue` da row = N (total de requirements)
///
/// UI do Bloco 10 desagrega o array pra renderizar barras por sub-task.
///
/// Mixed NÃO tem estado próprio — delega pros 2 helpers usando
/// sub-contexts sintéticos.
class MixedModalityStrategy implements MissionStrategy {
  final InternalModalityStrategy _internal;
  final RealTaskModalityStrategy _real;

  MixedModalityStrategy(this._internal, this._real);

  @override
  bool acceptsInput(MissionContext ctx, StrategyInput input) {
    final meta = _parseMeta(ctx.metaJson);
    final reqMetas = _parseReqMetas(meta);
    final reqProgress = _parseReqProgress(meta, reqMetas.length);

    if (input is EventStrategyInput) {
      // Aceita se algum req internal ainda não-completo aceita o evento.
      for (var i = 0; i < reqMetas.length; i++) {
        final rm = reqMetas[i];
        if (rm['internal_event'] == null) continue;
        if (reqProgress[i] >= (rm['target'] as int)) continue;
        final sub = _subContext(ctx, rm, reqProgress[i]);
        if (_internal.acceptsInput(sub, input)) return true;
      }
      return false;
    }
    if (input is UserDeltaStrategyInput) {
      final idx = input.requirementIndex;
      if (idx == null || idx < 0 || idx >= reqMetas.length) return false;
      // Só delta pra requirement real (sem internal_event).
      if (reqMetas[idx]['internal_event'] != null) return false;
      return true;
    }
    return false;
  }

  @override
  StrategyStep computeStep(MissionContext ctx, StrategyInput input) {
    final meta = _parseMeta(ctx.metaJson);
    final reqMetas = _parseReqMetas(meta);
    final reqProgress = _parseReqProgress(meta, reqMetas.length);

    final newProgress = List<int>.from(reqProgress);

    if (input is EventStrategyInput) {
      // Aplica em todos os requirements internal que aceitam o evento e
      // ainda não estão completos.
      for (var i = 0; i < reqMetas.length; i++) {
        final rm = reqMetas[i];
        final target = rm['target'] as int;
        if (rm['internal_event'] == null) continue;
        if (newProgress[i] >= target) continue;
        final sub = _subContext(ctx, rm, newProgress[i]);
        if (!_internal.acceptsInput(sub, input)) continue;
        final step = _internal.computeStep(sub, input);
        newProgress[i] = step.newCurrentValue > target
            ? target
            : step.newCurrentValue;
      }
    } else if (input is UserDeltaStrategyInput) {
      final idx = input.requirementIndex!;
      final rm = reqMetas[idx];
      final target = rm['target'] as int;
      final sub = _subContext(ctx, rm, newProgress[idx]);
      final step = _real.computeStep(
        sub,
        UserDeltaStrategyInput(input.delta),
      );
      // Real clampa em target*3, mas pro agregado da mixed contamos
      // até o target (parcial excedente não faz sentido pra sub-req).
      newProgress[idx] =
          step.newCurrentValue > target ? target : step.newCurrentValue;
      if (newProgress[idx] < 0) newProgress[idx] = 0;
    }

    // Agregado: # de requirements em que newProgress[i] >= target[i].
    var completedCount = 0;
    for (var i = 0; i < reqMetas.length; i++) {
      if (newProgress[i] >= (reqMetas[i]['target'] as int)) completedCount++;
    }

    final newMeta = {
      ...meta,
      'requirements_progress': newProgress,
      'requirements_meta': reqMetas,
    };

    return StrategyStep(
      newCurrentValue: completedCount,
      newMetaJson: jsonEncode(newMeta),
      shouldComplete: completedCount >= ctx.targetValue,
    );
  }

  /// Cria MissionContext sintético pra delegação. O sub-contexto
  /// herda playerId/modality/tabOrigin da parent mas redefine target +
  /// current + metaJson pra simular um requirement isolado.
  MissionContext _subContext(
    MissionContext parent,
    Map<String, dynamic> reqMeta,
    int currentReqValue,
  ) {
    final subMetaJson = jsonEncode({
      // Preserva `internal_event` pro InternalModalityStrategy ler.
      if (reqMeta['internal_event'] != null)
        'internal_event': reqMeta['internal_event'],
    });
    return MissionContext(
      missionProgressId: parent.missionProgressId,
      playerId: parent.playerId,
      missionKey: parent.missionKey,
      modality: parent.modality,
      tabOrigin: parent.tabOrigin,
      currentValue: currentReqValue,
      targetValue: reqMeta['target'] as int,
      rewardDeclared: const RewardDeclared(), // irrelevante pra strategy pura
      metaJson: subMetaJson,
    );
  }

  Map<String, dynamic> _parseMeta(String raw) {
    if (raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return decoded.cast<String, dynamic>();
  }

  List<Map<String, dynamic>> _parseReqMetas(Map<String, dynamic> meta) {
    final raw = meta['requirements_meta'];
    if (raw is! List) return const [];
    return raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  List<int> _parseReqProgress(Map<String, dynamic> meta, int expectedLength) {
    final raw = meta['requirements_progress'];
    if (raw is! List) return List.filled(expectedLength, 0);
    final out = raw.map((e) => e as int).toList();
    // Normaliza tamanho em caso de meta desalinhada (ex: evolução do
    // template da missão no catálogo sem migration).
    if (out.length < expectedLength) {
      out.addAll(List.filled(expectedLength - out.length, 0));
    }
    return out;
  }
}
