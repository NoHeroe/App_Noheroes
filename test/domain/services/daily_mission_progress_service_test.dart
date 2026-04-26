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
    data: '2026-04-25',
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

DailySubTaskInstance _mkSub(String key, int target) => DailySubTaskInstance(
      subTaskKey: key,
      nomeVisivel: key,
      escalaAlvo: target,
      unidade: 'x',
      tipoUnidade: DailyUnitType.contagem,
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

  group('incrementSubTask', () {
    test('atualiza progressoAtual da sub-tarefa', () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 5);
      final m = await read(missionId);
      expect(m.subTarefas.firstWhere((s) => s.subTaskKey == 'a').progressoAtual,
          5);
      expect(m.status, DailyMissionStatus.pending);
    });

    test('marca completed quando atinge escala alvo', () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      final m = await read(missionId);
      expect(m.subTarefas.firstWhere((s) => s.subTaskKey == 'a').completed,
          isTrue);
    });

    test('delta negativo respeita mínimo 0', () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 3);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: -100);
      final m = await read(missionId);
      expect(m.subTarefas.firstWhere((s) => s.subTaskKey == 'a').progressoAtual,
          0);
    });

    test('todas 3 completas → status=completed + reward + rewardClaimed',
        () async {
      // Rank C: 28 XP / 20 gold base.
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);
      final m = await read(missionId);
      expect(m.status, DailyMissionStatus.completed);
      expect(m.rewardClaimed, isTrue);
      expect(m.completedAt, isNotNull);

      final p = await readPlayer();
      expect(p.gold, 20, reason: 'rank C base = 20 gold');
      // XP credita via addXp; rank C = 28 XP, level inicial 1, xpToNext 100.
      expect(p.xp, 28);
    });

    test('idempotência: incrementar após completar é noop', () async {
      // Completa
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);
      final pAfter = await readPlayer();
      // Tenta regrantar
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      final pNow = await readPlayer();
      expect(pNow.gold, pAfter.gold);
      expect(pNow.xp, pAfter.xp);
    });

    test('streak ≥10 adiciona +50% reward', () async {
      // Force streak = 10
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
      final p = await readPlayer();
      // Rank C: 28 XP / 20 gold base × 1.5 = 42 XP / 30 gold.
      expect(p.gold, 30);
      expect(p.xp, 42);
    });

    test('bônus excedência: todas ultrapassam → +20%', () async {
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 11); // > 10
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 21); // > 20
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 6); // > 5
      final p = await readPlayer();
      // Rank C × 1.2 = 33.6 XP → round 34 / 24 gold.
      expect(p.gold, 24);
      expect(p.xp, 34);
    });

    test('cap de 300% não deixa reward explodir', () async {
      // streak 10 (×1.5) + excedência (×1.2) = ×1.8 → abaixo do cap.
      // Pra forçar cap: streak ≥ 10 (1.5) × excedência (1.2) = 1.8.
      // Cap é 3.0. Não bate. Como usamos só 2 multiplicadores, máximo
      // é 1.5*1.2 = 1.8 < 3.0 cap. Confirma sem violar cap.
      await db.customUpdate(
        'UPDATE players SET daily_missions_streak = 50 WHERE id = ?',
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 11);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 21);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 6);
      final p = await readPlayer();
      // 28 × 1.5 × 1.2 = 50.4 → 50; gold 20 × 1.8 = 36.
      expect(p.xp, 50);
      expect(p.gold, 36);
    });
  });

  group('reward base por rank', () {
    test('rank E = 8 XP / 5 gold', () async {
      await db.customUpdate(
        "UPDATE players SET guild_rank = 'E' WHERE id = ?",
        variables: [Variable.withInt(pid)],
        updates: {db.playersTable},
      );
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'a', delta: 10);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'b', delta: 20);
      await svc.incrementSubTask(
          missionId: missionId, subTaskKey: 'c', delta: 5);
      final p = await readPlayer();
      expect(p.xp, 8);
      expect(p.gold, 5);
    });

    test('rank S = 120 XP / 80 gold (level up rola: 120 > xpToNext=100)',
        () async {
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
      final p = await readPlayer();
      // 120 XP creditados; level 1→2 (xpToNext=100); resíduo XP = 20.
      expect(p.level, 2);
      expect(p.xp, 20, reason: 'resíduo após level up');
      expect(p.gold, 80, reason: 'gold sem level up effect');
    });
  });

  group('markFailed', () {
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

  group('computeReward (cálculo puro)', () {
    test('failed (0/3) = zero', () {
      final r = DailyMissionProgressService.computeReward(
        rank: 'B',
        missionWithFinalProgress: _mkMission(
            playerId: 1, subs: [_mkSub('a', 10), _mkSub('b', 10), _mkSub('c', 10)]),
        partial: true,
        subCompletas: 0,
        dailyMissionsStreak: 0,
      );
      expect(r.xp, 0);
      expect(r.gold, 0);
    });

    test('partial 2/3 = base × (2/3) × 0.5', () {
      // Rank C base 28 XP / 20 gold. 2/3 × 0.5 = 0.333.
      final r = DailyMissionProgressService.computeReward(
        rank: 'C',
        missionWithFinalProgress: _mkMission(
            playerId: 1,
            subs: [_mkSub('a', 1), _mkSub('b', 1), _mkSub('c', 1)]),
        partial: true,
        subCompletas: 2,
        dailyMissionsStreak: 0,
      );
      // 28 × 0.333 = 9.33 → 9; 20 × 0.333 = 6.66 → 7.
      expect(r.xp, 9);
      expect(r.gold, 7);
    });
  });
}
