import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/diary_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/guild_ascension_progress_service.dart';
import 'package:noheroes_app/data/datasources/local/guild_ascension_service.dart';

/// A.2 — ignição do motor de ascensão. Cobre:
/// - cada check_type vivo conta certo (incl. mapeamento de categoria);
/// - ignição avança progress por evento;
/// - step completa ao bater target;
/// - cada ciclo do catálogo real completável de ponta a ponta.
Future<int> _seedPlayer(
  AppDatabase db, {
  String guildRank = 'E',
  int totalQuests = 0,
  int streak = 0,
}) async {
  return db.customInsert(
    'INSERT INTO players (email, password_hash, guild_rank, '
    'total_quests_completed, streak_days) VALUES (?, ?, ?, ?, ?)',
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withString(guildRank),
      Variable.withInt(totalQuests),
      Variable.withInt(streak),
    ],
  );
}

/// Pré-seed de UMA row de step (bypassa o initCycle aleatório → teste
/// determinístico por check_type).
Future<void> _seedStep(
  AppDatabase db, {
  required int playerId,
  required String checkType,
  required Map<String, dynamic> checkParams,
  required int target,
  String rankFrom = 'E',
  String rankTo = 'D',
  int step = 1,
}) async {
  await db.customStatement(
    'INSERT INTO guild_ascension_progress (player_id, rank_from, rank_to, '
    'step, quest_key, title, description, check_type, check_params_json, '
    'unlock_level, xp_reward, gold_reward, progress_target) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      playerId, rankFrom, rankTo, step, 'k$step', 't', 'd',
      checkType, jsonEncode(checkParams), 1, 100, 50, target,
    ],
  );
}

Future<({bool completed, int progress})> _readStep(
    AppDatabase db, int playerId, {int step = 1}) async {
  final rows = await db.customSelect(
    'SELECT completed, progress FROM guild_ascension_progress '
    'WHERE player_id = ? AND step = ?',
    variables: [Variable.withInt(playerId), Variable.withInt(step)],
  ).get();
  final r = rows.first;
  // drift bool → int 0/1 no SQLite cru.
  final c = r.data['completed'];
  final completed = c == 1 || c == true;
  return (completed: completed, progress: (r.data['progress'] as int?) ?? 0);
}

Future<void> _insertCompletedDaily(
    AppDatabase db, int playerId, String modalidade,
    {int n = 1}) async {
  for (var i = 0; i < n; i++) {
    await db.customStatement(
      'INSERT INTO daily_missions (player_id, data, modalidade, titulo_key, '
      'titulo_resolvido, quote_resolvida, sub_tarefas_json, status, '
      'created_at, completed_at) '
      "VALUES (?, '2026-06-08', ?, 'k', 't', 'q', '[]', 'completed', 0, 1)",
      [playerId, modalidade],
    );
  }
}

Future<void> _insertAchievements(AppDatabase db, int playerId, int n) async {
  for (var i = 0; i < n; i++) {
    await db.customStatement(
      'INSERT INTO player_achievements_completed (player_id, achievement_key, '
      'completed_at) VALUES (?, ?, 0)',
      [playerId, 'ACH_$i'],
    );
  }
}

