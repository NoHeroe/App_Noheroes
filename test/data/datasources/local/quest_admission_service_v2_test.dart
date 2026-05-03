import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/faction_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/class_quest_service.dart';
import 'package:noheroes_app/data/datasources/local/quest_admission_service.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';

/// Sprint 3.4 Sub-Etapa B.2 — testes do `QuestAdmissionService` v2.
///
/// Cobertura:
/// - `factionId == 'guild'` → early-return `[]` sem efeito colateral
/// - Cria N missões corretamente pra moon_clan (catálogo v2)
/// - Apenas 1ª missão `is_unlocked=true`; demais lockadas
/// - metaJson contém `sub_tasks`, `window_start_ms`, `snapshot_rank`,
///   `mission_id`, `title`, `description`
/// - Escala de dificuldade: reputação > 70 → janela 72h + threshold
///   reduzido; reputação < 40 → 36h + threshold aumentado
/// - Emite `FactionAdmissionStarted`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  late QuestAdmissionService service;
  const playerId = 1;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    final missionRepo = MissionRepositoryDrift(db);
    final classQuests = ClassQuestService(missionRepo);
    service = QuestAdmissionService(db, missionRepo, classQuests, bus);
    await db.customStatement(
      "INSERT INTO players (id, email, password_hash) VALUES (?, ?, ?)",
      [playerId, 'test@test.com', 'hash'],
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  // ─── Guilda early-return ────────────────────────────────────────

  test('factionId="guild" → early-return [] sem criar missão',
      () async {
    final created =
        await service.startFactionAdmission(playerId, 'guild');
    expect(created, isEmpty);

    final all =
        await MissionRepositoryDrift(db).findByTab(playerId, MissionTabOrigin.admission);
    expect(all, isEmpty);
  });

  // ─── Criação normal ─────────────────────────────────────────────

  test('moon_clan cria 3 missões; só a 1ª is_unlocked', () async {
    final created =
        await service.startFactionAdmission(playerId, 'moon_clan');
    expect(created.length, 3);

    var unlockedCount = 0;
    for (var i = 0; i < created.length; i++) {
      final meta = jsonDecode(created[i].metaJson) as Map<String, dynamic>;
      expect(meta['faction_id'], 'moon_clan');
      expect(meta['mission_id'], startsWith('ADM_MOON_'));
      expect(meta['title'], isA<String>());
      expect(meta['description'], isA<String>());
      expect(meta['snapshot_rank'], isA<String>());
      expect(meta['sub_tasks'], isA<List>());
      if (meta['is_unlocked'] == true) unlockedCount++;
    }
    expect(unlockedCount, 1, reason: 'só a 1ª missão deve estar unlocked');
  });

  test('emite FactionAdmissionStarted com totalQuests + attemptCount',
      () async {
    final captured = <FactionAdmissionStarted>[];
    final sub = bus.on<FactionAdmissionStarted>().listen(captured.add);

    await service.startFactionAdmission(playerId, 'moon_clan');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(captured.length, 1);
    expect(captured.first.factionId, 'moon_clan');
    expect(captured.first.totalQuests, 3);
    expect(captured.first.attemptCount, 1);

    await sub.cancel();
  });

  // ─── Idempotência ───────────────────────────────────────────────

  test('chamada repetida com missões ativas é idempotente', () async {
    final first =
        await service.startFactionAdmission(playerId, 'moon_clan');
    expect(first.length, 3);

    final second =
        await service.startFactionAdmission(playerId, 'moon_clan');
    // Retorna as missões existentes em vez de duplicar.
    expect(second.length, first.length);

    final all = await MissionRepositoryDrift(db)
        .findByTab(playerId, MissionTabOrigin.admission);
    final moonOnly = all.where((m) {
      try {
        final dec = jsonDecode(m.metaJson);
        return dec is Map && dec['faction_id'] == 'moon_clan';
      } catch (_) {
        return false;
      }
    });
    expect(moonOnly.length, 3);
  });

  // ─── Escala de dificuldade ──────────────────────────────────────

  test('reputação > 70 → janela 72h + threshold reduzido (-15%)',
      () async {
    // Set reputação 80 pra moon_clan.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO player_faction_reputation '
      '(player_id, faction_id, reputation, updated_at) VALUES (?, ?, ?, ?)',
      [playerId, 'moon_clan', 80, nowMs],
    );

    final created =
        await service.startFactionAdmission(playerId, 'moon_clan');
    final firstMeta =
        jsonDecode(created.first.metaJson) as Map<String, dynamic>;
    expect(firstMeta['window_duration_ms'], 72 * 60 * 60 * 1000);

    // ADM_MOON_1 sub-task 1 = daily_count_window target=5 mental.
    // Threshold scaling -15% → ceil(5 * 0.85) = ... no, mult=0.85,
    // floor(4.25) = 4. (Ver _scaleTarget: mult > 1 = ceil; mult < 1 = floor.)
    final subs = (firstMeta['sub_tasks'] as List).cast<Map>();
    final dailyCount = subs.firstWhere(
        (s) => s['sub_type'] == 'admission_daily_count_window');
    expect(dailyCount['target'], 4); // floor(5 * 0.85) = 4
  });

  test('reputação < 40 → janela 36h + threshold aumentado (+20%)',
      () async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO player_faction_reputation '
      '(player_id, faction_id, reputation, updated_at) VALUES (?, ?, ?, ?)',
      [playerId, 'moon_clan', 30, nowMs],
    );

    final created =
        await service.startFactionAdmission(playerId, 'moon_clan');
    final firstMeta =
        jsonDecode(created.first.metaJson) as Map<String, dynamic>;
    expect(firstMeta['window_duration_ms'], 36 * 60 * 60 * 1000);

    // 5 * 1.20 = 6 (ceil pra mult > 1).
    final subs = (firstMeta['sub_tasks'] as List).cast<Map>();
    final dailyCount = subs.firstWhere(
        (s) => s['sub_type'] == 'admission_daily_count_window');
    expect(dailyCount['target'], 6);
  });

  // Sprint 3.4 hotfix B.2 — label do catálogo persiste em metaJson.
  test('label do catálogo persiste em metaJson das sub-tasks',
      () async {
    final created =
        await service.startFactionAdmission(playerId, 'moon_clan');
    final firstMeta =
        jsonDecode(created.first.metaJson) as Map<String, dynamic>;
    final subs = (firstMeta['sub_tasks'] as List).cast<Map>();
    for (final s in subs) {
      expect(s['label'], isA<String>(),
          reason: 'sub-task deveria ter label persistido');
      expect((s['label'] as String).isNotEmpty, isTrue);
    }
    // Verifica conteúdo do 1º label (vem do catálogo v2:
    // ADM_MOON_1 sub-task 1 = "5 missões mentais em 48h").
    expect(subs.first['label'], contains('5 missões mentais'));
  });

  test('zero_failed_window NÃO sofre scaling (target=0 sempre)',
      () async {
    // reputação alta — mas zero_failed deve continuar 0.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO player_faction_reputation '
      '(player_id, faction_id, reputation, updated_at) VALUES (?, ?, ?, ?)',
      [playerId, 'moon_clan', 80, nowMs],
    );

    final created =
        await service.startFactionAdmission(playerId, 'moon_clan');
    // ADM_MOON_2 tem zero_failed_window target=0.
    for (final m in created) {
      final meta = jsonDecode(m.metaJson) as Map<String, dynamic>;
      final subs = (meta['sub_tasks'] as List).cast<Map>();
      for (final s in subs) {
        if (s['sub_type'] == 'admission_zero_failed_window') {
          expect(s['target'], 0);
        }
      }
    }
  });
}
