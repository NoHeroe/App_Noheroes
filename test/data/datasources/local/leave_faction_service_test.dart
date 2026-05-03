import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/faction_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/leave_faction_service.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/domain/services/faction_reputation_service.dart';

/// Sprint 3.4 Sub-Etapa B.2 — testes do `LeaveFactionService`.
///
/// Cobertura:
/// - leave normal: -20 rep + faction_type='none' + lockedUntil/
///   debuffUntil set + emite FactionLeft
/// - Guilda: faction_type='none' MAS guild_rank PRESERVADO
/// - propagação via matriz: -20 em moon_clan → +10 em sun_clan
///   (rival -0.5 × -20 = +10)
/// - guards: factionId vazio, player não é membro
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  late LeaveFactionService service;
  const playerId = 1;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    final factionRep = FactionReputationService(
      repo: PlayerFactionReputationRepositoryDrift(db),
      bus: bus,
    );
    service = LeaveFactionService(
      db: db,
      bus: bus,
      factionRep: factionRep,
    );
    // Cria player.
    await db.customStatement(
      "INSERT INTO players (id, email, password_hash, faction_type) "
      "VALUES (?, ?, ?, ?)",
      [playerId, 'test@test.com', 'hash', 'moon_clan'],
    );
    // Cria membership row pra moon_clan.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO player_faction_membership '
      '(player_id, faction_id, joined_at, left_at, locked_until, '
      ' debuff_until, admission_attempts) '
      'VALUES (?, ?, ?, NULL, NULL, NULL, 0)',
      [playerId, 'moon_clan', nowMs - 1000],
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  test('leaveFaction normal: faction_type vai pra none + lock 7d + '
      'debuff 48h + emite FactionLeft', () async {
    final captured = <FactionLeft>[];
    final sub = bus.on<FactionLeft>().listen(captured.add);

    await service.leaveFaction(playerId: playerId, factionId: 'moon_clan');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // faction_type
    final pRows = await db.customSelect(
      'SELECT faction_type FROM players WHERE id = ?',
      variables: [Variable.withInt(playerId)],
    ).get();
    expect(pRows.first.read<String>('faction_type'), 'none');

    // membership row updated
    final memRows = await db.customSelect(
      "SELECT left_at, locked_until, debuff_until "
      "FROM player_faction_membership "
      "WHERE player_id = ? AND faction_id = 'moon_clan'",
      variables: [Variable.withInt(playerId)],
    ).get();
    expect(memRows.first.data['left_at'], isNotNull);
    expect(memRows.first.data['locked_until'], isNotNull);
    expect(memRows.first.data['debuff_until'], isNotNull);

    // FactionLeft emitido
    expect(captured.length, 1);
    expect(captured.first.factionId, 'moon_clan');

    await sub.cancel();
  });

  test('Guilda: leaveFaction zera faction_type MAS preserva guild_rank',
      () async {
    // Setup: player tem guild_rank='c' E faction_type='guild'.
    await db.customStatement(
      "UPDATE players SET faction_type = 'guild', guild_rank = 'c' "
      "WHERE id = ?",
      [playerId],
    );
    await db.customStatement(
      'INSERT INTO player_faction_membership '
      '(player_id, faction_id, joined_at, left_at, locked_until, '
      ' debuff_until, admission_attempts) '
      'VALUES (?, ?, ?, NULL, NULL, NULL, 0)',
      [playerId, 'guild', DateTime.now().millisecondsSinceEpoch - 1000],
    );

    await service.leaveFaction(playerId: playerId, factionId: 'guild');

    final rows = await db.customSelect(
      'SELECT faction_type, guild_rank FROM players WHERE id = ?',
      variables: [Variable.withInt(playerId)],
    ).get();
    expect(rows.first.read<String>('faction_type'), 'none');
    // KEY: guild_rank preservado (Aventureiro nível 1 não perde).
    expect(rows.first.read<String>('guild_rank'), 'c');
  });

  test('propagação via matriz: leave moon_clan → -20 moon + cascata',
      () async {
    // Reputação inicial padrão (50) pra moon_clan e sun_clan.
    // moon_clan ↔ sun_clan rivais (-0.5). Saída moon_clan -20 →
    // propagação em sun_clan = -20 × -0.5 = +10. Resultado:
    //   moon_clan: 50 - 20 = 30
    //   sun_clan: 50 + 10 = 60
    await service.leaveFaction(playerId: playerId, factionId: 'moon_clan');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final moonRow = await db.customSelect(
      "SELECT reputation FROM player_faction_reputation "
      "WHERE player_id = ? AND faction_id = 'moon_clan'",
      variables: [Variable.withInt(playerId)],
    ).get();
    expect(moonRow.first.read<int>('reputation'), 30);

    final sunRow = await db.customSelect(
      "SELECT reputation FROM player_faction_reputation "
      "WHERE player_id = ? AND faction_id = 'sun_clan'",
      variables: [Variable.withInt(playerId)],
    ).get();
    expect(sunRow.first.read<int>('reputation'), 60);
  });

  test('guard: factionId vazio lança LeaveFactionException', () async {
    expect(
      () => service.leaveFaction(playerId: playerId, factionId: ''),
      throwsA(isA<LeaveFactionException>()),
    );
  });

  test('guard: player não é membro lança LeaveFactionException',
      () async {
    expect(
      () => service.leaveFaction(playerId: playerId, factionId: 'sun_clan'),
      throwsA(isA<LeaveFactionException>()),
    );
  });
}
