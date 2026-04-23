import 'package:flutter/material.dart';

import '../../../domain/models/mission_progress.dart';
import 'mission_card_base.dart';

/// Sprint 3.1 Bloco 10a.1 — card da família **internal**: sistema detecta
/// progresso via EventBus (Bloco 6 strategies). UI é passiva — só
/// mostra barra de progresso + contador.
///
/// Usada nas abas Classe / Facção / Admissão e em algumas Extras.
class InternalMissionCard extends StatelessWidget {
  final MissionProgress mission;

  const InternalMissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final pct = mission.targetValue == 0
        ? 0.0
        : (mission.currentValue / mission.targetValue).clamp(0.0, 1.0);
    return MissionCardBase(
      mission: mission,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: pct),
          const SizedBox(height: 6),
          Text(
            '${mission.currentValue} / ${mission.targetValue}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
