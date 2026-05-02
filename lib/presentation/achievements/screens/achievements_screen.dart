import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../../domain/models/achievement_definition.dart';
import '../../../domain/models/player_daily_mission_stats.dart';
import '../../shared/widgets/app_snack.dart';
import '../utils/achievement_progress.dart';
import '../utils/reward_display_helper.dart';
import '../widgets/achievement_card.dart';
import '../widgets/achievement_filters.dart';
import '../widgets/achievement_stats_header.dart';

/// Sprint 3.3 Etapa Final-B — tela `/achievements` redesenhada.
///
/// Funcionalidades:
///   - 5 estados de card (locked/pending/claimed/secretLocked/secretUnlocked)
///   - Coleta manual via [AchievementsService.claimReward]
///   - Filtros (Todas/Pendentes/Desbloqueadas/Bloqueadas + Por categoria)
///   - Stats topo (X/Y, %, pendentes, shells "em breve")
///   - Progresso por trigger numérico (barra) ou ocultada em binários
///   - Display pós-multiplier SOULSLIKE
///   - Ordenação: pendentes topo → lendárias → outras desbloqueadas →
///     bloqueadas → secretas D fundo
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late Future<_AchievementsViewData> _future;
  AchievementFilter _filter = AchievementFilter.todas;
  String? _category;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AchievementsViewData> _load() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      return const _AchievementsViewData(
        catalog: [],
        unlockedKeys: {},
        pendingKeys: {},
        progressContext: null,
      );
    }
    final service = ref.read(achievementsServiceProvider);
    await service.ensureLoaded();
    final repo = ref.read(playerAchievementsRepositoryProvider);
    final unlocked = (await repo.listCompletedKeys(player.id)).toSet();
    final pending = (await repo.listPendingClaims(player.id)).toSet();

    // Snapshot pra calcular progress sem N queries por card.
    final db = ref.read(appDatabaseProvider);
    final freshPlayer = await PlayerDao(db).findById(player.id) ?? player;
    final statsDao = ref.read(playerDailyMissionStatsDaoProvider);
    final PlayerDailyMissionStats? stats =
        await statsDao.findByPlayerId(player.id);
    final totalCompleted = await repo.countCompleted(player.id);

    return _AchievementsViewData(
      catalog: service.catalog.values.toList(growable: false),
      unlockedKeys: unlocked,
      pendingKeys: pending,
      progressContext: AchievementProgressContext(
        player: freshPlayer,
        stats: stats,
        totalCompletedAchievements: totalCompleted,
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _claim(String key) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final svc = ref.read(achievementsServiceProvider);
    final ok = await svc.claimReward(player.id, key);

    // Refresh player no provider (XP/gold/gems podem ter subido).
    final db = ref.read(appDatabaseProvider);
    final updated = await PlayerDao(db).findById(player.id);
    if (!mounted) return;
    if (updated != null) {
      ref.read(currentPlayerProvider.notifier).state = updated;
    }

    if (!ok) {
      AppSnack.info(context, 'Conquista já coletada.');
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: FutureBuilder<_AchievementsViewData>(
          future: _future,
          builder: (ctx, snap) {
            final loading =
                snap.connectionState != ConnectionState.done;
            final data = snap.data;
            return Column(
              children: [
                _buildHeader(),
                if (data != null && !loading) ...[
                  AchievementStatsHeader(
                    unlocked: data.unlockedKeys.length,
                    total: data.catalog.length,
                    shellCount:
                        data.catalog.where((d) => d.disabled).length,
                    pendingClaims: data.pendingKeys.length,
                  ),
                  AchievementFilters(
                    active: _filter,
                    activeCategory: _category,
                    categories: _categoriesOf(data.catalog),
                    pendingCount: data.pendingKeys.length,
                    onFilterChange: (f) => setState(() {
                      _filter = f;
                      _category = null;
                    }),
                    onCategoryChange: (c) => setState(() {
                      _category = c;
                    }),
                  ),
                ],
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.purple),
                        )
                      : snap.hasError
                          ? _buildError(snap.error)
                          : _buildList(data!),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('achievements-back'),
            onTap: () => context.go('/sanctuary'),
            child: const Icon(Icons.arrow_back_ios,
                color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Text('CONQUISTAS',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 16,
                  color: AppColors.gold,
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildError(Object? err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Erro ao carregar conquistas:\n$err',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(color: AppColors.hp, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildList(_AchievementsViewData data) {
    if (data.catalog.isEmpty) {
      return _emptyState(
        icon: Icons.emoji_events_outlined,
        text: 'Nenhuma conquista no catálogo.',
        keyValue: 'achievements-empty',
      );
    }
    final filtered = _applyFilters(data);
    if (filtered.isEmpty) {
      return _emptyState(
        icon: _filter == AchievementFilter.pendentes
            ? Icons.check_circle_outline
            : Icons.search_off,
        text: _emptyMessageForFilter(),
        keyValue: 'achievements-empty-filter',
      );
    }

    final ordered = _sortDisplay(filtered, data);

    return ListView.builder(
      key: const ValueKey('achievements-list'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: ordered.length,
      itemBuilder: (_, i) {
        final def = ordered[i];
        return _buildCard(def, data);
      },
    );
  }

  Widget _buildCard(
      AchievementDefinition def, _AchievementsViewData data) {
    final unlocked = data.unlockedKeys.contains(def.key);
    final pending = data.pendingKeys.contains(def.key);

    // Estado D — secreta bloqueada
    if (def.isSecret && !unlocked) {
      return const AchievementSecretCard();
    }

    // Estado E — secreta desbloqueada (rainbow border permanente)
    final isSecretUnlocked = def.isSecret && unlocked;

    final state = isSecretUnlocked
        ? AchievementCardState.secretUnlocked
        : (unlocked && pending
            ? AchievementCardState.pending
            : (unlocked
                ? AchievementCardState.claimed
                : AchievementCardState.locked));

    AchievementProgress? progress;
    if (state == AchievementCardState.locked &&
        data.progressContext != null) {
      progress = AchievementProgressCalculator.compute(
          def, data.progressContext!);
    }

    final reward = def.reward == null
        ? null
        : RewardDisplay.fromDeclared(def.reward!);

    // Estado E pendente também precisa do botão.
    final canClaim = pending && !def.disabled;

    return AchievementCard(
      def: def,
      state: state == AchievementCardState.secretUnlocked && pending
          ? AchievementCardState.secretUnlocked
          : state,
      progress: progress,
      reward: reward,
      onClaim: canClaim ? () => _claim(def.key) : null,
    );
  }

  List<AchievementDefinition> _applyFilters(_AchievementsViewData data) {
    var list = data.catalog.where((d) {
      if (_category != null && d.category != _category) return false;
      final unlocked = data.unlockedKeys.contains(d.key);
      final pending = data.pendingKeys.contains(d.key);

      switch (_filter) {
        case AchievementFilter.todas:
          return true;
        case AchievementFilter.pendentes:
          return unlocked && pending;
        case AchievementFilter.desbloqueadas:
          return unlocked;
        case AchievementFilter.bloqueadas:
          // Preserva surpresa: bloqueadas NÃO mostra secretas.
          return !unlocked && !d.isSecret;
      }
    }).toList(growable: false);
    return list;
  }

  /// Ordenação dentro do filtro:
  /// 1. Pendentes (estado B / E pendente) — usuário precisa interagir
  /// 2. Lendárias topo desbloqueadas
  /// 3. Outras desbloqueadas
  /// 4. Bloqueadas em progresso (não-secretas)
  /// 5. Secretas não desbloqueadas (estado D) no fundo
  List<AchievementDefinition> _sortDisplay(
    List<AchievementDefinition> list,
    _AchievementsViewData data,
  ) {
    int rank(AchievementDefinition d) {
      final unlocked = data.unlockedKeys.contains(d.key);
      final pending = data.pendingKeys.contains(d.key);
      if (unlocked && pending) return 0;
      if (unlocked &&
          kLegendaryTopAchievementKeys.contains(d.key)) {
        return 1;
      }
      if (unlocked) return 2;
      if (!unlocked && !d.isSecret) return 3;
      return 4; // secret não desbloqueada
    }

    final out = [...list];
    out.sort((a, b) {
      final ra = rank(a);
      final rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      return a.key.compareTo(b.key);
    });
    return out;
  }

  Widget _emptyState({
    required IconData icon,
    required String text,
    required String keyValue,
  }) {
    return Center(
      key: ValueKey(keyValue),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: AppColors.textMuted.withValues(alpha: 0.3),
              size: 48),
          const SizedBox(height: 12),
          Text(text,
              style: GoogleFonts.roboto(
                  color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  String _emptyMessageForFilter() {
    return switch (_filter) {
      AchievementFilter.pendentes => 'Nenhuma conquista pendente.',
      AchievementFilter.desbloqueadas =>
        'Você ainda não desbloqueou conquistas.',
      AchievementFilter.bloqueadas =>
        'Todas as conquistas conhecidas já foram desbloqueadas.',
      AchievementFilter.todas =>
        'Nenhuma conquista no catálogo pra esta categoria.',
    };
  }

  List<String> _categoriesOf(List<AchievementDefinition> catalog) {
    final set = <String>{for (final d in catalog) d.category};
    final list = set.toList()..sort();
    return list;
  }
}

class _AchievementsViewData {
  final List<AchievementDefinition> catalog;
  final Set<String> unlockedKeys;
  final Set<String> pendingKeys;
  final AchievementProgressContext? progressContext;
  const _AchievementsViewData({
    required this.catalog,
    required this.unlockedKeys,
    required this.pendingKeys,
    required this.progressContext,
  });
}
