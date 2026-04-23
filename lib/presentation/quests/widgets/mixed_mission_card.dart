import 'package:flutter/material.dart';

import '../../../domain/models/mission_progress.dart';
import 'mission_card_base.dart';

/// Sprint 3.1 Bloco 10a.2 (placeholder do 10a.1) — card da família
/// **mixed** (sub-tasks internal + real combo). Implementação completa
/// fica no **10a.2**.
class MixedMissionCard extends StatelessWidget {
  final MissionProgress mission;

  const MixedMissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return MissionCardBase(
      mission: mission,
      child: const Text('TODO bloco 10a.2 — MixedMissionCard'),
    );
  }
}
