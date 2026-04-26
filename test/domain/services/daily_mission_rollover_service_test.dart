import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/daily_missions_dao.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/domain/enums/daily_unit_type.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/models/daily_mission.dart';
import 'package:noheroes_app/domain/models/daily_mission_status.dart';
import 'package:noheroes_app/domain/models/daily_sub_task_instance.dart';
import 'package:noheroes_app/domain/services/daily_mission_progress_service.dart';
import 'package:noheroes_app/domain/services/daily_mission_rollover_service.dart';

DailySubTaskInstance _sub(String k, int target,
        {int progresso = 0, bool? completed}) =>
    DailySubTaskInstance(
      subTaskKey: k,
      nomeVisivel: k,
      escalaAlvo: target,
      unidade: 'x',
      tipoUnidade: DailyUnitType.contagem,
      progressoAtual: progresso,
      completed: completed ?? (progresso >= target),
    );

DailyMission _mkMission({
  required int playerId,
  required String date,
  required List<DailySubTaskInstance> subs,
  DailyMissionStatus status = DailyMissionStatus.pending,
  bool rewardClaimed = false,
}) =>
    DailyMission(
      id: 0,
      playerId: playerId,
      data: date,
      modalidade: MissionCategory.fisico,
      subCategoria: 'treino',
      tituloKey: 'Forja',
      tituloResolvido: 'Forja',
      quoteResolvida: 'q',
      subTarefas: subs,
      status: status,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      completedAt: null,
      rewardClaimed: rewardClaimed,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DailyMissionsDao dao;
  late PlayerDao playerDao;
  late AppEventBus bus;
  late DailyMissionProgressService progress;
  late DailyMissionRolloverService rollover;
  late int pid;

  String dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = DailyMissionsDao(db);
    playerDao = PlayerDao(db);
    bus = AppEventBus();
    progress = DailyMissionProgressService(
      db: db,
      missionsDao: dao,
      playerDao: playerDao,
      bus: bus,
    );
    rollover = DailyMissionRolloverService(
      missionsDao: dao,
      playerDao: playerDao,
      progress: progress,
    );
    pid = await db.into(db.playersTable).insert(const PlayersTableCompanion(
          email: Value('rl@t'),
          passwordHash: Value('h'),
          shadowName: Value('S'),
          guildRank: Value('C'),
        ));
  });

  tearDown(() async {
    await db.close();
    await bus.dispose();
  });

  Future<PlayersTableData> readPlayer() => (db.select(db.playersTable)
        ..where((t) => t.id.equals(pid)))
      .getSingle();

  group('processRollover — pendentes do dia anterior', () {
    test('partial: 2/3 sub-tarefas completas → status=partial + reward parcial',
        () async {
      final yesterday =
          dateStr(DateTime.now().subtract(const Duration(days: 1)));
      final saved = await dao.insertAll([
        _mkMission(playerId: pid, date: yesterday, subs: [
          _sub('a', 10, progresso: 10), // completed
          _sub('b', 20, progresso: 20), // completed
          _sub('c', 30, progresso: 5),  // não
        ]),
      ]);

      await rollover.processRollover(pid);

      final fresh = await dao.findById(saved.first.id);
      expect(fresh!.status, DailyMissionStatus.partial);
      expect(fresh.rewardClaimed, isTrue);

      final p = await readPlayer();
      // Hotfix Etapa 1.3.A — partial = factor proporcional real:
      //   factor = (1.0 + 1.0 + 5/30) / 3 = 2.166/3 = 0.722
      //   28 × 0.722 = 20.22 → 20 XP; 20 × 0.722 = 14.44 → 14 gold.
      expect(p.xp, 20);
      expect(p.gold, 14);
    });

    test('failed: 0/3 completas → status=failed, sem reward', () async {
      final yesterday =
          dateStr(DateTime.now().subtract(const Duration(days: 1)));
      final saved = await dao.insertAll([
        _mkMission(playerId: pid, date: yesterday, subs: [
          _sub('a', 10, progresso: 0),
          _sub('b', 20, progresso: 5),
          _sub('c', 30, progresso: 5),
        ]),
      ]);

      await rollover.processRollover(pid);

      final fresh = await dao.findById(saved.first.id);
      expect(fresh!.status, DailyMissionStatus.failed);
      expect(fresh.rewardClaimed, isFalse);
      final p = await readPlayer();
      expect(p.xp, 0);
      expect(p.gold, 0);
    });

    test('missão completed (já fechou) é ignorada — sem dupla-recompensa',
        () async {
      final yesterday =
          dateStr(DateTime.now().subtract(const Duration(days: 1)));
      final saved = await dao.insertAll([
        _mkMission(
          playerId: pid,
          date: yesterday,
          status: DailyMissionStatus.completed,
          rewardClaimed: true,
          subs: [
            _sub('a', 10, progresso: 10),
            _sub('b', 20, progresso: 20),
            _sub('c', 30, progresso: 30),
          ],
        ),
      ]);

      await rollover.processRollover(pid);

      final fresh = await dao.findById(saved.first.id);
      expect(fresh!.status, DailyMissionStatus.completed);
      // gold/xp não foram tocados pelo rollover.
      final p = await readPlayer();
      expect(p.gold, 0);
    });
  });

  group('streak', () {
    test('todas 3 do dia anterior completed → streak +1', () async {
      final yesterday =
          dateStr(DateTime.now().subtract(const Duration(days: 1)));
      // Cria 3 missões já fechadas
      await dao.insertAll([
        for (var i = 0; i < 3; i++)
          _mkMission(
            playerId: pid,
            date: yesterday,
            status: DailyMissionStatus.completed,
            rewardClaimed: true,
            subs: [_sub('a$i', 1, progresso: 1)],
          ),
      ]);

      await rollover.processRollover(pid);

      final p = await readPlayer();
      expect(p.dailyMissionsStreak, 1);
    });

    test('uma falha de ontem → streak reseta a 0', () async {
      // Player com streak 5 acumulada.
      await db.customUpdate(
        'UPDATE players SET daily_missions_streak = 5 WHERE id = ?',
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      final yesterday =
          dateStr(DateTime.now().subtract(const Duration(days: 1)));
      await dao.insertAll([
        _mkMission(
          playerId: pid,
          date: yesterday,
          status: DailyMissionStatus.completed,
          rewardClaimed: true,
          subs: [_sub('a', 1, progresso: 1)],
        ),
        _mkMission(
          playerId: pid,
          date: yesterday,
          status: DailyMissionStatus.completed,
          rewardClaimed: true,
          subs: [_sub('b', 1, progresso: 1)],
        ),
        // Esta vai virar `failed` no rollover.
        _mkMission(playerId: pid, date: yesterday, subs: [
          _sub('c', 10, progresso: 0),
          _sub('d', 10, progresso: 0),
          _sub('e', 10, progresso: 0),
        ]),
      ]);

      await rollover.processRollover(pid);

      final p = await readPlayer();
      expect(p.dailyMissionsStreak, 0);
    });

    test('sem missões ontem → streak preservada (não incrementa nem zera)',
        () async {
      await db.customUpdate(
        'UPDATE players SET daily_missions_streak = 7 WHERE id = ?',
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      await rollover.processRollover(pid);
      final p = await readPlayer();
      expect(p.dailyMissionsStreak, 7);
    });
  });

  group('idempotência', () {
    test('chamar 2× no mesmo dia não duplica reward parcial', () async {
      final yesterday =
          dateStr(DateTime.now().subtract(const Duration(days: 1)));
      await dao.insertAll([
        _mkMission(playerId: pid, date: yesterday, subs: [
          _sub('a', 10, progresso: 10),
          _sub('b', 20, progresso: 20),
          _sub('c', 30, progresso: 5),
        ]),
      ]);

      await rollover.processRollover(pid);
      final pAfter1 = await readPlayer();

      await rollover.processRollover(pid);
      final pAfter2 = await readPlayer();

      expect(pAfter2.gold, pAfter1.gold);
      expect(pAfter2.xp, pAfter1.xp);
    });

    test('first-call marca lastDailyMissionRollover', () async {
      expect((await readPlayer()).lastDailyMissionRollover, isNull);
      await rollover.processRollover(pid);
      expect(
          (await readPlayer()).lastDailyMissionRollover, isNotNull);
    });

    test('mesmo dia: re-chamada é noop (não atualiza timestamp)', () async {
      await rollover.processRollover(pid);
      final ts1 = (await readPlayer()).lastDailyMissionRollover;
      // Re-chama — mesmo lastDailyMissionRollover (não atualiza).
      await rollover.processRollover(pid);
      final ts2 = (await readPlayer()).lastDailyMissionRollover;
      expect(ts2, ts1);
    });
  });

  group('multi-dia (app fechado por dias)', () {
    test('fecha pendentes de dois dias atrás também', () async {
      final two = dateStr(DateTime.now().subtract(const Duration(days: 2)));
      final saved = await dao.insertAll([
        _mkMission(playerId: pid, date: two, subs: [
          _sub('a', 10, progresso: 0),
          _sub('b', 10, progresso: 0),
          _sub('c', 10, progresso: 0),
        ]),
      ]);

      await rollover.processRollover(pid);
      final fresh = await dao.findById(saved.first.id);
      expect(fresh!.status, DailyMissionStatus.failed);
    });
  });
}
