import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/extras_mission_spec.dart';

/// Sprint 3.1 Bloco 11a — card display-only pra missões Extras
/// (DESIGN_DOC §8 aba Extras). Tom **roxo/místico** por padrão pra
/// distinguir das missões gameplay (diárias/classe/facção).
///
/// No 11a o botão "Aceitar" é **placeholder não funcional** — UX de
/// aceitar missão (persistir como `MissionProgress` ativa) fica no
/// 11b junto com form de criação de individual.
///
/// Tipo renderiza badge de cor distinta:
///   - NPC: roxo (cor padrão)
///   - Lore: dourado (narrativa)
///   - Secreta: vermelho (revelada, ênfase)
///   - Evento: cinza (stub — futuro)
class ExtrasCard extends StatelessWidget {
  final ExtrasMissionSpec spec;
  final VoidCallback? onTap;

  const ExtrasCard({super.key, required this.spec, this.onTap});

  Color _badgeColorFor(ExtraMissionType type) {
    switch (type) {
      case ExtraMissionType.npc:
        return AppColors.purple;
      case ExtraMissionType.lore:
        return AppColors.gold;
      case ExtraMissionType.secret:
        return AppColors.hp;
      case ExtraMissionType.event:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = _badgeColorFor(spec.type);
    return Card(
      key: ValueKey('extras-card-${spec.key}'),
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: badgeColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeBadge(type: spec.type, color: badgeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      spec.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (spec.unlockLevel != null)
                    Text('Lvl ${spec.unlockLevel}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        )),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                spec.description,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (spec.narrative != null) ...[
                const SizedBox(height: 8),
                Text(
                  spec.narrative!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (spec.rewardXp > 0)
                    _RewardChip(
                        label: '+${spec.rewardXp} XP', color: badgeColor),
                  const SizedBox(width: 6),
                  if (spec.rewardGold > 0)
                    _RewardChip(
                        label: '+${spec.rewardGold} ouro',
                        color: AppColors.gold),
                  const Spacer(),
                  // TODO(bloco11b): aceitar missão → persiste como
                  // MissionProgress ativa e navega pro fluxo de
                  // tracking. Por enquanto placeholder disabled.
                  TextButton(
                    key: ValueKey('extras-accept-${spec.key}'),
                    onPressed: null,
                    child: const Text('Aceitar (em breve)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final ExtraMissionType type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.display.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RewardChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
