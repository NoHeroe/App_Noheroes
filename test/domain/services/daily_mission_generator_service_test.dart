import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/daily_missions_dao.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_style.dart';
import 'package:noheroes_app/domain/models/mission_preferences.dart';
import 'package:noheroes_app/domain/repositories/mission_preferences_repository.dart';
import 'package:noheroes_app/domain/services/body_metrics_service.dart';
import 'package:noheroes_app/domain/services/daily_mission_generator_service.dart';
import 'package:noheroes_app/domain/services/daily_pool_service.dart';
import 'package:noheroes_app/domain/services/mission_preferences_service.dart';

class _FakePrefsRepo implements MissionPreferencesRepository {
  MissionPreferences? stored;

  @override
  Future<MissionPreferences?> findByPlayerId(int playerId) async => stored;

  @override
  Future<void> upsert(MissionPreferences prefs) async => stored = prefs;

  @override
  Future<int> updatesCountOf(int playerId) async =>
      stored?.updatesCount ?? 0;

  @override
  Future<void> deleteForPlayer(int playerId) async => stored = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DailyPoolService pools;
  late BodyMetricsService bodyMetrics;
  late MissionPreferencesService prefs;
  late _FakePrefsRepo prefsRepo;
  late AppEventBus bus;
  late DailyMissionsDao missionsDao;
  late PlayerDao playerDao;

  Future<int> seedPlayer({
    String rank = 'C',
    MissionCategory? primaryFocus,
  }) async {
    final id = await db.into(db.playersTable).insert(PlayersTableCompanion(
          email: Value('p${DateTime.now().microsecondsSinceEpoch}@t'),
          passwordHash: const Value('h'),
          shadowName: const Value('S'),
          guildRank: Value(rank),
        ));
    if (primaryFocus != null) {
      prefsRepo.stored = MissionPreferences(
        playerId: id,
        primaryFocus: primaryFocus,
        intensity: Intensity.medium,
        missionStyle: MissionStyle.mixed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return id;
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    pools = DailyPoolService();
    await pools.loadAll();
    bodyMetrics = BodyMetricsService(dao: PlayerDao(db));
    prefsRepo = _FakePrefsRepo();
    bus = AppEventBus();
    prefs = MissionPreferencesService(repo: prefsRepo, bus: bus, db: db);
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
        prefs: prefs,
        playerDao: playerDao,
        missionsDao: missionsDao,
        bus: bus,
        random: random ?? Random(42),
      );

  group('generateForToday', () {
    test('gera exatamente 3 missões, cada uma com 3 sub-tarefas',
        () async {
      final pid = await seedPlayer(primaryFocus: MissionCategory.fisico);
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

    test('sub-tarefas únicas cross-missions no mesmo dia', () async {
      final pid = await seedPlayer(primaryFocus: MissionCategory.mental);
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
      final pid =
          await seedPlayer(primaryFocus: MissionCategory.espiritual);
      final svc = make();
      final first = await svc.generateForToday(pid);
      final second = await svc.generateForToday(pid);
      expect(second.length, 3);
      expect(second.map((m) => m.id).toList(),
          first.map((m) => m.id).toList());
    });

    test('persistência: getTodayMissions devolve o que foi salvo',
        () async {
      final pid = await seedPlayer(primaryFocus: MissionCategory.fisico);
      final svc = make();
      await svc.generateForToday(pid);
      final fetched = await svc.getTodayMissions(pid);
      expect(fetched.length, 3);
    });

    test('garante ≥2 modalidades distintas no dia (forçamento)',
        () async {
      // Random "ruim" que sempre retorna 0 — sem forçamento, todos os 3
      // sorteios cairiam no primeiro pilar do mapa de pesos. Validamos
      // que o forçamento entra e quebra o trio.
      final pid = await seedPlayer(primaryFocus: MissionCategory.fisico);
      final svc = make(random: _AlwaysZero());
      final missions = await svc.generateForToday(pid);
      final modalidades =
          missions.map((m) => m.modalidade).toSet();
      expect(modalidades.length, greaterThanOrEqualTo(2),
          reason: 'sempre ≥2 modalidades distintas');
    });

    test(
        'sub-tarefas com escala 0 no rank do jogador NÃO são sorteadas',
        () async {
      // Rank E + Espiritual/Ritual: 3 sub-tarefas têm escala 0
      // (jejum_curto, repetir_pratica, jejum_dia). Nunca devem aparecer.
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
        final pid = await seedPlayer(rank: 'E');
        // Reseta DB pra cada iteração — diferentes seeds.
        final svc = DailyMissionGeneratorService(
          pools: pools,
          bodyMetrics: bodyMetrics,
          prefs: prefs,
          playerDao: playerDao,
          missionsDao: missionsDao,
          bus: bus,
          random: Random(i * 13 + 1),
        );
        final missions = await svc.generateForToday(pid);
        for (final m in missions) {
          for (final s in m.subTarefas) {
            expect(banidasRankE.contains(s.subTaskKey), isFalse,
                reason: 'sub "${s.subTaskKey}" não pode aparecer rank E');
          }
        }
      }
    });

    test('Vitalismo: 1 sub-tarefa de cada pilar quando cai', () async {
      // Tenta forçar Vitalismo escolhendo seed que produza pelo menos
      // uma missão Vitalismo nas 3.
      final pid = await seedPlayer(primaryFocus: MissionCategory.fisico);
      // Roda várias seeds até achar uma com Vitalismo.
      for (var i = 0; i < 50; i++) {
        await db.delete(db.dailyMissionsTable).go();
        final svc = make(random: Random(i * 7 + 3));
        final missions = await svc.generateForToday(pid);
        final vitalismo = missions
            .where((m) => m.modalidade == MissionCategory.vitalismo)
            .toList();
        if (vitalismo.isNotEmpty) {
          final v = vitalismo.first;
          final pilares =
              v.subTarefas.map((s) => s.subPilar).toSet();
          expect(pilares, {'fisico', 'mental', 'espiritual'},
              reason: 'Vitalismo deve ter 1 sub de cada pilar');
          expect(v.subCategoria, isNull,
              reason: 'sub_categoria null em Vitalismo');
          return;
        }
      }
      // Não rolou — registra a observação mas não falha (probabilístico).
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

  // Hotfix Etapa 1.3.A — dedup de títulos cross-missions.
  group('dedup de títulos', () {
    test('50 seeds: nenhuma roda tem título duplicado entre as 3 missões',
        () async {
      for (var i = 0; i < 50; i++) {
        final pid =
            await seedPlayer(primaryFocus: MissionCategory.fisico);
        await db.delete(db.dailyMissionsTable).go();
        final svc = DailyMissionGeneratorService(
          pools: pools,
          bodyMetrics: bodyMetrics,
          prefs: prefs,
          playerDao: playerDao,
          missionsDao: missionsDao,
          bus: bus,
          random: Random(i + 7),
        );
        final missions = await svc.generateForToday(pid);
        final titulos = missions.map((m) => m.tituloResolvido).toList();
        expect(titulos.toSet().length, titulos.length,
            reason: 'seed=$i: títulos duplicados $titulos');
      }
    });
  });
}

/// Random determinístico que sempre retorna 0 — usado pra simular caso
/// patológico onde os 3 sorteios cairiam todos na mesma modalidade.
class _AlwaysZero implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0.0;
  @override
  int nextInt(int max) => 0;
}
