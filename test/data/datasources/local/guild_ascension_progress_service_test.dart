import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/guild_ascension_progress_service.dart';
import 'package:noheroes_app/data/datasources/local/guild_ascension_service.dart';

/// B.3 — windowing dos trials (união daily+pmp), gating por janela ativa,
/// mock auto-satisfeito. Cobre:
/// - countMissionsCompleted (união lifetime + windowed; fora da janela não
///   conta; pmp failed não conta);
/// - motor (evaluatePlayer) no-op fora de active; avança dentro da janela;
/// - complete_category_total windowed;
/// - mock completed na materialização (initCycle).

const int _farFuture = 99999999999999; // ms bem no futuro

Future<int> _seedPlayer(AppDatabase db, {String guildRank = 'E'}) async {
  return db.customInsert(
    'INSERT INTO players (email, password_hash, guild_rank) VALUES (?, ?, ?)',
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withString(guildRank),
    ],
  );
}

/// Insere um STATE ativo com janela [start, deadline).
Future<void> _seedActiveState(AppDatabase db, int playerId,
    {String rank = 'E', int start = 0, int deadline = _farFuture}) async {
  await db.customStatement(
    'INSERT INTO guild_ascension_state (player_id, rank_from, attempts, '
    'failures, paid_cost, window_started_ms, window_deadline_ms, status) '
    "VALUES (?, ?, 1, 0, 0, ?, ?, 'active')",
    [playerId, rank, start, deadline],
  );
}

/// Pré-seed de UMA row de trial (bypassa initCycle).
Future<void> _seedStep(
  AppDatabase db, {
  required int playerId,
  required String checkType,
  required Map<String, dynamic> checkParams,
  required int target,
  String rankFrom = 'E',
  int step = 1,
}) async {
  await db.customStatement(
    'INSERT INTO guild_ascension_progress (player_id, rank_from, rank_to, '
    'step, quest_key, title, description, check_type, check_params_json, '
    'unlock_level, xp_reward, gold_reward, progress_target) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      playerId, rankFrom, 'D', step, 'k$step', 't', 'd',
      checkType, jsonEncode(checkParams), 1, 0, 0, target,
    ],
  );
}

Future<bool> _stepCompleted(AppDatabase db, int playerId,
    {int step = 1}) async {
  final r = await db.customSelect(
    'SELECT completed FROM guild_ascension_progress '
    'WHERE player_id = ? AND step = ?',
    variables: [Variable.withInt(playerId), Variable.withInt(step)],
  ).getSingle();
  final c = r.data['completed'];
  return c == 1 || c == true;
}

Future<void> _insertDaily(AppDatabase db, int playerId,
    {String modalidade = 'mental',
    int completedAt = 1,
    String status = 'completed',
    int n = 1}) async {
  for (var i = 0; i < n; i++) {
    await db.customStatement(
      'INSERT INTO daily_missions (player_id, data, modalidade, titulo_key, '
      'titulo_resolvido, quote_resolvida, sub_tarefas_json, status, '
      "created_at, completed_at) VALUES (?, '2026-06-08', ?, 'k', 't', 'q', "
      "'[]', ?, 0, ?)",
      [playerId, modalidade, status, completedAt],
    );
  }
}

