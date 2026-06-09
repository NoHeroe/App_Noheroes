import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/diary_events.dart';
import '../../../domain/entities/diary_entry.dart';

/// Serviço full-online de entradas de diário (Época 2, ADR-0024).
///
/// Não há invariante atômica de servidor pro diário (1 row/dia por jogador é
/// resolvido client-side via select-then-insert/update), então as escritas
/// usam PostgREST direto — sem RPC.
class DiaryService {
  final SupabaseClient _client;

  /// Sprint 3.4 Sub-Etapa B.2 — bus opcional pra emitir
  /// `DiaryEntryCreated` quando o jogador salva uma entrada. Foundation
  /// pro sub-type `admission_diary_entry_window` reagir em tempo real
  /// sem aguardar polling de outro evento terminal. Provider injeta;
  /// callers legacy podem omitir e o emit vira noop.
  final AppEventBus? _bus;

  DiaryService(this._client, {AppEventBus? bus}) : _bus = bus;

  static int countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  /// Bridge do uuid (String) pro `int playerId` do contrato de evento
  /// (`AppEvent.playerId` é `int?`, compartilhado por ~18 eventos). Mesma
  /// convenção dos demais services convertidos (ADR-0024).

  /// Retorna a entrada de hoje, ou null se não existe.
  Future<DiaryEntry?> getTodayEntry(String playerId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final row = await _client
        .from('diary_entries')
        .select()
        .eq('player_id', playerId)
        .gte('entry_date', today.toIso8601String())
        .lt('entry_date', tomorrow.toIso8601String())
        .maybeSingle();
    return row == null ? null : DiaryEntry.fromMap(row);
  }

  /// Salva ou atualiza a entrada de hoje.
  Future<void> saveEntry(String playerId, String content) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final words = countWords(content);
    final existing = await getTodayEntry(playerId);

    final isNew = existing == null;
    if (existing != null) {
      await _client.from('diary_entries').update({
        'content': content,
        'word_count': words,
        'updated_at': now.toIso8601String(),
      }).eq('id', existing.id);
    } else {
      await _client.from('diary_entries').insert({
        'player_id': playerId,
        'content': content,
        'word_count': words,
        'entry_date': today.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
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

  /// Histórico de entradas (mais recentes primeiro).
  Future<List<DiaryEntry>> getHistory(String playerId, {int limit = 30}) async {
    final rows = await _client
        .from('diary_entries')
        .select()
        .eq('player_id', playerId)
        .order('entry_date', ascending: false)
        .limit(limit);
    return rows.map((r) => DiaryEntry.fromMap(r)).toList();
  }

  /// Total de palavras escritas (para conquistas/missões).
  Future<int> getTotalWords(String playerId) async {
    final rows = await _client
        .from('diary_entries')
        .select('word_count')
        .eq('player_id', playerId);
    return rows.fold<int>(0, (sum, r) => sum + ((r['word_count'] as num?)?.toInt() ?? 0));
  }

  /// Total de entradas (dias escritos).
  Future<int> getTotalEntries(String playerId) async {
    final rows = await _client
        .from('diary_entries')
        .select('id')
        .eq('player_id', playerId);
    return rows.length;
  }
}
