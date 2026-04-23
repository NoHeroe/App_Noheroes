import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/events/mission_events.dart';
import '../../../domain/models/mission_progress.dart';

/// Sprint 3.1 Bloco 12 — card do Histórico com detail expand inline via
/// `ExpansionTile`. Exibe badge de status (Concluída / Apagada / Expirou /
/// Desistiu / Falhou) + detail expandido com descrição, progresso final,
/// reward e timestamp.
///
/// `failed_at != null` + `reason` do `metaJson` distinguem apagadas
/// (`MissionFailureReason.deletedByUser`) de expiradas (`expired`) de
/// desistências (`abandoned`). Missões legacy sem reason caem em "Falhou".
///
/// NB: `reason` não é coluna — vive no `metaJson`. Bloco 10a.2 não
/// escreveu `reason` ao marcar failed; `IndividualDeleteService` chama
/// `markFailed` mas o reason `deletedByUser` é conhecido pelo EVENTO
/// emitido, não persistido. Pra 1ª iteração do Histórico, simplifica:
/// se `completed_at != null` → "Concluída"; senão → "Falhou" genérico.
/// Distinção fina de reasons (Apagada/Expirou) entra quando o schema
/// persistir reason (sprint futura + Bloco 13 sweep de expiração).
class HistoryMissionCard extends StatelessWidget {
  final MissionProgress mission;

  const HistoryMissionCard({super.key, required this.mission});

  bool get _isCompleted => mission.completedAt != null;

  DateTime get _displayTimestamp =>
      mission.completedAt ?? mission.failedAt ?? mission.startedAt;

  String get _statusLabel {
    if (_isCompleted) return 'Concluída';
    // Heurística: mission individual user_created + failed = provável apagar.
    // Sem reason persistido, exibimos só "Falhou" no 1º ciclo. Bloco 13
    // adiciona persistência do reason e refina a badge.
    return 'Falhou';
  }

  Color get _statusColor =>
      _isCompleted ? AppColors.shadowAscending : AppColors.hp;

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('history-card-${mission.id}'),
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: _statusColor.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            _StatusBadge(label: _statusLabel, color: _statusColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mission.missionKey,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _formatDate(_displayTimestamp),
          style: const TextStyle(
              fontSize: 11, color: AppColors.textMuted),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          _kv('Progresso final',
              '${mission.currentValue} / ${mission.targetValue}'),
          _kv('Rank', mission.rank.name.toUpperCase()),
          _kv('Modalidade', mission.modality.name),
          _kv('Reward XP', '${mission.reward.xp}'),
          _kv('Reward Ouro', '${mission.reward.gold}'),
          if (mission.reward.gems > 0)
            _kv('Reward Gemas', '${mission.reward.gems}'),
          if (!_isCompleted)
            _kv('Data da falha', _formatDate(_displayTimestamp))
          else
            _kv('Data de conclusão', _formatDate(_displayTimestamp)),
          // Tentativa de extrair name/description do metaJson (missões
          // individuais user_created). Missões de catálogo ignoram.
          _MetaDescription(metaJson: mission.metaJson),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Extrai `description` do `metaJson` se for missão individual
/// user-created (Bloco 11a). Silencioso em missões de catálogo.
class _MetaDescription extends StatelessWidget {
  final String metaJson;
  const _MetaDescription({required this.metaJson});

  @override
  Widget build(BuildContext context) {
    final desc = _tryExtract(metaJson);
    if (desc == null || desc.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        desc,
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  String? _tryExtract(String json) {
    if (json.isEmpty) return null;
    final m = RegExp(r'"description"\s*:\s*"([^"]*)"').firstMatch(json);
    return m?.group(1);
  }
}

/// Reason constants reexportados pra leitura simplificada caller-side.
class HistoryReasons {
  const HistoryReasons._();
  static const deletedByUser = MissionFailureReason.deletedByUser;
  static const expired = MissionFailureReason.expired;
  static const abandoned = MissionFailureReason.abandoned;
}
