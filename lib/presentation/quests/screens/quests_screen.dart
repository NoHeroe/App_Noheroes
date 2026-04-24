import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_bg.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/models/mission_progress.dart';
import '../../individual_creation/widgets/create_individual_mission_sheet.dart';
import '../providers/quests_screen_notifier.dart';
import '../widgets/extras_card.dart';
import '../widgets/individual_mission_card.dart';
import '../widgets/internal_mission_card.dart';
import '../widgets/mixed_mission_card.dart';
import '../widgets/quests_header.dart';
import '../widgets/real_task_mission_card.dart';
import '../widgets/section_accordion.dart';

/// Sprint 3.1 Bloco 14.6c — `/quests` reestruturada (port v0.28.2
/// `habits_screen.dart`).
///
/// Lista única com **6 seções em sanfona**:
///
///   1. RITUAIS DIÁRIOS (`wb_sunny_outlined`, gold)
///   2. MISSÕES DE CLASSE (`auto_fix_high_outlined`, purple) + subtitle
///      "Concluídas automaticamente ao agir."
///   3. MISSÃO DA FACÇÃO (`shield_outlined`, gold)
///   4. ADMISSÃO DE FACÇÃO (`shield_outlined`, #8B2020 vermelho escuro)
///   5. EXTRAS (`auto_stories_outlined`, gold) — lista do catálogo
///      (gate de unlock é débito Sprint 3.2 — ver
///      `docs/sprint_missoes/DEBITO_EXTRAS_GATE.md`)
///   6. MISSÕES INDIVIDUAIS (`person_outline`, gold) + botão inline
///      "Nova Missão Individual" (roboto 13, caixa mista — copy v0.28.2
///      linhas 277-300)
///
/// Header rico fixo no topo: "MISSÕES" CinzelDecorative gold + streak
/// badge 🔥 + done/total + progress bar roxa.
///
/// Background `AnimatedBg` compartilhado com `/history` e `/login`.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

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
                  QuestsHeader(
                    done: state.doneCount,
                    total: state.totalCount,
                    streak: player.streakDays,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: notifier.refresh,
                      child: _Body(
                        state: state,
                        playerId: player.id,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final QuestsScreenState state;
  final int playerId;

  const _Body({required this.state, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      key: const ValueKey('quests-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        if (state.dailyMissions.isNotEmpty) ...[
          SectionAccordion(
            title: 'RITUAIS DIÁRIOS',
            icon: Icons.wb_sunny_outlined,
            children: state.dailyMissions
                .map((m) => _MissionCardDispatcher(mission: m))
                .toList(),
          ),
        ],
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

/// Seleciona o card especializado conforme `modality`. Uma única fonte
/// de despacho — qualquer novo tipo de missão adiciona aqui.
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

/// Sprint 3.1 Bloco 14.6c — botão inline "Nova Missão Individual".
/// Copy v0.28.2: caixa mista + `GoogleFonts.roboto(fontSize: 13,
/// color: AppColors.purple)`. Fica dentro da seção Individuais,
/// **após** a lista (match exato v0.28.2 linhas 277-300).
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

