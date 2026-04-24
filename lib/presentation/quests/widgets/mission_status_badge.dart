import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/mission_progress.dart';

/// Sprint 3.1 Bloco 14.6c — badge textual multi-estado na linha do
/// status da missão (port v0.28.2 `habit_card.dart` linhas 54-67
/// adaptado pro enum `MissionProgressStatus`).
///
/// 4 estados visuais — "Niet" foi retirado do jogo (decisão CEO 14.6c):
///
/// | Status           | Label         | Cor                       |
/// |------------------|---------------|---------------------------|
/// | `completed`      | ✓ Concluído   | `shadowAscending`         |
/// | `partial`        | ◑ Parcial     | `mp`                      |
/// | `failed`         | ✗ Falhou      | `shadowChaotic`           |
/// | `pending`/`inProgress` | Pendente | `textMuted`              |
///
/// Admissão de Facção é **binária por design** (ADR: missão internal
/// com targetValue=1) — nunca vira `partial`, então o badge lá só
/// alterna `pending / completed / failed` naturalmente.
class MissionStatusBadge extends StatelessWidget {
  final MissionProgressStatus status;

  const MissionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status);
    return Text(
      label,
      key: ValueKey('mission-status-badge-${status.name}'),
      style: GoogleFonts.roboto(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static (String, Color) _resolve(MissionProgressStatus status) =>
      switch (status) {
        MissionProgressStatus.completed => (
          '✓ Concluído',
          AppColors.shadowAscending
        ),
        MissionProgressStatus.partial => ('◑ Parcial', AppColors.mp),
        MissionProgressStatus.failed => (
          '✗ Falhou',
          AppColors.shadowChaotic
        ),
        MissionProgressStatus.pending ||
        MissionProgressStatus.inProgress =>
          ('Pendente', AppColors.textMuted),
      };
}
