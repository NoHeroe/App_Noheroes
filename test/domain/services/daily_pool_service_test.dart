import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/models/daily_modalidade_pool.dart';
import 'package:noheroes_app/domain/models/vitalismo_pool.dart';
import 'package:noheroes_app/domain/services/body_metrics_service.dart';
import 'package:noheroes_app/domain/services/daily_pool_service.dart';

/// Sprint 3.2 Etapa 1.1 — cobre carregamento dos 4 JSONs canônicos,
/// contagens, busca por key e resolução de escala (inclui ramo IMC
/// com [BodyMetricsService] real).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DailyPoolService service;

  setUp(() async {
    service = DailyPoolService();
    await service.loadAll();
  });

  group('loadAll + estrutura canônica', () {
    test('carrega os 4 JSONs sem erro', () async {
      // Idempotência: re-chamar é noop.
      await service.loadAll();
      expect(service.fisicoPool().modalidade, 'fisico');
      expect(service.mentalPool().modalidade, 'mental');
      expect(service.espiritualPool().modalidade, 'espiritual');
      expect(service.vitalismoPool().modalidade, 'vitalismo');
    });

    test('cores canônicas batem', () {
      expect(service.fisicoPool().corCanonica, '#A32D2D');
      expect(service.mentalPool().corCanonica, '#185FA5');
      expect(service.espiritualPool().corCanonica, '#854F0B');
      expect(service.vitalismoPool().corCanonica, '#534AB7');
    });

    test('contagem de sub-tarefas: 60/60/60/0', () {
      expect(service.fisicoPool().subTarefas.length, 60);
      expect(service.mentalPool().subTarefas.length, 60);
      expect(service.espiritualPool().subTarefas.length, 60);
      // Vitalismo não tem campo subTarefas (model diferente).
    });

    test('contagem de sub-tarefas por sub-categoria: 15 cada', () {
      void check(DailyModalidadePool pool, List<String> subcats) {
        for (final sc in subcats) {
          final n = pool.subTarefas.where((s) => s.subCategoria == sc).length;
          expect(n, 15, reason: '${pool.modalidade}/$sc');
        }
      }

      check(service.fisicoPool(),
          ['treino', 'recuperacao', 'nutricao', 'descanso']);
      check(service.mentalPool(),
          ['estudo', 'organizacao', 'criatividade', 'foco']);
      check(service.espiritualPool(),
          ['proposito', 'conexao', 'silencio', 'ritual']);
    });

    test('títulos: 32 por pilar (8×4 sub-categorias) + 12 vitalismo', () {
      int totalTitulos(DailyModalidadePool pool) =>
          pool.titulosPorSubcategoria.values
              .fold(0, (a, list) => a + list.length);
      expect(totalTitulos(service.fisicoPool()), 32);
      expect(totalTitulos(service.mentalPool()), 32);
      expect(totalTitulos(service.espiritualPool()), 32);
      expect(service.vitalismoPool().titulos.length, 12);

      // 8 títulos por sub-categoria
      for (final pool in [
        service.fisicoPool(),
        service.mentalPool(),
        service.espiritualPool(),
      ]) {
        for (final entry in pool.titulosPorSubcategoria.entries) {
          expect(entry.value.length, 8,
              reason: '${pool.modalidade}/${entry.key}');
        }
      }
    });

    test('quotes: 20 por pilar (80 total)', () {
      expect(service.fisicoPool().quotes.length, 20);
      expect(service.mentalPool().quotes.length, 20);
      expect(service.espiritualPool().quotes.length, 20);
      expect(service.vitalismoPool().quotes.length, 20);
    });

    test('pesos sub-categoria somam 1.0 em cada pool', () {
      for (final pool in [
        service.fisicoPool(),
        service.mentalPool(),
        service.espiritualPool(),
      ]) {
        final total =
            pool.pesosSubcategoria.values.fold<double>(0, (a, b) => a + b);
        expect(total, closeTo(1.0, 0.001), reason: pool.modalidade);
      }
      // Vitalismo: 3 mapas, cada um soma 1.0.
      for (final entry
          in service.vitalismoPool().pesosSubcategoriaPorPilar.entries) {
        final total = entry.value.values.fold<double>(0, (a, b) => a + b);
        expect(total, closeTo(1.0, 0.001), reason: 'vitalismo/${entry.key}');
      }
    });

    test('sub-tarefas com requer_imc são exatamente água + proteína', () {
      final reqImc = service
          .fisicoPool()
          .subTarefas
          .where((s) => s.requerImc)
          .map((s) => s.key)
          .toSet();
      expect(reqImc, {'agua_diaria', 'proteina_diaria'});
    });
  });

  group('poolFor (MissionCategory)', () {
    test('Físico/Mental/Espiritual retornam DailyModalidadePool', () {
      expect(service.poolFor(MissionCategory.fisico),
          isA<DailyModalidadePool>());
      expect(service.poolFor(MissionCategory.mental),
          isA<DailyModalidadePool>());
      expect(service.poolFor(MissionCategory.espiritual),
          isA<DailyModalidadePool>());
    });

    test('Vitalismo retorna VitalismoPool', () {
      expect(service.poolFor(MissionCategory.vitalismo),
          isA<VitalismoPool>());
    });
  });

  group('subTaskByKey', () {
    test('retorna spec correta pra "flexoes"', () {
      final spec = service.subTaskByKey('flexoes');
      expect(spec, isNotNull);
      expect(spec!.nomeVisivel, 'Flexões');
      expect(spec.subCategoria, 'treino');
      expect(spec.unidade, 'x');
      expect(spec.escalaPorRank, {
        'E': 10,
        'D': 25,
        'C': 50,
        'B': 90,
        'A': 150,
        'S': 300,
      });
    });

    test('retorna spec do Mental ("pomodoro")', () {
      final spec = service.subTaskByKey('pomodoro');
      expect(spec, isNotNull);
      expect(spec!.subCategoria, 'foco');
    });

    test('retorna spec do Espiritual ("gratidao_3")', () {
      final spec = service.subTaskByKey('gratidao_3');
      expect(spec, isNotNull);
      expect(spec!.subCategoria, 'conexao');
    });

    test('retorna null pra key inexistente', () {
      expect(service.subTaskByKey('inexistente'), isNull);
      expect(service.subTaskByKey(''), isNull);
    });

    test('keys são únicas cross-pool (180 sub-tarefas distintas)', () {
      final all = <String>{};
      for (final pool in [
        service.fisicoPool(),
        service.mentalPool(),
        service.espiritualPool(),
      ]) {
        for (final s in pool.subTarefas) {
          expect(all.add(s.key), isTrue,
              reason: 'key duplicada: ${s.key}');
        }
      }
      expect(all.length, 180);
    });
  });

  group('resolveScale', () {
    late AppDatabase db;
    late BodyMetricsService bodyMetrics;
    late int playerId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      bodyMetrics = BodyMetricsService(dao: PlayerDao(db), bus: AppEventBus());
      playerId = await db.into(db.playersTable).insert(
            const PlayersTableCompanion(
              email: Value('rs@t'),
              passwordHash: Value('h'),
            ),
          );
    });

    tearDown(() async => db.close());

    Future<PlayersTableData> readPlayer() => (db.select(db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .getSingle();

    test('rank E retorna escala E (flexões = 10)', () async {
      final spec = service.subTaskByKey('flexoes')!;
      final p = await readPlayer();
      final scale = service.resolveScale(
          spec: spec, rank: 'E', bodyMetrics: bodyMetrics, player: p);
      expect(scale, 10);
    });

    test('rank S retorna escala S (flexões = 300, Saitama-tier)',
        () async {
      final spec = service.subTaskByKey('flexoes')!;
      final p = await readPlayer();
      final scale = service.resolveScale(
          spec: spec, rank: 'S', bodyMetrics: bodyMetrics, player: p);
      expect(scale, 300);
    });

    test('escala 0 (visitar_alguem rank E) retorna 0', () async {
      final spec = service.subTaskByKey('visitar_alguem')!;
      final p = await readPlayer();
      final scale = service.resolveScale(
          spec: spec, rank: 'E', bodyMetrics: bodyMetrics, player: p);
      expect(scale, 0);
    });

    test('requer_imc água: usa BodyMetricsService (peso 70 → 2450ml)',
        () async {
      await bodyMetrics.save(
          playerId: playerId, weightKg: 70, heightCm: 170);
      final spec = service.subTaskByKey('agua_diaria')!;
      expect(spec.requerImc, isTrue);
      final p = await readPlayer();
      final scale = service.resolveScale(
          spec: spec, rank: 'E', bodyMetrics: bodyMetrics, player: p);
      expect(scale, 2450);
    });

    test('requer_imc proteína: usa BodyMetricsService (peso 70 → 112g)',
        () async {
      await bodyMetrics.save(
          playerId: playerId, weightKg: 70, heightCm: 170);
      final spec = service.subTaskByKey('proteina_diaria')!;
      final p = await readPlayer();
      final scale = service.resolveScale(
          spec: spec, rank: 'C', bodyMetrics: bodyMetrics, player: p);
      expect(scale, 112);
    });

    test('requer_imc sem peso: cai pros fallbacks 2000ml/80g', () async {
      final p = await readPlayer();
      final water = service.resolveScale(
          spec: service.subTaskByKey('agua_diaria')!,
          rank: 'E',
          bodyMetrics: bodyMetrics,
          player: p);
      expect(water, DailyPoolService.fallbackWaterMl);
      expect(water, 2000);
      final protein = service.resolveScale(
          spec: service.subTaskByKey('proteina_diaria')!,
          rank: 'E',
          bodyMetrics: bodyMetrics,
          player: p);
      expect(protein, DailyPoolService.fallbackProteinG);
      expect(protein, 80);
    });

    test('rank inválido lança ArgumentError', () async {
      final spec = service.subTaskByKey('flexoes')!;
      final p = await readPlayer();
      expect(
        () => service.resolveScale(
            spec: spec, rank: 'X', bodyMetrics: bodyMetrics, player: p),
        throwsArgumentError,
      );
    });
  });

  group('estado pré-load', () {
    test('poolFor lança StateError se loadAll não foi chamado', () {
      final fresh = DailyPoolService();
      expect(() => fresh.poolFor(MissionCategory.fisico), throwsStateError);
      expect(() => fresh.fisicoPool(), throwsStateError);
      expect(() => fresh.vitalismoPool(), throwsStateError);
    });

    test('subTaskByKey retorna null antes de loadAll', () {
      final fresh = DailyPoolService();
      expect(fresh.subTaskByKey('flexoes'), isNull);
    });
  });
}
