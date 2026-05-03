import 'package:drift/drift.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/diary_events.dart';
import '../../database/app_database.dart';

class DiaryService {
  final AppDatabase _db;

  /// Sprint 3.4 Sub-Etapa B.2 — bus opcional pra emitir
  /// `DiaryEntryCreated` quando o jogador salva uma entrada. Foundation
  /// pro sub-type `admission_diary_entry_window` reagir em tempo real
  /// sem aguardar polling de outro evento terminal. Provider injeta;
  /// callers legacy (testes que constroem DiaryService direto) podem
  /// omitir e o emit vira noop.
  final AppEventBus? _bus;

  DiaryService(this._db, {AppEventBus? bus}) : _bus = bus;

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

    final isNew = existing == null;
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
    // Sprint 3.4 Sub-Etapa B.2 — emite evento pra
    // FactionAdmissionProgressService re-avaliar sub-tasks
    // diary_entry_window em tempo real.
    _bus?.publish(DiaryEntryCreated(
      playerId: playerId,
      wordCount: words,
      isNew: isNew,
    ));
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
