import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/domain/services/faction_admission_sub_task_types.dart';
import 'package:noheroes_app/domain/services/faction_admission_validator.dart';

/// Sprint 3.4 Etapa B (Sub-Etapa B.1) — testes do
/// `FactionAdmissionValidator`. 1 caso por sub-type cobrindo
/// caminho positivo (achieved=true), caminho negativo (achieved=false)
/// e edge case de janela quando aplicável.
///
/// Setup: cria player + insere fixtures via `customStatement` (mais
/// barato que ir via service real). Janela start = 1000ms, eventos
/// dentro/fora controlados por timestamp `completed_at`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FactionAdmissionValidator validator;
  const playerId = 1;
  const windowStart = 1000;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    validator = FactionAdmissionValidator(db);
    // Cria player base.
    await db.customStatement(
      "INSERT INTO players (id, email, password_hash) VALUES (?, ?, ?)",
      [playerId, 'test@test.com', 'hash'],
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ─── Helpers de fixture ─────────────────────────────────────────

  Future<void> insertDaily({
    required int id,
    required String modalidade,
    required String status,
    required int completedAt,
    String data = '2026-05-04',
  }) async {
    await db.customStatement(
      "INSERT INTO daily_missions (id, player_id, data, modalidade, "
      " titulo_key, titulo_resolvido, quote_resolvida, "
      " sub_tarefas_json, status, created_at, completed_at) "
      "VALUES (?, ?, ?, ?, 'k', 't', 'q', '[]', ?, 0, ?)",
      [id, playerId, data, modalidade, status, completedAt],
    );
  }

  Future<void> insertIndividual({
    required int id,
    required int completedAt,
  }) async {
    await db.customStatement(
      "INSERT INTO player_mission_progress (id, player_id, mission_key, "
      " modality, tab_origin, rank, target_value, current_value, "
      " reward_json, started_at, completed_at, reward_claimed, meta_json) "
      "VALUES (?, ?, 'IND_$id', 'individual', 'extras', 'e', 1, 1, "
      " '{}', 0, ?, 0, '{}')",
      [id, playerId, completedAt],
    );
  }

  Future<void> insertDiaryEntry({required int entryDate}) async {
    // diary_entries.entry_date é DateTimeColumn (Drift padrão = unix
    // seconds). updated_at tem default currentDateAndTime, omitimos.
    await db.customStatement(
      "INSERT INTO diary_entries (player_id, content, entry_date) "
      "VALUES (?, 'entry', ?)",
      [playerId, entryDate],
    );
  }

  // ─── 1. dailyCountWindow ────────────────────────────────────────

  group('admission_modality_count_window', () {
    test('atinge target quando há N+ dailies completed na janela',
        () async {
      await insertDaily(id: 1, modalidade: 'mental', status: 'completed', completedAt: 1500);
      await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 1600);
      await insertDaily(id: 3, modalidade: 'mental', status: 'partial', completedAt: 1700);
      // 3 mentais (2 completed + 1 partial) na janela.
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.modalityCountWindow,
          target: 3,
          windowStartMs: windowStart,
          params: {'modalidade': 'mental'},
        ),
      );
      expect(eval.current, 3);
      expect(eval.achieved, isTrue);
    });

    test('NÃO atinge se eventos foram antes da janela', () async {
      await insertDaily(id: 1, modalidade: 'mental', status: 'completed', completedAt: 500); // antes
      await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 800); // antes
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.modalityCountWindow,
          target: 1,
          windowStartMs: windowStart,
          params: {'modalidade': 'mental'},
        ),
      );
      expect(eval.current, 0);
      expect(eval.achieved, isFalse);
    });

    test('filtra por modalidade quando params.modalidade != null',
        () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500);
      await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 1600);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.modalityCountWindow,
          target: 1,
          windowStartMs: windowStart,
          params: {'modalidade': 'fisico'},
        ),
      );
      expect(eval.current, 1);
      expect(eval.achieved, isTrue);
    });

    test('respect_snapshot_rank: bloqueia quando rank atual < snapshot',
        () async {
      // Player rank='e' (default), snapshot='d' → bloqueia.
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.modalityCountWindow,
          target: 1,
          windowStartMs: windowStart,
          snapshotRank: 'd',
          params: {'modalidade': 'fisico', 'respect_snapshot_rank': true},
        ),
      );
      expect(eval.achieved, isFalse);
    });
  });

  // ─── 2. zeroFailedWindow ────────────────────────────────────────

  group('admission_zero_failed_window', () {
    test('achieved=true quando 0 falhas na janela', () async {
      await insertDaily(id: 1, modalidade: 'mental', status: 'completed', completedAt: 1500);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.zeroFailedWindow,
          target: 0,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.achieved, isTrue);
      expect(eval.failed, isFalse);
    });

    test('failed=true quando aparece 1 falha na janela (irrecuperável)',
        () async {
      await insertDaily(id: 1, modalidade: 'mental', status: 'failed', completedAt: 1500);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.zeroFailedWindow,
          target: 0,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.achieved, isFalse);
      expect(eval.failed, isTrue);
    });
  });

  // ─── 3. fullPerfectDayWindow ────────────────────────────────────

  group('admission_full_perfect_day_window', () {
    test('detecta dia onde 3/3 dailies estão completed', () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500, data: '2026-05-04');
      await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 1600, data: '2026-05-04');
      await insertDaily(id: 3, modalidade: 'espiritual', status: 'completed', completedAt: 1700, data: '2026-05-04');
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.fullPerfectDayWindow,
          target: 1,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.current, 1);
      expect(eval.achieved, isTrue);
    });

    test('NÃO detecta se algum partial existe no dia', () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500, data: '2026-05-04');
      await insertDaily(id: 2, modalidade: 'mental', status: 'partial', completedAt: 1600, data: '2026-05-04');
      await insertDaily(id: 3, modalidade: 'espiritual', status: 'completed', completedAt: 1700, data: '2026-05-04');
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.fullPerfectDayWindow,
          target: 1,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.achieved, isFalse);
    });
  });

  // ─── 4. individualCompletedWindow ────────────────────────────────

  group('admission_individual_completed_window', () {
    test('conta individuals completados na janela', () async {
      await insertIndividual(id: 1, completedAt: 1500);
      await insertIndividual(id: 2, completedAt: 1600);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.individualCompletedWindow,
          target: 2,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.current, 2);
      expect(eval.achieved, isTrue);
    });

    test('ignora individuals fora da janela', () async {
      await insertIndividual(id: 1, completedAt: 500); // antes
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.individualCompletedWindow,
          target: 1,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.achieved, isFalse);
    });
  });

  // ─── 5. diaryEntryWindow ────────────────────────────────────────

  group('admission_diary_entry_window', () {
    test('conta entradas de diário na janela (unix seconds)', () async {
      // windowStartMs=1000 → unix seconds=1. Inserir entry com
      // entry_date=2 (>= 1) deve contar.
      await insertDiaryEntry(entryDate: 2);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.diaryEntryWindow,
          target: 1,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.current, 1);
      expect(eval.achieved, isTrue);
    });
  });

  // ─── 6. zeroCategoryWindow ──────────────────────────────────────

  group('admission_zero_category_window', () {
    test('failed=true se completou 1 missão da modalidade proibida',
        () async {
      await insertDaily(id: 1, modalidade: 'mental', status: 'completed', completedAt: 1500);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.zeroCategoryWindow,
          target: 0,
          windowStartMs: windowStart,
          params: {'modalidade': 'mental'},
        ),
      );
      expect(eval.achieved, isFalse);
      expect(eval.failed, isTrue);
    });

    test('achieved se completou outras modalidades (não a proibida)',
        () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.zeroCategoryWindow,
          target: 0,
          windowStartMs: windowStart,
          params: {'modalidade': 'mental'},
        ),
      );
      expect(eval.achieved, isTrue);
      expect(eval.failed, isFalse);
    });
  });

  // ─── 7. streakMinimum ───────────────────────────────────────────

  group('admission_streak_minimum', () {
    test('lê players.daily_missions_streak corrente', () async {
      await db.customStatement(
        'UPDATE players SET daily_missions_streak = ? WHERE id = ?',
        [3, playerId],
      );
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.streakMinimum,
          target: 2,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.current, 3);
      expect(eval.achieved, isTrue);
    });

    test('falha se streak < target', () async {
      await db.customStatement(
        'UPDATE players SET daily_missions_streak = ? WHERE id = ?',
        [1, playerId],
      );
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.streakMinimum,
          target: 5,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.achieved, isFalse);
    });
  });

  // ─── 8. goldEarnedViaQuestsWindow ───────────────────────────────

  group('admission_gold_earned_via_quests_window', () {
    test('delta = current - baseline; passa se delta >= target',
        () async {
      // Set total_gold_earned_via_quests = 80.
      await db.customStatement(
        'UPDATE players SET total_gold_earned_via_quests = ? WHERE id = ?',
        [80, playerId],
      );
      // Baseline 30 → delta 50 → atinge target 50.
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType:
              FactionAdmissionSubTaskTypes.goldEarnedViaQuestsWindow,
          target: 50,
          windowStartMs: windowStart,
          params: {'baseline_gold_via_quests': 30},
        ),
      );
      expect(eval.current, 50);
      expect(eval.achieved, isTrue);
    });

    test('delta=0 quando não houve mudança desde baseline', () async {
      await db.customStatement(
        'UPDATE players SET total_gold_earned_via_quests = ? WHERE id = ?',
        [30, playerId],
      );
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType:
              FactionAdmissionSubTaskTypes.goldEarnedViaQuestsWindow,
          target: 1,
          windowStartMs: windowStart,
          params: {'baseline_gold_via_quests': 30},
        ),
      );
      expect(eval.current, 0);
      expect(eval.achieved, isFalse);
    });
  });

  // ─── 9. goldBalanceThreshold ────────────────────────────────────

  group('admission_gold_balance_threshold', () {
    test('snapshot de players.gold corrente', () async {
      await db.customStatement(
        'UPDATE players SET gold = ? WHERE id = ?',
        [150, playerId],
      );
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.goldBalanceThreshold,
          target: 100,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.current, 150);
      expect(eval.achieved, isTrue);
    });
  });

  // ─── 10. noPartialDayWindow ─────────────────────────────────────

  group('admission_no_partial_day_window', () {
    test('detecta dia com 3/3 completed e 0 partial', () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500, data: '2026-05-04');
      await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 1600, data: '2026-05-04');
      await insertDaily(id: 3, modalidade: 'espiritual', status: 'completed', completedAt: 1700, data: '2026-05-04');
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.noPartialDayWindow,
          target: 1,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.achieved, isTrue);
    });

    test('NÃO detecta se há partial no dia', () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500, data: '2026-05-04');
      await insertDaily(id: 2, modalidade: 'mental', status: 'partial', completedAt: 1600, data: '2026-05-04');
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.noPartialDayWindow,
          target: 1,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.achieved, isFalse);
    });
  });

  // ─── 11. exactDailyCountWindow ──────────────────────────────────

  group('admission_exact_daily_count_window', () {
    test('achieved quando count == target exato', () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500);
      await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 1600);
      await insertDaily(id: 3, modalidade: 'espiritual', status: 'completed', completedAt: 1700);
      await insertDaily(id: 4, modalidade: 'fisico', status: 'completed', completedAt: 1800);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.exactDailyCountWindow,
          target: 4,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.current, 4);
      expect(eval.achieved, isTrue);
      expect(eval.failed, isFalse);
    });

    test('failed=true se count > target (passou do limite)', () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500);
      await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 1600);
      await insertDaily(id: 3, modalidade: 'espiritual', status: 'completed', completedAt: 1700);
      await insertDaily(id: 4, modalidade: 'fisico', status: 'completed', completedAt: 1800);
      await insertDaily(id: 5, modalidade: 'mental', status: 'completed', completedAt: 1900);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.exactDailyCountWindow,
          target: 4,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.current, 5);
      expect(eval.achieved, isFalse);
      expect(eval.failed, isTrue);
    });

    test('still in progress se count < target', () async {
      await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 1500);
      await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 1600);
      final eval = await validator.evaluate(
        playerId: playerId,
        subTask: const FactionAdmissionSubTask(
          subType: FactionAdmissionSubTaskTypes.exactDailyCountWindow,
          target: 4,
          windowStartMs: windowStart,
        ),
      );
      expect(eval.current, 2);
      expect(eval.achieved, isFalse);
      expect(eval.failed, isFalse); // still in progress
    });
  });

  // ─── Serialização FactionAdmissionSubTask ──────────────────────

  group('FactionAdmissionSubTask JSON', () {
    test('toJson/fromJson roundtrip preserva campos', () {
      const original = FactionAdmissionSubTask(
        subType: FactionAdmissionSubTaskTypes.modalityCountWindow,
        target: 5,
        windowStartMs: 12345,
        snapshotRank: 'd',
        params: {'modalidade': 'mental'},
        completed: true,
      );
      final json = original.toJson();
      final restored = FactionAdmissionSubTask.fromJson(json);
      expect(restored.subType, original.subType);
      expect(restored.target, 5);
      expect(restored.windowStartMs, 12345);
      expect(restored.snapshotRank, 'd');
      expect(restored.params!['modalidade'], 'mental');
      expect(restored.completed, isTrue);
    });

    test('fromJson rejeita sub_type inválido', () {
      expect(
        () => FactionAdmissionSubTask.fromJson({
          'sub_type': 'not_a_real_type',
          'target': 1,
          'window_start_ms': 0,
        }),
        throwsFormatException,
      );
    });

    // Sprint 3.4 hotfix B.2 — label persistido em metaJson via toJson;
    // fromJson lê pra back-fill. UI usa pra renderizar texto legível
    // em vez de sub_type cru.
    test('label roundtrip: toJson inclui label se não-null', () {
      const original = FactionAdmissionSubTask(
        subType: FactionAdmissionSubTaskTypes.modalityCountWindow,
        target: 5,
        windowStartMs: 1000,
        label: 'Completar 5 missões mentais em 48h',
      );
      final json = original.toJson();
      expect(json['label'], 'Completar 5 missões mentais em 48h');
      final restored = FactionAdmissionSubTask.fromJson(json);
      expect(restored.label, 'Completar 5 missões mentais em 48h');
    });

    test('label roundtrip: toJson omite label quando null', () {
      const original = FactionAdmissionSubTask(
        subType: FactionAdmissionSubTaskTypes.streakMinimum,
        target: 3,
        windowStartMs: 1000,
      );
      final json = original.toJson();
      expect(json.containsKey('label'), isFalse);
      final restored = FactionAdmissionSubTask.fromJson(json);
      expect(restored.label, isNull);
    });
  });

  // ─── Sanity check: PlayerDao read ──────────────────────────────

  test('PlayerDao.findById retorna total_gold_earned_via_quests=0 default',
      () async {
    final p = await PlayerDao(db).findById(playerId);
    expect(p, isNotNull);
    expect(p!.totalGoldEarnedViaQuests, 0);
  });
}
