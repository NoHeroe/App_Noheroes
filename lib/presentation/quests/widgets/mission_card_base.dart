import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/mission_progress.dart';

/// Sprint 3.1 Bloco 10a.1 — shell comum dos MissionCards.
///
/// Mantém o header (rank + título + status badge) + slot `child` pro
/// conteúdo específico de cada modalidade (barra passiva / botões ± /
/// sub-tasks / etc).
///
/// Responsabilidades intencionalmente mínimas — delega a lógica
/// específica pros cards especializados. Estética polida (partículas,
/// dark-fantasy) fica pro Bloco 10b.
class MissionCardBase extends StatelessWidget {
  final MissionProgress mission;
  final Widget child;
  final VoidCallback? onTap;

  const MissionCardBase({
    super.key,
    required this.mission,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = mission.completedAt != null;
    final isFailed = mission.failedAt != null;
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _RankBadge(rank: mission.rank.name),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mission.missionKey,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCompleted)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20)
                  else if (isFailed)
                    const Icon(Icons.cancel, color: Colors.red, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final String rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rank.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
        ),
      ),
    );
  }
}
