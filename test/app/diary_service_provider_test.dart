import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/diary_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.4 Etapa G.2 (D15) — `diaryServiceProvider` injeta o
/// `appEventBusProvider`, de modo que `saveEntry` publique
/// `DiaryEntryCreated`. Sem o bus (o bug: `DiaryService(db)` direto no
/// `library_screen`), o publish virava no-op e a sub-task de admissão
/// `admission_diary_entry_window` não progredia.
///
/// Especificação canônica: salvar uma entrada via o serviço resolvido pelo
/// provider DEVE publicar exatamente um `DiaryEntryCreated` no bus.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('diaryServiceProvider: saveEntry publica DiaryEntryCreated no bus',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final bus = container.read(appEventBusProvider);
    final received = <DiaryEntryCreated>[];
    final sub = bus.on<DiaryEntryCreated>().listen(received.add);
    addTearDown(sub.cancel);

    final service = container.read(diaryServiceProvider);
    await service.saveEntry(1, 'minha primeira entrada de diario hoje');

    // Stream broadcast entrega no microtask seguinte.
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1),
        reason: 'saveEntry via provider deve publicar 1 DiaryEntryCreated');
    expect(received.first.playerId, 1);
    expect(received.first.isNew, isTrue);
    expect(received.first.wordCount, 6);
  });
}
