import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/faction_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:drift/drift.dart' show Variable;

import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/domain/services/faction_buff_service.dart';
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

  // ─── Sprint 3.4 Etapa C — xpMult universal aplica em rep ──────────
  group('FactionReputationService — xpMult universal (Etapa C)', () {
    late FactionReputationService buffedService;
    late FactionBuffService buffService;
    const playerId = 1;

    setUp(() async {
      buffService = FactionBuffService(db);
      buffService.debugSetCatalog(<String, dynamic>{
        'guild': {
          'applied': {'xp_mult': 1.10},  // hipotético — Guilda buff ativo
          'pending': [],
        },
        'new_order': {
          'applied': {'xp_mult': 1.10},
          'pending': [],
        },
      });
      buffedService = FactionReputationService(
        repo: PlayerFactionReputationRepositoryDrift(db),
        bus: bus,
        db: db,
        factionBuff: buffService,
      );
    });

    Future<void> seedPlayer(String factionType) async {
      await db.customStatement(
        "INSERT INTO players (id, email, password_hash, faction_type) "
        "VALUES (?, ?, ?, ?)",
        [playerId, 't@t.com', 'hash', factionType],
      );
    }

    test('Player Nova Ordem ganhando rep em moon_clan: +10 → +11 (round)',
        () async {
      await seedPlayer('new_order');
      // sun_clan/moon_clan/etc não têm relação na matriz com new_order
      // (ver kFactionAlliances Sprint 3.4 Q13). Vou usar moon_clan que
      // tem rivais — mas cuidado: matriz pode propagar.
      // Simplificação: usar 'noryan' (não existe na matriz) → sem propagação.
      await buffedService.adjustReputation(
        playerId: playerId,
        factionId: 'noryan',
        delta: 10,
      );
      // round(10 × 1.10) = 11.
      expect(await buffedService.current(playerId, 'noryan'), 61);
    });

    test('OPÇÃO A: Guilda member ganhando rep da Guilda → SEM buff', () async {
      await seedPlayer('guild');
      await buffedService.adjustReputation(
        playerId: playerId,
        factionId: 'guild',
        delta: 10,
      );
      // Sem buff (OPÇÃO A): delta cru +10. Default 50 → 60.
      // Mas matriz Guilda propaga +0.1 pra outras 7 facções (delta original).
      expect(await buffedService.current(playerId, 'guild'), 60);
    });

    test('OPÇÃO A: Guilda member ganhando rep de OUTRA facção → COM buff',
        () async {
      await seedPlayer('guild');
      // Hipotético: ganha +10 rep em moon_clan. Buff 1.10 aplica.
      // moon_clan não está na matriz com noryan → sem propagação confusa.
      // Mas moon_clan TEM matriz: rivais sun_clan -0.5, alianças etc.
      // Pra evitar propagações, uso 'noryan' (não na matriz).
      await buffedService.adjustReputation(
        playerId: playerId,
        factionId: 'noryan',
        delta: 10,
      );
      // round(10 × 1.10) = 11. Default 50 → 61.
      expect(await buffedService.current(playerId, 'noryan'), 61);
    });

    test('Delta NEGATIVO não amplifica (penalidade passa cru)', () async {
      await seedPlayer('new_order');
      // Player Nova Ordem com xp_mult=1.10. Delta -10 → fica -10 (não -11).
      await buffedService.adjustReputation(
        playerId: playerId,
        factionId: 'noryan',
        delta: -10,
      );
      // Default 50 - 10 (cru) = 40.
      expect(await buffedService.current(playerId, 'noryan'), 40);
    });

    test('Player sem facção → mults 1.0 → sem buff', () async {
      await seedPlayer('none');
      await buffedService.adjustReputation(
        playerId: playerId,
        factionId: 'noryan',
        delta: 10,
      );
      expect(await buffedService.current(playerId, 'noryan'), 60);
    });
  });
}
