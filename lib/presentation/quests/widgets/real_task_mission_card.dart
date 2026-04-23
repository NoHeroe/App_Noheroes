import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models/mission_progress.dart';
import 'mission_card_base.dart';

/// Sprint 3.1 Bloco 10a.1 — card da família **real**: jogador marca
/// progresso manualmente via botões ±1/±10/±25.
///
/// Usada nas Diárias. Delega ao `MissionProgressService.onUserAction`
/// (Bloco 6) que aplica a strategy `RealTaskModalityStrategy` e credita
/// reward parcial/total via `RewardGrantService` quando o alvo é atingido.
///
/// UI intencionalmente básica no 10a.1 — barra + ± + progresso + confirm.
/// Bloco 10b polia (timer até meia-noite, partículas, NPC overlay).
class RealTaskMissionCard extends ConsumerWidget {
  final MissionProgress mission;

  const RealTaskMissionCard({super.key, required this.mission});

  Future<void> _applyDelta(WidgetRef ref, int delta) async {
    final service = ref.read(missionProgressServiceProvider);
    await service.onUserAction(mission.id, delta);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = mission.targetValue == 0
        ? 0.0
        : (mission.currentValue / mission.targetValue).clamp(0.0, 1.0);
    final locked = mission.completedAt != null || mission.failedAt != null;
    return MissionCardBase(
      mission: mission,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: pct),
          const SizedBox(height: 6),
          Text('${mission.currentValue} / ${mission.targetValue}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (!locked)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final delta in const [-25, -10, -1, 1, 10, 25])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        key: ValueKey('real-delta-${mission.id}-$delta'),
                        onPressed: () => _applyDelta(ref, delta),
                        child: Text(delta > 0 ? '+$delta' : '$delta'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
