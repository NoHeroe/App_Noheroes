import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/faction_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/class_quest_service.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/quest_admission_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_achievements_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/data/services/reward_grant_service.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/models/reward_resolved.dart';

Future<int> _seedPlayer(AppDatabase db) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp, total_quests_completed) "
    "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0)",
    variables: [
      Variable.withString('r@t.com'),
      Variable.withString('h'),
    ],
  );
}

Future<int> _seedFactionMission(
  AppDatabase db, {
  required int playerId,
  int xp = 300,
  int gold = 150,
}) async {
  final repo = MissionRepositoryDrift(db);
  return repo.insert(MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: 'FACTION_TEST',
    modality: MissionModality.internal,
    tabOrigin: MissionTabOrigin.faction,
    rank: GuildRank.e,
    targetValue: 1,
    currentValue: 0,
    reward: RewardDeclared(xp: xp, gold: gold),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: '{}',
  ));
}

RewardGrantService _makeGranter(AppDatabase db, AppEventBus bus) {
  final catalog = ItemsCatalogService(db);
  return RewardGrantService(
    db: db,
    missionRepo: MissionRepositoryDrift(db),
    achievementsRepo: PlayerAchievementsRepositoryDrift(db),
    inventory: PlayerInventoryService(db, catalog),
    recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
    factionRep: PlayerFactionReputationRepositoryDrift(db),
    eventBus: bus,
  );
}

