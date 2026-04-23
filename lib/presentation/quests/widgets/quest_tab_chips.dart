import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/quests_screen_notifier.dart';

/// Sprint 3.1 Bloco 10a.1 — chips horizontais das 6 abas de `/quests`.
///
/// Decisão R3-Q1: ListView + chips (não TabController). Mantém scroll
/// lateral + estado único consolidado no Notifier.
class QuestTabChips extends StatelessWidget {
  final QuestTab active;
  final ValueChanged<QuestTab> onSelect;

  const QuestTabChips({
    super.key,
    required this.active,
    required this.onSelect,
  });

  static const _labels = {
    QuestTab.daily: 'Diárias',
    QuestTab.classTab: 'Classe',
    QuestTab.faction: 'Facção',
    QuestTab.extras: 'Extras',
    QuestTab.admission: 'Admissão',
    QuestTab.history: 'Histórico',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: QuestTab.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final tab = QuestTab.values[i];
          final selected = tab == active;
          return ChoiceChip(
            key: ValueKey('quest-tab-${tab.name}'),
            label: Text(_labels[tab]!),
            selected: selected,
            selectedColor: AppColors.purple,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: selected ? AppColors.purple : AppColors.border,
            ),
            onSelected: (_) => onSelect(tab),
          );
        },
      ),
    );
  }
}
