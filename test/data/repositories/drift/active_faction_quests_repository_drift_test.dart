import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/active_faction_quests_repository_drift.dart';

import '_repo_test_helpers.dart';

/// Seed do progresso que a transação materializa.
Map<String, dynamic> _progressSeed({
  String modality = 'internal',
  String rank = 'd',
  int target = 5,
  String rewardJson = '{"xp":200,"gold":100}',
}) =>
    {
      'modality': modality,
      'rank': rank,
      'target_value': target,
      'reward_json': rewardJson,
    };

void main() {
  late AppDatabase db;
  late ActiveFactionQuestsRepositoryDrift repo;

  setUp(() {
    db = newTestDb();
    repo = ActiveFactionQuestsRepositoryDrift(db);
  });
  tearDown(() async => db.close());

  test('findActiveFor sem ledger → null', () async {
    expect(await repo.findActiveFor(1, 'noryan', '2026-04-20'), isNull);
  });

  test('upsertAtomic cria ledger + progress row em transação', () async {
    final result = await repo.upsertAtomic(
      playerId: 1,
      factionId: 'noryan',
      missionKey: 'FACTION_NORYAN_WEEKLY_01',
      weekStart: '2026-04-20',
      progressSeedJson: _progressSeed(),
    );

    expect(result.ledgerId, isPositive);
    expect(result.progressId, isPositive);

    final ledger = await repo.findActiveFor(1, 'noryan', '2026-04-20');
    expect(ledger, isNotNull);
    expect(ledger!.missionKey, 'FACTION_NORYAN_WEEKLY_01');

    // Progress row também foi criada na mesma transação.
    final progressRows = await db.select(db.playerMissionProgressTable).get();
    expect(progressRows, hasLength(1));
    expect(progressRows.single.tabOrigin, 'faction');
    expect(progressRows.single.missionKey, 'FACTION_NORYAN_WEEKLY_01');
    expect(progressRows.single.rewardJson, '{"xp":200,"gold":100}');
  });

  test('upsertAtomic chamado 2x sequencial é idempotente — 2ª retorna ids '
      'existentes', () async {
    final first = await repo.upsertAtomic(
      playerId: 1,
      factionId: 'noryan',
      missionKey: 'FACTION_NORYAN_WEEKLY_01',
      weekStart: '2026-04-20',
      progressSeedJson: _progressSeed(),
    );
    final second = await repo.upsertAtomic(
      playerId: 1,
      factionId: 'noryan',
      missionKey: 'FACTION_NORYAN_WEEKLY_02', // tentativa de trocar — ignorada
      weekStart: '2026-04-20',
      progressSeedJson: _progressSeed(),
    );

    expect(second.ledgerId, first.ledgerId,
        reason: 'mesma tripla retorna mesmo ledger');
    expect(second.progressId, first.progressId);

    // Só uma linha de cada tabela.
    final ledgers = await db.select(db.activeFactionQuestsTable).get();
    final progresses = await db.select(db.playerMissionProgressTable).get();
    expect(ledgers, hasLength(1));
    expect(progresses, hasLength(1));
  });

  test('bug 3 — 2 chamadas concorrentes com Future.wait só deixam 1 row',
      () async {
    // Regressão explícita do bug 3 da Sprint 2.3: race condition no
    // assignWeeklyQuest legacy. UNIQUE + transação + catch da violação
    // tornam isto impossível a partir do schema 24.
    final results = await Future.wait([
      repo.upsertAtomic(
        playerId: 1,
        factionId: 'noryan',
        missionKey: 'FACTION_NORYAN_WEEKLY_01',
        weekStart: '2026-04-20',
        progressSeedJson: _progressSeed(),
      ),
      repo.upsertAtomic(
        playerId: 1,
        factionId: 'noryan',
        missionKey: 'FACTION_NORYAN_WEEKLY_01',
        weekStart: '2026-04-20',
        progressSeedJson: _progressSeed(),
      ),
    ]);

    // Ambas as chamadas retornam com resultado válido apontando pra
    // mesmo ledger + progress.
    expect(results[0].ledgerId, results[1].ledgerId);
    expect(results[0].progressId, results[1].progressId);

    final ledgers = await db.select(db.activeFactionQuestsTable).get();
    final progresses = await db.select(db.playerMissionProgressTable).get();
    expect(ledgers, hasLength(1), reason: 'UNIQUE impediu duplicata');
    expect(progresses, hasLength(1),
        reason: 'transação + rollback evitou progress órfão');
  });

  test('triplas diferentes convivem (outra facção, outra semana, outro '
      'player)', () async {
    await repo.upsertAtomic(
      playerId: 1,
      factionId: 'noryan',
      missionKey: 'FACTION_NORYAN_WEEKLY_01',
      weekStart: '2026-04-20',
      progressSeedJson: _progressSeed(),
    );
    await repo.upsertAtomic(
      playerId: 1,
      factionId: 'noryan',
      missionKey: 'FACTION_NORYAN_WEEKLY_02',
      weekStart: '2026-04-27',
      progressSeedJson: _progressSeed(),
    );
    await repo.upsertAtomic(
      playerId: 1,
      factionId: 'silente',
      missionKey: 'FACTION_SILENTE_WEEKLY_01',
      weekStart: '2026-04-20',
      progressSeedJson: _progressSeed(),
    );
    await repo.upsertAtomic(
      playerId: 2,
      factionId: 'noryan',
      missionKey: 'FACTION_NORYAN_WEEKLY_01',
      weekStart: '2026-04-20',
      progressSeedJson: _progressSeed(),
    );

    final ledgers = await db.select(db.activeFactionQuestsTable).get();
    expect(ledgers, hasLength(4));
  });

  test('deleteExpiredBefore remove semanas antigas', () async {
    await repo.upsertAtomic(
      playerId: 1,
      factionId: 'noryan',
      missionKey: 'OLD',
      weekStart: '2026-03-01',
      progressSeedJson: _progressSeed(),
    );
    await repo.upsertAtomic(
      playerId: 1,
      factionId: 'noryan',
      missionKey: 'NEW',
      weekStart: '2026-04-20',
      progressSeedJson: _progressSeed(),
    );

    final deleted = await repo.deleteExpiredBefore('2026-04-01');
    expect(deleted, 1);

    final remaining = await db.select(db.activeFactionQuestsTable).get();
    expect(remaining, hasLength(1));
    expect(remaining.single.missionKey, 'NEW');
  });
}
