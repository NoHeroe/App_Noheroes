import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/achievement_definition.dart';

/// Sprint 3.1 Bloco 14.6b — restauração da tela de Conquistas
/// (port v0.28.2 adaptado ao Bloco 8 JSON-driven).
///
/// ## Fontes de dados
///
///   - **Catálogo in-memory**: `AchievementsService.catalog`
///     (carregado de `assets/data/achievements.json`)
///   - **Keys desbloqueadas do jogador**:
///     `PlayerAchievementsRepository.listCompletedKeys(playerId)`
///
/// ## Diferença vs v0.28.2
///
/// v0.28.2 tinha 2 estados: **pending** (unlocked mas não coletado) +
/// **collected** (após botão "Coletar"). Bloco 8 refez o pipeline — o
/// grant é **automático e atômico** junto com o markCompleted. Não há
/// mais "Coletar" manual. A UI aqui tem 2 estados:
///
///   - **unlocked** (colorido + "DESBLOQUEADO" em CinzelDecorative +
///     XP/gold/gem badges da reward declarada)
///   - **locked** (cinza + ícone outlined)
///
/// Conquistas `isSecret` que ainda estão locked renderizam um card
/// genérico (`_SecretCard`) sem expor nome ou descrição.
///
/// Sem schema change, sem mudança em service. Só consumer novo.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late Future<_AchievementsViewData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AchievementsViewData> _load() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      return const _AchievementsViewData(catalog: [], unlockedKeys: {});
    }
    final service = ref.read(achievementsServiceProvider);
    await service.ensureLoaded();
    final repo = ref.read(playerAchievementsRepositoryProvider);
    final keys = await repo.listCompletedKeys(player.id);
    return _AchievementsViewData(
      catalog: service.catalog.values.toList(growable: false),
      unlockedKeys: keys.toSet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<_AchievementsViewData>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.purple),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Erro ao carregar conquistas:\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              color: AppColors.hp, fontSize: 12),
                        ),
                      ),
                    );
                  }
                  final data = snap.data!;
                  if (data.catalog.isEmpty) {
                    return _buildEmpty();
                  }
                  return _buildList(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<_AchievementsViewData>(
      future: _future,
      builder: (_, snap) {
        final total = snap.data?.catalog.length ?? 0;
        final unlocked = snap.data?.unlockedKeys.length ?? 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
              const Spacer(),
              if (snap.connectionState == ConnectionState.done &&
                  !snap.hasError)
                Text('$unlocked/$total',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      key: const ValueKey('achievements-empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 12),
          Text('Nenhuma conquista no catálogo.',
              style: GoogleFonts.roboto(
                  color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList(_AchievementsViewData data) {
    return ListView.builder(
      key: const ValueKey('achievements-list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      itemCount: data.catalog.length,
      itemBuilder: (_, i) {
        final def = data.catalog[i];
        final unlocked = data.unlockedKeys.contains(def.key);
        if (def.isSecret && !unlocked) {
          return const _SecretCard();
        }
        return _AchievementCard(def: def, unlocked: unlocked);
      },
    );
  }
}

/// View-model interno da tela — evita múltiplas leituras do service no
/// rebuild.
class _AchievementsViewData {
  final List<AchievementDefinition> catalog;
  final Set<String> unlockedKeys;
  const _AchievementsViewData({
    required this.catalog,
    required this.unlockedKeys,
  });
}

class _AchievementCard extends StatelessWidget {
  final AchievementDefinition def;
  final bool unlocked;

  const _AchievementCard({required this.def, required this.unlocked});

  Color get _catColor => switch (def.category) {
        'progression' => AppColors.xp,
        'missions' => AppColors.shadowStable,
        'habits' => AppColors.shadowStable,
        'shadow' => AppColors.shadowChaotic,
        'exploration' => AppColors.gold,
        'social' => AppColors.mp,
        'meta' => AppColors.purpleLight,
        _ => AppColors.purple,
      };

  @override
  Widget build(BuildContext context) {
    final reward = def.reward;
    return Container(
      key: ValueKey('achievement-card-${def.key}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? _catColor.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? _catColor.withValues(alpha: 0.15)
                  : AppColors.surfaceAlt,
              border: Border.all(
                color: unlocked
                    ? _catColor.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Icon(
              unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: unlocked ? _catColor : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.name,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 13,
                        color: unlocked
                            ? AppColors.textPrimary
                            : AppColors.textMuted)),
                const SizedBox(height: 3),
                Text(def.description,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
                if (unlocked) ...[
                  const SizedBox(height: 6),
                  Text('DESBLOQUEADO',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 9,
                          color: _catColor,
                          letterSpacing: 2)),
                  if (reward != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        if (reward.xp > 0)
                          Text('+${reward.xp} XP',
                              style: GoogleFonts.roboto(
                                  fontSize: 10, color: AppColors.xp)),
                        if (reward.gold > 0)
                          Text('+${reward.gold} ouro',
                              style: GoogleFonts.roboto(
                                  fontSize: 10, color: AppColors.gold)),
                        if (reward.gems > 0)
                          Text('+${reward.gems} gemas',
                              style: GoogleFonts.roboto(
                                  fontSize: 10, color: AppColors.mp)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretCard extends StatelessWidget {
  const _SecretCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('achievement-card-secret'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.lock_outline,
                color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conquista Secreta',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 3),
                Text('Continue tua jornada pra revelar.',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
