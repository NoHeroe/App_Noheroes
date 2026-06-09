import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/ascension_service.dart';
import 'package:noheroes_app/data/datasources/local/guild_ascension_service.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/quest_reward_stats_service.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

/// B.2 — máquina de estados da ascensão (AscensionService).
/// Gates E→D (catálogo real): level>=10, missions>=100, gold_life>=10000,
/// card_wins (mock satisfeito), fee_base 5000, window 24h. Trial auto x1.

const int _hour = 3600000;

Future<int> _seedPlayer(
  AppDatabase db, {
  int level = 1,
  int missions = 0,
  int goldLifetime = 0,
  int gold = 0,
  String guildRank = 'E',
}) async {
  return db.customInsert(
    'INSERT INTO players (email, password_hash, level, '
    'total_quests_completed, total_gold_earned_lifetime, gold, guild_rank) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withInt(level),
      Variable.withInt(missions),
      Variable.withInt(goldLifetime),
      Variable.withInt(gold),
      Variable.withString(guildRank),
    ],
  );
}

/// Player com todos os gates do ciclo E→D atendidos + ouro pra fee.
Future<int> _seedEligible(AppDatabase db, {int gold = 10000}) {
  return _seedPlayer(db,
      level: 15, missions: 150, goldLifetime: 20000, gold: gold, guildRank: 'E');
}

Future<void> _seedCollar(AppDatabase db, int playerId) async {
  await db.customStatement(
    'INSERT INTO player_inventory (player_id, item_key, acquired_at, '
    "acquired_via, evolution_stage) VALUES (?, 'COLLAR_GUILD', 0, "
    "'quest_reward', 'stage_E')",
    [playerId],
  );
}

Future<Map<String, dynamic>?> _state(
    AppDatabase db, int playerId, String rank) async {
  final rows = await db.customSelect(
    'SELECT status, failures, attempts, paid_cost AS pc, '
    'window_deadline_ms AS dl, cooldown_until_ms AS cd '
    'FROM guild_ascension_state WHERE player_id = ? AND rank_from = ?',
    variables: [Variable.withInt(playerId), Variable.withString(rank)],
  ).get();
  if (rows.isEmpty) return null;
  final r = rows.first;
  return {
    'status': r.read<String>('status'),
    'failures': r.read<int>('failures'),
    'attempts': r.read<int>('attempts'),
    'paid_cost': r.read<int>('pc'),
    'deadline': r.data['dl'] as int?,
    'cooldown': r.data['cd'] as int?,
  };
}

