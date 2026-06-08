import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/services/weekly_faction_validator.dart';

/// FATIA B1 — testes do `WeeklyFactionValidator`. Cobre cada sub-type
/// acumulativo + a JANELA LIMITADA (upper-bound: progresso antes de
/// weekStart e a partir de weekEnd NÃO conta) + o caso `equipment_improved`
/// que lê `current` do subTask (sem query).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WeeklyFactionValidator validator;
  const playerId = 1;

  // Semana fictícia: [10_000, 20_000) ms. Tudo fora desse intervalo
  // não deve contar.
  const weekStart = 10000;
  const weekEnd = 20000;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    validator = WeeklyFactionValidator(db);
    await db.customStatement(
      "INSERT INTO players (id, email, password_hash) VALUES (?, ?, ?)",
      [playerId, 'test@test.com', 'hash'],
    );
  });

  tearDown(() async => db.close());

  // ─── helpers de fixture ───────────────────────────────────────────

  Future<void> insertDaily({
    required int id,
    required String modalidade,
    required String status,
    required int completedAt,
    String data = '2026-06-08',
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

  Future<void> insertDiaryEntry({required int entryDateSeconds}) async {
    await db.customStatement(
      "INSERT INTO diary_entries (player_id, content, entry_date) "
      "VALUES (?, 'entry', ?)",
      [playerId, entryDateSeconds],
    );
  }

  Future<void> setStreak(int streak) async {
    await db.customStatement(
      "UPDATE players SET daily_missions_streak = ? WHERE id = ?",
      [streak, playerId],
    );
  }

  Future<void> setGoldEarned(int total) async {
    await db.customStatement(
      "UPDATE players SET total_gold_earned_via_quests = ? WHERE id = ?",
      [total, playerId],
    );
  }

  Future<void> setGold(int gold) async {
    await db.customStatement(
      "UPDATE players SET gold = ? WHERE id = ?",
      [gold, playerId],
    );
  }

  // Return type inferido (Future<SubTaskEvaluation>) — evita importar o
  // tipo, que vive em faction_admission_validator.dart.
  eval(WeeklyFactionSubTask sub) => validator.evaluate(
        playerId: playerId,
        subTask: sub,
        weekStartMs: weekStart,
        weekEndMs: weekEnd,
      );

  // ─── modality_count_window ────────────────────────────────────────

  group('modality_count_window', () {
    test('conta dailies completed/partial na janela (com filtro)', () async {
      await insertDaily(
          id: 1, modalidade: 'mental', status: 'completed', completedAt: 11000);
      await insertDaily(
          id: 2, modalidade: 'mental', status: 'partial', completedAt: 12000);
      await insertDaily(
          id: 3, modalidade: 'fisico', status: 'completed', completedAt: 13000);

      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.modalityCountWindow,
        target: 2,
        params: {'modalidade': 'mental'},
      ));
      expect(r.current, 2, reason: 'só os 2 mentais');
      expect(r.achieved, isTrue);
    });

    test('sem modalidade conta qualquer', () async {
      await insertDaily(
          id: 1, modalidade: 'mental', status: 'completed', completedAt: 11000);
      await insertDaily(
          id: 2, modalidade: 'fisico', status: 'completed', completedAt: 12000);
      await insertDaily(
          id: 3, modalidade: 'espiritual', status: 'partial', completedAt: 13000);

      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.modalityCountWindow,
        target: 3,
      ));
      expect(r.current, 3);
      expect(r.achieved, isTrue);
    });

    test('UPPER-BOUND: antes de weekStart e em/após weekEnd NÃO conta',
        () async {
      await insertDaily(
          id: 1, modalidade: 'mental', status: 'completed', completedAt: 9999); // antes
      await insertDaily(
          id: 2, modalidade: 'mental', status: 'completed', completedAt: 10000); // borda inicial (inclui)
      await insertDaily(
          id: 3, modalidade: 'mental', status: 'completed', completedAt: 19999); // dentro
      await insertDaily(
          id: 4, modalidade: 'mental', status: 'completed', completedAt: 20000); // weekEnd (exclui)
      await insertDaily(
          id: 5, modalidade: 'mental', status: 'completed', completedAt: 25000); // depois

      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.modalityCountWindow,
        target: 2,
        params: {'modalidade': 'mental'},
      ));
      // Só id=2 (>=10000) e id=3 (<20000) contam.
      expect(r.current, 2, reason: '[weekStart, weekEnd) — bordas corretas');
      expect(r.achieved, isTrue);
    });

    test('não atinge quando current < target', () async {
      await insertDaily(
          id: 1, modalidade: 'fisico', status: 'completed', completedAt: 11000);
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.modalityCountWindow,
        target: 4,
        params: {'modalidade': 'fisico'},
      ));
      expect(r.current, 1);
      expect(r.achieved, isFalse);
    });
  });

  // ─── streak_minimum ───────────────────────────────────────────────

  group('streak_minimum', () {
    test('snapshot do streak corrente (sem janela)', () async {
      await setStreak(5);
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.streakMinimum,
        target: 5,
      ));
      expect(r.current, 5);
      expect(r.achieved, isTrue);
    });

    test('streak abaixo do target não atinge', () async {
      await setStreak(3);
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.streakMinimum,
        target: 5,
      ));
      expect(r.current, 3);
      expect(r.achieved, isFalse);
    });
  });

  // ─── gold_earned_via_quests_window ───────────────────────────────

  group('gold_earned_via_quests_window', () {
    test('delta desde o baseline do assign', () async {
      await setGoldEarned(1300);
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.goldEarnedViaQuestsWindow,
        target: 400,
        params: {'baseline_gold_via_quests': 1000},
      ));
      expect(r.current, 300, reason: '1300 - 1000');
      expect(r.achieved, isFalse);
    });

    test('atinge quando delta >= target', () async {
      await setGoldEarned(1500);
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.goldEarnedViaQuestsWindow,
        target: 400,
        params: {'baseline_gold_via_quests': 1000},
      ));
      expect(r.current, 500);
      expect(r.achieved, isTrue);
    });
  });

  // ─── gold_balance_threshold ───────────────────────────────────────

  group('gold_balance_threshold', () {
    test('snapshot do gold corrente', () async {
      await setGold(120);
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.goldBalanceThreshold,
        target: 100,
      ));
      expect(r.current, 120);
      expect(r.achieved, isTrue);
    });
  });

  // ─── individual_completed_window ─────────────────────────────────

  group('individual_completed_window', () {
    test('conta individuais completadas na janela', () async {
      await insertIndividual(id: 1, completedAt: 11000);
      await insertIndividual(id: 2, completedAt: 12000);
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.individualCompletedWindow,
        target: 2,
      ));
      expect(r.current, 2);
      expect(r.achieved, isTrue);
    });

    test('UPPER-BOUND: fora da janela não conta', () async {
      await insertIndividual(id: 1, completedAt: 9000); // antes
      await insertIndividual(id: 2, completedAt: 21000); // depois
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.individualCompletedWindow,
        target: 1,
      ));
      expect(r.current, 0);
      expect(r.achieved, isFalse);
    });
  });

  // ─── diary_entry_window ──────────────────────────────────────────

  group('diary_entry_window', () {
    test('conta entradas na janela (entry_date em segundos)', () async {
      // weekStart=10000ms → 10s; weekEnd=20000ms → 20s.
      await insertDiaryEntry(entryDateSeconds: 12); // dentro
      await insertDiaryEntry(entryDateSeconds: 15); // dentro
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.diaryEntryWindow,
        target: 2,
      ));
      expect(r.current, 2);
      expect(r.achieved, isTrue);
    });

    test('UPPER-BOUND: antes/depois (em segundos) não conta', () async {
      await insertDiaryEntry(entryDateSeconds: 9); // antes de 10s
      await insertDiaryEntry(entryDateSeconds: 20); // weekEnd (exclui)
      await insertDiaryEntry(entryDateSeconds: 25); // depois
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.diaryEntryWindow,
        target: 1,
      ));
      expect(r.current, 0);
      expect(r.achieved, isFalse);
    });
  });

  // ─── full_perfect_day_window ─────────────────────────────────────

  group('full_perfect_day_window', () {
    test('conta dias com 3/3 completed', () async {
      // Dia A: 3 completed → perfeito.
      await insertDaily(
          id: 1, modalidade: 'fisico', status: 'completed', completedAt: 11000, data: 'A');
      await insertDaily(
          id: 2, modalidade: 'mental', status: 'completed', completedAt: 11100, data: 'A');
      await insertDaily(
          id: 3, modalidade: 'espiritual', status: 'completed', completedAt: 11200, data: 'A');
      // Dia B: 2 completed + 1 partial → NÃO perfeito.
      await insertDaily(
          id: 4, modalidade: 'fisico', status: 'completed', completedAt: 12000, data: 'B');
      await insertDaily(
          id: 5, modalidade: 'mental', status: 'completed', completedAt: 12100, data: 'B');
      await insertDaily(
          id: 6, modalidade: 'espiritual', status: 'partial', completedAt: 12200, data: 'B');

      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.fullPerfectDayWindow,
        target: 1,
      ));
      expect(r.current, 1, reason: 'só o dia A');
      expect(r.achieved, isTrue);
    });
  });

  // ─── no_partial_day_window ───────────────────────────────────────

  group('no_partial_day_window', () {
    test('conta dias completos sem partial', () async {
      await insertDaily(
          id: 1, modalidade: 'fisico', status: 'completed', completedAt: 11000, data: 'A');
      await insertDaily(
          id: 2, modalidade: 'mental', status: 'completed', completedAt: 11100, data: 'A');
      await insertDaily(
          id: 3, modalidade: 'espiritual', status: 'completed', completedAt: 11200, data: 'A');
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.noPartialDayWindow,
        target: 1,
      ));
      expect(r.current, 1);
      expect(r.achieved, isTrue);
    });
  });

  // ─── equipment_improved (NÃO querya DB) ──────────────────────────

  group('equipment_improved', () {
    test('lê current do subTask, não do banco', () async {
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.equipmentImproved,
        target: 2,
        current: 2,
      ));
      expect(r.current, 2);
      expect(r.achieved, isTrue);
    });

    test('current abaixo do target não atinge', () async {
      final r = await eval(const WeeklyFactionSubTask(
        subType: WeeklyFactionSubTaskTypes.equipmentImproved,
        target: 3,
        current: 1,
      ));
      expect(r.current, 1);
      expect(r.achieved, isFalse);
    });
  });
}
