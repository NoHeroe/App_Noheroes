import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class RegionsScreen extends StatelessWidget {
  const RegionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final regions = [
      _Region('Ruínas Exteriores', 'O ponto de partida. Fragmentos de Caelum.',
          Icons.castle_outlined, AppColors.textMuted, true, 'Desbloqueada'),
      _Region('Vale Estilhaçado', 'Ventos cortantes e ecos do Vazio.',
          Icons.terrain, AppColors.textMuted, false, 'Nível 5'),
      _Region('Floresta Branca', 'Névoa eterna. Criaturas silenciosas.',
          Icons.forest_outlined, AppColors.shadowStable, false, 'Nível 8'),
      _Region('Campos de Aureum', 'Planícies douradas com ruínas sagradas.',
          Icons.wb_sunny_outlined, AppColors.gold, false, 'Nível 12'),
      _Region('Nova Draconis', 'Território de fogo e escamas antigas.',
          Icons.local_fire_department_outlined, AppColors.hp, false, 'Nível 20'),
      _Region('Thanam', 'A raiz do mundo. Poucos retornam.',
          Icons.dark_mode_outlined, AppColors.purple, false, 'Nível 35'),
      _Region('Fendas Dimensionais', 'Instabilidade pura. Recompensas únicas.',
          Icons.blur_on, AppColors.xp, false, 'Evento especial'),
    ];

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text('REGIÕES',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                      const Spacer(),
                      Text('1/7 desbloqueadas',
                          style: GoogleFonts.roboto(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: regions.length,
                    itemBuilder: (_, i) => _RegionCard(region: regions[i]),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: NhBottomNav(currentIndex: 3),
          ),
        ],
      ),
    );
  }
}

class _Region {
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final String requirement;
  _Region(this.name, this.desc, this.icon, this.color,
      this.unlocked, this.requirement);
}

class _RegionCard extends StatelessWidget {
  final _Region region;
  const _RegionCard({super.key, required this.region});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: region.unlocked
              ? region.color.withOpacity(0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: region.unlocked
                  ? region.color.withOpacity(0.15)
                  : AppColors.surfaceAlt,
            ),
            child: Icon(region.icon,
                color: region.unlocked
                    ? region.color
                    : AppColors.textMuted,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(region.name,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 13,
                        color: region.unlocked
                            ? AppColors.textPrimary
                            : AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(region.desc,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: region.unlocked
                  ? region.color.withOpacity(0.1)
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: region.unlocked
                    ? region.color.withOpacity(0.4)
                    : AppColors.border,
              ),
            ),
            child: Text(
              region.unlocked ? 'Acessar' : region.requirement,
              style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: region.unlocked
                      ? region.color
                      : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
