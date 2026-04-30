import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/daily_mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/daily_missions_dao.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/data/database/daos/player_daily_mission_stats_dao.dart';
import 'package:noheroes_app/data/database/daos/player_daily_subtask_volume_dao.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/data/datasources/local/player_inventory_service.dart';
import 'package:noheroes_app/data/datasources/local/player_recipes_service.dart';
import 'package:noheroes_app/data/datasources/local/recipes_catalog_service.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_achievements_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/data/services/reward_grant_service.dart';
import 'package:noheroes_app/domain/enums/daily_unit_type.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/models/daily_mission.dart';
import 'package:noheroes_app/domain/models/daily_mission_status.dart';
import 'package:noheroes_app/domain/models/daily_sub_task_instance.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import 'package:noheroes_app/domain/services/achievement_trigger_types.dart';
import 'package:noheroes_app/domain/services/achievements_service.dart';
import 'package:noheroes_app/domain/services/daily_mission_progress_service.dart';
import 'package:noheroes_app/domain/services/daily_mission_rollover_service.dart';
import 'package:noheroes_app/domain/services/daily_mission_stats_service.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

/// Sprint 3.3 Etapa 2.1c-β — testes do modo automático de daily missions.
///
/// Cobre:
///   - Migration 30→31: 4 colunas adicionadas, defaults corretos
///   - Persistência was_auto_confirmed em daily_missions
///   - PlayerDao.setAutoConfirmEnabled
///   - DailyMissionRolloverService: branch nova auto-confirm + fluxo legacy
///   - DailyMissionProgressService.applyAutoCompleted
///   - DailyMissionStatsService: propaga wasAutoConfirmed → DAO
///   - DAO.incrementOnCompleted: bumps corretos + anti-cheese
///   - 2 triggers novos: daily_auto_confirm_count + daily_zero_progress_manual_count
///   - Streak: auto-confirm CONTA pra streak (design choice consciente)

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

DailySubTaskInstance _sub({
  required String key,
  required int alvo,
  required int progresso,
}) =>
    DailySubTaskInstance(
      subTaskKey: key,
      nomeVisivel: key,
      escalaAlvo: alvo,
      unidade: 'x',
      tipoUnidade: DailyUnitType.contagem,
      progressoAtual: progresso,
      completed: progresso >= alvo,
    );

DailyMission _mkMission({
  required int id,
  required int playerId,
  required String data,
  required List<DailySubTaskInstance> subs,
  DailyMissionStatus status = DailyMissionStatus.pending,
  bool wasAutoConfirmed = false,
}) =>
    DailyMission(
      id: id,
      playerId: playerId,
      data: data,
      modalidade: MissionCategory.fisico,
      subCategoria: 'forca',
      tituloKey: 'k',
      tituloResolvido: 't',
      quoteResolvida: 'q',
      subTarefas: subs,
      status: status,
      createdAt: DateTime(2026, 4, 29),
      completedAt: null,
      rewardClaimed: false,
      wasAutoConfirmed: wasAutoConfirmed,
    );

