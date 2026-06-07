import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/daily_missions_dao.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/services/body_metrics_service.dart';
import 'package:noheroes_app/domain/services/daily_mission_generator_service.dart';
import 'package:noheroes_app/domain/services/daily_pool_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DailyPoolService pools;
  late BodyMetricsService bodyMetrics;
  late AppEventBus bus;
  late DailyMissionsDao missionsDao;
  late PlayerDao playerDao;

  Future<int> seedPlayer({String rank = 'C'}) async {
    return db.into(db.playersTable).insert(PlayersTableCompanion(
          email: Value('p${DateTime.now().microsecondsSinceEpoch}@t'),
          passwordHash: const Value('h'),
          shadowName: const Value('S'),
          guildRank: Value(rank),
        ));
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    pools = DailyPoolService();
    await pools.loadAll();
    bodyMetrics = BodyMetricsService(dao: PlayerDao(db), bus: AppEventBus());
    bus = AppEventBus();
    missionsDao = DailyMissionsDao(db);
    playerDao = PlayerDao(db);
  });

  tearDown(() async {
    await db.close();
    await bus.dispose();
  });

  DailyMissionGeneratorService make({Random? random}) =>
      DailyMissionGeneratorService(
        pools: pools,
        bodyMetrics: bodyMetrics,
        playerDao: playerDao,
        missionsDao: missionsDao,
        bus: bus,
        random: random ?? Random(42),
      );

  group('generateForToday — modelo fixo [fisico, mental, espiritual]', () {
    test('gera exatamente 3 missões, cada uma com 3 sub-tarefas',
        () async {
      final pid = await seedPlayer();
      final svc = make();
      final missions = await svc.generateForToday(pid);
      expect(missions.length, 3);
      for (final m in missions) {
        expect(m.subTarefas.length, 3);
        for (final s in m.subTarefas) {
          expect(s.escalaAlvo, greaterThan(0));
          expect(s.progressoAtual, 0);
          expect(s.completed, isFalse);
        }
      }
    });

    test('as 3 modalidades são fisico, mental e espiritual (sem vitalismo)',
        () async {
      // Várias seeds: deve ser SEMPRE o trio fixo, nunca vitalismo.
      for (var i = 0; i < 30; i++) {
        await db.delete(db.dailyMissionsTable).go();
        final pid = await seedPlayer();
        final svc = make(random: Random(i * 11 + 1));
        final missions = await svc.generateForToday(pid);
        final modalidades = missions.map((m) => m.modalidade).toList();
        expect(modalidades, [
          MissionCategory.fisico,
          MissionCategory.mental,
          MissionCategory.espiritual,
        ], reason: 'seed=$i: trio fixo na ordem canônica');
        expect(
            modalidades.contains(MissionCategory.vitalismo), isFalse,
            reason: 'vitalismo não entra nas diárias');
      }
    });

    test('sub-tarefas únicas cross-missions no mesmo dia', () async {
      final pid = await seedPlayer();
      final svc = make();
      final missions = await svc.generateForToday(pid);
      final allKeys = <String>[];
      for (final m in missions) {
        allKeys.addAll(m.subTarefas.map((s) => s.subTaskKey));
      }
      expect(allKeys.length, 9);
      expect(allKeys.toSet().length, 9, reason: 'sem duplicatas');
    });

    test('idempotência: re-chamar retorna as mesmas missões', () async {
      final pid = await seedPlayer();
      final svc = make();
      final first = await svc.generateForToday(pid);
      final second = await svc.generateForToday(pid);
      expect(second.length, 3);
      expect(second.map((m) => m.id).toList(),
          first.map((m) => m.id).toList());
    });

    test('persistência: getTodayMissions devolve o que foi salvo',
        () async {
      final pid = await seedPlayer();
      final svc = make();
      await svc.generateForToday(pid);
      final fetched = await svc.getTodayMissions(pid);
      expect(fetched.length, 3);
    });

    test(
        'sub-tarefas com escala 0 no rank do jogador NÃO são sorteadas',
        () async {
      // Rank E: várias sub-tarefas têm escala 0 (jejum_curto, retiro_dia,
      // timer_concentracao, etc.). Nunca devem aparecer.
      const banidasRankE = {
        'jejum_curto',
        'repetir_pratica',
        'jejum_dia',
        'visitar_alguem',
        'retiro_dia',
        'folga_total',
        'timer_concentracao',
      };
      for (var i = 0; i < 20; i++) {
        await db.delete(db.dailyMissionsTable).go();
        final pid = await seedPlayer(rank: 'E');
        final svc = make(random: Random(i * 13 + 1));
        final missions = await svc.generateForToday(pid);
        for (final m in missions) {
          for (final s in m.subTarefas) {
            expect(banidasRankE.contains(s.subTaskKey), isFalse,
                reason: 'sub "${s.subTaskKey}" não pode aparecer rank E');
          }
        }
      }
    });

    test('rank A: água/proteína usam IMC do BodyMetricsService',
        () async {
      final pid = await seedPlayer(rank: 'A');
      await bodyMetrics.save(playerId: pid, weightKg: 80, heightCm: 180);

      // Roda muitas seeds até achar agua_diaria.
      for (var i = 0; i < 80; i++) {
        await db.delete(db.dailyMissionsTable).go();
        final svc = make(random: Random(i + 100));
        final missions = await svc.generateForToday(pid);
        for (final m in missions) {
          for (final s in m.subTarefas) {
            if (s.subTaskKey == 'agua_diaria') {
              expect(s.escalaAlvo, 80 * 35,
                  reason: 'água deve usar peso × 35ml');
              return;
            }
          }
        }
      }
    });
  });

  group('rank "none" → fallback rank E', () {
    test('player sem rank usa escala E', () async {
      final pid = await seedPlayer(rank: 'none');
      final svc = make();
      final missions = await svc.generateForToday(pid);
      expect(missions.length, 3);
      // Sanity: alguma sub-tarefa rank E (escala baixa)
      final hasLowScale = missions.any((m) =>
          m.subTarefas.any((s) => s.escalaAlvo > 0 && s.escalaAlvo < 50));
      expect(hasLowScale, isTrue);
    });
  });

  // BUG 1 — geração concorrente não pode duplicar (single-flight guard).
  group('BUG 1: geração concorrente é atômica', () {
    test('10 chamadas concorrentes → exatamente 3 missões, nunca 6/9',
        () async {
      final pid = await seedPlayer();
      final svc = make();
      // Dispara 10 generateForToday em paralelo (simula builds da /quests
      // re-disparados por invalidateSelf durante o build).
      final futures =
          List.generate(10, (_) => svc.generateForToday(pid));
      final results = await Future.wait(futures);

      // Todas as chamadas devem ver o MESMO conjunto de 3 missões.
      for (final r in results) {
        expect(r.length, 3, reason: 'cada chamada retorna 3');
      }
      final firstIds = results.first.map((m) => m.id).toSet();
      for (final r in results) {
        expect(r.map((m) => m.id).toSet(), firstIds,
            reason: 'mesmas missões em todas as chamadas');
      }

      // E no banco só pode haver 3 linhas pro dia.
      final dateStr = _todayStr();
      final persisted = await missionsDao.findByPlayerAndDate(pid, dateStr);
      expect(persisted.length, 3,
          reason: 'sem duplicação no banco (era o BUG 1: 6/9)');
    });
  });

  // Hotfix Etapa 1.3.A — dedup de títulos cross-missions.
  group('dedup de títulos', () {
    test('50 seeds: nenhuma roda tem título duplicado entre as 3 missões',
        () async {
      for (var i = 0; i < 50; i++) {
        await db.delete(db.dailyMissionsTable).go();
        final pid = await seedPlayer();
        final svc = make(random: Random(i + 7));
        final missions = await svc.generateForToday(pid);
        final titulos = missions.map((m) => m.tituloResolvido).toList();
        expect(titulos.toSet().length, titulos.length,
            reason: 'seed=$i: títulos duplicados $titulos');
      }
    });
  });
}

String _todayStr() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
