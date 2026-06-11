import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/avatar_provider.dart';

/// Bloco 2 do restyle — componentes do topo do Santuário.
/// Toda a fonte de dados é o `currentPlayerProvider` (sem mudar lógica).

// ─── MiniProfile ──────────────────────────────────────────────────────
class SanctuaryMiniProfile extends ConsumerWidget {
  const SanctuaryMiniProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final level = player?.level ?? 1;
    final xp = player?.xp ?? 0;
    final xpToNext = (player?.xpToNext ?? 200).clamp(1, 1 << 30);
    final name = (player?.shadowName.isNotEmpty ?? false)
        ? player!.shadowName
        : 'Sombra';
    final progress = (xp / xpToNext).clamp(0.0, 1.0);

    return Row(
      children: [
        _Avatar(level: level),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.txt,
                ),
              ),
              const SizedBox(height: 6),
              _XpBar(progress: progress, xp: xp, xpToNext: xpToNext),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends ConsumerWidget {
  final int level;
  const _Avatar({required this.level});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref
        .watch(selectedAvatarProvider)
        .clamp(0, kAvatarPresets.length - 1);
    final preset = kAvatarPresets[idx];
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ring dourado (SweepGradient) + pad 2
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                startAngle: 220 * math.pi / 180,
                colors: [
                  AppColors.goldDk,
                  AppColors.goldLt,
                  AppColors.goldDk,
                ],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF3A2D52), Color(0xFF140E20)],
                ),
              ),
              child: Icon(preset.icon, color: preset.color, size: 22),
            ),
          ),
          // Badge de nível bottom-right
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A2038), Color(0xFF120D1C)],
                ),
                border: Border.all(color: AppColors.gold, width: 1),
              ),
              child: Text(
                '$level',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 9,
                  color: AppColors.goldLt,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final double progress;
  final int xp;
  final int xpToNext;
  const _XpBar({
    required this.progress,
    required this.xp,
    required this.xpToNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C0912), Color(0xFF15101E)],
        ),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Stack(
        children: [
          // Fill
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(
                  colors: [AppColors.purpleDk, AppColors.purpleLt],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.purpleGlow45,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          // Texto centro
          Center(
            child: Text(
              '$xp / $xpToNext XP',
              style: GoogleFonts.roboto(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.txt,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WalletPills ──────────────────────────────────────────────────────
class SanctuaryWalletPills extends ConsumerWidget {
  const SanctuaryWalletPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Pill(
          icon: Icons.monetization_on,
          iconColor: AppColors.gold,
          iconSize: 13,
          value: player?.gold ?? 0,
        ),
        const SizedBox(height: 6),
        _Pill(
          icon: Icons.diamond_outlined,
          iconColor: AppColors.purple,
          iconSize: 12,
          value: player?.gems ?? 0,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final int value;
  const _Pill({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 3, 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xE6141019), Color(0xE60A080E)],
        ),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.txt,
            ),
          ),
          const SizedBox(width: 6),
          // Botão "+" (placeholder — sem ação)
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldDk),
            ),
            child: const Text(
              '+',
              style: TextStyle(
                color: AppColors.goldLt,
                fontSize: 12,
                height: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── UtilRow ──────────────────────────────────────────────────────────
class SanctuaryUtilRow extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onInbox;
  final VoidCallback onFriends;
  final VoidCallback onBell;
  const SanctuaryUtilRow({
    super.key,
    required this.onMenu,
    required this.onInbox,
    required this.onFriends,
    required this.onBell,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IBtn(icon: Icons.menu, onTap: onMenu),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.mail_outline, onTap: onInbox),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.people_outline, onTap: onFriends),
        const Spacer(),
        _IBtn(icon: Icons.notifications_none, onTap: onBell, showDot: true),
      ],
    );
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;
  const _IBtn({required this.icon, required this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF221A2E), Color(0xFF0B0910)],
              ),
              // Mesma paleta dourada dos botoes/medalhoes do app.
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: AppColors.goldLt, size: 19),
          ),
          if (showDot)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.6),
                        blurRadius: 6),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Medallion ────────────────────────────────────────────────────────
class SanctuaryMedallion extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool locked;
  const SanctuaryMedallion({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final medColor = locked ? AppColors.txtMut : AppColors.goldLt;
    final ringColor = locked ? AppColors.borderViolet : AppColors.goldDk;
    return Opacity(
      opacity: locked ? 0.4 : 1.0,
      child: GestureDetector(
        // Sempre tappable: quando locked a tela decide mostrar o snack do
        // gate (sem navegar). Mantém o feedback do comportamento atual.
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF221A2E), Color(0xFF0B0910)],
                ),
                border: Border.all(color: ringColor),
                boxShadow: locked
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          blurRadius: 12,
                        ),
                      ],
              ),
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: medColor, size: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              locked ? '???' : label.toUpperCase(),
              style: GoogleFonts.roboto(
                fontSize: 11,
                letterSpacing: 1.5,
                color: locked ? AppColors.txtMut : AppColors.txt2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
