import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/models/mission_progress.dart';
import '../providers/quests_screen_notifier.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/extras_card.dart';
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

    final activeTab = asyncState.valueOrNull?.activeTab;
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Missões'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      // Bloco 11b.2 — FAB "Criar missão individual" visível APENAS na
      // aba Extras (sub-seção Individuais). Oculto nas demais (daily,
      // classe, facção, admissão, histórico não aceitam criação).
      floatingActionButton: activeTab == QuestTab.extras
          ? FloatingActionButton.extended(
              key: const ValueKey('quests-fab-create-individual'),
              backgroundColor: AppColors.purple,
              icon: const Icon(Icons.add),
              label: const Text('Criar missão'),
              onPressed: () => context.go('/individual_creation'),
            )
          : null,
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.purple),
        ),
        error: (e, _) => Center(
          child: Text('Erro: $e',
              style: const TextStyle(color: AppColors.hp)),
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

/// Sprint 3.1 Bloco 10b — copy diferenciado de empty state por aba.
String _emptyMessageFor(QuestTab tab) {
  switch (tab) {
    case QuestTab.daily:
      return 'Nenhuma missão diária hoje. Volta amanhã.';
    case QuestTab.classTab:
      return 'Aguardando missões de classe.';
    case QuestTab.faction:
      return 'Nenhuma missão de facção ativa.';
    case QuestTab.extras:
      return 'Sem extras disponíveis. Explora regiões pra desbloquear.';
    case QuestTab.admission:
      return 'Complete a admissão pra entrar na facção.';
    case QuestTab.history:
      return 'Nada no histórico ainda.';
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
    // Bloco 11a — aba Extras mostra MissionProgress individuais do jogador
    // (user_created=true) + catálogo Extras (NPCs/Lore/Secret-revealed).
    // Outras abas mostram só missions do repo.
    final isExtras = state.activeTab == QuestTab.extras;
    final missions = state.missions;
    final extras = state.extras;
    final totalItems = isExtras ? missions.length + extras.length : missions.length;

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
            child: totalItems == 0
                ? ListView(
                    key: const ValueKey('quests-empty'),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _emptyMessageFor(state.activeTab),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    key: const ValueKey('quests-list'),
                    itemCount: totalItems,
                    itemBuilder: (_, i) {
                      // Em Extras: primeiro as individuais ativas, depois
                      // o catálogo de NPCs/Lore.
                      if (isExtras && i >= missions.length) {
                        return ExtrasCard(
                          spec: extras[i - missions.length],
                        );
                      }
                      return _MissionCardDispatcher(
                        mission: missions[i],
                      );
                    },
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