Future<int> _gold(AppDatabase db, int playerId) async {
  final r = await db.customSelect('SELECT gold FROM players WHERE id = ?',
      variables: [Variable.withInt(playerId)]).getSingle();
  return r.read<int>('gold');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  late GuildAscensionService guildAsc;
  late AscensionService svc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    guildAsc = GuildAscensionService(db);
    svc = AscensionService(
      db: db,
      bus: bus,
      resolver: RewardResolveService(ItemsCatalogService(db)),
      ascension: guildAsc,
      resolvePlayer: (pid) async {
        final row = await (db.select(db.playersTable)
              ..where((t) => t.id.equals(pid)))
            .getSingle();
        return PlayerSnapshot(
          level: row.level,
          rank: GuildRankSystem.fromString(row.guildRank),
          classKey: row.classType,
          factionKey: row.factionType,
        );
      },
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('evaluateGates', () {
    test('gates não atingidos → locked; atingidos → payable', () async {
      final p = await _seedPlayer(db, level: 1, guildRank: 'E');
      expect((await svc.evaluateGates(p, 'E')).state,
          AscensionViewState.locked);

      // Atinge os gates.
      await db.customStatement(
        'UPDATE players SET level = 15, total_quests_completed = 150, '
        'total_gold_earned_lifetime = 20000 WHERE id = ?',
        [p],
      );
      expect((await svc.evaluateGates(p, 'E')).state,
          AscensionViewState.payable);
    });

    test('cadeia sequencial: só o rank atual é elegível', () async {
      // Player rank D, todos os números altos.
      final p = await _seedPlayer(db,
          level: 30, missions: 500, goldLifetime: 100000, guildRank: 'D');
      // Avaliar o ciclo E→D NÃO é elegível (rank atual != E).
      expect((await svc.evaluateGates(p, 'E')).state,
          AscensionViewState.locked);
      // O ciclo D→C (rank atual == D) é payable.
      expect((await svc.evaluateGates(p, 'D')).state,
          AscensionViewState.payable);
    });

    test('card_wins é mock-satisfeito (gate sempre met)', () async {
      final p = await _seedEligible(db);
      final view = await svc.evaluateGates(p, 'E');
      final cardGate = view.gates.firstWhere((g) => g.key == 'card_wins');
      expect(cardGate.met, isTrue);
    });

    test('current_cost infla 1.1^failures', () async {
      final p = await _seedEligible(db);
      // Injeta state com 2 falhas (status idle).
      await db.customStatement(
        'INSERT INTO guild_ascension_state (player_id, rank_from, attempts, '
        "failures, paid_cost, status) VALUES (?, 'E', 1, 2, 0, 'idle')",
        [p],
      );
      // 5000 * 1.21 = 6050.
      expect((await svc.evaluateGates(p, 'E')).currentCost, 6050);
    });

    test('cooldown expirado → payable', () async {
      final p = await _seedEligible(db);
      final past = DateTime.now().millisecondsSinceEpoch - 1000;
      await db.customStatement(
        'INSERT INTO guild_ascension_state (player_id, rank_from, attempts, '
        "failures, paid_cost, cooldown_until_ms, status) "
        "VALUES (?, 'E', 1, 1, 5000, ?, 'cooldown')",
        [p, past],
      );
      expect((await svc.evaluateGates(p, 'E')).state,
          AscensionViewState.payable);
    });
  });

  group('pay', () {
    test('debita ouro, abre janela, materializa trials', () async {
      final p = await _seedEligible(db, gold: 10000);
      final res = await svc.pay(p, 'E');
      expect(res.ok, isTrue);
      expect(res.cost, 5000);
      expect(await _gold(db, p), 5000);
      final st = await _state(db, p, 'E');
      expect(st!['status'], 'active');
      expect(st['deadline'], isNotNull);
      expect(st['attempts'], 1);
      // Trials materializados (E→D tem 1).
      final trials = await guildAsc.getMissions(p, 'E');
      expect(trials, hasLength(1));
    });

    test('saldo insuficiente → rejeita, não debita, não abre janela',
        () async {
      final p = await _seedEligible(db, gold: 100);
      final res = await svc.pay(p, 'E');
      expect(res.ok, isFalse);
      expect(res.reason, 'insufficient_gold');
      expect(await _gold(db, p), 100);
      expect(await _state(db, p, 'E'), isNull);
    });

    test('não-payable (gates não OK) → rejeita', () async {
      final p = await _seedPlayer(db, level: 1, gold: 10000, guildRank: 'E');
      final res = await svc.pay(p, 'E');
      expect(res.ok, isFalse);
      expect(res.reason, 'not_payable');
    });
  });

  group('checkDeadline', () {
    test('janela vencida + trials incompletos → cooldown + reset', () async {
      final p = await _seedEligible(db, gold: 10000);
      await svc.pay(p, 'E');
      // Força a janela pro passado.
      await db.customStatement(
        'UPDATE guild_ascension_state SET window_deadline_ms = ? '
        'WHERE player_id = ? AND rank_from = ?',
        [DateTime.now().millisecondsSinceEpoch - 1000, p, 'E'],
      );
      expect(await guildAsc.getMissions(p, 'E'), isNotEmpty);

      await svc.checkDeadline(p, 'E');

      final st = await _state(db, p, 'E');
      expect(st!['status'], 'cooldown');
      expect(st['failures'], 1);
      expect(st['cooldown'], isNotNull);
      // Trials resetados.
      expect(await guildAsc.getMissions(p, 'E'), isEmpty);
    });

    test('janela ainda válida → não faz nada', () async {
      final p = await _seedEligible(db, gold: 10000);
      await svc.pay(p, 'E');
      await svc.checkDeadline(p, 'E');
      final st = await _state(db, p, 'E');
      expect(st!['status'], 'active');
      expect(st['failures'], 0);
    });
  });

  group('ascend', () {
    Future<int> setupActiveComplete(AppDatabase db, AscensionService svc,
        GuildAscensionService guildAsc) async {
      final p = await _seedEligible(db, gold: 10000);
      await _seedCollar(db, p);
      await svc.pay(p, 'E'); // status active + trials
      // Completa todos os trials (E→D tem 1).
      await db.customStatement(
        'UPDATE guild_ascension_progress SET completed = 1 '
        'WHERE player_id = ? AND rank_from = ?',
        [p, 'E'],
      );
      return p;
    }

    test('credita reward + sobe rank + evolui colar + status done', () async {
      final p = await setupActiveComplete(db, svc, guildAsc);
      final goldBefore = await _gold(db, p);

      final res = await svc.ascend(p, 'E');
      expect(res.ok, isTrue);
      expect(res.newRank, 'D');

      // Rank subiu.
      final pr = await db.customSelect(
          'SELECT guild_rank AS gr, insignias AS ins FROM players WHERE id = ?',
          variables: [Variable.withInt(p)]).getSingle();
      expect(pr.read<String>('gr'), 'D');
      // Reward: gold creditado (>before) + insígnias fixas (50).
      expect(await _gold(db, p), greaterThan(goldBefore));
      expect(pr.read<int>('ins'), 50);
      // Colar evoluiu E→D.
      final col = await db.customSelect(
          'SELECT evolution_stage AS es FROM player_inventory '
          "WHERE player_id = ? AND item_key = 'COLLAR_GUILD'",
          variables: [Variable.withInt(p)]).getSingle();
      expect(col.read<String>('es'), 'stage_D');
      // Status done.
      expect((await _state(db, p, 'E'))!['status'], 'done');
    });

    test('idempotente: 2º ascend = no-op (sem duplo crédito)', () async {
      final p = await setupActiveComplete(db, svc, guildAsc);
      await svc.ascend(p, 'E');
      final goldAfter1 = await _gold(db, p);

      final res2 = await svc.ascend(p, 'E');
      expect(res2.ok, isFalse);
      expect(await _gold(db, p), goldAfter1, reason: 'sem re-crédito');
    });

    test('trials incompletos → rejeita', () async {
      final p = await _seedEligible(db, gold: 10000);
      await svc.pay(p, 'E'); // trials criados mas não completados
      final res = await svc.ascend(p, 'E');
      expect(res.ok, isFalse);
      expect(res.reason, 'trials_incomplete');
    });

    test('reward de ascensão NÃO conta como ouro-via-quests', () async {
      // QuestRewardStatsService ligado no mesmo bus — deve IGNORAR o
      // RewardGranted(fromAscension:true) emitido pelo ascend.
      final stats = QuestRewardStatsService(db: db, bus: bus);
      await stats.start();
      try {
        final p = await setupActiveComplete(db, svc, guildAsc);
        final res = await svc.ascend(p, 'E');
        expect(res.ok, isTrue);
        // Deixa a entrega assíncrona do bus rodar.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        final r = await db.customSelect(
            'SELECT total_gold_earned_via_quests AS vq FROM players WHERE id = ?',
            variables: [Variable.withInt(p)]).getSingle();
        expect(r.read<int>('vq'), 0,
            reason: 'ascensão não polui total_gold_earned_via_quests');
      } finally {
        await stats.stop();
      }
    });
  });
}
