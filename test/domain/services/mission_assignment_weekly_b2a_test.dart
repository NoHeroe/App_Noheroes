import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/mission_catalogs_service.dart';
import 'package:noheroes_app/data/repositories/drift/active_faction_quests_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/services/mission_assignment_service.dart';

/// FATIA B2a — loader per-facção + assign embutindo sub_tasks/janela/
/// reward no metaJson.

class _FakeBundle extends AssetBundle {
  final Map<String, String> contents;
  _FakeBundle(this.contents);

  @override
  Future<ByteData> load(String key) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(s)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return s;
  }
}

/// Catálogo per-facção de teste — FATIA B4: SEM rank/reward (vêm do
/// assign). moon com 2 missões (gold_earned pra provar baseline+escala).
String _weeklyJson() => jsonEncode({
      '_doc': 'fixture',
      'moon_clan': [
        {
          'id': 'WK_MOON_1',
          'title': 'Vigília Lunar',
          'description': 'desc',
          'sub_tasks': [
            {
              'sub_type': 'modality_count_window',
              'target': 4,
              'params': {'modalidade': 'mental'},
              'label': '4 mentais'
            },
            {
              'sub_type': 'gold_earned_via_quests_window',
              'target': 400,
              'label': 'Ouro ganho via quests na semana'
            },
          ],
        },
      ],
    });

Future<int> _seedPlayer(AppDatabase db) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp) "
    "VALUES (?, ?, 'S', 5, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
    ],
  );
}

