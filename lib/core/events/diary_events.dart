import 'app_event.dart';

/// Sprint 3.4 Sub-Etapa B.2 — entrada de diário criada ou atualizada.
///
/// Emitido pelo `DiaryService.saveEntry` após persistir. Consumido
/// pelo `FactionAdmissionProgressService` pra re-avaliar sub-tasks
/// `admission_diary_entry_window` em tempo real (sem aguardar próximo
/// evento terminal pra polling).
///
/// `wordCount` carregado pra futuros listeners que precisem
/// (achievements de "X palavras totais", etc).
class DiaryEntryCreated extends AppEvent {
  @override
  final int playerId;
  final int wordCount;

  /// `true` quando o evento representa a 1ª entrada do dia (insert
  /// novo); `false` quando é update de entry existente do mesmo dia.
  /// Listener pode optar por reagir só a inserts (1 evento por dia)
  /// ou a updates também.
  final bool isNew;

  DiaryEntryCreated({
    required this.playerId,
    required this.wordCount,
    required this.isNew,
    super.at,
  });

  @override
  String toString() =>
      'DiaryEntryCreated(player=$playerId, words=$wordCount, new=$isNew)';
}
