import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action('Missões', Icons.assignment_outlined, '/quests', AppColors.purple),
      _Action('Personagem', Icons.person_outline, '/character', AppColors.gold),
      _Action('Sombra', Icons.blur_on, '/shadow', AppColors.shadowStable),
      _Action('Regiões', Icons.map_outlined, '/regions', AppColors.mp),
      _Action('Inventário', Icons.inventory_2_outlined, '/inventory', AppColors.rarityRare),
      _Action('Facções', Icons.shield_outlined, '/factions', AppColors.hp),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACESSO RÁPIDO',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 11,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: actions.map((a) => _ActionCard(action: a)).toList(),
        ),
      ],
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  _Action(this.label, this.icon, this.route, this.color);
}

class _ActionCard extends StatelessWidget {
  final _Action action;
  const _ActionCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(action.route),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: action.color.withOpacity(0.12),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
