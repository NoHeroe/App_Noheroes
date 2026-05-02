import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/achievement_definition.dart';
import '../utils/achievement_progress.dart';
import '../utils/reward_display_helper.dart';
import 'golden_border.dart';
import 'rainbow_border.dart';

/// Sprint 3.3 Etapa Final-B — estados visuais do card de conquista.
enum AchievementCardState {
  locked,          // A — não desbloqueada (mostra progresso)
  pending,         // B — desbloqueada não coletada (botão RECEBER)
  claimed,         // C — coletada (opacidade reduzida)
  secretUnlocked,  // E — secreta desbloqueada (rainbow border permanente)
}

/// Sprint 3.3 Etapa Final-B — keys das 6 conquistas com tier
/// `lendaria_boost_10`. Recebem `GoldenBorder` (não-animada, dourada
/// brilhante) ao desbloquear. Hardcoded porque `tier_definitions` não
/// flui pro `AchievementDefinition` (helper `_resolveTier` na Etapa 2.2
/// expande tier inline e descarta a ref). Futuro: preservar `tierName`
/// no parser se mais features visuais derivarem de tier.
const Set<String> kLegendaryTopAchievementKeys = {
  'VOL_MITO_DISCIPLINA',
  'STREAK_SOL_NEGRO',
  'BEST_ECO_SOL_NEGRO',
  'PERF_GEOMETRIA_SAGRADA',
  'SUPERPERF_EXCEDENTE_ETERNO',
  'NOFAIL_PACTO_ETERNO',
};

/// Sprint 3.3 Etapa Final-B — card unificado pros estados A, B, C, E
/// (secret bloqueado D fica em `AchievementSecretCard`).
///
/// Visual decoration ramifica em:
/// - `secretUnlocked` → `RainbowBorder` animada (LED arco-íris)
/// - `def.key in kLegendaryTopAchievementKeys` & `state != locked` →
///   `GoldenBorder` (estática, brilho dourado)
/// - default → border padrão da categoria
///
/// `RepaintBoundary` envolve o conteúdo quando `RainbowBorder` ativa
/// pra isolar repaint do animation controller em listas longas.
class AchievementCard extends StatefulWidget {
  final AchievementDefinition def;
  final AchievementCardState state;
  final AchievementProgress? progress;
  final RewardDisplay? reward;
  final Future<void> Function()? onClaim;

  const AchievementCard({
    super.key,
    required this.def,
    required this.state,
    this.progress,
    this.reward,
    this.onClaim,
  });

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _claiming = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _isLegendaryTop =>
      kLegendaryTopAchievementKeys.contains(widget.def.key);

  Color get _categoryColor {
    return switch (widget.def.category) {
      'iniciais' => AppColors.gold,
      'volume' => AppColors.shadowStable,
      'streak' || 'best_streak' => AppColors.hp,
      'perfect' || 'super_perfect' => AppColors.purpleLight,
      'falhas' => AppColors.shadowChaotic,
      'no_fail_streak' => AppColors.shadowAscending,
      'subtask_volume_indiv' || 'total_subtask' => AppColors.xp,
      'janelas_temporais' => AppColors.mp,
      'fim_de_semana' => AppColors.gold,
      'pilar_balance' => AppColors.purpleLight,
      'active_days' => AppColors.shadowAscending,
      'speedrun' => AppColors.shadowObsessive,
      'secret' => AppColors.purple,
      _ => AppColors.purple,
    };
  }

