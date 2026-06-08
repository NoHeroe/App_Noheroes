import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/reward_events.dart';
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
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/models/reward_resolved.dart';
import 'package:noheroes_app/domain/services/faction_buff_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

/// FATIA A — Insígnias (moeda de facção) no pipeline de reward.
///
/// Cobre o caminho fim-a-fim: declarado → resolvido → concedido.
/// Invariante central: insígnias é **valor fixo** — NÃO sofre a fórmula
/// 0-300% nem os multiplicadores SOULSLIKE, e NÃO é bufada pelos
/// multiplicadores de facção (diferente de xp/gold/gems).

Future<int> _seedPlayer(AppDatabase db) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, constitution, "
    "spirit, charisma, attribute_points, shadow_corruption, vitalism_level, "
    "vitalism_xp) "
    "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
    variables: [
      Variable.withString('test@test.com'),
      Variable.withString('hash'),
    ],
  );
}

Future<int> _seedFactionPlayer(AppDatabase db, String factionType) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, constitution, "
    "spirit, charisma, attribute_points, shadow_corruption, vitalism_level, "
    "vitalism_xp, faction_type) "
    "VALUES (?, ?, 'Sombra', 1, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, ?)",
    variables: [
      Variable.withString('test@test.com'),
      Variable.withString('hash'),
      Variable.withString(factionType),
    ],
  );
}

Future<int> _seedMission(AppDatabase db, int playerId) async {
  final repo = MissionRepositoryDrift(db);
  return repo.insert(MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: 'FAC_TEST',
    modality: MissionModality.internal,
    tabOrigin: MissionTabOrigin.faction,
    rank: GuildRank.d,
    targetValue: 1,
    currentValue: 1,
    reward: const RewardDeclared(insignias: 50),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: '{}',
  ));
}

Future<int> _insignias(AppDatabase db, int playerId) async {
  final rows = await db.customSelect(
    'SELECT insignias FROM players WHERE id = ?',
    variables: [Variable.withInt(playerId)],
  ).get();
  return rows.single.read<int>('insignias');
}

void main() {
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

  RewardGrantService buildGrant({FactionBuffService? buff}) {
    final catalog = ItemsCatalogService(db);
    return RewardGrantService(
      db: db,
      missionRepo: missionRepo,
      achievementsRepo: PlayerAchievementsRepositoryDrift(db),
      inventory: PlayerInventoryService(db, catalog),
      recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
      factionRep: PlayerFactionReputationRepositoryDrift(db),
      eventBus: bus,
      factionBuff: buff,
    );
  }

  group('FATIA A — resolver propaga insígnias SEM mult/fórmula', () {
    test('insígnias passa intacta enquanto gold sofre SOULSLIKE', () async {
      final resolver =
          RewardResolveService(ItemsCatalogService(db), random: Random(1));

      final resolved = await resolver.resolve(
        const RewardDeclared(gold: 100, insignias: 80),
        const PlayerSnapshot(level: 10, rank: GuildRank.e),
      );

      // gold: 100 × 0.35 = 35 (SOULSLIKE aplicado).
      expect(resolved.gold, 35, reason: 'gold sofre mult');
      // insígnias: 80 → 80 (intacta).
      expect(resolved.insignias, 80, reason: 'insígnias NÃO sofre mult');
    });

    test('insígnias ignora a fórmula 0-300% mesmo com progressPct≠100',
        () async {
      final resolver =
          RewardResolveService(ItemsCatalogService(db), random: Random(1));

      // progressPct=50 reduziria gold pela metade; insígnias deve ficar igual.
      final resolved = await resolver.resolve(
        const RewardDeclared(gold: 100, insignias: 80),
        const PlayerSnapshot(level: 10, rank: GuildRank.e),
        progressPct: 50,
      );

      // gold: 100 × (50/100) × 0.35 = 17.5 → 18.
      expect(resolved.gold, 18, reason: 'gold sofre 0-300% + mult');
      expect(resolved.insignias, 80,
          reason: 'insígnias fixa, ignora progressPct');
    });
  });

  group('FATIA A — grant credita players.insignias', () {
    test('reward com insígnias incrementa a coluna pelo valor exato',
        () async {
      final grant = buildGrant();
      final playerId = await _seedPlayer(db);
      final missionId = await _seedMission(db, playerId);

      expect(await _insignias(db, playerId), 0);

      await grant.grant(
        missionProgressId: missionId,
        playerId: playerId,
        resolved: const RewardResolved(insignias: 50),
      );

      expect(await _insignias(db, playerId), 50);
    });

    test('insígnias 0 não escreve (sem incremento)', () async {
      final grant = buildGrant();
      final playerId = await _seedPlayer(db);
      final missionId = await _seedMission(db, playerId);

      await grant.grant(
        missionProgressId: missionId,
        playerId: playerId,
        resolved: const RewardResolved(xp: 10),
      );

      expect(await _insignias(db, playerId), 0);
    });

    test('RewardGranted carrega insígnias no payload', () async {
      final grant = buildGrant();
      final playerId = await _seedPlayer(db);
      final missionId = await _seedMission(db, playerId);

      RewardGranted? captured;
      final sub = bus.on<RewardGranted>().listen((e) => captured = e);

      await grant.grant(
        missionProgressId: missionId,
        playerId: playerId,
        resolved: const RewardResolved(insignias: 50),
      );
      await pumpEventQueue();

      expect(captured, isNotNull);
      expect(captured!.rewardResolvedJson, contains('"insignias":50'));

      await sub.cancel();
    });
  });

  group('FATIA A — insígnias NÃO é bufada por facção', () {
    test('buff +10% xp não afeta insígnias (xp escala, insígnias não)',
        () async {
      final buff = FactionBuffService(db);
      buff.debugSetCatalog(<String, dynamic>{
        'new_order': {
          'applied': {'xp_mult': 1.10, 'gold_mult': 1.10},
          'pending': [],
        },
      });
      final grant = buildGrant(buff: buff);
      final playerId = await _seedFactionPlayer(db, 'new_order');
      final missionId = await _seedMission(db, playerId);

      await grant.grant(
        missionProgressId: missionId,
        playerId: playerId,
        resolved: const RewardResolved(xp: 50, insignias: 50),
      );

      final rows = await db.customSelect(
        'SELECT xp, insignias FROM players WHERE id = ?',
        variables: [Variable.withInt(playerId)],
      ).get();
      expect(rows.single.read<int>('xp'), 55, reason: 'xp bufado 50×1.10');
      expect(rows.single.read<int>('insignias'), 50,
          reason: 'insígnias fixa, sem buff');
    });
  });
}
