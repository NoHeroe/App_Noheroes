import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/asset_loader.dart';

final _worksProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return AssetLoader.getLibraryWorks();
});

class WorksTab extends ConsumerWidget {
  const WorksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final worksAsync = ref.watch(_worksProvider);

    return worksAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.purple)),
      error: (e, _) => Center(
          child: Text('Erro: $e',
              style: const TextStyle(color: AppColors.textMuted))),
      data: (works) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner passe
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: AppColors.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Passe NoHeroes',
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 11, color: AppColors.gold)),
                        Text(
                            'Acesso ilimitado a todas as obras da Biblioteca.',
                            style: GoogleFonts.roboto(
                                fontSize: 10,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: Text('Em breve',
                        style: GoogleFonts.roboto(
                            fontSize: 10, color: AppColors.gold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ...works.map((w) {
              final level = w['unlock_level'] as int? ?? 1;
              final playerLevel = player?.level ?? 1;
              final locked = playerLevel < level;
              final isFree = w['is_free'] as bool? ?? false;
              final requiresPass = w['requires_pass'] as bool? ?? false;
              final type = w['type'] as String? ?? 'livro';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: locked
                          ? AppColors.border
                          : const Color(0xFFC2A05A)
                              .withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    // Capa
                    Container(
                      width: 48, height: 64,
                      decoration: BoxDecoration(
                        color: locked
                            ? AppColors.surfaceAlt
                            : const Color(0xFFC2A05A)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: locked
                                ? AppColors.border
                                : const Color(0xFFC2A05A)
                                    .withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        _typeIcon(type),
                        color: locked
                            ? AppColors.textMuted
                            : const Color(0xFFC2A05A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w['title'] as String,
                              style: GoogleFonts.cinzelDecorative(
                                  fontSize: 11,
                                  color: locked
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(w['author'] as String,
                              style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            w['description'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4),
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            _Badge(
                                label: type,
                                color: const Color(0xFFC2A05A)),
                            const SizedBox(width: 6),
                            if (locked)
                              _Badge(
                                  label: 'Nível $level',
                                  color: AppColors.textMuted)
                            else if (isFree)
                              _Badge(
                                  label: 'Grátis',
                                  color: AppColors.shadowAscending)
                            else if (requiresPass)
                              _Badge(
                                  label: 'Passe',
                                  color: AppColors.gold)
                            else
                              _Badge(
                                  label: 'Comprar',
                                  color: AppColors.mp),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      locked ? Icons.lock_outline : Icons.menu_book_outlined,
                      color: locked
                          ? AppColors.textMuted
                          : const Color(0xFFC2A05A),
                      size: 20,
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'mangá' || 'manga'   => Icons.image_outlined,
        'webtoon'            => Icons.view_day_outlined,
        'novela'             => Icons.edit_note_outlined,
        _                    => Icons.menu_book_outlined,
      };
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.roboto(fontSize: 9, color: color)),
    );
  }
}
