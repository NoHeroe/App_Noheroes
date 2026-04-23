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
    test('adjust aplica delta + emite FactionReputationChanged', () async {
      final captured = <FactionReputationChanged>[];
      final sub = bus.on<FactionReputationChanged>().listen(captured.add);

      await service.adjustReputation(
          playerId: 1, factionId: 'guild', delta: 10);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(await service.current(1, 'guild'), 60); // 50 default + 10
      expect(captured.length, 1);
      expect(captured.first.factionId, 'guild');
      expect(captured.first.previousValue, 50);
      expect(captured.first.newValue, 60);

      await sub.cancel();
    });

    test('matrix NEUTRA (padrão do Bloco 13b): zero propagação', () async {
      final captured = <FactionReputationChanged>[];
      final sub = bus.on<FactionReputationChanged>().listen(captured.add);

      await service.adjustReputation(
          playerId: 1, factionId: 'guild', delta: 10);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Só guild mudou. Outras facções permanecem em 50.
      expect(captured.length, 1);
      for (final f in [
        'moon_clan',
        'sun_clan',
        'black_legion',
        'new_order',
        'trinity',
        'renegades'
      ]) {
        expect(await service.current(1, f), 50,
            reason: '$f deve continuar em 50 (matrix neutra)');
      }
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
