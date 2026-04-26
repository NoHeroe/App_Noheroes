import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_bg.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/models/mission_progress.dart';
import '../../individual_creation/widgets/create_individual_mission_sheet.dart';
import '../../shared/widgets/nh_bottom_nav.dart';
import '../providers/quests_screen_notifier.dart';
import '../widgets/daily_quests_header.dart';
import '../widgets/daily_section.dart';
import '../widgets/extras_card.dart';
import '../widgets/individual_mission_card.dart';
import '../widgets/internal_mission_card.dart';
import '../widgets/mixed_mission_card.dart';
import '../widgets/real_task_mission_card.dart';
import '../widgets/section_accordion.dart';

/// Sprint 3.1 Bloco 14.6c — `/quests` reestruturada.
/// Sprint 3.2 Etapa 1.3.A — header novo + seção "MISSÕES DIÁRIAS" no
/// topo (DailyMission da Etapa 1.2). Seção legacy "RITUAIS DIÁRIOS"
/// (MissionProgress.daily) **dropada da UI** — backend
/// `MissionAssignmentService` continua existindo intacto.
///
/// Lista atual (5 seções sanfona):
///   1. **MISSÕES DIÁRIAS** (Etapa 1.2 — DailyMissionCard com 3 modos)
///   2. MISSÕES DE CLASSE
///   3. MISSÃO DA FACÇÃO
///   4. ADMISSÃO DE FACÇÃO
///   5. EXTRAS
///   6. MISSÕES INDIVIDUAIS
///
/// Bottom nav adicionada (índice 1 — Missões).
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  // Reward base por rank das missões diárias (Etapa 1.2 — alinhado
  // SOULSLIKE 0.4/0.35). Mantemos um espelho aqui só pra exibir no
  // card fechado SEM precisar carregar o serviço inteiro pra cada card.
  static const Map<String, ({int xp, int gold})> _rewardByRank = {
    'E': (xp: 8, gold: 5),
    'D': (xp: 16, gold: 12),
    'C': (xp: 28, gold: 20),
    'B': (xp: 45, gold: 32),
    'A': (xp: 72, gold: 50),
    'S': (xp: 120, gold: 80),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    if (player == null) {
      return const Scaffold(body: Center(child: Text('Sem jogador.')));
    }
    final asyncState =
        ref.watch(questsScreenNotifierProvider(player.id));
    final notifier =
        ref.read(questsScreenNotifierProvider(player.id).notifier);

    final rankLabel = (player.guildRank == 'none' || player.guildRank.isEmpty)
        ? 'E'
        : player.guildRank.toUpperCase();
    final reward = _rewardByRank[rankLabel] ?? _rewardByRank['E']!;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBg(),
          SafeArea(
            child: asyncState.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.purple)),
              error: (e, _) => Center(
                child: Text('Erro: $e',
                    style: const TextStyle(color: AppColors.hp)),
              ),
              data: (state) => Column(
                children: [
                  DailyQuestsHeader(
                    subTasksDone: state.dailySubTasksDone,
                    subTasksTotal: state.dailySubTasksTotal,
                    streak: player.dailyMissionsStreak,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: notifier.refresh,
                      child: _Body(
                        state: state,
                        playerId: player.id,
                        rankLabel: rankLabel,
                        rewardXp: reward.xp,
                        rewardGold: reward.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const NhBottomNav(currentIndex: 1),
    );
  }
}

class _Body extends ConsumerWidget {
  final QuestsScreenState state;
  final int playerId;
  final String rankLabel;
  final int rewardXp;
  final int rewardGold;

  const _Body({
    required this.state,
    required this.playerId,
    required this.rankLabel,
    required this.rewardXp,
    required this.rewardGold,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier =
        ref.read(questsScreenNotifierProvider(playerId).notifier);

    final rewardsByMissionId = <int, ({int xp, int gold})>{
      for (final m in state.dailyMissionsNew)
        m.id: (xp: rewardXp, gold: rewardGold),
    };

    return ListView(
      key: const ValueKey('quests-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Sprint 3.2 Etapa 1.3.A — seção nova no topo.
        DailySection(
          missions: state.dailyMissionsNew,
          rewardsByMissionId: rewardsByMissionId,
          rankLabel: rankLabel,
          onSubTaskDelta: (missionId, subKey, delta) {
            notifier.incrementDailySubTask(
              missionId: missionId,
              subTaskKey: subKey,
              delta: delta,
            );
          },
        ),
        if (state.classMissions.isNotEmpty)
          SectionAccordion(
            title: 'MISSÕES DE CLASSE',
            icon: Icons.auto_fix_high_outlined,
            color: AppColors.purple,
            subtitle: 'Concluídas automaticamente ao agir.',
            children: state.classMissions
                .map((m) => _MissionCardDispatcher(mission: m))
                .toList(),
          ),
        if (state.factionMissions.isNotEmpty)
          SectionAccordion(
            title: 'MISSÃO DA FACÇÃO',
            icon: Icons.shield_outlined,
            children: state.factionMissions
                .map((m) => _MissionCardDispatcher(mission: m))
                .toList(),
          ),
        if (state.admissionMissions.isNotEmpty)
          SectionAccordion(
            title: 'ADMISSÃO DE FACÇÃO',
            icon: Icons.shield_outlined,
            color: const Color(0xFF8B2020),
            children: state.admissionMissions
                .map((m) => _MissionCardDispatcher(mission: m))
                .toList(),
          ),
        if (state.extrasCatalog.isNotEmpty)
          SectionAccordion(
            title: 'EXTRAS',
            icon: Icons.auto_stories_outlined,
            children: state.extrasCatalog
                .map<Widget>((spec) => ExtrasCard(spec: spec))
                .toList(),
          ),
        // MISSÕES INDIVIDUAIS — sempre renderiza (jogador cria).
        SectionAccordion(
          title: 'MISSÕES INDIVIDUAIS',
          icon: Icons.person_outline,
          children: [
            if (state.individualMissions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nenhuma missão individual ainda.',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            else
              ...state.individualMissions
                  .map((m) => _MissionCardDispatcher(mission: m)),
            const SizedBox(height: 10),
            const _CreateIndividualInlineButton(),
          ],
        ),
      ],
    );
  }
}

/// Seleciona o card especializado conforme `modality` (sistemas legacy
/// MissionProgress — não confundir com DailyMissionCard da Etapa 1.2).
class _MissionCardDispatcher extends StatelessWidget {
  final MissionProgress mission;
  const _MissionCardDispatcher({required this.mission});

  @override
  Widget build(BuildContext context) {
    return switch (mission.modality) {
      MissionModality.internal => InternalMissionCard(mission: mission),
      MissionModality.real => RealTaskMissionCard(mission: mission),
      MissionModality.individual => IndividualMissionCard(mission: mission),
      MissionModality.mixed => MixedMissionCard(mission: mission),
    };
  }
}

class _CreateIndividualInlineButton extends ConsumerWidget {
  const _CreateIndividualInlineButton();

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final result = await showCreateIndividualMissionSheet(context);
    if (result == true) {
      final notifier =
          ref.read(questsScreenNotifierProvider(player.id).notifier);
      await notifier.refresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      key: const ValueKey('quests-create-individual-inline'),
      onTap: () => _openSheet(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
          color: AppColors.purple.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.purple, size: 18),
            const SizedBox(width: 8),
            Text(
              'Nova Missão Individual',
              style: GoogleFonts.roboto(
                color: AppColors.purple,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
