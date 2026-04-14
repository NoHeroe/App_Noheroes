import 'package:drift/drift.dart';
import '../../database/app_database.dart';

class DiaryService {
  final AppDatabase _db;
  DiaryService(this._db);

  static int countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  /// Retorna a entrada de hoje, ou null se não existe
  Future<DiaryEntriesTableData?> getTodayEntry(int playerId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return (_db.select(_db.diaryEntriesTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.entryDate.isBetweenValues(today, tomorrow)))
        .getSingleOrNull();
  }

  /// Salva ou atualiza entrada de hoje
  Future<void> saveEntry(int playerId, String content) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final words = countWords(content);
    final existing = await getTodayEntry(playerId);

    if (existing != null) {
      await (_db.update(_db.diaryEntriesTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(DiaryEntriesTableCompanion(
        content: Value(content),
        wordCount: Value(words),
        updatedAt: Value(now),
      ));
    } else {
      await _db.into(_db.diaryEntriesTable).insert(
        DiaryEntriesTableCompanion(
          playerId: Value(playerId),
          content: Value(content),
          wordCount: Value(words),
          entryDate: Value(today),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Histórico de entradas (mais recentes primeiro)
  Future<List<DiaryEntriesTableData>> getHistory(int playerId,
      {int limit = 30}) async {
    return (_db.select(_db.diaryEntriesTable)
          ..where((t) => t.playerId.equals(playerId))
          ..orderBy([(t) => OrderingTerm.desc(t.entryDate)])
          ..limit(limit))
        .get();
  }

  /// Total de palavras escritas (para conquistas/missões)
  Future<int> getTotalWords(int playerId) async {
    final entries = await (_db.select(_db.diaryEntriesTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    return entries.fold<int>(0, (sum, e) => sum + e.wordCount);
  }

  /// Total de entradas (dias escritos)
  Future<int> getTotalEntries(int playerId) async {
    final entries = await (_db.select(_db.diaryEntriesTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    return entries.length;
  }
}
