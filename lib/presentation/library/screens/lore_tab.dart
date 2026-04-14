import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/asset_loader.dart';

final _loreProvider = FutureProvider.autoDispose<
    List<Map<String, dynamic>>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  return AssetLoader.getAvailableLoreEntries(
    playerLevel: player.level,
    caelumDay: player.caelumDay,
  );
});

class LoreTab extends ConsumerWidget {
  const LoreTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loreAsync = ref.watch(_loreProvider);

    return loreAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.purple)),
      error: (e, _) => Center(
          child: Text('Erro: $e',
              style: const TextStyle(color: AppColors.textMuted))),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined,
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                      size: 48),
                  const SizedBox(height: 12),
                  Text('Nenhum lore disponível ainda.',
                      style: GoogleFonts.roboto(
                          color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('Continue sua jornada para desbloquear.',
                      style: GoogleFonts.roboto(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          fontSize: 11)),
                ],
              ),
            ),
          );
        }

        // Agrupa por categoria
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final e in entries) {
          final cat = e['category'] as String? ?? 'geral';
          grouped.putIfAbsent(cat, () => []).add(e);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: grouped.entries.map((cat) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.key.toUpperCase(),
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 10,
                        color: const Color(0xFFC2A05A),
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                ...cat.value.map((entry) => _LoreCard(entry: entry)),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class _LoreCard extends StatefulWidget {
  final Map<String, dynamic> entry;
  const _LoreCard({required this.entry});

  @override
  State<_LoreCard> createState() => _LoreCardState();
}

class _LoreCardState extends State<_LoreCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFC2A05A).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories_outlined,
                    color: Color(0xFFC2A05A), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.entry['title'] as String,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: AppColors.textPrimary)),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted, size: 18,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              Text(widget.entry['content'] as String,
                  style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
