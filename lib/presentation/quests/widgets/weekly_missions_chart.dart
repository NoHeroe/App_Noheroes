import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/mission_progress.dart';

/// Sprint 3.1 Bloco 12 — gráfico semanal de missões completadas (reimplementa
/// o `_buildWeeklyChart` da `shadow_chamber_screen.dart.bak` com fontes do
/// schema 24 — `habit_logs` foi droppada no Bloco 1).
///
/// Consome a lista de missões retornada por `findCompletedInWindow` (janela
/// 7 dias) — agrupa por dia da semana (Dom..Sáb), normaliza pelo peak, e
/// renderiza barras AnimatedContainer.
///
/// Pattern visual clonado do .bak pra manter identidade — dia atual em
/// dourado, demais em verde (ascending) quando > 0, cinza (border) quando 0.
class WeeklyMissionsChart extends StatelessWidget {
  /// Missões não-ativas dos últimos 7 dias (já filtradas pela janela).
  final List<MissionProgress> missionsLast7Days;

  const WeeklyMissionsChart({super.key, required this.missionsLast7Days});

  @override
  Widget build(BuildContext context) {
    // Agrupa por dia da semana (Dom=0..Sáb=6). `failed_at` ou `completed_at`
    // como timestamp canônico (COALESCE).
    final counts = _groupByWeekday(missionsLast7Days);
    final peak = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final denom = peak == 0 ? 1 : peak;
    final todayIdx = DateTime.now().weekday % 7;
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Container(
      key: const ValueKey('history-weekly-chart'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MISSÕES SEMANAIS',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.gold,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                _DayBar(
                  label: days[i],
                  value: counts[i] ?? 0,
                  heightPx: ((counts[i] ?? 0) / denom) * 60,
                  isToday: i == todayIdx,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Map<int, int> _groupByWeekday(List<MissionProgress> missions) {
    final out = <int, int>{};
    final cutoff =
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    for (final m in missions) {
      final ts =
          m.completedAt?.millisecondsSinceEpoch ??
              m.failedAt?.millisecondsSinceEpoch;
      if (ts == null || ts < cutoff) continue;
      final wd = DateTime.fromMillisecondsSinceEpoch(ts).weekday % 7;
      out[wd] = (out[wd] ?? 0) + 1;
    }
    return out;
  }
}

class _DayBar extends StatelessWidget {
  final String label;
  final int value;
  final double heightPx;
  final bool isToday;
  const _DayBar({
    required this.label,
    required this.value,
    required this.heightPx,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final color = isToday
        ? AppColors.gold
        : value > 0
            ? AppColors.shadowAscending
            : AppColors.border;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$value',
            style: TextStyle(
              fontSize: 9,
              color: value > 0
                  ? AppColors.shadowAscending
                  : AppColors.textMuted,
            )),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 28,
          height: heightPx.clamp(4.0, 60.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
              fontSize: 9,
              color: isToday ? AppColors.gold : AppColors.textMuted,
            )),
      ],
    );
  }
}
