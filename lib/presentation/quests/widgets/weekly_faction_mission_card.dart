import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/services/faction_admission_validator.dart'
    show SubTaskEvaluation;
import '../../../domain/services/weekly_faction_validator.dart';

/// FATIA B3 — card da missão de facção SEMANAL (motor acumulativo B1/B2).
///
/// **Sibling** do `AdmissionMissionCard`, com 3 diferenças:
/// - **SEM** placeholder de cadeado — a semanal não tem lock/
///   sequenciamento; todas as sub-tasks abrem desde o assign.
/// - **Countdown até `week_end_ms`** (timestamp absoluto da virada da
///   semana), não `window_duration_ms`.
/// - Avalia via `weeklyFactionValidatorProvider`, passando
///   `week_start_ms`/`week_end_ms` do metaJson pra mostrar current/target
///   ao vivo por sub-task. `equipment_improved` lê o `current` do próprio
///   subTask (persistido pelo listener B2b).
class WeeklyFactionMissionCard extends ConsumerStatefulWidget {
  final MissionProgress mission;

  const WeeklyFactionMissionCard({super.key, required this.mission});

  @override
  ConsumerState<WeeklyFactionMissionCard> createState() =>
      _WeeklyFactionMissionCardState();
}

class _WeeklyFactionMissionCardState
    extends ConsumerState<WeeklyFactionMissionCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _decodeMetaFrom(String metaJson) {
    try {
      final raw = jsonDecode(metaJson);
      if (raw is Map<String, dynamic>) return raw;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Stream do DB pra reagir a sub-task completed (listener B2b) sem
    // depender de invalidação manual. Fallback pro metaJson original.
    final streamRow = ref
        .watch(missionProgressStreamProvider(widget.mission.id))
        .valueOrNull;
    final liveMetaJson = streamRow?.metaJson ?? widget.mission.metaJson;

    final meta = _decodeMetaFrom(liveMetaJson);
    if (meta == null) return const SizedBox.shrink();

    final title = (meta['title'] as String?) ?? widget.mission.missionKey;
    final description = meta['description'] as String?;
    final subTasks = (meta['sub_tasks'] as List?) ?? const [];
    final weekStartMs = (meta['week_start_ms'] as int?) ?? 0;
    final weekEndMs = (meta['week_end_ms'] as int?) ?? 0;
    final remaining = _computeRemaining(weekEndMs);
    final completedCount = subTasks
        .where((s) =>
            (s as Map).cast<String, dynamic>()['completed'] == true)
        .length;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _RankBadge(rank: widget.mission.rank.name),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
                Text('$completedCount/${subTasks.length}',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(description,
                  style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 8),
            ...subTasks.map((s) => _WeeklySubTaskRow(
                  data: (s as Map).cast<String, dynamic>(),
                  playerId: widget.mission.playerId,
                  weekStartMs: weekStartMs,
                  weekEndMs: weekEndMs,
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                    remaining == null
                        ? 'semana: —'
                        : 'fecha em: $remaining',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tempo restante até `week_end_ms`. Null se ausente; 'expirada' se já
  /// passou. Formato Dd HH:MM (a semana pode ter dias).
  String? _computeRemaining(int weekEndMs) {
    if (weekEndMs == 0) return null;
    final remainingMs = weekEndMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return 'expirada';
    final days = remainingMs ~/ (24 * 60 * 60 * 1000);
    final hours = (remainingMs ~/ (60 * 60 * 1000)) % 24;
    final mins = (remainingMs ~/ (60 * 1000)) % 60;
    final hhmm = '${hours.toString().padLeft(2, '0')}:'
        '${mins.toString().padLeft(2, '0')}';
    return days > 0 ? '${days}d $hhmm' : hhmm;
  }
}

class _WeeklySubTaskRow extends ConsumerWidget {
  final Map<String, dynamic> data;
  final String playerId;
  final int weekStartMs;
  final int weekEndMs;

  const _WeeklySubTaskRow({
    required this.data,
    required this.playerId,
    required this.weekStartMs,
    required this.weekEndMs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = data['completed'] == true;
    final rawLabel = data['label'] as String?;
    final label = rawLabel ??
        '[bug:] ${data['sub_type'] as String? ?? '?'}';

    if (completed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.shadowAscending, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough)),
            ),
          ],
        ),
      );
    }

    // Pending — consulta o validator semanal on-demand pra current/target.
    return FutureBuilder<SubTaskEvaluation>(
      future: _evaluate(ref),
      builder: (ctx, snap) {
        final eval = snap.data;
        final Widget icon;
        final Color textColor;
        final String suffix;

        if (eval == null) {
          icon = const SizedBox(width: 14, height: 14);
          textColor = AppColors.textSecondary;
          suffix = '';
        } else {
          // Acumulativo — nunca há estado `failed`; só pending/atingido.
          icon = const Icon(Icons.radio_button_unchecked,
              color: AppColors.textMuted, size: 14);
          textColor = AppColors.textSecondary;
          suffix = '${eval.current}/${eval.target}';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: textColor)),
              ),
              if (suffix.isNotEmpty)
                Text(suffix,
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: textColor)),
            ],
          ),
        );
      },
    );
  }

  Future<SubTaskEvaluation> _evaluate(WidgetRef ref) async {
    final validator = ref.read(weeklyFactionValidatorProvider);
    final subTask = WeeklyFactionSubTask.fromJson(data);
    return validator.evaluate(
      playerId: playerId,
      subTask: subTask,
      weekStartMs: weekStartMs,
      weekEndMs: weekEndMs,
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