Future<void> _insertPmp(AppDatabase db, int playerId,
    {int? completedAt = 1, int? failedAt, int n = 1}) async {
  for (var i = 0; i < n; i++) {
    await db.customStatement(
      'INSERT INTO player_mission_progress (player_id, mission_key, modality, '
      'tab_origin, rank, target_value, reward_json, started_at, completed_at, '
      "failed_at) VALUES (?, ?, 'internal', 'class', 'E', 1, '{}', 0, ?, ?)",
      [playerId, 'm${completedAt}_${failedAt}_$i', completedAt, failedAt],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  late GuildAscensionService ascension;
  late GuildAscensionProgressService progress;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    ascension = GuildAscensionService(db);
    progress = GuildAscensionProgressService(
      db: db,
      bus: bus,
      ascension: ascension,
    );
    progress.start();
  });

  tearDown(() async {
    await progress.stop();
    await bus.dispose();
    await db.close();
  });

  group('countMissionsCompleted (união daily + pmp)', () {
    test('lifetime conta daily + pmp completados', () async {
      final p = await _seedPlayer(db);
      await _insertDaily(db, p, n: 3);
      await _insertPmp(db, p, n: 2);
      expect(await ascension.countMissionsCompleted(p), 5);
    });

    test('pmp failed (sem completed_at) NÃO conta', () async {
      final p = await _seedPlayer(db);
      await _insertPmp(db, p, completedAt: null, failedAt: 1, n: 4);
      expect(await ascension.countMissionsCompleted(p), 0);
    });

    test('daily PARTIAL (com completed_at) NÃO conta — só completed', () async {
      final p = await _seedPlayer(db);
      await _insertDaily(db, p, status: 'partial', completedAt: 1, n: 3);
      await _insertDaily(db, p, status: 'completed', completedAt: 1, n: 2);
      expect(await ascension.countMissionsCompleted(p), 2,
          reason: 'partial não conta; só os 2 completed');
    });

    test('windowed conta só dentro de [start, deadline)', () async {
      final p = await _seedPlayer(db);
      await _insertDaily(db, p, completedAt: 50, n: 2); // dentro
      await _insertPmp(db, p, completedAt: 60, n: 1); // dentro
      await _insertDaily(db, p, completedAt: 5, n: 3); // antes
      await _insertPmp(db, p, completedAt: 200, n: 2); // depois
      expect(await ascension.countMissionsCompleted(p), 8, reason: 'lifetime');
      expect(
          await ascension.countMissionsCompleted(p, startMs: 10, deadlineMs: 100),
          3,
          reason: '2 daily + 1 pmp na janela [10,100)');
    });
  });

  group('motor (evaluatePlayer) — gating por janela', () {
    test('no-op fora de active (sem state) → trial não avança', () async {
      final p = await _seedPlayer(db);
      await _seedStep(db,
          playerId: p,
          checkType: 'complete_any_total',
          checkParams: {'count': 1},
          target: 1);
      await _insertPmp(db, p, n: 5); // sobra de completions
      await progress.evaluatePlayer(p);
      expect(await _stepCompleted(db, p), isFalse,
          reason: 'sem janela ativa, motor não avança');
    });

    test('no-op se janela vencida', () async {
      final p = await _seedPlayer(db);
      await _seedStep(db,
          playerId: p,
          checkType: 'complete_any_total',
          checkParams: {'count': 1},
          target: 1);
      await _insertPmp(db, p, n: 5);
      await _seedActiveState(db, p, deadline: 1); // já vencida
      await progress.evaluatePlayer(p);
      expect(await _stepCompleted(db, p), isFalse);
    });

    test('complete_any_total windowed: completa com completions na janela',
        () async {
      final p = await _seedPlayer(db);
      final now = DateTime.now().millisecondsSinceEpoch;
      await _seedStep(db,
          playerId: p,
          checkType: 'complete_any_total',
          checkParams: {'count': 3},
          target: 3);
      // Janela aberta (deadline futuro) começando pouco antes de agora.
      await _seedActiveState(db, p, start: now - 1000);
      await _insertDaily(db, p, completedAt: now, n: 2);
      await _insertPmp(db, p, completedAt: now, n: 1);
      await progress.evaluatePlayer(p);
      expect(await _stepCompleted(db, p), isTrue);
    });

    test('complete_any_total windowed: completions fora da janela não contam',
        () async {
      final p = await _seedPlayer(db);
      final now = DateTime.now().millisecondsSinceEpoch;
      await _seedStep(db,
          playerId: p,
          checkType: 'complete_any_total',
          checkParams: {'count': 3},
          target: 3);
      await _seedActiveState(db, p, start: now - 1000);
      // Antes do início da janela → não conta.
      await _insertDaily(db, p, completedAt: now - 100000, n: 5);
      await progress.evaluatePlayer(p);
      expect(await _stepCompleted(db, p), isFalse);
    });

    test('complete_category_total windowed (physical→fisico)', () async {
      final p = await _seedPlayer(db);
      final now = DateTime.now().millisecondsSinceEpoch;
      await _seedStep(db,
          playerId: p,
          checkType: 'complete_category_total',
          checkParams: {'category': 'physical', 'count': 2},
          target: 2);
      await _seedActiveState(db, p, start: now - 1000);
      await _insertDaily(db, p, modalidade: 'fisico', completedAt: now, n: 2);
      await _insertDaily(db, p, modalidade: 'mental', completedAt: now, n: 5);
      await progress.evaluatePlayer(p);
      expect(await _stepCompleted(db, p), isTrue,
          reason: '2 fisico na janela; mental não conta');
    });
  });

  group('mock auto-satisfeito na materialização', () {
    test('initCycle marca trials mock (card_wins) como completed', () async {
      // Ciclo B→A tem ba_t4 (mock card_wins).
      final p = await _seedPlayer(db, guildRank: 'B');
      await ascension.initCycle(p, 'B');
      final mock = await db.customSelect(
        'SELECT completed FROM guild_ascension_progress '
        "WHERE player_id = ? AND quest_key = 'ba_t4'",
        variables: [Variable.withInt(p)],
      ).getSingle();
      final c = mock.data['completed'];
      expect(c == 1 || c == true, isTrue, reason: 'mock auto-completo');
    });
  });
}
