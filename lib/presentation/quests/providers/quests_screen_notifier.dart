import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/events/mission_events.dart';
import '../../../core/events/reward_events.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/repositories/mission_repository.dart';

/// Sprint 3.1 Bloco 10a.1 — abas da tela `/quests`. `classTab` evita
/// colisão com a keyword `class` do Dart; storage do `MissionTabOrigin`
/// correspondente é `'class'` (ver `MissionTabOrigin.classTab`).
///
/// A aba `history` **não** tem correspondência 1:1 com `MissionTabOrigin`
/// — é uma view agregada (missões não-ativas de qualquer aba), resolvida
/// via `MissionRepository.findHistorical`.
enum QuestTab { daily, classTab, faction, extras, admission, history }

/// Estado imutável consumido pela tela `/quests`. Todos os campos são
/// derivados do Notifier — UI apenas renderiza.
class QuestsScreenState {
  final QuestTab activeTab;

  /// Filtros de categoria (chips). Conjunto vazio = "todas as categorias".
  /// Consolida AND com o `activeTab` no resultado final.
  final Set<MissionCategory> categoryFilters;

  /// Lista filtrada conforme `activeTab` + `categoryFilters`. Ordenação
  /// definida pelo repositório (activeTab ≠ history: DESC por
  /// started_at; history: DESC por COALESCE(completed_at, failed_at)).
  final List<MissionProgress> missions;

  const QuestsScreenState({
    required this.activeTab,
    required this.categoryFilters,
    required this.missions,
  });

  QuestsScreenState copyWith({
    QuestTab? activeTab,
    Set<MissionCategory>? categoryFilters,
    List<MissionProgress>? missions,
  }) {
    return QuestsScreenState(
      activeTab: activeTab ?? this.activeTab,
      categoryFilters: categoryFilters ?? this.categoryFilters,
      missions: missions ?? this.missions,
    );
  }
}

