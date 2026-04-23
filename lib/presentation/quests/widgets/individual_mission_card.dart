import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/requirements_helper.dart';
import '../../../domain/balance/individual_delete_cost.dart';
import '../../../domain/models/mission_progress.dart';
import 'mission_card_base.dart';

/// Sprint 3.1 Bloco 10a.2 (refatorado no 14.6b) — card da família
/// **individual** com requirements múltiplos.
///
/// ## Estrutura
///
/// Lê `metaJson.requirements` (serializado via [RequirementsHelper]).
/// Renderiza:
///   - Nome + descrição pessoal (metaJson.name / description) +
///     auto-description atmosférica (metaJson.auto_description) se houver.
///   - Progresso agregado `currentValue / targetValue`.
///   - Uma linha por sub-requirement: label + `done/target unit`, barra
///     de progresso e botões ±1/±10/±25 que chamam
///     `service.onUserAction(id, delta, requirementIndex: i)`.
///   - Botão "Apagar missão" (via `IndividualDeleteService`).
///
/// Row sem `metaJson.requirements` legível → placeholder seguro,
/// evita crash em catálogo legacy.
class IndividualMissionCard extends ConsumerWidget {
  final MissionProgress mission;

  const IndividualMissionCard({super.key, required this.mission});

  Future<void> _applyDelta(
      WidgetRef ref, int delta, int requirementIndex) async {
    final service = ref.read(missionProgressServiceProvider);
    await service.onUserAction(mission.id, delta,
        requirementIndex: requirementIndex);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final cost = IndividualDeleteCost.forRank(mission.rank);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar missão individual?'),
        content: Text(
          'Custa ${cost.gold} ouro e ${cost.gems} gemas. A missão '
          'vai pro histórico como "apagada" — não afeta sombra.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('individual-delete-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const ValueKey('individual-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(individualDeleteServiceProvider).deleteIndividual(
            playerId: mission.playerId,
            missionProgressId: mission.id,
          );
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao apagar: $e')),
      );
    }
  }

  _ParsedMeta _parseMeta() {
    try {
      final decoded = jsonDecode(mission.metaJson);
      if (decoded is! Map<String, dynamic>) return const _ParsedMeta.empty();
      final reqsRaw = decoded['requirements'];
      final reqs = reqsRaw is String
          ? RequirementsHelper.parse(reqsRaw)
          : const <RequirementItem>[];
      return _ParsedMeta(
        name: decoded['name'] as String?,
        description: decoded['description'] as String?,
        autoDescription: decoded['auto_description'] as String?,
        requirements: reqs,
      );
    } catch (_) {
      return const _ParsedMeta.empty();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = _parseMeta();
    final locked = mission.completedAt != null || mission.failedAt != null;
    final pct = mission.targetValue == 0
        ? 0.0
        : (mission.currentValue / mission.targetValue).clamp(0.0, 1.0);

    return MissionCardBase(
      mission: mission,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (meta.name != null)
            Text(
              meta.name!,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 13,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
          if (meta.description != null && meta.description!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              meta.description!,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (meta.autoDescription != null &&
              meta.autoDescription!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${meta.autoDescription!}"',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 10),
          LinearProgressIndicator(value: pct),
          const SizedBox(height: 4),
          Text(
            '${mission.currentValue} / ${mission.targetValue}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (meta.requirements.isEmpty)
            const Text('(sub-requisitos indisponíveis)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11))
          else
            for (var i = 0; i < meta.requirements.length; i++)
              _RequirementRow(
                req: meta.requirements[i],
                index: i,
                locked: locked,
                onDelta: (d) => _applyDelta(ref, d, i),
              ),
          if (!locked) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              key: ValueKey('individual-delete-${mission.id}'),
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Apagar missão'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParsedMeta {
  final String? name;
  final String? description;
  final String? autoDescription;
  final List<RequirementItem> requirements;

  const _ParsedMeta({
    required this.name,
    required this.description,
    required this.autoDescription,
    required this.requirements,
  });

  const _ParsedMeta.empty()
      : name = null,
        description = null,
        autoDescription = null,
        requirements = const [];
}

class _RequirementRow extends StatelessWidget {
  final RequirementItem req;
  final int index;
  final bool locked;
  final ValueChanged<int> onDelta;

  const _RequirementRow({
    required this.req,
    required this.index,
    required this.locked,
    required this.onDelta,
  });

  @override
  Widget build(BuildContext context) {
    final pct = req.target == 0
        ? 0.0
        : (req.done / req.target).clamp(0.0, 1.0);
    final complete = req.done >= req.target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (complete)
                const Icon(Icons.check_circle,
                    color: AppColors.shadowAscending, size: 14)
              else
                const Icon(Icons.radio_button_unchecked,
                    color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  req.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${req.done}/${req.target} ${req.unitLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: pct),
          if (!locked) ...[
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final d in const [-25, -10, -1, 1, 10, 25])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        key: ValueKey('individual-sub-$index-delta-$d'),
                        onPressed: () => onDelta(d),
                        child: Text(d > 0 ? '+$d' : '$d'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
