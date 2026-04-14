import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/asset_loader.dart';
import '../../../data/datasources/local/diary_service.dart';
import '../../../data/database/app_database.dart';

class CollectorTab extends ConsumerWidget {
  const CollectorTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    return FutureBuilder(
      future: _loadStats(ref, player?.id ?? 0, player?.level ?? 1,
          player?.caelumDay ?? 1),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.purple));
        }
        final stats = snap.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Progresso de lore
            _SectionTitle('LORE DESCOBERTA'),
            const SizedBox(height: 10),
            _ProgressCard(
              label: 'Entradas de Lore',
              current: stats['lore_unlocked'] as int,
              total: stats['lore_total'] as int,
              color: const Color(0xFFC2A05A),
              icon: Icons.auto_stories_outlined,
            ),
            const SizedBox(height: 8),
            _ProgressCard(
              label: 'Obras Adquiridas',
              current: stats['works_owned'] as int,
              total: stats['works_total'] as int,
              color: AppColors.gold,
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 20),

            // Estatísticas do diário
            _SectionTitle('DIÁRIO PESSOAL'),
            const SizedBox(height: 10),
            _StatRow('Entradas escritas',
                '${stats['diary_entries']} dias'),
            _StatRow('Total de palavras',
                '${stats['diary_words']} palavras'),
            const SizedBox(height: 20),

            // Missões de lore
            _SectionTitle('MISSÕES DE LORE'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Missões de lore chegam como eventos.\nFique atento aos próximos capítulos.',
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadStats(
      WidgetRef ref, int playerId, int level, int caelumDay) async {
    final db = ref.read(appDatabaseProvider);
    final diaryService = DiaryService(db);

    final allLore = await AssetLoader.getAllLoreEntries();
    final unlockedLore = await AssetLoader.getAvailableLoreEntries(
        playerLevel: level, caelumDay: caelumDay);
    final allWorks = await AssetLoader.getLibraryWorks();
    final ownedWorks =
        allWorks.where((w) => w['is_free'] == true).length;

    final diaryEntries = await diaryService.getTotalEntries(playerId);
    final diaryWords = await diaryService.getTotalWords(playerId);

    return {
      'lore_unlocked': unlockedLore.length,
      'lore_total': allLore.length,
      'works_owned': ownedWorks,
      'works_total': allWorks.length,
      'diary_entries': diaryEntries,
      'diary_words': diaryWords,
    };
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.cinzelDecorative(
            fontSize: 10,
            color: const Color(0xFFC2A05A),
            letterSpacing: 2));
  }
}

class _ProgressCard extends StatelessWidget {
  final String label;
  final int current, total;
  final Color color;
  final IconData icon;
  const _ProgressCard(
      {required this.label, required this.current, required this.total,
       required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? current / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 12, color: AppColors.textPrimary)),
            const Spacer(),
            Text('$current/$total',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).round()}% descoberto',
              style: GoogleFonts.roboto(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.roboto(
                fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFFC2A05A),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
