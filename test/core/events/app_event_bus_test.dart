import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/app_event.dart';
import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/crafting_events.dart';
import 'package:noheroes_app/core/events/faction_events.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/events/player_events.dart';
import 'package:noheroes_app/core/events/reward_events.dart';
import 'package:noheroes_app/core/events/streak_events.dart';

/// Sprint 3.1 Bloco 2 — contratos do EventBus local.
///
/// Cobre os 11 casos acordados no plan-first:
///   1. Subscribe → publish → listener recebe payload intacto
///   2. `on<T>()` filtra por tipo
///   3. Múltiplos listeners recebem todos
///   4. `subscription.cancel()` para de receber
///   5. Pós-dispose: publish é noop silencioso (não lança)
///   6. Todo evento tem `timestamp` não nulo próximo do agora
///   7. Ordem preservada (async-aware via pumpEventQueue)
///   8. Provider Riverpod retorna mesma instância em reads consecutivos
///   9. `toString()` inclui tipo + payload
///  10. Eventos com mesmo payload são instâncias distintas (sem igualdade)
///  11. Listener tardio NÃO recebe evento passado (broadcast stream sem replay)
void main() {
  group('AppEventBus — contratos básicos', () {
    test('1. subscribe + publish + listener recebe payload intacto',
        () async {
      final bus = AppEventBus();
      MissionCompleted? received;
      final sub = bus.on<MissionCompleted>().listen((e) => received = e);

      bus.publish(MissionCompleted(
        missionKey: 'DAILY_PUSHUPS_E',
        playerId: 42,
        rewardResolvedJson: '{"xp":40}',
      ));
      await pumpEventQueue();

      expect(received, isNotNull);
      expect(received!.missionKey, 'DAILY_PUSHUPS_E');
      expect(received!.playerId, 42);
      expect(received!.rewardResolvedJson, '{"xp":40}');

      await sub.cancel();
      await bus.dispose();
    });

    test('2. on<T>() filtra por tipo', () async {
      final bus = AppEventBus();
      final received = <AppEvent>[];
      final subMission =
          bus.on<MissionCompleted>().listen(received.add);
      final subLevel = bus.on<LevelUp>().listen(received.add);

      bus.publish(LevelUp(playerId: 1, newLevel: 5, previousLevel: 4));
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.first, isA<LevelUp>());

      await subMission.cancel();
      await subLevel.cancel();
      await bus.dispose();
    });

    test('3. múltiplos listeners no mesmo tipo todos recebem', () async {
      final bus = AppEventBus();
      var countA = 0;
      var countB = 0;
      final subA = bus.on<AchievementUnlocked>().listen((_) => countA++);
      final subB = bus.on<AchievementUnlocked>().listen((_) => countB++);

      bus.publish(AchievementUnlocked(
        playerId: 1,
        achievementKey: 'ACH_FIRST_CRAFT',
      ));
      await pumpEventQueue();

      expect(countA, 1);
      expect(countB, 1);

      await subA.cancel();
      await subB.cancel();
      await bus.dispose();
    });

    test('4. subscription.cancel() para de receber', () async {
      final bus = AppEventBus();
      var count = 0;
      final sub = bus.on<ItemCrafted>().listen((_) => count++);

      bus.publish(ItemCrafted(
        playerId: 1,
        itemKey: 'SWORD_E',
        recipeKey: 'RECIPE_SWORD_E',
      ));
      await pumpEventQueue();
      expect(count, 1);

      await sub.cancel();
      bus.publish(ItemCrafted(
        playerId: 1,
        itemKey: 'SWORD_D',
        recipeKey: 'RECIPE_SWORD_D',
      ));
      await pumpEventQueue();
      expect(count, 1, reason: 'após cancel, não deveria receber mais');

      await bus.dispose();
    });
  });

  group('AppEventBus — dispose', () {
    test('5. publish pós-dispose é noop silencioso (NÃO lança)', () async {
      final bus = AppEventBus();
      var received = 0;
      final sub = bus.on<GoldSpent>().listen((_) => received++);

      // Emissão antes do dispose chega.
      bus.publish(GoldSpent(
        playerId: 1,
        amount: 100,
        source: GoldSink.shop,
      ));
      await pumpEventQueue();
      expect(received, 1);

      await sub.cancel();
      await bus.dispose();
      expect(bus.isDisposed, isTrue);

      // Pós-dispose: não lança, não emite, não crasha.
      expect(
        () => bus.publish(GoldSpent(
          playerId: 1,
          amount: 50,
          source: GoldSink.forge,
        )),
        returnsNormally,
        reason:
            'contrato do dispose: publish pós-dispose é noop silencioso '
            '(ver dartdoc em AppEventBus.dispose)',
      );

      // dispose é idempotente.
      await expectLater(bus.dispose(), completes);
    });
  });

  group('AppEventBus — metadata', () {
    test('6. todo evento tem timestamp não nulo próximo do agora', () {
      final before = DateTime.now();
      final e = FactionJoined(playerId: 1, factionId: 'noryan');
      final after = DateTime.now();

      expect(e.timestamp, isNotNull);
      expect(
        e.timestamp.isAtSameMomentAs(before) ||
            e.timestamp.isAfter(before) ||
            e.timestamp.isAtSameMomentAs(after) ||
            e.timestamp.isBefore(after),
        isTrue,
      );
      // Precisão grosseira mas suficiente pra provar captura automática.
      expect(
        e.timestamp.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        e.timestamp.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch),
      );
    });

    test('7. ordem preservada (async-aware com pumpEventQueue)', () async {
      final bus = AppEventBus();
      final received = <int>[];
      final sub = bus
          .on<MissionProgressed>()
          .listen((e) => received.add(e.currentValue));

      bus.publish(MissionProgressed(
        missionKey: 'X',
        playerId: 1,
        currentValue: 1,
        targetValue: 10,
      ));
      await pumpEventQueue();

      bus.publish(MissionProgressed(
        missionKey: 'X',
        playerId: 1,
        currentValue: 2,
        targetValue: 10,
      ));
      await pumpEventQueue();

      bus.publish(MissionProgressed(
        missionKey: 'X',
        playerId: 1,
        currentValue: 3,
        targetValue: 10,
      ));
      await pumpEventQueue();

      expect(received, [1, 2, 3]);

      await sub.cancel();
      await bus.dispose();
    });

    test('9. toString inclui tipo + campos principais', () {
      final e = MissionFailed(
        missionKey: 'DAILY_RUN_E',
        playerId: 7,
        reason: MissionFailureReason.expired,
      );
      final s = e.toString();
      expect(s, contains('MissionFailed'));
      expect(s, contains('DAILY_RUN_E'));
      expect(s, contains('7'));
      expect(s, contains('expired'));
    });

    test(
        '10. dois eventos com mesmo payload são instâncias distintas '
        '(sem igualdade estrutural)', () {
      final a = StreakMaintained(playerId: 1, currentStreak: 10);
      final b = StreakMaintained(playerId: 1, currentStreak: 10);
      expect(identical(a, b), isFalse);
      // `==` default é identity, confirma que não reimplantamos value equality.
      expect(a == b, isFalse);
    });
  });

  group('AppEventBus — singleton via Riverpod', () {
    test('8. appEventBusProvider retorna mesma instância em reads '
        'consecutivos', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final a = container.read(appEventBusProvider);
      final b = container.read(appEventBusProvider);
      expect(identical(a, b), isTrue);
    });
  });

  group('AppEventBus — broadcast sem replay', () {
    test('11. listener adicionado DEPOIS do publish NÃO recebe evento '
        'passado', () async {
      final bus = AppEventBus();

      bus.publish(StreakBroken(playerId: 1, lastStreak: 42));
      await pumpEventQueue();

      StreakBroken? late;
      final sub = bus.on<StreakBroken>().listen((e) => late = e);
      await pumpEventQueue();

      expect(
        late,
        isNull,
        reason: 'broadcast stream não tem replay — contrato documentado '
            'no dartdoc de AppEventBus',
      );

      // E emissões novas chegam normalmente.
      bus.publish(StreakBroken(playerId: 1, lastStreak: 10));
      await pumpEventQueue();
      expect(late, isNotNull);
      expect(late!.lastStreak, 10);

      await sub.cancel();
      await bus.dispose();
    });
  });
}
