import 'package:flutter/material.dart';

import '../../../domain/enums/mission_category.dart';

/// Sprint 3.1 Bloco 10a.1 — chips multi-select de categoria
/// (Físico / Mental / Espiritual / Vitalismo). Conjunto vazio = "todas".
class CategoryFilterChips extends StatelessWidget {
  final Set<MissionCategory> active;
  final ValueChanged<MissionCategory> onToggle;
  final VoidCallback onClear;

  const CategoryFilterChips({
    super.key,
    required this.active,
    required this.onToggle,
    required this.onClear,
  });

  static const _labels = {
    MissionCategory.fisico: 'Físico',
    MissionCategory.mental: 'Mental',
    MissionCategory.espiritual: 'Espiritual',
    MissionCategory.vitalismo: 'Vitalismo',
  };

  @override
  Widget build(BuildContext context) {
    final anyActive = active.isNotEmpty;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (anyActive)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                key: const ValueKey('category-clear'),
                label: const Text('Limpar'),
                avatar: const Icon(Icons.close, size: 16),
                onPressed: onClear,
              ),
            ),
          for (final cat in MissionCategory.values) ...[
            FilterChip(
              key: ValueKey('category-${cat.storage}'),
              label: Text(_labels[cat]!),
              selected: active.contains(cat),
              onSelected: (_) => onToggle(cat),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
