import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/models/mission_progress.dart';
import '../../individual_creation/widgets/create_individual_mission_sheet.dart';
import '../providers/quests_screen_notifier.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/extras_card.dart';
import '../widgets/history_filter_chips.dart';
import '../widgets/history_mission_card.dart';
import '../widgets/individual_mission_card.dart';
import '../widgets/internal_mission_card.dart';
import '../widgets/mission_counters.dart';
import '../widgets/mixed_mission_card.dart';
import '../widgets/quest_tab_chips.dart';
import '../widgets/real_task_mission_card.dart';
import '../widgets/weekly_missions_chart.dart';

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
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Missões'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
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
          player: player,
          onSelectTab: notifier.setActiveTab,
          onToggleCategory: notifier.toggleCategoryFilter,
          onClearCategories: notifier.clearFilters,
          onRefresh: notifier.refresh,
          onSelectHistoryFilter: notifier.setHistoryFilter,
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
  final dynamic player; // PlayersTableData — tipo via currentPlayerProvider
  final ValueChanged<QuestTab> onSelectTab;
  final ValueChanged<MissionCategory> onToggleCategory;
  final VoidCallback onClearCategories;
  final Future<void> Function() onRefresh;
  final ValueChanged<HistoryFilter> onSelectHistoryFilter;

  const _QuestsBody({
    required this.state,
    required this.player,
    required this.onSelectTab,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onRefresh,
    required this.onSelectHistoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isExtras = state.activeTab == QuestTab.extras;
    final isHistory = state.activeTab == QuestTab.history;
    final missions =
        isHistory ? state.filteredHistory : state.missions;
    final extras = state.extras;
    final totalItems =
        isExtras ? missions.length + extras.length : missions.length;

    return Column(
      children: [
        const SizedBox(height: 8),
        QuestTabChips(active: state.activeTab, onSelect: onSelectTab),
        const SizedBox(height: 8),
        if (isHistory)
          HistoryFilterChips(
            active: state.historyFilter,
            onSelect: onSelectHistoryFilter,
          )
        else
          CategoryFilterChips(
            active: state.categoryFilters,
            onToggle: onToggleCategory,
            onClear: onClearCategories,
          ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: isHistory
                ? _buildHistoryBody(missions)
                : _buildDefaultBody(missions, extras, isExtras, totalItems),
          ),
        ),
      ],
    );
  }

  /// Bloco 12 — aba Histórico tem header fixo (chart + counters) e lista
  /// filtrada por `historyFilter` abaixo. ListView único pra permitir
  /// scroll vertical incluindo header.
  Widget _buildHistoryBody(List<MissionProgress> missions) {
    final totalQuests =
        (player as dynamic)?.totalQuestsCompleted as int? ?? 0;
    return ListView(
      key: const ValueKey('quests-history-list'),
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: WeeklyMissionsChart(
              missionsLast7Days: state.last7DaysWindow),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: MissionCounters(
            missionsLast7Days: state.last7DaysWindow,
            totalQuestsCompleted: totalQuests,
          ),
        ),
        const SizedBox(height: 16),
        if (missions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 40),
            child: Text(
              _emptyMessageFor(QuestTab.history),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          ...missions.map((m) => HistoryMissionCard(mission: m)),
      ],
    );
  }

  Widget _buildDefaultBody(
    List<MissionProgress> missions,
    List extras,
    bool isExtras,
    int totalItems,
  ) {
    if (totalItems == 0) {
      return ListView(
        key: const ValueKey('quests-empty'),
        children: [
          if (isExtras)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: _CreateIndividualInlineButton(),
            ),
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _emptyMessageFor(state.activeTab),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      );
    }
    // Bloco 14.6b — botão "Nova Missão Individual" vira um header inline
    // da aba Extras, substituindo o FAB removido.
    final headerOffset = isExtras ? 1 : 0;
    return ListView.builder(
      key: const ValueKey('quests-list'),
      itemCount: totalItems + headerOffset,
      itemBuilder: (_, i) {
        if (isExtras && i == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: _CreateIndividualInlineButton(),
          );
        }
        final idx = i - headerOffset;
        if (isExtras && idx >= missions.length) {
          return ExtrasCard(spec: extras[idx - missions.length]);
        }
        return _MissionCardDispatcher(mission: missions[idx]);
      },
    );
  }
}

/// Sprint 3.1 Bloco 14.6b — botão inline "Nova Missão Individual".
/// Substitui o FAB flutuante do Bloco 11b.2 (CEO preferiu pattern
/// v0.28.2: botão contextual na seção). Fica fixo no topo da aba
/// Extras (visível no empty state e na lista).
class _CreateIndividualInlineButton extends ConsumerWidget {
  const _CreateIndividualInlineButton();

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final result = await showCreateIndividualMissionSheet(context);
    if (result == true) {
      final notifier = ref.read(
          questsScreenNotifierProvider(player.id).notifier);
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
          color: AppColors.purple.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.purple, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.purple, size: 18),
            const SizedBox(width: 8),
            Text(
              'NOVA MISSÃO INDIVIDUAL',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 12,
                color: AppColors.purpleLight,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
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
