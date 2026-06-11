import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/mission_progress.dart';
import 'mission_status_badge.dart';

/// Sprint 3.4 Etapa A hotfix — extrai um título legível do `metaJson`
/// quando o produtor da missão registrou esse campo (ex.:
/// `QuestAdmissionService.startFactionAdmission` agora persiste
/// `{title, description, faction_id}` em metaJson).
///
/// Fallback: `missionKey`. Mantém compatibilidade com mission types que
/// ainda não populam `title` no metaJson (class quests, faction weekly
/// `FAC_X_Y`, individuals) — esses continuam mostrando key crua até
/// sprint que normalize o catálogo.
String displayTitleOf(MissionProgress mission) {
  if (mission.metaJson.isEmpty) return mission.missionKey;
  try {
    final decoded = jsonDecode(mission.metaJson);
    if (decoded is Map && decoded['title'] is String) {
      final title = decoded['title'] as String;
      if (title.isNotEmpty) return title;
    }
  } catch (_) {
    // metaJson malformado — fallback silencioso.
  }
  return mission.missionKey;
}

/// Sprint 3.1 Bloco 10a.1 — shell comum dos MissionCards.
///
/// Mantém o header (rank + título + status badge) + slot `child` pro
/// conteúdo específico de cada modalidade (barra passiva / botões ± /
/// sub-tasks / etc).
///
/// Bloco 14.6c: ícones check/cancel duplicados do header foram
/// substituídos por `MissionStatusBadge` textual (✓ Concluído /
/// ◑ Parcial / ✗ Falhou / Pendente) — 1 widget único aplicado a
/// todas as famílias.
class MissionCardBase extends StatelessWidget {
  final MissionProgress mission;
  final Widget child;
  final VoidCallback? onTap;

  /// Ícone (família da missão) no badge circular. Default: pergaminho.
  final IconData icon;

  /// Cor de destaque (borda + ícone). Default: dourado.
  final Color? accent;

  const MissionCardBase({
    super.key,
    required this.mission,
    required this.child,
    this.onTap,
    this.icon = Icons.assignment_outlined,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Padroniza com o card de DIÁRIA: container surface.85 + borda colorida +
    // raio 10 + ícone circular + título CinzelDecorative + rank/status.
    final color = accent ?? AppColors.gold;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border:
            Border.all(color: color.withValues(alpha: 0.5), width: 1.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                        border:
                            Border.all(color: color.withValues(alpha: 0.6)),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitleOf(mission),
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              letterSpacing: 1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _RankBadge(rank: mission.rank.name),
                              const SizedBox(width: 8),
                              MissionStatusBadge(status: mission.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
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
