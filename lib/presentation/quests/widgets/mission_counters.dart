import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/mission_progress.dart';

/// Sprint 3.1 Bloco 12 — 3 métricas de missão no header da aba Histórico.
///
/// Derivadas da **mesma lista** que alimenta o `WeeklyMissionsChart` —
/// evita query duplicada. `Hoje` e `Semana` são contagens client-side
/// sobre `missionsLast7Days`. `Total` lê `players.totalQuestsCompleted`
/// (persistido globalmente pelo `RewardGrantService` Bloco 7b bug-fix 4).
///
/// NB: substitui o `_buildDisciplineCard` do `.bak` (que misturava Streak
/// + Hoje + Dia em Caelum — mix de gameplay geral com stats de missão).
/// Aqui só métricas de missão, conforme decisão do CEO no Bloco 12.
class MissionCounters extends StatelessWidget {
  final List<MissionProgress> missionsLast7Days;
  final int totalQuestsCompleted;

  const MissionCounters({
    super.key,
    required this.missionsLast7Days,
    required this.totalQuestsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final today = _countToday(missionsLast7Days);
    final week = missionsLast7Days
        .where((m) => m.completedAt != null)
        .length; // semana conta só completadas — falhas/apagadas não entram
    return Container(
      key: const ValueKey('history-mission-counters'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MISSÕES COMPLETADAS',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.gold,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(
                  label: 'Hoje', value: '$today', color: AppColors.purple),
              _MetricItem(
                  label: 'Semana',
                  value: '$week',
                  color: AppColors.shadowAscending),
              _MetricItem(
                  label: 'Total',
                  value: '$totalQuestsCompleted',
                  color: AppColors.gold),
            ],
          ),
        ],
      ),
    );
  }

  int _countToday(List<MissionProgress> missions) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return missions
        .where((m) =>
            m.completedAt != null &&
            m.completedAt!.isAfter(startOfDay))
        .length;
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 22,
              color: color,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            )),
      ],
    );
  }
}
