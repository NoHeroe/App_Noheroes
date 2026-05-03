import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/diary_service.dart';
import '../../../data/database/app_database.dart';
import '../../shared/widgets/app_snack.dart';

final _diaryTodayProvider =
    FutureProvider.autoDispose<DiaryEntriesTableData?>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return null;
  return DiaryService(ref.read(appDatabaseProvider)).getTodayEntry(player.id);
});

final _diaryHistoryProvider =
    FutureProvider.autoDispose<List<DiaryEntriesTableData>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return [];
  return DiaryService(ref.read(appDatabaseProvider)).getHistory(player.id);
});

class DiaryTab extends ConsumerStatefulWidget {
  const DiaryTab({super.key});

  @override
  ConsumerState<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends ConsumerState<DiaryTab> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  int _words = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() => _words = DiaryService.countWords(text));
  }

  Future<void> _save() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null || _ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    // Sprint 3.4 Sub-Etapa B.2 — bus injetado pra emitir
    // DiaryEntryCreated (consumido pelo FactionAdmissionProgressService).
    await DiaryService(
      ref.read(appDatabaseProvider),
      bus: ref.read(appEventBusProvider),
    ).saveEntry(player.id, _ctrl.text.trim());
    setState(() => _saving = false);
    ref.invalidate(_diaryTodayProvider);
    ref.invalidate(_diaryHistoryProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Entrada salva — $_words palavras.',
            style: GoogleFonts.roboto(color: Colors.white)),
        backgroundColor: AppColors.shadowAscending,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(_diaryTodayProvider);
    final historyAsync = ref.watch(_diaryHistoryProvider);

    return todayAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.purple)),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (today) {
        if (today != null && _ctrl.text.isEmpty) {
          _ctrl.text = today.content;
          _words = today.wordCount;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Editor
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFC2A05A).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Row(
                      children: [
                        Text(
                          _formatToday(),
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 10,
                              color: const Color(0xFFC2A05A),
                              letterSpacing: 1),
                        ),
                        const Spacer(),
                        Text('$_words palavras',
                            style: GoogleFonts.roboto(
                                fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _ctrl,
                    onChanged: _onChanged,
                    maxLines: 12,
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.6),
                    decoration: InputDecoration(
                      hintText: 'O que aconteceu hoje em Caelum?',
                      hintStyle: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic),
                      contentPadding: const EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _saving ? null : _save,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFC2A05A)
                              .withValues(alpha: 0.15),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: const Color(0xFFC2A05A)
                                    .withValues(alpha: 0.4)),
                          ),
                        ),
                        child: Text(
                          _saving ? 'Salvando...' : 'Salvar Entrada',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 11,
                              color: const Color(0xFFC2A05A)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Histórico
            if (historyAsync.hasValue &&
                historyAsync.value!.isNotEmpty) ...[
              Text('ENTRADAS ANTERIORES',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 2)),
              const SizedBox(height: 10),
              ...historyAsync.value!.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(e.entryDate),
                                style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: const Color(0xFFC2A05A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.content.length > 80
                                    ? '${e.content.substring(0, 80)}...'
                                    : e.content,
                                style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${e.wordCount}p',
                            style: GoogleFonts.roboto(
                                fontSize: 10,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }

  String _formatToday() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
