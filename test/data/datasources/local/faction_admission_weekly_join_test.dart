import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/faction_events.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/database/daos/player_dao.dart';
import 'package:noheroes_app/data/datasources/local/faction_admission_progress_service.dart';
import 'package:noheroes_app/data/datasources/local/mission_catalogs_service.dart';
import 'package:noheroes_app/data/repositories/drift/active_faction_quests_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/data/repositories/drift/player_faction_reputation_repository_drift.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/services/faction_admission_validator.dart';
import 'package:noheroes_app/domain/services/faction_reputation_service.dart';
import 'package:noheroes_app/domain/services/mission_assignment_service.dart';
import 'package:noheroes_app/domain/services/weekly_reset_service.dart';

/// FATIA B4 (Fix gatilho-JOIN) — entrar numa facção atribui a semanal NA
/// HORA, sem esperar o próximo boot do Santuário (`WeeklyResetService`).
///
/// Cobre o caminho EXTERNO (`FactionAdmissionApproved` emitido sem
/// `_approveAdmission` rodar — dev tool `_forceCompleteAdmission`), que
/// dispara `_handleApproved` → promove faction_type + atribui weekly.
/// O caminho real (`_approveAdmission`) chama o MESMO helper.
///
/// Também valida idempotência: join atribui + reset cíclico depois NÃO
/// duplica (upsert por (player, faction, weekStart)).
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

MissionAssignmentService _buildAssignment(AppDatabase db, AppEventBus bus) {
  return MissionAssignmentService(
    missionRepo: MissionRepositoryDrift(db),
    catalogs: MissionCatalogsService(
      bundle: _FakeBundle({
        // FATIA B4 — per-facção, SEM rank/reward (vêm do assign).
        'assets/data/missions_faction_weekly.json': jsonEncode({
          'moon_clan': [
            {
              'id': 'WK_MOON_1',
              'title': 'Vigília Lunar',
              'description': 'd',
              'sub_tasks': [
                {
                  'sub_type': 'diary_entry_window',
                  'target': 4,
                  'label': '4 entradas',
                },
              ],
            },
          ],
        }),
      }),
    ),
    factionRepo: ActiveFactionQuestsRepositoryDrift(db),
    bus: bus,
  );
}

Future<int> _seedPlayer(AppDatabase db, {required String factionType}) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp, faction_type) "
    "VALUES (?, ?, 'S', 7, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, ?)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
      Variable.withString(factionType),
    ],
  );
}

/// Aguarda a promoção de faction_type (listener é async) com timeout.
Future<void> _waitForPromotion(
    AppDatabase db, int playerId, String expected) async {
  for (var i = 0; i < 100; i++) {
    final rows = await db.customSelect(
      'SELECT faction_type FROM players WHERE id = ?',
      variables: [Variable.withInt(playerId)],
    ).get();
    if (rows.isNotEmpty &&
        rows.first.read<String?>('faction_type') == expected) {
      // dá uma folga extra pro assign da weekly fechar dentro do handler.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppEventBus bus;
  late MissionRepositoryDrift missionRepo;
  late MissionAssignmentService assignment;
  late FactionAdmissionProgressService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    missionRepo = MissionRepositoryDrift(db);
    assignment = _buildAssignment(db, bus);
    service = FactionAdmissionProgressService(
      db: db,
      bus: bus,
      validator: FactionAdmissionValidator(db),
      missionRepo: missionRepo,
      factionRep: FactionReputationService(
        repo: PlayerFactionReputationRepositoryDrift(db),
        bus: bus,
      ),
      factionRepo: PlayerFactionReputationRepositoryDrift(db),
      assignment: assignment,
    );
    service.start();
  });

  tearDown(() async {
    await service.stop();
    await bus.dispose();
    await db.close();
  });

  test('aprovação (dev tool / externa) → promove faction_type + atribui '
      'weekly NA HORA', () async {
    final playerId = await _seedPlayer(db, factionType: 'pending:moon_clan');

    bus.publish(FactionAdmissionApproved(
      playerId: playerId,
      factionId: 'moon_clan',
      attemptCount: 1,
    ));
    await _waitForPromotion(db, playerId, 'moon_clan');

    final factionMissions =
        await missionRepo.findByTab(playerId, MissionTabOrigin.faction);
    expect(factionMissions, hasLength(1),
        reason: 'weekly de facção criada na aprovação, sem esperar boot');
    expect(factionMissions.first.missionKey, 'WK_MOON_1');
  });

  test('idempotente: join atribui + WeeklyResetService depois NÃO duplica '
      '(mesma weekStart)', () async {
    final playerId = await _seedPlayer(db, factionType: 'pending:moon_clan');

    bus.publish(FactionAdmissionApproved(
      playerId: playerId,
      factionId: 'moon_clan',
      attemptCount: 1,
    ));
    await _waitForPromotion(db, playerId, 'moon_clan');

    expect(
        await missionRepo.findByTab(playerId, MissionTabOrigin.faction),
        hasLength(1));

    // Reset cíclico roda depois (lastWeeklyReset ainda null) → mesma
    // semana → upsert não cria 2ª row.
    final weekly = WeeklyResetService(
      missionRepo: missionRepo,
      assignment: assignment,
      playerDao: PlayerDao(db),
      bus: bus,
    );
    final r = await weekly.checkAndApply(playerId);
    expect(r.reassigned, isTrue, reason: 'reset reusa a row existente');

    final after =
        await missionRepo.findByTab(playerId, MissionTabOrigin.faction);
    expect(after, hasLength(1),
        reason: 'idempotência: nenhuma duplicata na mesma weekStart');
  });
}