/// Sprint 3.1 Bloco 10a.1 — Notifier central da tela `/quests`. Mantém
/// state da aba ativa + filtros de categoria + lista reativa.
///
/// ## Pattern de subscription no bus
///
/// `build()` é reexecutado a cada `invalidateSelf()`. Subscriptions
/// criadas dentro de `build` **sempre** precisam ser canceladas em
/// `ref.onDispose` — senão cada refresh adiciona listeners fantasma
/// (leak de memória + handlers duplicados).
///
/// Este Notifier assina 3 tipos de evento que invalidam o state:
///   - `MissionCompleted` — missão fechada pelo jogador
///   - `MissionFailed` — missão falhada (auto-complete à meia-noite ou
///     desistência explícita)
///   - `RewardGranted` — reward creditada (captura fim de class/faction
///     quest que não emitem `MissionCompleted` próprio ainda)
///
/// Qualquer um dispara `ref.invalidateSelf()` — que reroda `build`, que
/// cancela as subscriptions velhas via `ref.onDispose` (Riverpod chama
/// o dispose ANTES de reexecutar o build) e cria novas.
///
/// ## Autodispose family
///
/// `AutoDisposeFamilyAsyncNotifier<State, int>` — `int` é o `playerId`.
/// Autodispose libera recursos quando a tela `/quests` sai de tela
/// (cancela subs, encerra). Reentrada na tela recria do zero com
/// `findByTab(playerId, daily)` default.
class QuestsScreenNotifier
    extends AutoDisposeFamilyAsyncNotifier<QuestsScreenState, int> {
  @override
  Future<QuestsScreenState> build(int playerId) async {
    final bus = ref.read(appEventBusProvider);
    final repo = ref.read(missionRepositoryProvider);

    // Capturar o activeTab e filtros do state anterior (se houver) — se
    // o invalidateSelf acontece após uma mudança de aba, queremos
    // preservar a aba. Previous state só existe após primeiro build.
    final prev = state.valueOrNull;
    final activeTab = prev?.activeTab ?? QuestTab.daily;
    final filters = prev?.categoryFilters ?? const <MissionCategory>{};

    // Subscriptions DEVEM ser canceladas em onDispose — senão cada
    // invalidateSelf acumula listeners. Riverpod chama o onDispose do
    // build anterior antes de rodar o novo.
    final subCompleted = bus
        .on<MissionCompleted>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    final subFailed = bus
        .on<MissionFailed>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    final subReward = bus
        .on<RewardGranted>()
        .where((e) => e.playerId == playerId)
        .listen((_) => ref.invalidateSelf());
    ref.onDispose(() {
      subCompleted.cancel();
      subFailed.cancel();
      subReward.cancel();
    });

    final missions = await _loadForTab(repo, playerId, activeTab, filters);
    return QuestsScreenState(
      activeTab: activeTab,
      categoryFilters: filters,
      missions: missions,
    );
  }

  /// Alterna pra [tab] e refaz a query. Preserva `categoryFilters`.
  Future<void> setActiveTab(QuestTab tab) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.activeTab == tab) return;
    state = AsyncValue.data(current.copyWith(activeTab: tab));
    final repo = ref.read(missionRepositoryProvider);
    final playerId = arg;
    final missions =
        await _loadForTab(repo, playerId, tab, current.categoryFilters);
    state = AsyncValue.data(current.copyWith(
      activeTab: tab,
      missions: missions,
    ));
  }

  /// Adiciona/remove [cat] dos filtros e refaz a query. Assinatura
  /// async pra permitir `await` nos testes — a UI chama fire-and-forget
  /// (o state atualiza sozinho via rebuild quando o Future resolve).
  Future<void> toggleCategoryFilter(MissionCategory cat) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = Set<MissionCategory>.from(current.categoryFilters);
    if (!next.add(cat)) next.remove(cat);
    state = AsyncValue.data(current.copyWith(categoryFilters: next));
    await _reloadCurrentTab();
  }

  /// Limpa todos os filtros de categoria.
  Future<void> clearFilters() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(
      categoryFilters: const <MissionCategory>{},
    ));
    await _reloadCurrentTab();
  }

  /// Força re-query do repo (pull-to-refresh do RefreshIndicator).
  Future<void> refresh() async {
    ref.invalidateSelf();
    // Espera rebuild terminar — `future` completa após o próximo build.
    await future;
  }

  Future<void> _reloadCurrentTab() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repo = ref.read(missionRepositoryProvider);
    final missions = await _loadForTab(
      repo,
      arg,
      current.activeTab,
      current.categoryFilters,
    );
    final latest = state.valueOrNull ?? current;
    state = AsyncValue.data(latest.copyWith(missions: missions));
  }

  Future<List<MissionProgress>> _loadForTab(
    MissionRepository repo,
    int playerId,
    QuestTab tab,
    Set<MissionCategory> filters,
  ) async {
    final List<MissionProgress> raw;
    if (tab == QuestTab.history) {
      raw = await repo.findHistorical(playerId);
    } else {
      raw = await repo.findByTab(playerId, _tabToOrigin(tab));
    }
    if (filters.isEmpty) return raw;
    // Filtro de categoria é client-side — as categorias vivem no
    // meta_json da missão (ou no RewardDeclared). Pro MVP do 10a.1:
    // categoria é extraída do `metaJson` via key 'category' (strings
    // do enum MissionCategory.storage). Missões sem essa key ficam
    // de fora quando filtros estão ativos (comportamento opt-in).
    return raw.where((m) {
      final cat = _categoryOf(m);
      return cat != null && filters.contains(cat);
    }).toList(growable: false);
  }

  MissionTabOrigin _tabToOrigin(QuestTab tab) => switch (tab) {
        QuestTab.daily => MissionTabOrigin.daily,
        QuestTab.classTab => MissionTabOrigin.classTab,
        QuestTab.faction => MissionTabOrigin.faction,
        QuestTab.extras => MissionTabOrigin.extras,
        QuestTab.admission => MissionTabOrigin.admission,
        QuestTab.history => throw StateError(
            'history não tem MissionTabOrigin correspondente'),
      };

  /// Extrai categoria da missão. No MVP lê do `metaJson`.
  /// Bloco 14 (assignment) vai escrever explicitamente essa key ao
  /// criar cada missão. Missões legacy sem a key retornam null.
  MissionCategory? _categoryOf(MissionProgress m) {
    try {
      final raw = m.metaJson;
      if (raw.isEmpty) return null;
      // Parser leve — evita dependência de dart:convert aqui (bundle).
      final match = RegExp(r'"category"\s*:\s*"(\w+)"').firstMatch(raw);
      if (match == null) return null;
      return MissionCategoryCodec.fromStorage(match.group(1)!);
    } catch (_) {
      return null;
    }
  }
}

/// Provider exposto pra UI. `playerId` vem via `.call(playerId)`.
final questsScreenNotifierProvider = AutoDisposeAsyncNotifierProviderFamily<
    QuestsScreenNotifier, QuestsScreenState, int>(
  QuestsScreenNotifier.new,
);
