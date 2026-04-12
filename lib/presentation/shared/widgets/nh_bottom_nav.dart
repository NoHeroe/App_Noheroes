import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class NhBottomNav extends StatelessWidget {
  final int currentIndex;
  const NhBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
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
                onTap: () { if (!active) context.go(item.route); },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        color: active ? AppColors.purple : AppColors.textMuted,
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
