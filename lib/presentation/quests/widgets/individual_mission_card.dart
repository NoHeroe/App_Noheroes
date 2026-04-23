import 'package:flutter/material.dart';

import '../../../domain/models/mission_progress.dart';
import 'mission_card_base.dart';

/// Sprint 3.1 Bloco 10a.2 (placeholder do 10a.1) — card da família
/// **individual**. Implementação completa (criação + delete com custo +
/// fórmula 200% impacto sombra) vem no **10a.2**.
///
/// No 10a.1 renderiza apenas um Card indicativo pro dispatcher compilar.
class IndividualMissionCard extends StatelessWidget {
  final MissionProgress mission;

  const IndividualMissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return MissionCardBase(
      mission: mission,
      child: const Text('TODO bloco 10a.2 — IndividualMissionCard'),
    );
  }
}
