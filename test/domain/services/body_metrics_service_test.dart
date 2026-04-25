import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/domain/services/body_metrics_service.dart';

/// Sprint 3.2 Etapa 1.0 — cobre IMC, categorias OMS e recomendações
/// água/proteína. PlayerDao real em memória pra exercitar `save` ponta-a-ponta.
void main() {
  late AppDatabase db;
  late BodyMetricsService service;
  late int playerId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = BodyMetricsService(dao: PlayerDao(db));
    playerId = await db.into(db.playersTable).insert(const PlayersTableCompanion(
          email: Value('bm@test'),
          passwordHash: Value('h'),
          shadowName: Value('Sombra'),
        ));
  });

  tearDown(() async => db.close());

  Future<PlayersTableData> readPlayer() => (db.select(db.playersTable)
        ..where((t) => t.id.equals(playerId)))
      .getSingle();

  group('IMC', () {
    test('70kg/170cm → 24.2 (faixa Normal)', () async {
      await service.save(playerId: playerId, weightKg: 70, heightCm: 170);
      final p = await readPlayer();
      expect(service.bmi(p), 24.2);
      expect(service.bmiCategory(p), BodyMetricsService.categoryNormal);
    });

    test('50kg/170cm → faixa Abaixo', () async {
      await service.save(playerId: playerId, weightKg: 50, heightCm: 170);
      final p = await readPlayer();
      expect(service.bmiCategory(p), BodyMetricsService.categoryUnderweight);
    });

    test('80kg/170cm → faixa Sobrepeso', () async {
      await service.save(playerId: playerId, weightKg: 80, heightCm: 170);
      final p = await readPlayer();
      expect(service.bmiCategory(p), BodyMetricsService.categoryOverweight);
    });

    test('100kg/170cm → faixa Obesidade', () async {
      await service.save(playerId: playerId, weightKg: 100, heightCm: 170);
      final p = await readPlayer();
      expect(service.bmiCategory(p), BodyMetricsService.categoryObese);
    });

    test('peso ausente → bmi null + categoria Incompleto', () async {
      final p = await readPlayer();
      expect(service.bmi(p), isNull);
      expect(service.bmiCategory(p), BodyMetricsService.categoryIncomplete);
    });

    test('só altura preenchida → bmi null', () async {
      await service.save(playerId: playerId, heightCm: 170);
      final p = await readPlayer();
      expect(service.bmi(p), isNull);
      expect(service.bmiCategory(p), BodyMetricsService.categoryIncomplete);
    });
  });

  group('recomendações diárias', () {
    test('70kg → 2450ml água, 112g proteína', () async {
      await service.save(playerId: playerId, weightKg: 70, heightCm: 170);
      final p = await readPlayer();
      expect(service.recommendedWaterMl(p), 2450);
      expect(service.recommendedProteinG(p), 112);
    });

    test('peso ausente → recomendações null', () async {
      final p = await readPlayer();
      expect(service.recommendedWaterMl(p), isNull);
      expect(service.recommendedProteinG(p), isNull);
    });

    test('proteína arredondada (60kg → 96g)', () async {
      await service.save(playerId: playerId, weightKg: 60, heightCm: 170);
      final p = await readPlayer();
      expect(service.recommendedProteinG(p), 96);
    });
  });

  group('validação de range', () {
    test('peso fora do range lança ArgumentError', () {
      expect(
        () => service.save(playerId: playerId, weightKg: 19, heightCm: 170),
        throwsArgumentError,
      );
      expect(
        () => service.save(playerId: playerId, weightKg: 301, heightCm: 170),
        throwsArgumentError,
      );
    });

    test('altura fora do range lança ArgumentError', () {
      expect(
        () => service.save(playerId: playerId, weightKg: 70, heightCm: 99),
        throwsArgumentError,
      );
      expect(
        () => service.save(playerId: playerId, weightKg: 70, heightCm: 251),
        throwsArgumentError,
      );
    });

    test('limites inclusivos (20/300/100/250) passam', () async {
      await service.save(playerId: playerId, weightKg: 20, heightCm: 100);
      await service.save(playerId: playerId, weightKg: 300, heightCm: 250);
    });

    test('isValidWeight / isValidHeight refletem ranges', () {
      expect(service.isValidWeight(20), isTrue);
      expect(service.isValidWeight(300), isTrue);
      expect(service.isValidWeight(19), isFalse);
      expect(service.isValidWeight(301), isFalse);
      expect(service.isValidHeight(100), isTrue);
      expect(service.isValidHeight(250), isTrue);
      expect(service.isValidHeight(99), isFalse);
      expect(service.isValidHeight(251), isFalse);
    });
  });

  test('save persiste só os campos passados (Value.absent preserva)',
      () async {
    await service.save(playerId: playerId, weightKg: 70, heightCm: 170);
    await service.save(playerId: playerId, weightKg: 80); // só peso
    final p = await readPlayer();
    expect(p.weightKg, 80);
    expect(p.heightCm, 170);
  });
}
