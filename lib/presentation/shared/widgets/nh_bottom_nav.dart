import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../app/providers.dart';

class NhBottomNav extends ConsumerWidget {
  final int currentIndex;
  const NhBottomNav({super.key, required this.currentIndex});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final level = player?.level ?? 1;
    final items = [
      _NavItem('Santuário', Icons.home_outlined,    Icons.home,        '/sanctuary'),
      _NavItem('Missões',   Icons.assignment_outlined, Icons.assignment, '/habits'),
      _NavItem('Personagem',Icons.person_outline,   Icons.person,      '/character'),
      _NavItem('Regiões',   Icons.map_outlined,     Icons.map,         '/regions'),
      _NavItem('Sombra',    Icons.blur_on_outlined,  Icons.blur_on,    '/shadow'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
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
              return GestureDetector(
                onTap: () {
                  if (!active) {
                    // Regiões bloqueadas até nível 4
                    if (item.route == '/regions' && level < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Regiões desbloqueiam no Nível 4.',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: const Color(0xFF0E0E1A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFF2A2A3A)),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    context.go(item.route);
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.route == '/regions' && level < 4
                            ? Icons.lock_outline
                            : active ? item.activeIcon : item.icon,
                        color: item.route == '/regions' && level < 4
                            ? AppColors.border
                            : active ? AppColors.purple : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(item.label,
                          style: GoogleFonts.roboto(
                            fontSize: 9,
                            color: active
                                ? AppColors.purple
                                : AppColors.textMuted,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                    ],
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
  _NavItem(this.label, this.icon, this.activeIcon, this.route);
}