  Future<void> _handleClaim() async {
    if (widget.onClaim == null || _claiming) return;
    setState(() => _claiming = true);
    _pulseCtrl.forward(from: 0);
    try {
      await widget.onClaim!();
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBody = _buildBody();

    Widget card = cardBody;
    if (widget.state == AchievementCardState.secretUnlocked) {
      card = RepaintBoundary(
        child: RainbowBorder(
          surfaceColor: AppColors.surface,
          child: cardBody,
        ),
      );
    } else if (_isLegendaryTop &&
        widget.state != AchievementCardState.locked) {
      card = GoldenBorder(
        surfaceColor: AppColors.surface,
        child: cardBody,
      );
    } else {
      card = Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.state == AchievementCardState.pending
                ? AppColors.gold.withValues(alpha: 0.55)
                : (widget.state == AchievementCardState.locked
                    ? AppColors.border
                    : _categoryColor.withValues(alpha: 0.5)),
          ),
        ),
        child: cardBody,
      );
    }

    // Secret + lendária recebem margem inferior externamente.
    if (widget.state == AchievementCardState.secretUnlocked ||
        (_isLegendaryTop && widget.state != AchievementCardState.locked)) {
      card = Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: card,
      );
    }

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        // Pulse: scale 1.0 → 1.04 → 1.0 ao coletar.
        final t = _pulseCtrl.value;
        final scale = 1.0 + 0.04 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        return Transform.scale(scale: scale, child: child);
      },
      child: Semantics(
        button: widget.onClaim != null &&
            widget.state == AchievementCardState.pending,
        label: _semanticsLabel(),
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: card,
        ),
      ),
    );
  }

  String _semanticsLabel() {
    final base = widget.def.name;
    return switch (widget.state) {
      AchievementCardState.locked => '$base — bloqueada',
      AchievementCardState.pending => '$base — pendente de coleta',
      AchievementCardState.claimed => '$base — coletada',
      AchievementCardState.secretUnlocked =>
        '$base — conquista secreta desbloqueada',
    };
  }

  Widget _buildBody() {
    final state = widget.state;
    final isLocked = state == AchievementCardState.locked;
    final isPending = state == AchievementCardState.pending;
    final isClaimed = state == AchievementCardState.claimed;
    final reward = widget.reward;
    final progress = widget.progress;

    return Opacity(
      opacity: isClaimed ? 0.62 : 1.0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(widget.def.name,
                                style: GoogleFonts.cinzelDecorative(
                                    fontSize: 13,
                                    color: isLocked
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary)),
                          ),
                          if (isPending) _buildBadge('NOVO', AppColors.gold),
                          if (isClaimed)
                            _buildBadge('✓ COLETADA',
                                AppColors.shadowAscending),
                          if (widget.def.disabled)
                            _buildBadge('EM BREVE', AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.def.category}${_isLegendaryTop ? ' · lendária' : ''}',
                        style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8),
                      ),
                      if (progress != null && isLocked) ...[
                        const SizedBox(height: 6),
                        _buildProgressBar(progress),
                      ],
                      if (reward != null && !reward.isEmpty) ...[
                        const SizedBox(height: 6),
                        _buildRewardLine(
                          reward,
                          highlighted: isPending,
                          dimmed: isLocked || isClaimed,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isPending && widget.onClaim != null) ...[
              const SizedBox(height: 10),
              _buildClaimButton(),
            ],
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(widget.def.description,
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final isLocked = widget.state == AchievementCardState.locked;
    final color = _categoryColor;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLocked
            ? AppColors.surfaceAlt
            : color.withValues(alpha: 0.15),
        border: Border.all(
          color: isLocked
              ? AppColors.border
              : color.withValues(alpha: 0.5),
        ),
      ),
      child: Icon(
        _isLegendaryTop && !isLocked
            ? Icons.workspace_premium
            : (isLocked
                ? Icons.emoji_events_outlined
                : Icons.emoji_events),
        color: isLocked ? AppColors.textMuted : color,
        size: 22,
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: GoogleFonts.roboto(
              fontSize: 9, color: color, letterSpacing: 0.8)),
    );
  }

  Widget _buildProgressBar(AchievementProgress p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: p.pct,
            minHeight: 5,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(_categoryColor),
          ),
        ),
        const SizedBox(height: 3),
        Text('${p.current} / ${p.target}',
            style: GoogleFonts.robotoMono(
                fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildRewardLine(
    RewardDisplay reward, {
    required bool highlighted,
    required bool dimmed,
  }) {
    final xpColor = dimmed ? AppColors.textMuted : AppColors.xp;
    final goldColor = dimmed ? AppColors.textMuted : AppColors.gold;
    final gemColor = dimmed ? AppColors.textMuted : AppColors.mp;
    final fontSize = highlighted ? 11.5 : 10.5;
    final weight = highlighted ? FontWeight.w600 : FontWeight.w400;

    return Wrap(
      spacing: 8,
      runSpacing: 2,
      children: [
        if (reward.xp > 0)
          Text('+${reward.xp} XP',
              style: GoogleFonts.roboto(
                  fontSize: fontSize, color: xpColor, fontWeight: weight)),
        if (reward.gold > 0)
          Text('+${reward.gold} ouro',
              style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  color: goldColor,
                  fontWeight: weight)),
        if (reward.gems > 0)
          Text('+${reward.gems} gemas',
              style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  color: gemColor,
                  fontWeight: weight)),
        for (final item in reward.items)
          Text('+${item.quantity} ${_itemLabel(item.key)}',
              style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  color: dimmed
                      ? AppColors.textMuted
                      : AppColors.purpleLight,
                  fontWeight: weight)),
      ],
    );
  }

  String _itemLabel(String key) {
    return switch (key) {
      'CHEST_SECRET' => '🎁 Baú Secreto',
      'CHEST_DEFEATED' => '⚱ Baú do Derrotado',
      _ => key,
    };
  }

  Widget _buildClaimButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: ValueKey('achievement-claim-${widget.def.key}'),
        onPressed: _claiming ? null : _handleClaim,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size.fromHeight(40),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        child: _claiming
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text('RECEBER RECOMPENSA',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                )),
      ),
    );
  }
}

/// Sprint 3.3 Etapa Final-B — placeholder pra conquistas secretas que
/// ainda não desbloquearam (Estado D). Não revela nome, descrição ou
/// recompensa — preserva surpresa.
class AchievementSecretCard extends StatelessWidget {
  const AchievementSecretCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Conquista secreta — não revelada',
      child: Container(
        key: const ValueKey('achievement-card-secret-locked'),
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
      ),
    );
  }
}
