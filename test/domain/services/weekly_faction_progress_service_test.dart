import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/crafting_events.dart';
import 'package:noheroes_app/core/events/daily_mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_achievements_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/data/services/reward_grant_service.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';
import 'package:noheroes_app/domain/services/weekly_faction_progress_service.dart';
import 'package:noheroes_app/domain/services/weekly_faction_validator.dart';

/// FATIA B2b — testes do `WeeklyFactionProgressService` (acumulativo).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  late MissionRepositoryDrift missionRepo;
  late WeeklyFactionProgressService service;
  late int playerId;

  const weekStart = 10000;
  const weekEnd = 20000;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    missionRepo = MissionRepositoryDrift(db);

    playerId = await db.customInsert(
      "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
      "xp_to_next, gold, gems, strength, dexterity, intelligence, "
      "constitution, spirit, charisma, attribute_points, shadow_corruption, "
      "vitalism_level, vitalism_xp) "
      "VALUES (?, ?, 'S', 5, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
      variables: [Variable.withString('p@t'), Variable.withString('h')],
    );

    final catalog = ItemsCatalogService(db);
    final granter = RewardGrantService(
      db: db,
      missionRepo: missionRepo,
      achievementsRepo: PlayerAchievementsRepositoryDrift(db),
      inventory: PlayerInventoryService(db, catalog),
      recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
      factionRep: PlayerFactionReputationRepositoryDrift(db),
      eventBus: bus,
    );

    service = WeeklyFactionProgressService(
      db: db,
      bus: bus,
      validator: WeeklyFactionValidator(db),
      missionRepo: missionRepo,
      resolver: RewardResolveService(catalog),
      granter: granter,
      resolvePlayer: (_) async =>
          const PlayerSnapshot(level: 5, rank: GuildRank.e),
    );
    service.start();
  });

  tearDown(() async {
    await service.stop();
    await bus.dispose();
    await db.close();
  });

  // ─── fixtures ──────────────────────────────────────────────────────

  Map<String, dynamic> meta({
    required List<Map<String, dynamic>> subs,
    Map<String, dynamic> reward = const {'xp': 50, 'gold': 150, 'insignias': 50},
  }) =>
      {
        'faction_id': 'moon_clan',
        'mission_id': 'WK_MOON_1',
        'title': 't',
        'description': 'd',
        'rank': 'd',
        'week_start_ms': weekStart,
        'week_end_ms': weekEnd,
        'sub_tasks': subs,
        'reward': reward,
      };

  Future<int> insertWeekly(Map<String, dynamic> m) {
    return missionRepo.insert(MissionProgress(
      id: 0,
      playerId: playerId,
      missionKey: m['mission_id'] as String,
      modality: MissionModality.internal,
      tabOrigin: MissionTabOrigin.faction,
      rank: GuildRank.d,
      targetValue: (m['sub_tasks'] as List).length,
      currentValue: 0,
      reward: RewardDeclared.fromJson(
          (m['reward'] as Map).cast<String, dynamic>()),
      startedAt: DateTime.now(),
      rewardClaimed: false,
      metaJson: jsonEncode(m),
    ));
  }

  Future<void> insertDaily({
    required int id,
    required String modalidade,
    required String status,
    required int completedAt,
    String data = 'D',
  }) async {
    await db.customStatement(
      "INSERT INTO daily_missions (id, player_id, data, modalidade, "
      " titulo_key, titulo_resolvido, quote_resolvida, sub_tarefas_json, "
      " status, created_at, completed_at) "
      "VALUES (?, ?, ?, ?, 'k', 't', 'q', '[]', ?, 0, ?)",
      [id, playerId, data, modalidade, status, completedAt],
    );
  }

  Future<List<Map<String, dynamic>>> subsOf(int missionId) async {
    final mp = await missionRepo.findById(missionId);
    final m = jsonDecode(mp!.metaJson) as Map<String, dynamic>;
    return (m['sub_tasks'] as List).cast<Map<String, dynamic>>();
  }

  Future<int> readCol(String col) async {
    final rows = await db.customSelect(
      'SELECT $col AS v FROM players WHERE id = ?',
      variables: [Variable.withInt(playerId)],
    ).get();
    return rows.single.read<int>('v');
  }

  // ─── 1. DailyMissionCompleted → modality_count avança/completa ─────

  test('modality_count avança e completa ao bater target', () async {
    final mid = await insertWeekly(meta(subs: [
      {'sub_type': 'modality_count_window', 'target': 2, 'current': 0,
       'completed': false, 'label': '2 quaisquer'},
      {'sub_type': 'diary_entry_window', 'target': 5, 'current': 0,
       'completed': false, 'label': '5 diário'},
    ]));
    await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 11000);
    await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 12000);

    await service.evaluatePlayer(playerId);
    await service.settle();

    final subs = await subsOf(mid);
    expect(subs[0]['completed'], true, reason: 'modality_count completou');
    expect(subs[1]['completed'], false, reason: 'diary ainda não');
    final mp = await missionRepo.findById(mid);
    expect(mp!.completedAt, isNull, reason: 'missão ainda ativa (nem tudo)');
  });

  // ─── 2. DiaryEntryCreated → diary avança ──────────────────────────

  test('diary_entry avança', () async {
    final mid = await insertWeekly(meta(subs: [
      {'sub_type': 'diary_entry_window', 'target': 2, 'current': 0,
       'completed': false, 'label': '2 diário'},
      {'sub_type': 'modality_count_window', 'target': 99, 'current': 0,
       'completed': false, 'label': 'inatingível'},
    ]));
    // entry_date em segundos: weekStart=10000ms=10s, weekEnd=20000ms=20s.
    await db.customStatement(
      "INSERT INTO diary_entries (player_id, content, entry_date) VALUES (?,?,?)",
      [playerId, 'e', 12],
    );
    await db.customStatement(
      "INSERT INTO diary_entries (player_id, content, entry_date) VALUES (?,?,?)",
      [playerId, 'e', 15],
    );

    await service.evaluatePlayer(playerId);
    await service.settle();

    final subs = await subsOf(mid);
    expect(subs[0]['completed'], true);
  });

  // ─── 3. gold_earned respeita o baseline ───────────────────────────

  test('gold_earned_via_quests respeita o baseline gravado', () async {
    final mid = await insertWeekly(meta(subs: [
      {'sub_type': 'gold_earned_via_quests_window', 'target': 400,
       'params': {'baseline_gold_via_quests': 1000}, 'current': 0,
       'completed': false, 'label': '400 ouro'},
      {'sub_type': 'modality_count_window', 'target': 99, 'current': 0,
       'completed': false, 'label': 'inatingível'},
    ]));

    // 1300 - 1000 = 300 < 400 → não completa.
    await db.customStatement(
      "UPDATE players SET total_gold_earned_via_quests = 1300 WHERE id = ?",
      [playerId],
    );
    await service.evaluatePlayer(playerId);
    await service.settle();
    expect((await subsOf(mid))[0]['completed'], false, reason: '300 < 400');

    // 1500 - 1000 = 500 >= 400 → completa.
    await db.customStatement(
      "UPDATE players SET total_gold_earned_via_quests = 1500 WHERE id = ?",
      [playerId],
    );
    await service.evaluatePlayer(playerId);
    await service.settle();
    expect((await subsOf(mid))[0]['completed'], true, reason: '500 >= 400');
  });

  // ─── 4. equipment_improved incrementa (+1/evento) e completa ───────

  test('equipment_improved +1 por evento; completa ao bater target', () async {
    final mid = await insertWeekly(meta(subs: [
      {'sub_type': 'equipment_improved', 'target': 2, 'current': 0,
       'completed': false, 'label': 'melhorar 2'},
      {'sub_type': 'modality_count_window', 'target': 99, 'current': 0,
       'completed': false, 'label': 'inatingível'},
    ]));

    await service.registerEquipmentImprovement(playerId);
    await service.settle();
    var subs = await subsOf(mid);
    expect(subs[0]['current'], 1);
    expect(subs[0]['completed'], false, reason: '1 < 2');

    await service.registerEquipmentImprovement(playerId);
    await service.settle();
    subs = await subsOf(mid);
    expect(subs[0]['current'], 2);
    expect(subs[0]['completed'], true, reason: '2 >= 2');
  });

  test('ItemCrafted/ItemEnchanted via bus incrementam equipment', () async {
    final mid = await insertWeekly(meta(subs: [
      {'sub_type': 'equipment_improved', 'target': 2, 'current': 0,
       'completed': false, 'label': 'melhorar 2'},
      {'sub_type': 'modality_count_window', 'target': 99, 'current': 0,
       'completed': false, 'label': 'inatingível'},
    ]));

    bus.publish(ItemCrafted(playerId: playerId, itemKey: 'X', recipeKey: 'R'));
    bus.publish(ItemEnchanted(playerId: playerId, itemKey: 'X', runeKey: 'RUNE'));
    await pumpEventQueue();
    await service.settle();

    final subs = await subsOf(mid);
    expect(subs[0]['current'], 2, reason: '1 craft + 1 enchant');
    expect(subs[0]['completed'], true);
  });

  // ─── 5. conclusão antecipada paga reward CHEIO ────────────────────

  test('conclusão antecipada: reward cheio creditado (xp/gold/insígnias) '
      '+ markCompleted', () async {
    final mid = await insertWeekly(meta(
      subs: [
        {'sub_type': 'modality_count_window', 'target': 2, 'current': 0,
         'completed': false, 'label': '2 quaisquer'},
      ],
      reward: const {'xp': 50, 'gold': 150, 'insignias': 50},
    ));
    await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 11000);
    await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 12000);

    await service.evaluatePlayer(playerId);
    await pumpEventQueue();
    await service.settle();

    // Reward: xp 50×0.4=20; gold round(150×0.35)=53; insígnias 50 (fixo).
    expect(await readCol('xp'), 20);
    expect(await readCol('gold'), 53);
    expect(await readCol('insignias'), 50);

    final mp = await missionRepo.findById(mid);
    expect(mp!.completedAt, isNotNull, reason: 'markCompleted');
    expect(mp.rewardClaimed, isTrue);
  });

  // ─── 6. idempotência: re-emitir após completa NÃO re-credita ──────

  test('idempotência: re-avaliar após completa não re-credita', () async {
    await insertWeekly(meta(
      subs: [
        {'sub_type': 'modality_count_window', 'target': 2, 'current': 0,
         'completed': false, 'label': '2 quaisquer'},
      ],
      reward: const {'xp': 50, 'gold': 150, 'insignias': 50},
    ));
    await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 11000);
    await insertDaily(id: 2, modalidade: 'mental', status: 'completed', completedAt: 12000);

    await service.evaluatePlayer(playerId);
    await pumpEventQueue();
    await service.settle();
    expect(await readCol('insignias'), 50);

    // Re-avalia várias vezes — missão já completa → não re-paga.
    await service.evaluatePlayer(playerId);
    await service.evaluatePlayer(playerId);
    await pumpEventQueue();
    await service.settle();
    expect(await readCol('insignias'), 50, reason: 'sem double-credit');
  });

  // ─── 7. DailyMissionFailed NÃO rejeita ────────────────────────────

  test('DailyMissionFailed NÃO rejeita (missão segue ativa)', () async {
    final mid = await insertWeekly(meta(subs: [
      {'sub_type': 'modality_count_window', 'target': 2, 'current': 0,
       'completed': false, 'label': '2 quaisquer'},
    ]));

    bus.publish(DailyMissionFailed(
        playerId: playerId, missionId: 1, reason: 'expired'));
    await pumpEventQueue();
    await service.settle();

    final mp = await missionRepo.findById(mid);
    expect(mp!.failedAt, isNull, reason: 'acumulativo nunca reprova');
    expect(mp.completedAt, isNull);
  });

  // ─── wiring: DailyMissionCompleted via bus ────────────────────────

  test('wiring: DailyMissionCompleted no bus dispara avaliação', () async {
    final mid = await insertWeekly(meta(subs: [
      {'sub_type': 'modality_count_window', 'target': 1, 'current': 0,
       'completed': false, 'label': '1 qualquer'},
      {'sub_type': 'diary_entry_window', 'target': 9, 'current': 0,
       'completed': false, 'label': 'inatingível'},
    ]));
    await insertDaily(id: 1, modalidade: 'fisico', status: 'completed', completedAt: 11000);

    bus.publish(DailyMissionCompleted(
      playerId: playerId,
      missionId: 1,
      modalidade: MissionCategory.fisico,
      fullCompleted: true,
      partial: false,
    ));
    await pumpEventQueue();
    await service.settle();

    expect((await subsOf(mid))[0]['completed'], true);
  });
}
