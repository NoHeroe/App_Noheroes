import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/models/mission_progress.dart';
import '../providers/quests_screen_notifier.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/individual_mission_card.dart';
import '../widgets/internal_mission_card.dart';
import '../widgets/mixed_mission_card.dart';
import '../widgets/quest_tab_chips.dart';
import '../widgets/real_task_mission_card.dart';

/// Sprint 3.1 Bloco 10a.1 — tela `/quests` com 6 abas + chips de filtro.
///
/// Arquitetura:
///   - 1 `QuestsScreenNotifier` central (autodispose family por playerId)
///     assina eventos do bus e invalida state quando missão completa/falha.
///   - `QuestTabChips` + `CategoryFilterChips` mudam state via callbacks.
///   - Dispatcher por `modality` escolhe o card especializado.
///   - `RefreshIndicator` chama `notifier.refresh()` → `invalidateSelf`.
///
/// UI mínima — Bloco 10b polia (dark fantasy, partículas, NPC overlay,
/// timer, empty state temático por aba). Filho do ADR 0016 — zero
/// acesso direto ao Drift aqui; tudo via Repository abstrato.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    if (player == null) {
      // Defensivo — router redireciona pra /login se null, mas mantém o
      // build resiliente.
      return const Scaffold(body: Center(child: Text('Sem jogador.')));
    }
    final asyncState =
        ref.watch(questsScreenNotifierProvider(player.id));
    final notifier =
        ref.read(questsScreenNotifierProvider(player.id).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Missões')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e',
              style: const TextStyle(color: Colors.red)),
        ),
        data: (state) => _QuestsBody(
          state: state,
          onSelectTab: notifier.setActiveTab,
          onToggleCategory: notifier.toggleCategoryFilter,
          onClearCategories: notifier.clearFilters,
          onRefresh: notifier.refresh,
        ),
      ),
    );
  }
}

class _QuestsBody extends StatelessWidget {
  final QuestsScreenState state;
  final ValueChanged<QuestTab> onSelectTab;
  final ValueChanged<MissionCategory> onToggleCategory;
  final VoidCallback onClearCategories;
  final Future<void> Function() onRefresh;

  const _QuestsBody({
    required this.state,
    required this.onSelectTab,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final missions = state.missions;
    return Column(
      children: [
        const SizedBox(height: 8),
        QuestTabChips(active: state.activeTab, onSelect: onSelectTab),
        const SizedBox(height: 8),
        CategoryFilterChips(
          active: state.categoryFilters,
          onToggle: onToggleCategory,
          onClear: onClearCategories,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: missions.isEmpty
                ? ListView(
                    key: const ValueKey('quests-empty'),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Nenhuma missão nesta aba.')),
                    ],
                  )
                : ListView.builder(
                    key: const ValueKey('quests-list'),
                    itemCount: missions.length,
                    itemBuilder: (_, i) => _MissionCardDispatcher(
                      mission: missions[i],
                    ),
                  ),
          ),
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
