import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Sprint 3.3 Etapa Final-B — filtros principais da tela `/achievements`.
enum AchievementFilter {
  todas,
  pendentes,
  desbloqueadas,
  bloqueadas,
}

extension AchievementFilterLabel on AchievementFilter {
  String get label => switch (this) {
        AchievementFilter.todas => 'Todas',
        AchievementFilter.pendentes => 'Pendentes',
        AchievementFilter.desbloqueadas => 'Desbloqueadas',
        AchievementFilter.bloqueadas => 'Bloqueadas',
      };
}

/// Chip horizontal scrollable + dropdown opcional de categoria.
class AchievementFilters extends StatelessWidget {
  final AchievementFilter active;
  final String? activeCategory;
  final List<String> categories;
  final ValueChanged<AchievementFilter> onFilterChange;
  final ValueChanged<String?> onCategoryChange;
  final int pendingCount;

  const AchievementFilters({
    super.key,
    required this.active,
    required this.activeCategory,
    required this.categories,
    required this.onFilterChange,
    required this.onCategoryChange,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in AchievementFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _chip(
                  label: f == AchievementFilter.pendentes && pendingCount > 0
                      ? '${f.label} ($pendingCount)'
                      : f.label,
                  active: f == active && activeCategory == null,
                  onTap: () => onFilterChange(f),
                ),
              ),
            const SizedBox(width: 4),
            _categoryDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.gold.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? AppColors.gold.withValues(alpha: 0.7)
                : AppColors.border,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.roboto(
                fontSize: 11,
                color: active ? AppColors.gold : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeCategory != null
              ? AppColors.purpleLight.withValues(alpha: 0.7)
              : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: activeCategory,
          hint: Text('Por categoria',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.textSecondary)),
          dropdownColor: AppColors.surface,
          isDense: true,
          style: GoogleFonts.roboto(
              fontSize: 11, color: AppColors.purpleLight),
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem(value: null, child: Text('— sem filtro —')),
            for (final c in categories)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: onCategoryChange,
        ),
      ),
    );
  }
}