void main() {
  // A migração do AppDatabase semeia catálogos via rootBundle (assets),
  // que exige o binding inicializado — senão falha em batch com outros
  // test files ("Binding has not yet been initialized").
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  late MissionRepositoryDrift missionRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    missionRepo = MissionRepositoryDrift(db);
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  MissionAssignmentService makeService() {
    return MissionAssignmentService(
      missionRepo: missionRepo,
      catalogs: MissionCatalogsService(
        bundle: _FakeBundle({
          'assets/data/missions_faction_weekly.json': _weeklyJson(),
        }),
      ),
      factionRepo: ActiveFactionQuestsRepositoryDrift(db),
      bus: bus,
      random: Random(42),
    );
  }

  // ─── 1. LOADER ─────────────────────────────────────────────────────

  group('loadFactionWeekly (per-facção)', () {
    test('lê a lista da facção pedida', () async {
      final catalogs = MissionCatalogsService(
        bundle: _FakeBundle({
          'assets/data/missions_faction_weekly.json': _weeklyJson(),
        }),
      );
      final pool = await catalogs.loadFactionWeekly('moon_clan');
      expect(pool.length, 1);
      expect(pool.single['id'], 'WK_MOON_1');
      expect((pool.single['sub_tasks'] as List).length, 2);
    });

    test('facção sem pool no JSON → []', () async {
      final catalogs = MissionCatalogsService(
        bundle: _FakeBundle({
          'assets/data/missions_faction_weekly.json': _weeklyJson(),
        }),
      );
      expect(await catalogs.loadFactionWeekly('lone_wolf'), isEmpty);
      expect(await catalogs.loadFactionWeekly('sun_clan'), isEmpty);
    });

    test('asset ausente → []', () async {
      final catalogs =
          MissionCatalogsService(bundle: _FakeBundle(const {}));
      expect(await catalogs.loadFactionWeekly('moon_clan'), isEmpty);
    });
  });

  // ─── 2. ASSIGN — metaJson rico ─────────────────────────────────────

  group('ensureWeeklyFactionQuest — metaJson rico', () {
    test('embute sub_tasks (current 0/completed false) + janela + reward '
        '+ baseline', () async {
      final playerId = await _seedPlayer(db);
      final service = makeService();
      // Quarta-feira 2026-06-10 15:30 → semana começa segunda 2026-06-08.
      final now = DateTime(2026, 6, 10, 15, 30);

      final progressId = await service.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: 'moon_clan',
        playerRank: GuildRank.e,
        baselineGoldEarned: 777,
        now: now,
      );
      expect(progressId, isNotNull);

      final mission = await missionRepo.findById(progressId!);
      expect(mission, isNotNull);
      final meta = jsonDecode(mission!.metaJson) as Map<String, dynamic>;

      // Identidade.
      expect(meta['faction_id'], 'moon_clan');
      expect(meta['mission_id'], 'WK_MOON_1');
      expect(meta['title'], 'Vigília Lunar');
      expect(meta['rank'], 'e');

      // Janela: segunda 00:00 → +7d.
      final ws = meta['week_start_ms'] as int;
      final we = meta['week_end_ms'] as int;
      expect(we - ws, 7 * 24 * 60 * 60 * 1000);
      final wsDate = DateTime.fromMillisecondsSinceEpoch(ws);
      expect(wsDate.weekday, DateTime.monday);
      expect(wsDate.hour, 0);
      expect(wsDate.minute, 0);
      expect(wsDate.day, 8);
      expect(wsDate.month, 6);

      // Sub-tasks: current 0 / completed false.
      final subs = (meta['sub_tasks'] as List).cast<Map<String, dynamic>>();
      expect(subs.length, 2);
      for (final s in subs) {
        expect(s['current'], 0);
        expect(s['completed'], false);
        expect(s['label'], isA<String>());
      }

      // Baseline injetado SÓ na sub-task de ouro; target BASE × mult E
      // (1.0) = 400; label reconstruído.
      final gold = subs.firstWhere(
          (s) => s['sub_type'] == 'gold_earned_via_quests_window');
      expect((gold['params'] as Map)['baseline_gold_via_quests'], 777);
      expect(gold['target'], 400, reason: 'rank E mult 1.0');
      expect(gold['label'], '400 ouro ganho via quests na semana');
      final modal = subs.firstWhere(
          (s) => s['sub_type'] == 'modality_count_window');
      expect((modal['params'] as Map)['modalidade'], 'mental');
      expect((modal['params'] as Map).containsKey('baseline_gold_via_quests'),
          isFalse);

      // FATIA B4 — reward vem da CURVA por guild-rank (E: 15/100/50).
      final reward = meta['reward'] as Map<String, dynamic>;
      expect(reward['xp'], 100);
      expect(reward['gold'], 50);
      expect(reward['insignias'], 15);

      // target_value = nº de sub-tasks (header N/M).
      expect(mission.targetValue, 2);

      // reward_json espelha a reward da curva (insígnias via Fatia A).
      expect(mission.reward.insignias, 15);
    });

    test('FATIA B4 — Rank E RECEBE a missão (rank gating removido)',
        () async {
      final playerId = await _seedPlayer(db);
      final service = makeService();
      // Player Rank E + catálogo sem rank `e` → ANTES retornava null.
      final id = await service.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: 'moon_clan',
        playerRank: GuildRank.e,
      );
      expect(id, isNotNull, reason: 'Rank E agora recebe a semanal');
    });

    test('FATIA B4 — reward e gold-target escalam por guild-rank (D)',
        () async {
      final playerId = await _seedPlayer(db);
      final service = makeService();
      final id = await service.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: 'moon_clan',
        playerRank: GuildRank.d,
        baselineGoldEarned: 0,
        now: DateTime(2026, 6, 10, 15, 30),
      );
      final mission = await missionRepo.findById(id!);
      final meta = jsonDecode(mission!.metaJson) as Map<String, dynamic>;

      expect(meta['rank'], 'd');
      final reward = meta['reward'] as Map<String, dynamic>;
      expect(reward['xp'], 150, reason: 'curva D');
      expect(reward['gold'], 75);
      expect(reward['insignias'], 22);

      final subs = (meta['sub_tasks'] as List).cast<Map<String, dynamic>>();
      final gold = subs.firstWhere(
          (s) => s['sub_type'] == 'gold_earned_via_quests_window');
      // 400 BASE × mult D (1.3) = 520.
      expect(gold['target'], 520);
      expect(gold['label'], '520 ouro ganho via quests na semana');
    });

    test('idempotente: 2x na mesma semana → 1 row (mesmo progressId)',
        () async {
      final playerId = await _seedPlayer(db);
      final service = makeService();
      final now = DateTime(2026, 6, 10, 15, 30);

      final id1 = await service.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: 'moon_clan',
        playerRank: GuildRank.e,
        now: now,
      );
      final id2 = await service.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: 'moon_clan',
        playerRank: GuildRank.e,
        now: now,
      );
      expect(id1, isNotNull);
      expect(id1, id2, reason: 'UNIQUE (player, faction, week_start)');

      // Só 1 row de faction ativa.
      final rows = await db.customSelect(
        "SELECT COUNT(*) AS c FROM player_mission_progress "
        "WHERE player_id = ? AND tab_origin = 'faction'",
        variables: [Variable.withInt(playerId)],
      ).get();
      expect(rows.first.read<int>('c'), 1);
    });

    test('facção sem pool → null (nada criado)', () async {
      final playerId = await _seedPlayer(db);
      final service = makeService();
      final id = await service.ensureWeeklyFactionQuest(
        playerId: playerId,
        factionKey: 'lone_wolf',
        playerRank: GuildRank.e,
      );
      expect(id, isNull);
    });
  });
}