Future<void> _insertDiaryWords(AppDatabase db, int playerId, int words) async {
  // 'w ' repetido => `words` palavras (LENGTH - LENGTH(sem espaço) + 1).
  final content = List.filled(words, 'w').join(' ');
  await db.customStatement(
    'INSERT INTO diary_entries (player_id, content, entry_date) '
    'VALUES (?, ?, 0)',
    [playerId, content],
  );
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

  group('check_types vivos contam certo', () {
    test('complete_any_total ← players.total_quests_completed', () async {
      final p = await _seedPlayer(db, totalQuests: 30);
      await _seedStep(db,
          playerId: p,
          checkType: 'complete_any_total',
          checkParams: {'count': 25},
          target: 25);
      await progress.evaluatePlayer(p);
      final s = await _readStep(db, p);
      expect(s.completed, isTrue);
    });

    test('complete_category_total mapeia physical→fisico (e ignora outras)',
        () async {
      final p = await _seedPlayer(db);
      await _seedStep(db,
          playerId: p,
          checkType: 'complete_category_total',
          checkParams: {'category': 'physical', 'count': 2},
          target: 2);
      await _insertCompletedDaily(db, p, 'fisico', n: 2);
      await _insertCompletedDaily(db, p, 'mental', n: 5); // não deve contar
      await progress.evaluatePlayer(p);
      final s = await _readStep(db, p);
      expect(s.completed, isTrue, reason: '2 fisico bate target 2');
    });

    test('complete_category_total NÃO completa abaixo do target', () async {
      final p = await _seedPlayer(db);
      await _seedStep(db,
          playerId: p,
          checkType: 'complete_category_total',
          checkParams: {'category': 'physical', 'count': 3},
          target: 3);
      await _insertCompletedDaily(db, p, 'fisico', n: 2);
      await progress.evaluatePlayer(p);
      final s = await _readStep(db, p);
      expect(s.completed, isFalse);
      expect(s.progress, 2, reason: 'grava progresso parcial');
    });

    test('streak_days ← players.streak_days', () async {
      final p = await _seedPlayer(db, streak: 10);
      await _seedStep(db,
          playerId: p,
          checkType: 'streak_days',
          checkParams: {'days': 7},
          target: 7);
      await progress.evaluatePlayer(p);
      expect((await _readStep(db, p)).completed, isTrue);
    });

    test('achievements_count ← player_achievements_completed', () async {
      final p = await _seedPlayer(db);
      await _insertAchievements(db, p, 5);
      await _seedStep(db,
          playerId: p,
          checkType: 'achievements_count',
          checkParams: {'count': 5},
          target: 5);
      await progress.evaluatePlayer(p);
      expect((await _readStep(db, p)).completed, isTrue);
    });

    test('diary_total_words ← diary_entries', () async {
      final p = await _seedPlayer(db);
      await _insertDiaryWords(db, p, 500);
      await _seedStep(db,
          playerId: p,
          checkType: 'diary_total_words',
          checkParams: {'words': 500},
          target: 500);
      await progress.evaluatePlayer(p);
      expect((await _readStep(db, p)).completed, isTrue);
    });
  });

  test('ignição por EVENTO avança o progresso (DiaryEntryCreated)', () async {
    final p = await _seedPlayer(db, totalQuests: 10);
    await _seedStep(db,
        playerId: p,
        checkType: 'complete_any_total',
        checkParams: {'count': 5},
        target: 5);

    bus.publish(DiaryEntryCreated(playerId: p, wordCount: 1, isNew: true));
    // Entrega de stream é assíncrona — deixa o listener enfileirar a task
    // ANTES de aguardar a fila esvaziar (senão settle() resolve no _tail
    // vazio inicial, antes da ignição rodar).
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await progress.settle();

    expect((await _readStep(db, p)).completed, isTrue,
        reason: 'evento disparou _evaluatePlayer → step completou');
  });

  group('catálogo real: cada ciclo completável de ponta a ponta', () {
    Future<void> maxOut(int playerId) async {
      await db.customStatement(
        'UPDATE players SET total_quests_completed = 999999, '
        'streak_days = 9999 WHERE id = ?',
        [playerId],
      );
      await _insertAchievements(db, playerId, 100);
      await _insertDiaryWords(db, playerId, 60000);
      for (final mod in ['fisico', 'mental', 'espiritual']) {
        await _insertCompletedDaily(db, playerId, mod, n: 105);
      }
    }

    for (final rank in ['E', 'D', 'C', 'B', 'A']) {
      test('ciclo rank $rank → canAscend (auto por gameplay + manual/mock '
          'simulados)', () async {
        final p = await _seedPlayer(db, guildRank: rank);
        await maxOut(p);
        // Cria as rows dos trials do ciclo real (catálogo B.1).
        await ascension.initCycle(p, rank);
        // B.1: trials manual/mock ainda NÃO auto-progridem (avanço = B.3).
        // Simula a conclusão deles aqui pra validar a completabilidade do
        // ciclo inteiro (e desbloqueia o loop pra alcançar os trials auto).
        await db.customStatement(
          'UPDATE guild_ascension_progress SET completed = 1 '
          'WHERE player_id = ? AND check_type IN '
          "('manual_proof', 'card_wins', 'boss_win')",
          [p],
        );
        // Ignição: avança os trials AUTO satisfeitos pelos contadores maxados.
        await progress.evaluatePlayer(p);
        expect(await ascension.canAscend(p, rank), isTrue,
            reason: 'ciclo $rank completável (auto via gameplay; manual/mock '
                'pendentes de B.3)');
      });
    }
  });
}
