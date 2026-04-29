import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/daily_mission_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/daily_missions_dao.dart';
import 'package:noheroes_app/data/database/daos/player_daily_mission_stats_dao.dart';
import 'package:noheroes_app/data/database/daos/player_daily_subtask_volume_dao.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/domain/enums/daily_unit_type.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/models/daily_mission.dart';
import 'package:noheroes_app/domain/models/daily_mission_status.dart';
import 'package:noheroes_app/domain/models/daily_sub_task_instance.dart';
import 'package:noheroes_app/domain/services/daily_mission_stats_service.dart';

/// Sprint 3.3 Etapa 2.1a — service agregador.
///
/// Cobre helpers (perfectness, time windows) sem precisar de DB. Cobre
/// listeners ponta-a-ponta com DB in-memory + bus real.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('helpers temporais', () {
    test('isBefore8AM', () {
      expect(DailyMissionStatsService.isBefore8AM(DateTime(2026, 4, 29, 7)),
          isTrue);
      expect(DailyMissionStatsService.isBefore8AM(DateTime(2026, 4, 29, 8)),
          isFalse);
      expect(DailyMissionStatsService.isBefore8AM(DateTime(2026, 4, 29, 23)),
          isFalse);
    });

    test('isAfter10PM', () {
      expect(DailyMissionStatsService.isAfter10PM(DateTime(2026, 4, 29, 21)),
          isFalse);
      expect(DailyMissionStatsService.isAfter10PM(DateTime(2026, 4, 29, 22)),
          isTrue);
      expect(DailyMissionStatsService.isAfter10PM(DateTime(2026, 4, 29, 23, 59)),
          isTrue);
    });

    test('isWeekend (sábado=6, domingo=7)', () {
      // 2026-04-25 é sábado, 26 é domingo, 27 é segunda
      expect(
          DailyMissionStatsService.isWeekend(DateTime(2026, 4, 25)), isTrue);
      expect(
          DailyMissionStatsService.isWeekend(DateTime(2026, 4, 26)), isTrue);
      expect(
          DailyMissionStatsService.isWeekend(DateTime(2026, 4, 27)), isFalse);
    });
  });

  group('calculatePerfectness', () {
    DailySubTaskInstance sub(int alvo, int progresso) =>
        DailySubTaskInstance(
          subTaskKey: 'k',
          nomeVisivel: 'n',
          escalaAlvo: alvo,
          unidade: 'x',
          tipoUnidade: DailyUnitType.contagem,
          progressoAtual: progresso,
          completed: progresso >= alvo,
        );

    DailyMission mission(List<DailySubTaskInstance> subs) => DailyMission(
          id: 1,
          playerId: 1,
          data: '2026-04-29',
          modalidade: MissionCategory.fisico,
          subCategoria: 'forca',
          tituloKey: 'k',
          tituloResolvido: 't',
          quoteResolvida: 'q',
          subTarefas: subs,
          status: DailyMissionStatus.completed,
          createdAt: DateTime(2026, 4, 29),
          completedAt: DateTime(2026, 4, 29, 10),
          rewardClaimed: true,
        );

    test('factor médio 3.0+ → isPerfect=true', () {
      final p = DailyMissionStatsService.calculatePerfectness(mission([
        sub(10, 30),
        sub(10, 30),
        sub(10, 30),
      ]));
      expect(p.isPerfect, isTrue);
      expect(p.isSuperPerfect, isTrue);
      expect(p.subsCompleted, 3);
      expect(p.subsOvershoot, 3);
      expect(p.zeroProgress, isFalse);
    });

    test('factor médio 1.0 → isPerfect=false, isSuperPerfect=false', () {
      final p = DailyMissionStatsService.calculatePerfectness(mission([
        sub(10, 10),
        sub(10, 10),
        sub(10, 10),
      ]));
      expect(p.isPerfect, isFalse);
      expect(p.isSuperPerfect, isFalse);
      expect(p.subsCompleted, 3);
      expect(p.subsOvershoot, 0);
    });

    test('factor médio 2.0 → isSuperPerfect=true mas isPerfect=false', () {
      final p = DailyMissionStatsService.calculatePerfectness(mission([
        sub(10, 20),
        sub(10, 20),
        sub(10, 20),
      ]));
      expect(p.isSuperPerfect, isTrue);
      expect(p.isPerfect, isFalse);
      expect(p.subsOvershoot, 3);
    });

    test('zero progress detectado quando avg factor < 0.05', () {
      final p = DailyMissionStatsService.calculatePerfectness(mission([
        sub(100, 0),
        sub(100, 0),
        sub(100, 0),
      ]));
      expect(p.zeroProgress, isTrue);
    });

    test('escalaAlvo=0 não afeta cálculo (defesa)', () {
      final p = DailyMissionStatsService.calculatePerfectness(mission([
        sub(0, 5), // ignorado
        sub(10, 30), // factor 3.0
      ]));
      // Só uma sub no avg → 3.0 → perfect.
      expect(p.isPerfect, isTrue);
    });
  });

  group('listeners ponta-a-ponta', () {
    late AppDatabase db;
    late DailyMissionsDao missionsDao;
    late PlayerDailyMissionStatsDao statsDao;
    late PlayerDailySubtaskVolumeDao volumeDao;
    late PlayerDao playerDao;
    late AppEventBus bus;
    late DailyMissionStatsService service;
    late int playerId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      missionsDao = DailyMissionsDao(db);
      statsDao = PlayerDailyMissionStatsDao(db);
      volumeDao = PlayerDailySubtaskVolumeDao(db);
      playerDao = PlayerDao(db);
      bus = AppEventBus();
      service = DailyMissionStatsService(
        statsDao: statsDao,
        volumeDao: volumeDao,
        playerDao: playerDao,
        missionsDao: missionsDao,
        bus: bus,
      );
      service.start();

      playerId = await db.customInsert(
        "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
        "xp_to_next, gold, gems, strength, dexterity, intelligence, "
        "constitution, spirit, charisma, attribute_points, shadow_corruption, "
        "vitalism_level, vitalism_xp, total_quests_completed, "
        "daily_missions_streak) "
        "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, "
        "0, 0, 5)",
        variables: [
          Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
          Variable.withString('h'),
        ],
      );
    });

    tearDown(() async {
      await service.dispose();
      await bus.dispose();
      await db.close();
    });

    test('DailyMissionGenerated → incrementa total_generated', () async {
      bus.publish(DailyMissionGenerated(
        playerId: playerId,
        missionId: 1,
        modalidade: MissionCategory.fisico,
      ));
      // drena microtasks
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      final stats = await statsDao.findByPlayerId(playerId);
      expect(stats!.totalGenerated, 1);
    });

    test('DailyMissionFailed → incrementa fails + reset days_without_failing',
        () async {
      // Pré-condição: bumpa days_without_failing pra ver reset.
      await statsDao.findOrCreate(playerId);
      await statsDao.bumpDaysWithoutFailing(playerId);
      await statsDao.bumpDaysWithoutFailing(playerId);

      // Insere missão pra _addVolumeFromMission encontrar.
      final missionId = await db.into(db.dailyMissionsTable).insert(
            DailyMissionsTableCompanion(
              playerId: Value(playerId),
              data: const Value('2026-04-29'),
              modalidade: const Value('fisico'),
              subCategoria: const Value('forca'),
              tituloKey: const Value('k'),
              tituloResolvido: const Value('t'),
              quoteResolvida: const Value('q'),
              subTarefasJson: const Value('[]'),
              status: const Value('failed'),
              createdAt:
                  Value(DateTime(2026, 4, 29).millisecondsSinceEpoch),
            ),
          );

      bus.publish(DailyMissionFailed(
        playerId: playerId,
        missionId: missionId,
        reason: 'rollover-zero',
      ));
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final stats = await statsDao.findByPlayerId(playerId);
      expect(stats!.totalFailed, 1);
      expect(stats.consecutiveFailsCount, 1);
      expect(stats.daysWithoutFailing, 0);
      expect(stats.bestDaysWithoutFailing, 2);
    });

    test('DailyMissionCompleted → soma volume + perfect + best streak',
        () async {
      // Insere missão real com 3 subs em 300% (perfect).
      const subs = [
        DailySubTaskInstance(
          subTaskKey: 'flexao',
          nomeVisivel: 'Flexões',
          escalaAlvo: 10,
          unidade: 'x',
          tipoUnidade: DailyUnitType.contagem,
          progressoAtual: 30,
          completed: true,
        ),
        DailySubTaskInstance(
          subTaskKey: 'abdominal',
          nomeVisivel: 'Abdominais',
          escalaAlvo: 10,
          unidade: 'x',
          tipoUnidade: DailyUnitType.contagem,
          progressoAtual: 30,
          completed: true,
        ),
        DailySubTaskInstance(
          subTaskKey: 'agachamento',
          nomeVisivel: 'Agachamentos',
          escalaAlvo: 10,
          unidade: 'x',
          tipoUnidade: DailyUnitType.contagem,
          progressoAtual: 30,
          completed: true,
        ),
      ];
      final mission = DailyMission(
        id: 0,
        playerId: playerId,
        data: '2026-04-29',
        modalidade: MissionCategory.fisico,
        subCategoria: 'forca',
        tituloKey: 'k',
        tituloResolvido: 't',
        quoteResolvida: 'q',
        subTarefas: subs,
        status: DailyMissionStatus.completed,
        createdAt: DateTime(2026, 4, 29, 9), // <12h antes de completedAt
        completedAt: DateTime(2026, 4, 29, 10),
        rewardClaimed: true,
      );
      final inserted = await missionsDao.insertAll([mission]);

      bus.publish(DailyMissionCompleted(
        playerId: playerId,
        missionId: inserted.first.id,
        modalidade: MissionCategory.fisico,
        fullCompleted: true,
        partial: false,
      ));
      await Future.delayed(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 50));

      final stats = await statsDao.findByPlayerId(playerId);
      expect(stats!.totalCompleted, 1);
      expect(stats.totalConfirmed, 1);
      expect(stats.totalPerfect, 1);
      expect(stats.totalSuperPerfect, 1);
      expect(stats.totalSubTasksCompleted, 3);
      expect(stats.totalSubTasksOvershoot, 3);
      expect(stats.totalSpeedrunCompletions, 1);
      // Volume
      expect(await volumeDao.getVolume(playerId, 'flexao'), 30);
      expect(await volumeDao.getVolume(playerId, 'abdominal'), 30);
      expect(await volumeDao.getVolume(playerId, 'agachamento'), 30);
      expect(await volumeDao.getTotalVolume(playerId), 90);
      // bestStreak ← player.dailyMissionsStreak (=5 no setup).
      expect(stats.bestStreak, 5);
      // Active day inicial = 1.
      expect(stats.consecutiveActiveDays, 1);
      expect(stats.lastActiveDay, '2026-04-29');
    });

    test('DailyMissionCompleted partial → incrementPartial + volume', () async {
      const subs = [
        DailySubTaskInstance(
          subTaskKey: 'meditacao',
          nomeVisivel: 'Meditação',
          escalaAlvo: 10,
          unidade: 'min',
          tipoUnidade: DailyUnitType.tempoMinutos,
          progressoAtual: 5,
          completed: false,
        ),
      ];
      final mission = DailyMission(
        id: 0,
        playerId: playerId,
        data: '2026-04-29',
        modalidade: MissionCategory.mental,
        subCategoria: 'foco',
        tituloKey: 'k',
        tituloResolvido: 't',
        quoteResolvida: 'q',
        subTarefas: subs,
        status: DailyMissionStatus.partial,
        createdAt: DateTime(2026, 4, 29, 9),
        completedAt: DateTime(2026, 4, 29, 23),
        rewardClaimed: true,
      );
      final inserted = await missionsDao.insertAll([mission]);

      bus.publish(DailyMissionCompleted(
        playerId: playerId,
        missionId: inserted.first.id,
        modalidade: MissionCategory.mental,
        fullCompleted: false,
        partial: true,
      ));
      await Future.delayed(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 50));

      final stats = await statsDao.findByPlayerId(playerId);
      expect(stats!.totalPartial, 1);
      expect(stats.totalCompleted, 0);
      expect(await volumeDao.getVolume(playerId, 'meditacao'), 5);
    });
  });
}
