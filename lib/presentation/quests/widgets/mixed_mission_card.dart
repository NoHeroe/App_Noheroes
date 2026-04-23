import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models/mission_progress.dart';
import 'mission_card_base.dart';

/// Sprint 3.1 Bloco 10a.2 — card da família **mixed** (combinação
/// internal+real, ADR 0014 §4).
///
/// ## Estado das sub-tarefas (pattern Bloco 6 MixedModalityStrategy)
///
/// Row em `player_mission_progress` armazena duas listas paralelas no
/// `metaJson`:
///
///   - `requirements_meta`: copiado do catálogo no assignment
///     `[{type, event|name, unit, target}, ...]`
///   - `requirements_progress`: array de ints — current value por sub
///
/// `currentValue` da row = # de requirements completos (0..N);
/// `targetValue` = N.
///
/// ## Renderização
///
/// Header agregado N/M + lista de linhas (1 por sub-task):
///   - **internal**: nome do evento + barra de progresso passiva
///   - **real**: nome + botões ±1/±10/±25 que chamam
///     `MissionProgressService.onUserAction(id, delta,
///     requirementIndex: i)`
///
/// ## Robustez
///
/// Se `metaJson` estiver malformado ou sem `requirements_meta`, o card
/// renderiza placeholder em vez de crashar — missões legacy não
/// assigned pelo novo assignment (Bloco 14) caem nesse caso.
class MixedMissionCard extends ConsumerWidget {
  final MissionProgress mission;

  const MixedMissionCard({super.key, required this.mission});

  Future<void> _applyDelta(
      WidgetRef ref, int delta, int requirementIndex) async {
    final service = ref.read(missionProgressServiceProvider);
    await service.onUserAction(mission.id, delta,
        requirementIndex: requirementIndex);
  }

  /// Tupla simples pra renderização — evita dependência de MissionRequirement
  /// (bloco 3 tem model completo, mas aqui só consumimos o meta copiado).
  List<_RequirementView>? _parseRequirements() {
    try {
      final meta = jsonDecode(mission.metaJson);
      if (meta is! Map<String, dynamic>) return null;
      final metaList = meta['requirements_meta'];
      final progressList = meta['requirements_progress'];
      if (metaList is! List || progressList is! List) return null;
      final out = <_RequirementView>[];
      for (var i = 0; i < metaList.length; i++) {
        final m = metaList[i];
        if (m is! Map<String, dynamic>) return null;
        final type = m['type'] as String?;
        final target = m['target'] as int?;
        if (type == null || target == null) return null;
        final prog = i < progressList.length ? progressList[i] as int? : 0;
        out.add(_RequirementView(
          type: type,
          target: target,
          current: prog ?? 0,
          label:
              (type == 'internal' ? m['event'] : m['name']) as String? ?? '?',
          unit: m['unit'] as String?,
        ));
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqs = _parseRequirements();
    final locked = mission.completedAt != null || mission.failedAt != null;
    return MissionCardBase(
      mission: mission,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${mission.currentValue} / ${mission.targetValue} '
            'requisitos completos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (reqs == null)
            const Text('(sub-tarefas indisponíveis)')
          else
            for (var i = 0; i < reqs.length; i++)
              _SubtaskRow(
                view: reqs[i],
                index: i,
                locked: locked,
                onDelta: (delta) => _applyDelta(ref, delta, i),
              ),
        ],
      ),
    );
  }
}

class _RequirementView {
  final String type;
  final String label;
  final String? unit;
  final int current;
  final int target;
  const _RequirementView({
    required this.type,
    required this.label,
    required this.current,
    required this.target,
    this.unit,
  });
}

class _SubtaskRow extends StatelessWidget {
  final _RequirementView view;
  final int index;
  final bool locked;
  final ValueChanged<int> onDelta;

  const _SubtaskRow({
    required this.view,
    required this.index,
    required this.locked,
    required this.onDelta,
  });

  @override
  Widget build(BuildContext context) {
    final pct =
        view.target == 0 ? 0.0 : (view.current / view.target).clamp(0.0, 1.0);
    final unit = view.unit == null ? '' : ' ${view.unit}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(view.label,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text(
                '${view.current}/${view.target}$unit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: pct),
          if (view.type == 'real' && !locked) ...[
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final d in const [-25, -10, -1, 1, 10, 25])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        key: ValueKey('mixed-sub-$index-delta-$d'),
                        onPressed: () => onDelta(d),
                        child: Text(d > 0 ? '+$d' : '$d'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
