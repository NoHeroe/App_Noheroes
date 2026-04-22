import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show OrderingTerm, OrderingMode;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/habit_dao.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/sanctuary'),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.surface,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('HISTÓRICO',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 16,
                          color: AppColors.gold,
                          letterSpacing: 2)),
                ],
              ),
            ),

            // Lista
            Expanded(
              child: player == null
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.purple))
                  : _HistoryList(playerId: player.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final int playerId;
  const _HistoryList({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return FutureBuilder<List<_LogEntry>>(
      future: _loadHistory(db, playerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.purple));
        }

        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return Center(
            child: Text('Nenhum histórico ainda.',
                style: GoogleFonts.roboto(
                    color: AppColors.textMuted, fontSize: 14)),
          );
        }

        // Agrupa por data
        final grouped = <String, List<_LogEntry>>{};
        for (final e in entries) {
          final key = _dateLabel(e.logDate);
          grouped.putIfAbsent(key, () => []).add(e);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: grouped.entries.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(group.key,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 10,
                          color: AppColors.gold,
                          letterSpacing: 2)),
                ),
                ...group.value.map((e) => _LogCard(entry: e)),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<_LogEntry>> _loadHistory(AppDatabase db, int playerId) async {
    final logs = await (db.select(db.habitLogsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..orderBy([(t) => OrderingTerm.desc(t.logDate)])
          ..limit(100))
        .get();

    final habits = await HabitDao(db).getHabits(playerId);
    final habitMap = {for (final h in habits) h.id: h};

    return logs.map((l) {
      final habit = habitMap[l.habitId];
      return _LogEntry(
        title: habit?.title ?? 'Missão removida',
        status: l.status,
        xpGained: l.xpGained,
        goldGained: l.goldGained,
        logDate: l.logDate,
        category: habit?.category ?? 'order',
      );
    }).toList();
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'HOJE';
    if (diff == 1) return 'ONTEM';
    return 'HÁ $diff DIAS';
  }
}

class _LogCard extends StatelessWidget {
  final _LogEntry entry;
  const _LogCard({super.key, required this.entry});

  Color get _statusColor => switch (entry.status) {
    'completed' => AppColors.shadowAscending,
    'partial'   => AppColors.mp,
    'niet'      => AppColors.gold,
    'failed'    => AppColors.shadowChaotic,
    _           => AppColors.textMuted,
  };

  String get _statusLabel => switch (entry.status) {
    'completed' => 'Concluído',
    'partial'   => 'Parcial',
    'niet'      => 'Niet',
    'failed'    => 'Falhou',
    _           => 'Pendente',
  };

  Color get _categoryColor => switch (entry.category) {
    'physical'  => AppColors.hp,
    'mental'    => AppColors.mp,
    'spiritual' => AppColors.shadowStable,
    'order'     => AppColors.gold,
    _           => AppColors.purple,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 40,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title,
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_statusLabel,
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: _statusColor)),
                    if (entry.xpGained > 0) ...[
                      const SizedBox(width: 8),
                      Text('+${entry.xpGained} XP',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: AppColors.xp)),
                    ],
                    if (entry.goldGained > 0) ...[
                      const SizedBox(width: 6),
                      Text('+${entry.goldGained} 🪙',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: AppColors.gold)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${entry.logDate.hour.toString().padLeft(2, '0')}:${entry.logDate.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.roboto(
                fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String title;
  final String status;
  final int xpGained;
  final int goldGained;
  final DateTime logDate;
  final String category;

  _LogEntry({
    required this.title,
    required this.status,
    required this.xpGained,
    required this.goldGained,
    required this.logDate,
    required this.category,
  });
}