void main() {
  late AppDatabase db;
  late AppEventBus bus;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('regression(bug1): XP/gold creditados em faction quest', () {
    test('grant de faction mission credita XP + gold no players', () async {
      final playerId = await _seedPlayer(db);
      final missionId = await _seedFactionMission(db, playerId: playerId);
      final granter = _makeGranter(db, bus);

      await granter.grant(
        missionProgressId: missionId,
        playerId: playerId,
        resolved: const RewardResolved(xp: 120, gold: 52),
      );

      final row = await db.customSelect(
          'SELECT xp, gold, level FROM players WHERE id = ?',
          variables: [Variable.withInt(playerId)]).getSingle();
      // Sprint 3.1 Bloco 14.5 — RewardGrantService agora usa
      // PlayerDao.addXp que recalcula level/xp. Com xpToNext=100 no
      // seed, +120 XP triggera level up: level 1 → 2, xp remainder = 20.
      // Bug 1 do 7b era "XP não credita em faction quest" — continua
      // fechado (XP total creditado foi 120, só foi consumido no level).
      final newLevel = row.data['level'] as int;
      final newXp = row.data['xp'] as int;
      expect(newLevel, greaterThan(1),
          reason: 'bug 1 fechado: grant credita XP e aciona level up');
      expect(newXp, 20,
          reason: 'xp remainder após level up = 120 - 100(xpToNext L1) = 20');
      expect(row.data['gold'], 52,
          reason: 'bug 1 fechado: faction quest credita gold');
    });
  });

  group('regression(bug2): MissionContext tem todos os campos preenchidos',
      () {
    test('MissionProgress → MissionContext preserva campos críticos',
        () async {
      final playerId = await _seedPlayer(db);
      final missionId = await _seedFactionMission(db, playerId: playerId);
      final repo = MissionRepositoryDrift(db);

      final loaded = await repo.findById(missionId);
      // Campos que no legacy vinham null / vazio no ctx antigo.
      expect(loaded, matcherIsNotNull);
      expect(loaded!.playerId, playerId);
      expect(loaded.missionKey, 'FACTION_TEST');
      expect(loaded.modality, MissionModality.internal);
      expect(loaded.tabOrigin, MissionTabOrigin.faction);
      expect(loaded.rank, GuildRank.e);
      expect(loaded.targetValue, 1);
      expect(loaded.reward.xp, 300);
      expect(loaded.reward.gold, 150);
      expect(loaded.metaJson, '{}');
    });
  });

  group('regression(bug4): totalQuestsCompleted incrementa 1x por grant',
      () {
    test('grant único → contador += 1 (não 2)', () async {
      final playerId = await _seedPlayer(db);
      final missionId = await _seedFactionMission(db, playerId: playerId);
      final granter = _makeGranter(db, bus);

      await granter.grant(
        missionProgressId: missionId,
        playerId: playerId,
        resolved: const RewardResolved(xp: 100, gold: 50),
      );

      final row = await db.customSelect(
          'SELECT total_quests_completed AS c FROM players WHERE id = ?',
          variables: [Variable.withInt(playerId)]).getSingle();
      expect(row.data['c'], 1,
          reason: 'bug 4 fechado: incrementa 1x por grant bem-sucedido');
    });

    test('3 missões completadas → contador = 3 (não duplicação)', () async {
      final playerId = await _seedPlayer(db);
      final granter = _makeGranter(db, bus);

      for (var i = 0; i < 3; i++) {
        final id = await _seedFactionMission(db, playerId: playerId);
        await granter.grant(
          missionProgressId: id,
          playerId: playerId,
          resolved: const RewardResolved(xp: 10),
        );
      }

      final row = await db.customSelect(
          'SELECT total_quests_completed AS c FROM players WHERE id = ?',
          variables: [Variable.withInt(playerId)]).getSingle();
      expect(row.data['c'], 3);
    });

    test('retry grant na mesma missão NÃO incrementa 2x (idempotência)',
        () async {
      final playerId = await _seedPlayer(db);
      final missionId = await _seedFactionMission(db, playerId: playerId);
      final granter = _makeGranter(db, bus);

      await granter.grant(
        missionProgressId: missionId,
        playerId: playerId,
        resolved: const RewardResolved(xp: 10),
      );

      // 2ª tentativa lança (Bloco 5 idempotência).
      try {
        await granter.grant(
          missionProgressId: missionId,
          playerId: playerId,
          resolved: const RewardResolved(xp: 10),
        );
      } catch (_) {
        // esperado
      }

      final row = await db.customSelect(
          'SELECT total_quests_completed AS c FROM players WHERE id = ?',
          variables: [Variable.withInt(playerId)]).getSingle();
      expect(row.data['c'], 1,
          reason: 'contador não incrementa em grant duplicado');
    });
  });

  group('QuestAdmissionService — fluxo ClassSelected + FactionJoined', () {
    test('startClassQuests emite ClassSelected com playerId + classId',
        () async {
      final playerId = await _seedPlayer(db);
      final service = QuestAdmissionService(
        db,
        MissionRepositoryDrift(db),
        ClassQuestService(MissionRepositoryDrift(db)),
        bus,
      );

      ClassSelected? captured;
      final sub = bus.on<ClassSelected>().listen((e) => captured = e);

      await service.startClassQuests(playerId, 'warrior');
      await pumpEventQueue();

      expect(captured, matcherIsNotNull);
      expect(captured!.playerId, playerId);
      expect(captured!.classId, 'warrior');

      await sub.cancel();
    });

    test('startClassQuests persiste classe no DB', () async {
      final playerId = await _seedPlayer(db);
      final service = QuestAdmissionService(
        db,
        MissionRepositoryDrift(db),
        ClassQuestService(MissionRepositoryDrift(db)),
        bus,
      );

      await service.startClassQuests(playerId, 'mage');

      final row = await db.customSelect(
          'SELECT class_type AS c FROM players WHERE id = ?',
          variables: [Variable.withInt(playerId)]).getSingle();
      expect(row.data['c'], 'mage');
    });

    // Sprint 3.4 Sub-Etapa B.2 — `checkFactionAdmission` foi removido
    // do QuestAdmissionService. A lógica de "verificar se admissão
    // concluiu + promover faction_type + emitir FactionJoined" agora
    // vive no `FactionAdmissionProgressService` (listener), que é
    // testado diretamente em `faction_admission_progress_service_test.
    // dart`. Os 2 testes de regressão antigos foram movidos pra
    // contemplar o novo flow lá; aqui ficam removidos pra evitar
    // duplicação + manter contagem de testes válida.
  });
}

const matcherIsNotNull = isNotNull;
