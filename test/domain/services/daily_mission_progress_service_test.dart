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

DailyMission _mkMission({
  required int playerId,
  required List<DailySubTaskInstance> subs,
}) {
  return DailyMission(
    id: 0,
    playerId: playerId,
    data: '2026-04-26',
    modalidade: MissionCategory.fisico,
    subCategoria: 'treino',
    tituloKey: 'Forja',
    tituloResolvido: 'Forja',
    quoteResolvida: 'q',
    subTarefas: subs,
    status: DailyMissionStatus.pending,
    createdAt: DateTime.now(),
    completedAt: null,
    rewardClaimed: false,
  );
}

DailySubTaskInstance _mkSub(String key, int target,
        {int progresso = 0, bool? completed}) =>
    DailySubTaskInstance(
      subTaskKey: key,
      nomeVisivel: key,
      escalaAlvo: target,
      unidade: 'x',
      tipoUnidade: DailyUnitType.contagem,
      progressoAtual: progresso,
      completed: completed ?? (progresso >= target),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DailyMissionsDao dao;
  late PlayerDao playerDao;
  late AppEventBus bus;
  late DailyMissionProgressService svc;
  late int pid;
  late int missionId;

  Future<int> insertMission(DailyMission m) async {
    final saved = await dao.insertAll([m]);
    return saved.first.id;
  }

  Future<DailyMission> read(int id) async {
    final m = await dao.findById(id);
    return m!;
  }

  Future<PlayersTableData> readPlayer() => (db.select(db.playersTable)
        ..where((t) => t.id.equals(pid)))
      .getSingle();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = DailyMissionsDao(db);
    playerDao = PlayerDao(db);
    bus = AppEventBus();
    svc = DailyMissionProgressService(
      db: db,
      missionsDao: dao,
      playerDao: playerDao,
      bus: bus,
    );
    pid = await db.into(db.playersTable).insert(const PlayersTableCompanion(
          email: Value('p@t'),
          passwordHash: Value('h'),
          shadowName: Value('S'),
          guildRank: Value('C'),
        ));
    missionId = await insertMission(_mkMission(
      playerId: pid,
      subs: [
        _mkSub('a', 10),
        _mkSub('b', 20),
        _mkSub('c', 5),
      ],
    ));
  });

  tearDown(() async {
    await db.close();
    await bus.dispose();
  });

  // ─── incrementSubTask: SEM auto-complete (regra nova) ─────────────

  group('incrementSubTask (sem auto-complete)', () {
    test('atualiza progressoAtual + marca sub completed; missão segue pending',
        () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      final m = await read(missionId);
      expect(m.subTarefas
              .firstWhere((s) => s.subTaskKey == 'a').progressoAtual,
          10);
      expect(m.subTarefas.firstWhere((s) => s.subTaskKey == 'a').completed,
          isTrue);
      // Missão fica pending — sem auto-complete.
      expect(m.status, DailyMissionStatus.pending);
      expect(m.rewardClaimed, isFalse);
    });

    test('completa 3/3: missão SEGUE pending (sem auto-complete)',
        () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.pending);
      expect(m.rewardClaimed, isFalse);
      // Sub-tarefas individuais marcam completed.
      expect(m.subTarefas.every((s) => s.completed), isTrue);
      // Player NÃO recebeu reward ainda (precisa confirmar manualmente).
      final p = await readPlayer();
      expect(p.gold, 0);
      expect(p.xp, 0);
    });

    test('delta negativo respeita mínimo 0', () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 3);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: -100);
      final m = await read(missionId);
      expect(m.subTarefas
              .firstWhere((s) => s.subTaskKey == 'a').progressoAtual,
          0);
    });

    test('progresso pode ultrapassar alvo (excedência acumulada)',
        () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 25);
      final m = await read(missionId);
      expect(m.subTarefas
              .firstWhere((s) => s.subTaskKey == 'a').progressoAtual,
          25);
      expect(m.subTarefas.firstWhere((s) => s.subTaskKey == 'a').completed,
          isTrue);
    });
  });

  // ─── confirmCompletion: status decision + reward ──────────────────

  group('confirmCompletion: 3/3 ≥ 100% → completed + reward integral', () {
    test('rank C base 28 XP / 20 gold sem bônus', () async {
      // Subs nos alvos exatos.
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);

      await svc.confirmCompletion(missionId: missionId);

      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.completed);
      expect(m.rewardClaimed, isTrue);
      expect(m.completedAt, isNotNull);

      final p = await readPlayer();
      expect(p.xp, 28);
      expect(p.gold, 20);
    });

    test('bônus excedência +20% quando todas ultrapassam', () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 11);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 21);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 6);
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // 28 × 1.2 = 33.6 → 34; 20 × 1.2 = 24
      expect(p.xp, 34);
      expect(p.gold, 24);
    });

    test('streak ≥10 multiplica 1.5×', () async {
      await db.customUpdate(
        'UPDATE players SET daily_missions_streak = 10 WHERE id = ?',
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // 28 × 1.5 = 42; 20 × 1.5 = 30
      expect(p.xp, 42);
      expect(p.gold, 30);
    });

    test('rank S = 120 XP / 80 gold (level up rola)', () async {
      await db.customUpdate(
        "UPDATE players SET guild_rank = 'S' WHERE id = ?",
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // 120 XP creditados; level 1→2; resíduo XP = 20.
      expect(p.level, 2);
      expect(p.xp, 20);
      expect(p.gold, 80);
    });
  });

  group('confirmCompletion: partial = factor proporcional (sem ×0.5)', () {
    test('3 a 50% → partial, factor 0.5 → reward × 0.5', () async {
      // Targets a=10, b=20, c=5 — preencher 50%: a=5, b=10, c=2 (com round)
      // Com c=5 alvo, 50% = 2.5 → uso 3 pra ficar > 25%. Aliás 3/5=0.6.
      // Vou reusar mock alvo padrão e mexer em valores.
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 5); // 5/10 = 0.5
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 10); // 10/20 = 0.5
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 3); // 3/5 = 0.6
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      // factor = (0.5 + 0.5 + 0.6) / 3 = 0.5333...
      // 28 × 0.5333 = 14.93 → 15; 20 × 0.5333 = 10.67 → 11
      final p = await readPlayer();
      expect(p.xp, 15);
      expect(p.gold, 11);
    });

    test('1 a 100% + 2 a 0% → partial, factor 0.33', () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      // b e c ficam em 0
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      // factor = (1.0 + 0 + 0) / 3 = 0.333...
      // 28 × 0.333 = 9.33 → 9; 20 × 0.333 = 6.67 → 7
      final p = await readPlayer();
      expect(p.xp, 9);
      expect(p.gold, 7);
    });

    test('2 a 100% + 1 a 50% → partial, factor 0.83', () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 3); // 3/5 = 0.6
      // Hmm: 0.6 não é 0.5. Vou usar c=5/2, mas escalaAlvo é 5, então
      // 50% = 2.5 não é inteiro. Usa b com alvo 20, progresso 10 (=0.5)
      // e adapta:
      // Re-cria missão com alvos 10/10/10 pra ficar exato.
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 10), // 1.0
          _mkSub('b', 10, progresso: 10), // 1.0
          _mkSub('c', 10, progresso: 5),  // 0.5
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      // factor = (1.0 + 1.0 + 0.5) / 3 = 0.833...
      // 28 × 0.833 = 23.33 → 23; 20 × 0.833 = 16.67 → 17
      final p = await readPlayer();
      expect(p.xp, 23);
      expect(p.gold, 17);
    });

    test('1 a 100% + 2 a 30% → partial, factor 0.53', () async {
      // Re-cria com alvos uniformes pra simplificar.
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 10), // 1.0
          _mkSub('b', 10, progresso: 3),  // 0.3
          _mkSub('c', 10, progresso: 3),  // 0.3
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      // factor = (1.0 + 0.3 + 0.3) / 3 = 0.533...
      // 28 × 0.533 = 14.93 → 15; 20 × 0.533 = 10.67 → 11
      final p = await readPlayer();
      expect(p.xp, 15);
      expect(p.gold, 11);
    });

    test('partial NÃO aplica streak nem excedência', () async {
      await db.customUpdate(
        'UPDATE players SET daily_missions_streak = 50 WHERE id = ?',
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 5), // 0.5
          _mkSub('b', 10, progresso: 5), // 0.5
          _mkSub('c', 10, progresso: 5), // 0.5
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // factor = 0.5 × 28 = 14 (sem streak), gold 10.
      expect(p.xp, 14);
      expect(p.gold, 10);
    });

    test('cap 100% por sub-tarefa: excedência não conta no partial',
        () async {
      // Sub a com excedência forte, b e c bem abaixo: ainda partial.
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 30), // cap 1.0
          _mkSub('b', 10, progresso: 3),  // 0.3
          _mkSub('c', 10, progresso: 3),  // 0.3
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // factor = (1.0 + 0.3 + 0.3) / 3 = 0.533 — excedência cap em 1.0.
      expect(p.xp, 15);
    });
  });

  group('confirmCompletion: failed (todas <25%)', () {
    test('3 a 20% → failed, zero reward', () async {
      // Targets: a=10/b=20/c=5. <25% = a<2.5/b<5/c<1.25
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 2); // 2/10 = 20%
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 4); // 4/20 = 20%
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 1); // 1/5 = 20%
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.failed);
      expect(m.rewardClaimed, isTrue);
      final p = await readPlayer();
      expect(p.xp, 0);
      expect(p.gold, 0);
    });

    test('todas 0/0 → failed', () async {
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.failed);
      final p = await readPlayer();
      expect(p.xp, 0);
      expect(p.gold, 0);
    });
  });

  group('confirmCompletion: idempotência', () {
    test('2× confirmCompletion lança RewardAlreadyGrantedException',
        () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);
      await svc.confirmCompletion(missionId: missionId);
      final pAfter = await readPlayer();

      expect(
        () => svc.confirmCompletion(missionId: missionId),
        throwsA(isA<RewardAlreadyGrantedException>()),
      );
      // Reward não duplica.
      final pNow = await readPlayer();
      expect(pNow.xp, pAfter.xp);
      expect(pNow.gold, pAfter.gold);
    });
  });

  group('partialFactor (cálculo puro)', () {
    test('3 a 100% → 1.0', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 10),
        _mkSub('b', 10, progresso: 10),
        _mkSub('c', 10, progresso: 10),
      ]);
      expect(DailyMissionProgressService.partialFactor(m), 1.0);
    });

    test('3 a 50% → 0.5', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 5),
        _mkSub('b', 10, progresso: 5),
        _mkSub('c', 10, progresso: 5),
      ]);
      expect(DailyMissionProgressService.partialFactor(m), 0.5);
    });

    test('cap 100% por sub: progresso 200% conta como 100%', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 20),
        _mkSub('b', 10, progresso: 5),
        _mkSub('c', 10, progresso: 5),
      ]);
      // (1.0 + 0.5 + 0.5) / 3 = 0.666...
      expect(
          DailyMissionProgressService.partialFactor(m), closeTo(0.666, 0.01));
    });

    test('1 a 100% + 2 a 0% → 0.333', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 10),
        _mkSub('b', 10, progresso: 0),
        _mkSub('c', 10, progresso: 0),
      ]);
      expect(
          DailyMissionProgressService.partialFactor(m), closeTo(0.333, 0.01));
    });
  });

  group('previewStatus', () {
    test('3 a 100% → completed', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 10),
        _mkSub('b', 10, progresso: 10),
        _mkSub('c', 10, progresso: 10),
      ]);
      expect(DailyMissionProgressService.previewStatus(m),
          DailyMissionStatus.completed);
    });

    test('3 a 20% → failed', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 2),
        _mkSub('b', 10, progresso: 2),
        _mkSub('c', 10, progresso: 2),
      ]);
      expect(DailyMissionProgressService.previewStatus(m),
          DailyMissionStatus.failed);
    });

    test('mistura → partial', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 10),
        _mkSub('b', 10, progresso: 5),
        _mkSub('c', 10, progresso: 0),
      ]);
      expect(DailyMissionProgressService.previewStatus(m),
          DailyMissionStatus.partial);
    });

    test('todas no limiar 25% → partial (≥ failureThreshold)', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 100, progresso: 25),
        _mkSub('b', 100, progresso: 25),
        _mkSub('c', 100, progresso: 25),
      ]);
      expect(DailyMissionProgressService.previewStatus(m),
          DailyMissionStatus.partial);
    });
  });

  group('markFailed (utilitário)', () {
    test('marca status=failed sem reward', () async {
      await svc.markFailed(missionId: missionId, reason: 'manual');
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.failed);
      expect(m.rewardClaimed, isFalse);
      final p = await readPlayer();
      expect(p.gold, 0);
      expect(p.xp, 0);
    });
  });
}
