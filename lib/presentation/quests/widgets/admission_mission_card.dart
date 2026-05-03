import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/services/faction_admission_validator.dart';

/// Sprint 3.4 Sub-Etapa B.2 — card específico pra missões com
/// `tabOrigin=admission`. Lê `metaJson` da `MissionProgress` pra
/// extrair `is_unlocked` (sequenciamento), `window_start_ms` /
/// `window_duration_ms` (countdown), `sub_tasks` (lista de
/// [FactionAdmissionSubTask]). Cada sub-task renderiza com:
///
/// - Label do catálogo
/// - Progresso atual (consultado on-demand via
///   [FactionAdmissionValidator.evaluate])
/// - Visual: completed (riscado + check), failed (vermelho + X),
///   pending (texto neutro)
///
/// Quando `is_unlocked == false` (missão N+1 com missão N pendente),
/// renderiza placeholder cinza com cadeado em vez do card cheio.
///
/// Countdown da janela atualiza a cada 60s via `Timer.periodic`.
class AdmissionMissionCard extends ConsumerStatefulWidget {
  final MissionProgress mission;

  const AdmissionMissionCard({super.key, required this.mission});

  @override
  ConsumerState<AdmissionMissionCard> createState() =>
      _AdmissionMissionCardState();
}

class _AdmissionMissionCardState
    extends ConsumerState<AdmissionMissionCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tick a cada 60s pra atualizar countdown sem desperdiçar rebuilds.
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
    // Sprint 3.4 hotfix B.2 — escuta stream do DB pra reagir
    // imediatamente a mudanças no metaJson (sub-task completed pelo
    // listener; window_start_ms shifted pelo dev panel; is_unlocked
    // promovido por sequenciamento). Fallback pro metaJson original
    // do widget enquanto stream não emitiu (1ª frame).
    final streamRow = ref
        .watch(missionProgressStreamProvider(widget.mission.id))
        .valueOrNull;
    final liveMetaJson = streamRow?.metaJson ?? widget.mission.metaJson;

    final meta = _decodeMetaFrom(liveMetaJson);
    if (meta == null) return const SizedBox.shrink();

    final isUnlocked = meta['is_unlocked'] == true;
    final title = (meta['title'] as String?) ?? widget.mission.missionKey;
    final description = meta['description'] as String?;

    if (!isUnlocked) {
      return _buildLockedPlaceholder(title);
    }

    final subTasks = (meta['sub_tasks'] as List?) ?? const [];
    final windowStartMs = (meta['window_start_ms'] as int?) ?? 0;
    final windowDurationMs =
        (meta['window_duration_ms'] as int?) ?? (48 * 60 * 60 * 1000);
    final remaining = _computeRemaining(windowStartMs, windowDurationMs);
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
            ...subTasks.map((s) => _SubTaskRow(
                  data: (s as Map).cast<String, dynamic>(),
                  playerId: widget.mission.playerId,
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                    remaining == null
                        ? 'janela: —'
                        : 'restante: $remaining',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedPlaceholder(String title) {
    return Card(
      color: AppColors.surface.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                color: AppColors.textMuted, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text('Complete a missão anterior pra desbloquear',
                      style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formato HH:MM. Null se windowStartMs == 0 (missão recém-criada
  /// sem janela ativa) ou se janela já expirou.
  String? _computeRemaining(int windowStartMs, int windowDurationMs) {
    if (windowStartMs == 0) return null;
    final endMs = windowStartMs + windowDurationMs;
    final remainingMs = endMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return 'expirada';
    final hours = remainingMs ~/ (60 * 60 * 1000);
    final mins = (remainingMs ~/ (60 * 1000)) % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${mins.toString().padLeft(2, '0')}';
  }
}

class _SubTaskRow extends ConsumerWidget {
  final Map<String, dynamic> data;
  final int playerId;

  const _SubTaskRow({required this.data, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = data['completed'] == true;
    // Sprint 3.4 Sub-Etapa B.2 hotfix — label do catálogo (vem via
    // metaJson após Fix 1). Fallback com prefixo `[bug:]` torna
    // visível qualquer caso onde label não foi persistido (legacy
    // metaJson criado pré-hotfix, ou sub-task construída em teste
    // sem label). Diagnóstico imediato em produção.
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

    // Sub-task pending — consulta validator on-demand pra current/target.
    return FutureBuilder<SubTaskEvaluation>(
      future: _evaluate(ref),
      builder: (ctx, snap) {
        final eval = snap.data;
        Widget icon;
        Color textColor;
        String suffix;

        if (eval == null) {
          icon = const SizedBox(width: 14, height: 14);
          textColor = AppColors.textSecondary;
          suffix = '';
        } else if (eval.failed) {
          icon = const Icon(Icons.cancel,
              color: AppColors.hp, size: 14);
          textColor = AppColors.hp;
          suffix = '${eval.current}/${eval.target} ✗';
        } else {
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
    final validator = ref.read(factionAdmissionValidatorProvider);
    final subTask = FactionAdmissionSubTask.fromJson(data);
    return validator.evaluate(playerId: playerId, subTask: subTask);
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
