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
import 'package:noheroes_app/domain/services/faction_buff_service.dart';

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

    test('cap em escalaAlvo × 3 (excedência limitada a 300%)', () async {
      // sub 'a' tem escalaAlvo=10 → cap em 30. Delta gigante satura.
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 9999);
      final m = await read(missionId);
      expect(
          m.subTarefas.firstWhere((s) => s.subTaskKey == 'a').progressoAtual,
          30);
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

    test('3×200% (todas ultrapassam 100%) → factor 2.0 → mult 1.45', () async {
      // Targets uniformes 10/10/10 pra factor exato 2.0.
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 20),
          _mkSub('b', 10, progresso: 20),
          _mkSub('c', 10, progresso: 20),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // factor = 2.0; mult = 1 + 0.45×1.0 = 1.45
      // xp = floor(28×1.45) = floor(40.6) = 40; gold = floor(20×1.45) = 29
      expect(p.xp, 40);
      expect(p.gold, 29);
    });

    test('3×300% (cap por sub) → factor 3.0 → mult 1.90', () async {
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 30),
          _mkSub('b', 10, progresso: 30),
          _mkSub('c', 10, progresso: 30),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // factor = 3.0; mult = 1 + 0.45×2.0 = 1.90
      // xp = floor(28×1.90) = floor(53.2) = 53; gold = floor(20×1.90) = 38
      expect(p.xp, 53);
      expect(p.gold, 38);
    });

    test('streak ≥10 multiplica 1.5× em completed 3×100%', () async {
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
      // factor = 1.0; mult = 1.0; streak = 1.5
      // xp = floor(28×1.0×1.5) = 42; gold = floor(20×1.0×1.5) = 30
      expect(p.xp, 42);
      expect(p.gold, 30);
    });

    test('streak ≥10 + 3×300% → 79 XP / 57 gold', () async {
      await db.customUpdate(
        'UPDATE players SET daily_missions_streak = 12 WHERE id = ?',
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 30),
          _mkSub('b', 10, progresso: 30),
          _mkSub('c', 10, progresso: 30),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // factor = 3.0; mult = 1.90; streak = 1.5
      // xp = floor(28×1.90×1.5) = floor(79.8) = 79
      // gold = floor(20×1.90×1.5) = floor(57.0) = 57
      expect(p.xp, 79);
      expect(p.gold, 57);
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

  group('confirmCompletion: partial = fórmula linear (sem ×0.5, com floor)',
      () {
    test('3×50% → factor 0.5 → mult 0.5 → 14 XP / 10 gold', () async {
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 5),
          _mkSub('b', 10, progresso: 5),
          _mkSub('c', 10, progresso: 5),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      final p = await readPlayer();
      // factor = 0.5; mult = 0.5
      // xp = floor(28×0.5) = 14; gold = floor(20×0.5) = 10
      expect(p.xp, 14);
      expect(p.gold, 10);
    });

    test('1×100% + 2×0% → factor 0.333 → 9 XP / 6 gold', () async {
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 10),
          _mkSub('b', 10, progresso: 0),
          _mkSub('c', 10, progresso: 0),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      final p = await readPlayer();
      // factor = (1+0+0)/3 = 0.333...; mult = 0.333
      // xp = floor(28×0.333) = floor(9.33) = 9
      // gold = floor(20×0.333) = floor(6.66) = 6
      expect(p.xp, 9);
      expect(p.gold, 6);
    });

    test('1×100% + 2×50% → factor 0.666 → 18 XP / 13 gold', () async {
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 10),
          _mkSub('b', 10, progresso: 5),
          _mkSub('c', 10, progresso: 5),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      final p = await readPlayer();
      // factor = (1+0.5+0.5)/3 = 0.666...; mult = 0.666
      // xp = floor(28×0.666) = floor(18.66) = 18
      // gold = floor(20×0.666) = floor(13.33) = 13
      expect(p.xp, 18);
      expect(p.gold, 13);
    });

    test('2×100% + 1×50% → factor 0.833 → 23 XP / 16 gold', () async {
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 10),
          _mkSub('b', 10, progresso: 10),
          _mkSub('c', 10, progresso: 5),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      final p = await readPlayer();
      // factor = (1+1+0.5)/3 = 0.833...; mult = 0.833
      // xp = floor(28×0.833) = floor(23.33) = 23
      // gold = floor(20×0.833) = floor(16.66) = 16
      expect(p.xp, 23);
      expect(p.gold, 16);
    });

    test('partial NÃO aplica streak (streak só em completed)', () async {
      await db.customUpdate(
        'UPDATE players SET daily_missions_streak = 50 WHERE id = ?',
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 5),
          _mkSub('b', 10, progresso: 5),
          _mkSub('c', 10, progresso: 5),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final p = await readPlayer();
      // status=partial → streak não aplica → 28×0.5=14 / 20×0.5=10
      expect(p.xp, 14);
      expect(p.gold, 10);
    });

    test('partial COM excedência: factor pode passar de 1.0 (linear)',
        () async {
      // Sub a a 300%, b e c a 30% — ainda partial (b/c < 100%).
      // missionFactor = (3.0 + 0.3 + 0.3) / 3 = 1.2
      // mult = 1 + 0.45 × 0.2 = 1.09
      // xp = floor(28×1.09) = floor(30.52) = 30
      // gold = floor(20×1.09) = floor(21.8) = 21
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 30),
          _mkSub('b', 10, progresso: 3),
          _mkSub('c', 10, progresso: 3),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      final p = await readPlayer();
      expect(p.xp, 30);
      expect(p.gold, 21);
    });

    test('partial 1×300% + 2×0% → factor 1.0 → mult 1.0 → 28 XP / 20 gold',
        () async {
      // Caso counterintuitivo intencional: factor médio bate em 1.0 mesmo
      // com 2 subs zeradas, então paga base completo. Status segue partial
      // porque _resolveStatus exige TODAS as 3 subs ≥ 100%.
      await dao.updateMission((await read(missionId)).copyWith(
        subTarefas: [
          _mkSub('a', 10, progresso: 30),
          _mkSub('b', 10, progresso: 0),
          _mkSub('c', 10, progresso: 0),
        ],
      ));
      await svc.confirmCompletion(missionId: missionId);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.partial);
      final p = await readPlayer();
      expect(p.xp, 28);
      expect(p.gold, 20);
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

  group('missionFactor (cap 3.0 por sub, usado em computeReward)', () {
    test('3×100% → 1.0', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 10),
        _mkSub('b', 10, progresso: 10),
        _mkSub('c', 10, progresso: 10),
      ]);
      expect(DailyMissionProgressService.missionFactor(m), 1.0);
    });

    test('3×300% → 3.0 (cap)', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 30),
        _mkSub('b', 10, progresso: 30),
        _mkSub('c', 10, progresso: 30),
      ]);
      expect(DailyMissionProgressService.missionFactor(m), 3.0);
    });

    test('1×500% (cap a 3.0) + 2×0% → 1.0', () {
      // Sem cap por sub, daria 5.0/3 = 1.666. Com cap 3.0 fica 3.0/3 = 1.0.
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 10, progresso: 50),
        _mkSub('b', 10, progresso: 0),
        _mkSub('c', 10, progresso: 0),
      ]);
      expect(DailyMissionProgressService.missionFactor(m), 1.0);
    });

    test('escalaAlvo=0 entra como 0 (defensivo)', () {
      final m = _mkMission(playerId: 1, subs: [
        _mkSub('a', 0, progresso: 5),
        _mkSub('b', 10, progresso: 10),
        _mkSub('c', 10, progresso: 10),
      ]);
      // (0 + 1 + 1) / 3 = 0.666
      expect(DailyMissionProgressService.missionFactor(m), closeTo(0.666, 0.01));
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

  // ─── Sprint 3.4 Etapa C hotfix #1 — buffs em daily missions ────────
  //
  // Bug histórico: confirmCompletion/applyPartialReward/applyAutoCompleted
  // chamavam _playerDao.addXp + UPDATE gold direto sem aplicar buff de
  // facção. Após hotfix #1, todos os 3 caminhos passam pelo `_applyBuffs`
  // do service que consulta FactionBuffService (opcional pra testes).
  group('Etapa C hotfix #1 — buffs aplicam em daily reward', () {
    late DailyMissionProgressService buffedSvc;
    late FactionBuffService buffSvc;

    setUp(() {
      buffSvc = FactionBuffService(db);
      buffSvc.debugSetCatalog(<String, dynamic>{
        'new_order': {
          'applied': {
            'xp_mult': 1.10,
            'gold_mult': 1.0,
          },
          'pending': [],
        },
        'sun_clan': {
          'applied': {
            'xp_mult': 1.0,
            'gold_mult': 1.09,
          },
          'pending': [],
        },
      });
      buffedSvc = DailyMissionProgressService(
        db: db,
        missionsDao: dao,
        playerDao: playerDao,
        bus: bus,
        factionBuff: buffSvc,
      );
    });

    test('Player Nova Ordem confirma daily 100% → XP +10% (CEO bug P0-A)',
        () async {
      // Set faction_type=new_order; rank C → reward base xp=28, gold=20.
      await db.customStatement(
        "UPDATE players SET faction_type = 'new_order' WHERE id = ?",
        [pid],
      );
      // Completa as 3 sub-tasks em 100%.
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);

      await buffedSvc.confirmCompletion(missionId: missionId);

      final p = await readPlayer();
      // Base xp rank C = 28. mult=1.0 (factor=1.0 com 3/3). round(28×1.10) = 31.
      expect(p.xp, 31, reason: 'Nova Ordem +10% xp: round(28 × 1.10) = 31');
      // Gold xp_mult=1.0 → round(20 × 1.0) = 20.
      expect(p.gold, 20);
    });

    test('Player Sol confirma daily 100% → gold +9%', () async {
      await db.customStatement(
        "UPDATE players SET faction_type = 'sun_clan' WHERE id = ?",
        [pid],
      );
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);

      await buffedSvc.confirmCompletion(missionId: missionId);

      final p = await readPlayer();
      // Sol xp_mult=1.0 → xp 28; gold_mult=1.09 → round(20 × 1.09) = 22.
      expect(p.xp, 28);
      expect(p.gold, 22, reason: 'Sun Clan +9% gold: round(20 × 1.09) = 22');
    });

    test('Player sem facção (faction_type=none) → reward cru', () async {
      await db.customStatement(
        "UPDATE players SET faction_type = 'none' WHERE id = ?",
        [pid],
      );
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);

      await buffedSvc.confirmCompletion(missionId: missionId);

      final p = await readPlayer();
      expect(p.xp, 28);
      expect(p.gold, 20);
    });

    test('Debuff -30% ativo → xp/gold viram 70%', () async {
      await db.customStatement(
        "UPDATE players SET faction_type = 'new_order' WHERE id = ?",
        [pid],
      );
      // Seed debuff em membership row.
      final until = DateTime.now()
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch;
      await db.customStatement(
        'INSERT INTO player_faction_membership '
        '(player_id, faction_id, debuff_until) VALUES (?, ?, ?)',
        [pid, 'new_order', until],
      );
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await buffedSvc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);

      await buffedSvc.confirmCompletion(missionId: missionId);

      final p = await readPlayer();
      // Debuff override: xp_mult/gold_mult = 0.7. round(28×0.7)=20, round(20×0.7)=14.
      expect(p.xp, 20, reason: 'debuff -30% xp: round(28 × 0.7) = 20');
      expect(p.gold, 14, reason: 'debuff -30% gold: round(20 × 0.7) = 14');
    });
  });
}
