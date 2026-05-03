import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/faction_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/domain/services/faction_reputation_service.dart';

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late FactionReputationService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    service = FactionReputationService(
      repo: PlayerFactionReputationRepositoryDrift(db),
      bus: bus,
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('FactionReputationService', () {
    test('adjust aplica delta principal + emite FactionReputationChanged',
        () async {
      final captured = <FactionReputationChanged>[];
      final sub = bus.on<FactionReputationChanged>().listen(captured.add);

      // Sprint 3.4 Etapa A — matriz `kFactionAlliances` populada com Q13.
      // `guild` é aliada fraco (multiplier 0.1) com TODAS as 7 outras
      // facções, então `adjustReputation('guild', 10)` agora dispara:
      //   - 1 evento na própria guild (delta direto +10)
      //   - 7 eventos nas aliadas (delta propagado +1 cada)
      //   = 8 eventos totais.
      await service.adjustReputation(
          playerId: 1, factionId: 'guild', delta: 10);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(await service.current(1, 'guild'), 60); // 50 default + 10
      expect(captured.length, 8); // guild + 7 aliadas (matriz Q13)
      // Primeiro evento é sempre o delta direto da facção alvo.
      expect(captured.first.factionId, 'guild');
      expect(captured.first.previousValue, 50);
      expect(captured.first.newValue, 60);

      await sub.cancel();
    });

    test('matrix populada (Q13 Sprint 3.4): guild propaga +0.1 pra TODAS',
        () async {
      final captured = <FactionReputationChanged>[];
      final sub = bus.on<FactionReputationChanged>().listen(captured.add);

      await service.adjustReputation(
          playerId: 1, factionId: 'guild', delta: 10);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 8 eventos: guild +10 (direto) + 7 aliadas +1 cada (propagação 0.1).
      expect(captured.length, 8);

      // Cada uma das 7 aliadas vira 51 (50 default + 1 propagado).
      for (final f in [
        'moon_clan',
        'sun_clan',
        'black_legion',
        'new_order',
        'trinity',
        'renegades',
        'error',
      ]) {
        expect(await service.current(1, f), 51,
            reason: '$f deve receber +1 propagado (guild aliada fraco)');
      }
      await sub.cancel();
    });

    test('matrix populada (Q13): rivais cósmicos sun↔moon propagam negativo',
        () async {
      final captured = <FactionReputationChanged>[];
      final sub = bus.on<FactionReputationChanged>().listen(captured.add);

      // sun_clan ↔ moon_clan: multiplier -0.5 (rivais mais fortes da matriz).
      // Subir +20 em sun_clan deve cair -10 em moon_clan + propagar
      // +2 na guild (sun↔guild aliada fraco 0.1).
      await service.adjustReputation(
          playerId: 1, factionId: 'sun_clan', delta: 20);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(await service.current(1, 'sun_clan'), 70); // 50 + 20
      expect(await service.current(1, 'moon_clan'), 40); // 50 - 10
      expect(await service.current(1, 'guild'), 52); // 50 + 2

      // Rivais não-relacionados continuam em 50.
      expect(await service.current(1, 'black_legion'), 50);
      expect(await service.current(1, 'new_order'), 50);
      expect(await service.current(1, 'trinity'), 50);
      expect(await service.current(1, 'renegades'), 50);

      // 3 eventos: sun_clan + moon_clan + guild.
      expect(captured.length, 3);

      await sub.cancel();
    });

    test('delta=0 noop — nada persistido, nada emitido', () async {
      final captured = <FactionReputationChanged>[];
      final sub = bus.on<FactionReputationChanged>().listen(captured.add);

      await service.adjustReputation(
          playerId: 1, factionId: 'guild', delta: 0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(captured, isEmpty);
      await sub.cancel();
    });

    test('clamp 0-100: delta enorme não estoura', () async {
      await service.adjustReputation(
          playerId: 1, factionId: 'guild', delta: 200);
      expect(await service.current(1, 'guild'), 100);

      await service.adjustReputation(
          playerId: 1, factionId: 'guild', delta: -500);
      expect(await service.current(1, 'guild'), 0);
    });
  });
}
