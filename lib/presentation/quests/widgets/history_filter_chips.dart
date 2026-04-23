import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.1 Bloco 12 — estados de filtro da aba Histórico. Client-side
/// sobre a lista `findHistorical` (Bloco 10a.1) — sem query dedicada.
///
/// `todas` = sem filtro. `concluidas` = `completed_at != null`.
/// `falhadas` = `failed_at != null` (agrega deletedByUser/expired/abandoned —
/// distinção visual fica na badge do `HistoryMissionCard`).
enum HistoryFilter { todas, concluidas, falhadas }

extension HistoryFilterExt on HistoryFilter {
  String get label => switch (this) {
        HistoryFilter.todas => 'Todas',
        HistoryFilter.concluidas => 'Concluídas',
        HistoryFilter.falhadas => 'Falhadas',
      };
}

class HistoryFilterChips extends StatelessWidget {
  final HistoryFilter active;
  final ValueChanged<HistoryFilter> onSelect;

  const HistoryFilterChips({
    super.key,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: HistoryFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = HistoryFilter.values[i];
          final selected = f == active;
          return ChoiceChip(
            key: ValueKey('history-filter-${f.name}'),
            label: Text(f.label),
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
            onSelected: (_) => onSelect(f),
          );
        },
      ),
    );
  }
}
