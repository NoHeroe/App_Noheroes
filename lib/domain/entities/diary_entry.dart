/// Modelo full-online de uma entrada de diário (Época 2, ADR-0024).
///
/// Substitui o `DiaryEntriesTableData` (Drift) como objeto em memória. Mantém
/// a mesma API de getters (camelCase) que a UI já lê (`e.content`,
/// `e.wordCount`, `e.entryDate`, `e.id`).
///
/// [id] é a PK de linha (bigserial -> int). [playerId] é o uuid do jogador
/// (`auth.users.id`), agora `String`.
///
/// `fromMap` lê as chaves snake_case da row do Postgres (PostgREST/Supabase).
class DiaryEntry {
  final int id;
  final String playerId;
  final String content;
  final int wordCount;
  final DateTime entryDate;
  final DateTime updatedAt;

  const DiaryEntry({
    required this.id,
    required this.playerId,
    this.content = '',
    this.wordCount = 0,
    required this.entryDate,
    required this.updatedAt,
  });

  static int _int(Object? v, [int fallback = 0]) =>
      v == null ? fallback : (v as num).toInt();

  static DateTime _dt(Object? v) => v == null
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.parse(v as String);

  /// Constrói a partir de uma row do Postgres (chaves snake_case).
  factory DiaryEntry.fromMap(Map<String, dynamic> m) => DiaryEntry(
        id: _int(m['id']),
        playerId: m['player_id'] as String,
        content: (m['content'] as String?) ?? '',
        wordCount: _int(m['word_count']),
        entryDate: _dt(m['entry_date']),
        updatedAt: _dt(m['updated_at']),
      );
}
