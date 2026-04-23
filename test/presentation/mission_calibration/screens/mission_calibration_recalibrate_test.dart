import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/mission_preferences_repository_drift.dart';
import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_style.dart';
import 'package:noheroes_app/domain/exceptions/reward_exceptions.dart';
import 'package:noheroes_app/domain/models/mission_preferences.dart';
import 'package:noheroes_app/domain/services/mission_preferences_service.dart';

/// Sprint 3.1 Bloco 10b — testes de integração do fluxo recalibrate
/// exercitando o `MissionPreferencesService` + bus, sem Widget. Widget
/// tests da tela recalibrate têm infra async complexa (NpcDialogOverlay
/// + showDialog + initState async + go_router); cobertura comportamental
/// via unit do service + tier de custo garante as invariantes críticas:
///
///   - costForRecalibration retorna tier correto por updatesCount
///   - chargeRecalibration debita + emite GemsSpent antes do save
///   - save incrementa updatesCount pra próximo refazer cobrar mais
///   - saldo insuficiente interrompe fluxo (exception propagada)
///
/// Widget test completo da tela Refazer fica como débito pra sprint
/// futura (ver Sprint_Missoes_Sessao1_Progresso.md).

Future<int> _seedPlayer(AppDatabase db,
    {int gems = 0, int level = 10}) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp) "
    "VALUES (?, ?, 'S', ?, 0, 100, 0, ?, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withInt(level),
      Variable.withInt(gems),
    ],
  );
}

MissionPreferences _sample(int playerId, {MissionCategory focus =
    MissionCategory.fisico}) {
  final now = DateTime.now();
  return MissionPreferences(
    playerId: playerId,
    primaryFocus: focus,
    intensity: Intensity.medium,
    missionStyle: MissionStyle.real,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late MissionPreferencesService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    service = MissionPreferencesService(
      repo: MissionPreferencesRepositoryDrift(db),
      bus: bus,
      db: db,
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('Fluxo recalibrate — service-level', () {
    test('primeira refazer (updatesCount=0) é free — sem charge necessário',
        () async {
      final playerId = await _seedPlayer(db, gems: 0);
      await service.save(_sample(playerId));
      // Na sequência o jogador tenta refazer: updatesCount=0 → free.
      final count = await service.currentUpdatesCount(playerId);
      expect(count, 0);
      final cost = service.costForRecalibration(count);
      expect(cost.isFree, isTrue);
      // chargeRecalibration(free) é noop — não lança, sem evento.
      final gemEvents = <GemsSpent>[];
      final sub = bus.on<GemsSpent>().listen(gemEvents.add);
      await service.chargeRecalibration(playerId, cost);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(gemEvents, isEmpty);
      await sub.cancel();
    });

    test('segunda refazer: cobra 100 gems + emite GemsSpent(recalibration)',
        () async {
      final playerId = await _seedPlayer(db, gems: 200);
      // Calibração inicial + 1 refazer free — simula via save 2x.
      await service.save(_sample(playerId));
      await service.save(_sample(playerId));
      expect(await service.currentUpdatesCount(playerId), 1);
      final cost = service.costForRecalibration(
          await service.currentUpdatesCount(playerId));
      expect(cost.gems, 100);

      final gemEvents = <GemsSpent>[];
      final sub = bus.on<GemsSpent>().listen(gemEvents.add);
      await service.chargeRecalibration(playerId, cost);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gems, 100); // 200 - 100 = 100
      expect(gemEvents.length, 1);
      expect(gemEvents.single.amount, 100);
      expect(gemEvents.single.source, GemSink.recalibration);
      await sub.cancel();
    });

    test(
        'save pós-charge incrementa updatesCount pra tier 300g+3s no próximo',
        () async {
      final playerId = await _seedPlayer(db, gems: 500);
      // Calibração inicial.
      await service.save(_sample(playerId));
      // 1ª refazer (free) — save direto.
      await service.save(_sample(playerId));
      // 2ª refazer (paga 100g+1s) — charge + save.
      await service.chargeRecalibration(
          playerId, service.costForRecalibration(1));
      await service.save(_sample(playerId));
      // 3ª refazer: cost já é 300g+3s.
      final cost = service.costForRecalibration(
          await service.currentUpdatesCount(playerId));
      expect(cost.gems, 300);
      expect(cost.seivas, 3);
    });

    test('saldo insuficiente → InsufficientGemsException + saldo intacto',
        () async {
      final playerId = await _seedPlayer(db, gems: 50);
      await service.save(_sample(playerId));
      await service.save(_sample(playerId));
      final cost = service.costForRecalibration(1); // precisa 100
      expect(
        () => service.chargeRecalibration(playerId, cost),
        throwsA(isA<InsufficientGemsException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gems, 50);
    });

    test(
        'MissionPreferencesChanged é emitido no save (consumer pode reassign)',
        () async {
      final playerId = await _seedPlayer(db);
      final events = <MissionPreferencesChanged>[];
      final sub = bus.on<MissionPreferencesChanged>().listen(events.add);
      await service.save(_sample(playerId));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events.length, 1);
      expect(events.single.playerId, playerId);
      await sub.cancel();
    });
  });

  group('canRecalibrate — gate consumido pelo SanctuaryDrawer', () {
    test('lvl 10 + prefs existentes → true', () async {
      final playerId = await _seedPlayer(db, level: 10);
      await service.save(_sample(playerId));
      final ok = await service.canRecalibrate(
          playerId: playerId, playerLevel: 10);
      expect(ok, isTrue);
    });

    test('lvl 10 sem prefs → false', () async {
      final playerId = await _seedPlayer(db, level: 10);
      final ok = await service.canRecalibrate(
          playerId: playerId, playerLevel: 10);
      expect(ok, isFalse);
    });

    test('lvl 9 + prefs → false (gate hard)', () async {
      final playerId = await _seedPlayer(db, level: 9);
      await service.save(_sample(playerId));
      final ok = await service.canRecalibrate(
          playerId: playerId, playerLevel: 9);
      expect(ok, isFalse);
    });
  });

  group('Regra 4 (race condition) — comportamento esperado da tela', () {
    // A tela usa `ref.invalidate(playerStreamProvider)` + delay 400ms
    // + go('/quests') SÓ no modo recalibrate. Calibração inicial não
    // invalidou nada → navega direto. Este teste documenta a
    // invariante via integração service + ProviderContainer.
    test(
        'chargeRecalibration dispara UPDATE em players — o caller da UI '
        'precisa invalidate + delay + go na sequência', () async {
      final playerId = await _seedPlayer(db, gems: 150);
      await service.save(_sample(playerId));
      await service.save(_sample(playerId));
      // Simula o fluxo da tela recalibrate:
      //   1. cost computado
      //   2. chargeRecalibration (invalida playersTable stream — UPDATE)
      //   3. save (atualiza prefs)
      //   A tela aplica Regra 4 aqui: invalidate + Future.delayed 400ms
      //      + go('/quests'). Este teste apenas garante que as
      //      transações subjacentes rodaram em ordem correta.
      await service.chargeRecalibration(
          playerId, service.costForRecalibration(1));
      await service.save(_sample(playerId));
      final row = await (db.select(db.playersTable)
            ..where((t) => t.id.equals(playerId)))
          .getSingle();
      expect(row.gems, 50); // 150 - 100
      final prefs = await service.findCurrent(playerId);
      expect(prefs!.updatesCount, 2);
    });
  });
}