Future<int> _seedPlayer(
  AppDatabase db, {
  bool autoConfirm = false,
  int dailyStreak = 0,
}) async {
  return db.into(db.playersTable).insert(PlayersTableCompanion.insert(
        email: 'p${DateTime.now().microsecondsSinceEpoch}@t',
        passwordHash: 'h',
        autoConfirmEnabled: Value(autoConfirm),
        dailyMissionsStreak: Value(dailyStreak),
      ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── 1. Migration 30→31 ─────────────────────────────────────────

  group('migration 30→31', () {
    test('schema 31 fresh install: 4 colunas com defaults corretos',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();

      // players.auto_confirm_enabled DEFAULT 0
      await db.into(db.playersTable).insert(PlayersTableCompanion.insert(
            email: 'mig@t',
            passwordHash: 'h',
          ));
      final players = await db.customSelect(
              'SELECT auto_confirm_enabled FROM players')
          .get();
      expect(players.first.read<int>('auto_confirm_enabled'), 0);

      // daily_missions e stats têm cols (PRAGMA check).
      final dmCols = await db
          .customSelect("PRAGMA table_info('daily_missions')")
          .get();
      final dmNames = dmCols.map((r) => r.read<String>('name')).toSet();
      expect(dmNames.contains('was_auto_confirmed'), isTrue);

      final statsCols = await db
          .customSelect("PRAGMA table_info('player_daily_mission_stats')")
          .get();
      final statsNames =
          statsCols.map((r) => r.read<String>('name')).toSet();
      expect(statsNames.contains('total_auto_confirm_completions'), isTrue);
      expect(
          statsNames.contains('total_zero_progress_manual_confirms'),
          isTrue);

      await db.close();
    });
  });

  // ─── 2. Persistência was_auto_confirmed em daily_missions ─────────

  group('DailyMissionsDao persiste wasAutoConfirmed', () {
    late AppDatabase db;
    late DailyMissionsDao missionsDao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      missionsDao = DailyMissionsDao(db);
    });

    tearDown(() async => db.close());

    test('insert + read round-trip', () async {
      final pid = await _seedPlayer(db);
      final mission = _mkMission(
        id: 0,
        playerId: pid,
        data: '2026-04-30',
        subs: [_sub(key: 'k', alvo: 10, progresso: 10)],
        wasAutoConfirmed: true,
      );
      final inserted = await missionsDao.insertAll([mission]);
      final loaded = await missionsDao.findById(inserted.first.id);
      expect(loaded!.wasAutoConfirmed, isTrue);
    });

    test('updateMission toggles flag', () async {
      final pid = await _seedPlayer(db);
      final mission = _mkMission(
        id: 0,
        playerId: pid,
        data: '2026-04-30',
        subs: [_sub(key: 'k', alvo: 10, progresso: 10)],
      );
      final inserted = await missionsDao.insertAll([mission]);
      await missionsDao.updateMission(
          inserted.first.copyWith(wasAutoConfirmed: true));
      final loaded = await missionsDao.findById(inserted.first.id);
      expect(loaded!.wasAutoConfirmed, isTrue);
    });
  });

  // ─── 3. PlayerDao.setAutoConfirmEnabled ─────────────────────────

  group('PlayerDao.setAutoConfirmEnabled', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async => db.close());

    test('toggle ON e OFF', () async {
      final pid = await _seedPlayer(db);
      final dao = PlayerDao(db);

      await dao.setAutoConfirmEnabled(pid, true);
      var p = await dao.findById(pid);
      expect(p!.autoConfirmEnabled, isTrue);

      await dao.setAutoConfirmEnabled(pid, false);
      p = await dao.findById(pid);
      expect(p!.autoConfirmEnabled, isFalse);
    });
  });

  // ─── 4. DailyMission.allSubsAtTarget helper ────────────────────

  group('DailyMission.allSubsAtTarget', () {
    test('todas em 100%+ → true', () {
      final m = _mkMission(id: 1, playerId: 1, data: 'd', subs: [
        _sub(key: 'a', alvo: 10, progresso: 10),
        _sub(key: 'b', alvo: 10, progresso: 12),
        _sub(key: 'c', alvo: 10, progresso: 30),
      ]);
      expect(m.allSubsAtTarget, isTrue);
    });

    test('uma sub em 99% → false', () {
      final m = _mkMission(id: 1, playerId: 1, data: 'd', subs: [
        _sub(key: 'a', alvo: 10, progresso: 10),
        _sub(key: 'b', alvo: 10, progresso: 9),
        _sub(key: 'c', alvo: 10, progresso: 10),
      ]);
      expect(m.allSubsAtTarget, isFalse);
    });

    test('sub com escalaAlvo=0 (degenerado) → false (defesa)', () {
      final m = _mkMission(id: 1, playerId: 1, data: 'd', subs: [
        _sub(key: 'a', alvo: 0, progresso: 5),
        _sub(key: 'b', alvo: 10, progresso: 10),
      ]);
      expect(m.allSubsAtTarget, isFalse);
    });

    test('subs vazias → false', () {
      final m = _mkMission(id: 1, playerId: 1, data: 'd', subs: const []);
      expect(m.allSubsAtTarget, isFalse);
    });
  });

  // ─── 5. DailyMissionRolloverService — auto-confirm ─────────────

  group('DailyMissionRolloverService auto-confirm', () {
    late AppDatabase db;
    late AppEventBus bus;
    late DailyMissionsDao missionsDao;
    late PlayerDao playerDao;
    late DailyMissionProgressService progress;
    late DailyMissionRolloverService rollover;
    late int playerId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      bus = AppEventBus();
      missionsDao = DailyMissionsDao(db);
      playerDao = PlayerDao(db);
      progress = DailyMissionProgressService(
        db: db,
        missionsDao: missionsDao,
        playerDao: playerDao,
        bus: bus,
      );
      rollover = DailyMissionRolloverService(
        missionsDao: missionsDao,
        playerDao: playerDao,
        progress: progress,
      );
    });

    tearDown(() async {
      await bus.dispose();
      await db.close();
    });

    test('toggle ON + 100% em todas as subs → completed + auto + reward',
        () async {
      playerId = await _seedPlayer(db, autoConfirm: true);
      // Insere missão com data=ontem e todas em 100%+.
      final inserted = await missionsDao.insertAll([
        _mkMission(
          id: 0,
          playerId: playerId,
          data: '2026-04-29',
          subs: [
            _sub(key: 'a', alvo: 10, progresso: 10),
            _sub(key: 'b', alvo: 10, progresso: 10),
            _sub(key: 'c', alvo: 10, progresso: 10),
          ],
        ),
      ]);

      final received = <DailyMissionCompleted>[];
      bus.on<DailyMissionCompleted>().listen(received.add);

      await rollover.processRollover(playerId, now: DateTime(2026, 4, 30));
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = await missionsDao.findById(inserted.first.id);
      expect(loaded!.status, DailyMissionStatus.completed);
      expect(loaded.wasAutoConfirmed, isTrue);
      expect(loaded.rewardClaimed, isTrue);

      expect(received.length, 1);
      expect(received.first.fullCompleted, isTrue);
      expect(received.first.wasAutoConfirmed, isTrue);

      // Player ganhou reward.
      final p = await playerDao.findById(playerId);
      expect(p!.gold, greaterThan(0));
      expect(p.xp, greaterThan(0));
    });

    test('toggle ON + 1 sub em 50% → fluxo partial (não auto)', () async {
      playerId = await _seedPlayer(db, autoConfirm: true);
      final inserted = await missionsDao.insertAll([
        _mkMission(
          id: 0,
          playerId: playerId,
          data: '2026-04-29',
          subs: [
            _sub(key: 'a', alvo: 10, progresso: 10),
            _sub(key: 'b', alvo: 10, progresso: 5), // 50%
            _sub(key: 'c', alvo: 10, progresso: 10),
          ],
        ),
      ]);

      await rollover.processRollover(playerId, now: DateTime(2026, 4, 30));
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = await missionsDao.findById(inserted.first.id);
      expect(loaded!.status, DailyMissionStatus.partial);
      expect(loaded.wasAutoConfirmed, isFalse);
    });

    test('toggle OFF + 100% em todas → fluxo legacy (continua pending)',
        () async {
      // Toggle OFF, todas 100%. Rollover pega `pending` antes de hoje
      // e cai no markFailed se completedSubCount=0, ou applyPartialReward
      // se >=1. Aqui completedSubCount=3 (todas completed=true via _sub
      // helper). Resultado: applyPartialReward → status=partial.
      playerId = await _seedPlayer(db, autoConfirm: false);
      final inserted = await missionsDao.insertAll([
        _mkMission(
          id: 0,
          playerId: playerId,
          data: '2026-04-29',
          subs: [
            _sub(key: 'a', alvo: 10, progresso: 10),
            _sub(key: 'b', alvo: 10, progresso: 10),
            _sub(key: 'c', alvo: 10, progresso: 10),
          ],
        ),
      ]);

      await rollover.processRollover(playerId, now: DateTime(2026, 4, 30));
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = await missionsDao.findById(inserted.first.id);
      // Sem auto-confirm: cai em applyPartialReward (3 subs completed),
      // que marca como `partial` (não `completed`). Auto-confirm NUNCA
      // aplica sem o toggle.
      expect(loaded!.status, DailyMissionStatus.partial);
      expect(loaded.wasAutoConfirmed, isFalse);
    });
  });

  // ─── 6. DailyMissionProgressService.applyAutoCompleted ─────────

  group('applyAutoCompleted', () {
    late AppDatabase db;
    late AppEventBus bus;
    late DailyMissionsDao missionsDao;
    late PlayerDao playerDao;
    late DailyMissionProgressService progress;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      bus = AppEventBus();
      missionsDao = DailyMissionsDao(db);
      playerDao = PlayerDao(db);
      progress = DailyMissionProgressService(
        db: db,
        missionsDao: missionsDao,
        playerDao: playerDao,
        bus: bus,
      );
    });

    tearDown(() async {
      await bus.dispose();
      await db.close();
    });

    test('reward calc usa status=completed (não partial)', () async {
      final pid = await _seedPlayer(db);
      final inserted = await missionsDao.insertAll([
        _mkMission(
          id: 0,
          playerId: pid,
          data: '2026-04-29',
          subs: [
            _sub(key: 'a', alvo: 10, progresso: 10),
            _sub(key: 'b', alvo: 10, progresso: 10),
            _sub(key: 'c', alvo: 10, progresso: 10),
          ],
        ),
      ]);

      await progress.applyAutoCompleted(mission: inserted.first);
      final p = await playerDao.findById(pid);
      // Rank E (none): xp=8 base; status=completed → mult=1.0 → 8 xp.
      expect(p!.xp, 8);
      expect(p.gold, 5);
    });

    test('idempotente: rewardClaimed=true → noop', () async {
      final pid = await _seedPlayer(db);
      final inserted = await missionsDao.insertAll([
        _mkMission(
          id: 0,
          playerId: pid,
          data: '2026-04-29',
          subs: [
            _sub(key: 'a', alvo: 10, progresso: 10),
          ],
          status: DailyMissionStatus.completed,
        ).copyWith(rewardClaimed: true),
      ]);

      await progress.applyAutoCompleted(mission: inserted.first);
      final p = await playerDao.findById(pid);
      // Sem credit (rewardClaimed=true → noop).
      expect(p!.xp, 0);
    });
  });

  // ─── 7. PlayerDailyMissionStatsDao — anti-cheese ───────────────

  group('PlayerDailyMissionStatsDao incrementOnCompleted +wasAutoConfirmed',
      () {
    late AppDatabase db;
    late PlayerDailyMissionStatsDao dao;
    int playerId = 0;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = PlayerDailyMissionStatsDao(db);
      playerId = await _seedPlayer(db);
    });

    tearDown(() async => db.close());

    test('auto: bumps total_auto_confirm + NÃO bumps manual_zero',
        () async {
      await dao.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 30, 10),
        dayOfWeek: 4,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: true,
        wasAutoConfirmed: true,
      );

      final stats = await dao.findByPlayerId(playerId);
      expect(stats!.totalAutoConfirmCompletions, 1);
      expect(stats.totalZeroProgressConfirms, 1); // legacy: conta tudo
      expect(stats.totalZeroProgressManualConfirms, 0); // anti-cheese
    });

    test('manual + zero: bumps manual_zero + NÃO bumps auto', () async {
      await dao.incrementOnCompleted(
        playerId,
        isPerfect: false,
        isSuperPerfect: false,
        subTasksCompleted: 0,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 30, 10),
        dayOfWeek: 4,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: true,
        wasAutoConfirmed: false,
      );

      final stats = await dao.findByPlayerId(playerId);
      expect(stats!.totalAutoConfirmCompletions, 0);
      expect(stats.totalZeroProgressConfirms, 1);
      expect(stats.totalZeroProgressManualConfirms, 1);
    });

    test('manual + non-zero: nada de zero counts', () async {
      await dao.incrementOnCompleted(
        playerId,
        isPerfect: true,
        isSuperPerfect: true,
        subTasksCompleted: 3,
        subTasksOvershoot: 0,
        confirmedAt: DateTime(2026, 4, 30, 10),
        dayOfWeek: 4,
        isBefore8AM: false,
        isAfter10PM: false,
        isWeekend: false,
        isSpeedrun: false,
        zeroProgress: false,
        wasAutoConfirmed: false,
      );

      final stats = await dao.findByPlayerId(playerId);
      expect(stats!.totalAutoConfirmCompletions, 0);
      expect(stats.totalZeroProgressConfirms, 0);
      expect(stats.totalZeroProgressManualConfirms, 0);
      expect(stats.totalPerfect, 1);
    });
  });

  // ─── 8. DailyMissionStatsService propaga wasAutoConfirmed ──────

  group('DailyMissionStatsService propaga wasAutoConfirmed', () {
    late AppDatabase db;
    late AppEventBus bus;
    late DailyMissionStatsService service;
    late PlayerDailyMissionStatsDao statsDao;
    late DailyMissionsDao missionsDao;
    late int playerId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      bus = AppEventBus();
      statsDao = PlayerDailyMissionStatsDao(db);
      missionsDao = DailyMissionsDao(db);
      service = DailyMissionStatsService(
        statsDao: statsDao,
        volumeDao: PlayerDailySubtaskVolumeDao(db),
        playerDao: PlayerDao(db),
        missionsDao: missionsDao,
        bus: bus,
      );
      service.start();
      playerId = await _seedPlayer(db);
    });

    tearDown(() async {
      await service.dispose();
      await bus.dispose();
      await db.close();
    });

    test('DailyMissionCompleted(wasAutoConfirmed: true) → DAO recebe true',
        () async {
      // Insere missão pra _addVolumeFromMission encontrar.
      final inserted = await missionsDao.insertAll([
        _mkMission(
          id: 0,
          playerId: playerId,
          data: '2026-04-30',
          subs: [_sub(key: 'a', alvo: 10, progresso: 10)],
          status: DailyMissionStatus.completed,
          wasAutoConfirmed: true,
        ).copyWith(completedAt: DateTime(2026, 4, 30, 10), rewardClaimed: true),
      ]);

      bus.publish(DailyMissionCompleted(
        playerId: playerId,
        missionId: inserted.first.id,
        modalidade: MissionCategory.fisico,
        fullCompleted: true,
        partial: false,
        wasAutoConfirmed: true,
      ));
      await Future.delayed(const Duration(milliseconds: 80));

      final stats = await statsDao.findByPlayerId(playerId);
      expect(stats!.totalCompleted, 1);
      expect(stats.totalAutoConfirmCompletions, 1);
    });

    test('DailyMissionCompleted(wasAutoConfirmed: false) → não bumps auto',
        () async {
      final inserted = await missionsDao.insertAll([
        _mkMission(
          id: 0,
          playerId: playerId,
          data: '2026-04-30',
          subs: [_sub(key: 'a', alvo: 10, progresso: 10)],
          status: DailyMissionStatus.completed,
        ).copyWith(completedAt: DateTime(2026, 4, 30, 10), rewardClaimed: true),
      ]);

      bus.publish(DailyMissionCompleted(
        playerId: playerId,
        missionId: inserted.first.id,
        modalidade: MissionCategory.fisico,
        fullCompleted: true,
        partial: false,
      ));
      await Future.delayed(const Duration(milliseconds: 80));

      final stats = await statsDao.findByPlayerId(playerId);
      expect(stats!.totalCompleted, 1);
      expect(stats.totalAutoConfirmCompletions, 0);
    });
  });

  // ─── 9. Streak: auto-confirm CONTA pra streak ──────────────────

  group('streak — auto-confirm CONTA pra streak (design choice)', () {
    test(
        'streak=3, auto-confirm completed → streak=4 '
        '(auto-confirm CONTA pra streak — design choice consciente)',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final playerDao = PlayerDao(db);
      final pid = await _seedPlayer(db, autoConfirm: true, dailyStreak: 3);

      final bus = AppEventBus();
      final missionsDao = DailyMissionsDao(db);
      final progress = DailyMissionProgressService(
        db: db,
        missionsDao: missionsDao,
        playerDao: playerDao,
        bus: bus,
      );
      final rollover = DailyMissionRolloverService(
        missionsDao: missionsDao,
        playerDao: playerDao,
        progress: progress,
      );

      // Missão de ontem com 100% em todas — 1 missão, será o "dia" de ontem.
      await missionsDao.insertAll([
        _mkMission(
          id: 0,
          playerId: pid,
          data: '2026-04-29',
          subs: [
            _sub(key: 'a', alvo: 10, progresso: 10),
            _sub(key: 'b', alvo: 10, progresso: 10),
            _sub(key: 'c', alvo: 10, progresso: 10),
          ],
        ),
      ]);

      await rollover.processRollover(pid, now: DateTime(2026, 4, 30));
      await Future.delayed(const Duration(milliseconds: 50));

      final p = await playerDao.findById(pid);
      // streak=3 → +1 (auto-confirm count) → 4
      expect(p!.dailyMissionsStreak, 4,
          reason:
              'auto-confirm CONTA pra streak — clicar ✓ é só burocracia '
              'que o modo automático tira; jogador completou 100% das subs');

      await bus.dispose();
      await db.close();
    });
  });

  // ─── 10. Triggers novos: daily_auto_confirm_count + manual_zero ──

  group('triggers novos', () {
    Future<AchievementsService> newSvc(
        AppDatabase db, AppEventBus bus, String catalogJson) async {
      final catalog = ItemsCatalogService(db);
      return AchievementsService(
        achievementsRepo: PlayerAchievementsRepositoryDrift(db),
        rewardResolve: RewardResolveService(catalog),
        rewardGrant: RewardGrantService(
          db: db,
          missionRepo: MissionRepositoryDrift(db),
          achievementsRepo: PlayerAchievementsRepositoryDrift(db),
          inventory: PlayerInventoryService(db, catalog),
          recipes: PlayerRecipesService(db, RecipesCatalogService(db)),
          factionRep: PlayerFactionReputationRepositoryDrift(db),
          eventBus: bus,
        ),
        bus: bus,
        statsDao: PlayerDailyMissionStatsDao(db),
        volumeDao: PlayerDailySubtaskVolumeDao(db),
        playerDao: PlayerDao(db),
        resolvePlayerFacts: (playerId) async {
          final row = await (db.select(db.playersTable)
                ..where((t) => t.id.equals(playerId)))
              .getSingle();
          return PlayerFacts(
            level: row.level,
            totalQuestsCompleted: row.totalQuestsCompleted,
            dailyMissionsStreak: row.dailyMissionsStreak,
            snapshot: PlayerSnapshot(level: row.level, rank: GuildRank.e),
          );
        },
        assetBundle: _FakeBundle({
          AchievementsService.catalogAssetPath: catalogJson,
        }),
      );
    }

    test('daily_auto_confirm_count: positive', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final bus = AppEventBus();
      final pid = await _seedPlayer(db);
      final stats = PlayerDailyMissionStatsDao(db);
      // Bumpa 3 auto-confirms.
      for (var i = 0; i < 3; i++) {
        await stats.incrementOnCompleted(
          pid,
          isPerfect: true,
          isSuperPerfect: true,
          subTasksCompleted: 3,
          subTasksOvershoot: 0,
          confirmedAt: DateTime(2026, 4, 30, 10),
          dayOfWeek: 4,
          isBefore8AM: false,
          isAfter10PM: false,
          isWeekend: false,
          isSpeedrun: false,
          zeroProgress: false,
          wasAutoConfirmed: true,
        );
      }

      final svc = await newSvc(db, bus, jsonEncode({
        'achievements': [
          {
            'key': 'AUTO_3',
            'name': 'AUTO_3',
            'description': 'd',
            'category': 'daily',
            'trigger': {
              'type': AchievementTriggerTypes.dailyAutoConfirmCount,
              'target': 3,
            },
          },
        ],
      }));
      await svc.attachDailyListeners();
      bus.publish(
          DailyStatsUpdated(playerId: pid, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'AUTO_3'),
          isTrue);
      await bus.dispose();
      await db.close();
    });

    test('daily_auto_confirm_count: negative (target=5, stats=2)',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final bus = AppEventBus();
      final pid = await _seedPlayer(db);
      final stats = PlayerDailyMissionStatsDao(db);
      for (var i = 0; i < 2; i++) {
        await stats.incrementOnCompleted(
          pid,
          isPerfect: false,
          isSuperPerfect: false,
          subTasksCompleted: 0,
          subTasksOvershoot: 0,
          confirmedAt: DateTime(2026, 4, 30, 10),
          dayOfWeek: 4,
          isBefore8AM: false,
          isAfter10PM: false,
          isWeekend: false,
          isSpeedrun: false,
          zeroProgress: false,
          wasAutoConfirmed: true,
        );
      }

      final svc = await newSvc(db, bus, jsonEncode({
        'achievements': [
          {
            'key': 'AUTO_5',
            'name': 'AUTO_5',
            'description': 'd',
            'category': 'daily',
            'trigger': {
              'type': AchievementTriggerTypes.dailyAutoConfirmCount,
              'target': 5,
            },
          },
        ],
      }));
      await svc.attachDailyListeners();
      bus.publish(
          DailyStatsUpdated(playerId: pid, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'AUTO_5'),
          isFalse);
      await bus.dispose();
      await db.close();
    });

    test(
        'daily_zero_progress_manual_count: positive '
        '(só manual zero conta — auto ignorado)',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final bus = AppEventBus();
      final pid = await _seedPlayer(db);
      final stats = PlayerDailyMissionStatsDao(db);

      // 5 confirms zero: 3 manual + 2 auto. Só os 3 manuais contam.
      for (var i = 0; i < 3; i++) {
        await stats.incrementOnCompleted(
          pid,
          isPerfect: false,
          isSuperPerfect: false,
          subTasksCompleted: 0,
          subTasksOvershoot: 0,
          confirmedAt: DateTime(2026, 4, 30, 10),
          dayOfWeek: 4,
          isBefore8AM: false,
          isAfter10PM: false,
          isWeekend: false,
          isSpeedrun: false,
          zeroProgress: true,
          wasAutoConfirmed: false, // manual
        );
      }
      for (var i = 0; i < 2; i++) {
        await stats.incrementOnCompleted(
          pid,
          isPerfect: false,
          isSuperPerfect: false,
          subTasksCompleted: 0,
          subTasksOvershoot: 0,
          confirmedAt: DateTime(2026, 4, 30, 10),
          dayOfWeek: 4,
          isBefore8AM: false,
          isAfter10PM: false,
          isWeekend: false,
          isSpeedrun: false,
          zeroProgress: true,
          wasAutoConfirmed: true, // auto: anti-cheese
        );
      }

      final svc = await newSvc(db, bus, jsonEncode({
        'achievements': [
          {
            'key': 'OLHO_3',
            'name': 'OLHO_3',
            'description': 'd',
            'category': 'daily',
            'trigger': {
              'type':
                  AchievementTriggerTypes.dailyZeroProgressManualCount,
              'target': 3,
            },
          },
        ],
      }));
      await svc.attachDailyListeners();
      bus.publish(
          DailyStatsUpdated(playerId: pid, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'OLHO_3'),
          isTrue);
      await bus.dispose();
      await db.close();
    });

    test(
        'daily_zero_progress_manual_count: negative '
        '(target=10, manual=3, auto=20 — auto NÃO conta)',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final bus = AppEventBus();
      final pid = await _seedPlayer(db);
      final stats = PlayerDailyMissionStatsDao(db);

      for (var i = 0; i < 3; i++) {
        await stats.incrementOnCompleted(
          pid,
          isPerfect: false,
          isSuperPerfect: false,
          subTasksCompleted: 0,
          subTasksOvershoot: 0,
          confirmedAt: DateTime(2026, 4, 30, 10),
          dayOfWeek: 4,
          isBefore8AM: false,
          isAfter10PM: false,
          isWeekend: false,
          isSpeedrun: false,
          zeroProgress: true,
          wasAutoConfirmed: false,
        );
      }
      for (var i = 0; i < 20; i++) {
        await stats.incrementOnCompleted(
          pid,
          isPerfect: false,
          isSuperPerfect: false,
          subTasksCompleted: 0,
          subTasksOvershoot: 0,
          confirmedAt: DateTime(2026, 4, 30, 10),
          dayOfWeek: 4,
          isBefore8AM: false,
          isAfter10PM: false,
          isWeekend: false,
          isSpeedrun: false,
          zeroProgress: true,
          wasAutoConfirmed: true,
        );
      }

      final svc = await newSvc(db, bus, jsonEncode({
        'achievements': [
          {
            'key': 'OLHO_10',
            'name': 'OLHO_10',
            'description': 'd',
            'category': 'daily',
            'trigger': {
              'type':
                  AchievementTriggerTypes.dailyZeroProgressManualCount,
              'target': 10,
            },
          },
        ],
      }));
      await svc.attachDailyListeners();
      bus.publish(
          DailyStatsUpdated(playerId: pid, eventType: 'completed'));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(
          await PlayerAchievementsRepositoryDrift(db)
              .isCompleted(pid, 'OLHO_10'),
          isFalse,
          reason: 'auto-confirm zero NÃO conta pro anti-cheese');
      await bus.dispose();
      await db.close();
    });
  });
}
