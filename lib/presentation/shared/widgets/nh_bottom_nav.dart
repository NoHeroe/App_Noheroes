import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';

class NhBottomNav extends ConsumerWidget {
  final int currentIndex;
  const NhBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final level = player?.level ?? 1;
    final attrPoints = player?.attributePoints ?? 0;

    // Restyle Santuário (mockup v3) — Santuário no CENTRO (index 2).
    final items = [
      _NavItem('Missões',   Icons.assignment_outlined, Icons.assignment, '/quests',    1),
      _NavItem('Personagem',Icons.person_outline,   Icons.person,      '/character',  1),
      _NavItem('Santuário', Icons.home_outlined,    Icons.home,        '/sanctuary',  1),
      _NavItem('Regiões',   Icons.map_outlined,     Icons.map,         '/regions',    4),
      _NavItem('Sombra',    Icons.blur_on_outlined,  Icons.blur_on,    '/shadow',    10),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final active = i == currentIndex;
              final locked = level < item.minLevel;
              // Ping dourado no Personagem (index 1) quando há pontos de
              // atributo pra distribuir.
              final showPing = i == 1 && !locked && attrPoints > 0;

              return GestureDetector(
                onTap: () {
                  if (active) return;
                  if (locked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${item.label} desbloqueia no Nível ${item.minLevel}.',
                          style: GoogleFonts.roboto(color: AppColors.textPrimary),
                        ),
                        backgroundColor: AppColors.surface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  context.go(item.route);
                },
                child: Opacity(
                  opacity: locked ? 0.45 : 1.0,
                  child: Container(
                    color: Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: active
                                  ? const BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.purpleGlow45,
                                          blurRadius: 12,
                                        ),
                                      ],
                                    )
                                  : null,
                              child: Icon(
                                locked
                                    ? Icons.lock_outline
                                    : (active ? item.activeIcon : item.icon),
                                color: locked
                                    ? AppColors.txtMut
                                    : (active
                                        ? AppColors.purpleLt
                                        : AppColors.textMuted),
                                size: 22,
                              ),
                            ),
                            // Ping dourado de pontos de atributo disponíveis.
                            if (showPing)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.gold,
                                    border: Border.all(
                                        color: AppColors.surface, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold
                                            .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.label,
                            style: GoogleFonts.roboto(
                              fontSize: 9,
                              color: locked
                                  ? AppColors.txtMut
                                  : (active
                                      ? AppColors.purpleLt
                                      : AppColors.textMuted),
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final int minLevel;
  _NavItem(this.label, this.icon, this.activeIcon, this.route, this.minLevel);
}
