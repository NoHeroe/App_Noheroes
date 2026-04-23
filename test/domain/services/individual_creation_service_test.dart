import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/mission_events.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/core/utils/requirements_helper.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/repositories/drift/mission_repository_drift.dart';
import 'package:noheroes_app/domain/balance/individual_creation_balance.dart';
import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/enums/mission_modality.dart';
import 'package:noheroes_app/domain/enums/mission_tab_origin.dart';
import 'package:noheroes_app/domain/models/mission_progress.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/services/individual_creation_service.dart';
import 'package:noheroes_app/domain/services/mission_balancer_service.dart';

Future<int> _seedPlayer(AppDatabase db) async {
  return db.customInsert(
    "INSERT INTO players (email, password_hash, shadow_name, level, xp, "
    "xp_to_next, gold, gems, strength, dexterity, intelligence, "
    "constitution, spirit, charisma, attribute_points, shadow_corruption, "
    "vitalism_level, vitalism_xp) "
    "VALUES (?, ?, 'S', 10, 0, 100, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)",
    variables: [
      Variable.withString('p${DateTime.now().microsecondsSinceEpoch}@t'),
      Variable.withString('h'),
    ],
  );
}

Future<int> _seedActiveIndividual(
    MissionRepositoryDrift repo, int playerId) async {
  return repo.insert(MissionProgress(
    id: 0,
    playerId: playerId,
    missionKey: 'IND_EXISTING_${DateTime.now().microsecondsSinceEpoch}',
    modality: MissionModality.individual,
    tabOrigin: MissionTabOrigin.extras,
    rank: GuildRank.e,
    targetValue: 10,
    currentValue: 0,
    reward: const RewardDeclared(),
    startedAt: DateTime.now(),
    rewardClaimed: false,
    metaJson: '{}',
  ));
}

IndividualCreationParams _params(int playerId, {
  String name = 'Flexões',
  String description = 'Fazer flexões',
  List<RequirementItem>? requirements,
  IndividualFrequency frequencia = IndividualFrequency.dias,
  bool isRepetivel = false,
}) =>
    IndividualCreationParams(
      playerId: playerId,
      name: name,
      description: description,
      categoria: MissionCategory.fisico,
      intensity: Intensity.medium,
      frequencia: frequencia,
      requirements: requirements ??
          [RequirementItem(label: 'Flexões', target: 20, unit: 'reps')],
      isRepetivel: isRepetivel,
      rank: GuildRank.e,
    );

void main() {
  late AppDatabase db;
  late AppEventBus bus;
  late MissionRepositoryDrift repo;
  late IndividualCreationService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bus = AppEventBus();
    repo = MissionRepositoryDrift(db);
    service = IndividualCreationService(
      db: db,
      missionRepo: repo,
      balancer: const MissionBalancerService(),
      bus: bus,
    );
  });

  tearDown(() async {
    await bus.dispose();
    await db.close();
  });

  group('IndividualCreationService.createIndividual', () {
    test('feliz: persiste MissionProgress + emite IndividualCreated', () async {
      final playerId = await _seedPlayer(db);
      final captured = <IndividualCreated>[];
      final sub = bus.on<IndividualCreated>().listen(captured.add);

      final id = await service.createIndividual(_params(playerId));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final mission = await repo.findById(id);
      expect(mission, isNotNull);
      expect(mission!.modality, MissionModality.individual);
      expect(mission.tabOrigin, MissionTabOrigin.extras);
      expect(mission.targetValue, 20);
      expect(mission.missionKey, startsWith('IND_USER_'));

      final meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
      expect(meta['name'], 'Flexões');
      expect(meta['description'], 'Fazer flexões');
      expect(meta['frequencia'], 'dias');
      expect(meta['is_repetivel'], false);
      expect(meta['user_created'], true);
      expect(meta['category'], 'fisico');
      // Sprint 3.1 Bloco 14.6b — requirements múltiplos.
      final reqs = RequirementsHelper.parse(meta['requirements'] as String);
      expect(reqs, hasLength(1));
      expect(reqs.single.label, 'Flexões');
      expect(reqs.single.target, 20);
      expect(reqs.single.unit, 'reps');
      // deadline_at = now + 1 dia (aprox — validamos que existe)
      expect(meta['deadline_at'], isA<int>());

      expect(captured.length, 1);
      expect(captured.single.playerId, playerId);
      expect(captured.single.missionProgressId, id);
      expect(captured.single.categoria, 'fisico');

      await sub.cancel();
    });

    test('one_shot → deadline_at null', () async {
      final playerId = await _seedPlayer(db);
      final id = await service.createIndividual(_params(
        playerId,
        frequencia: IndividualFrequency.oneShot,
      ));
      final mission = (await repo.findById(id))!;
      final meta = jsonDecode(mission.metaJson) as Map<String, dynamic>;
      expect(meta['deadline_at'], isNull);
      expect(meta['frequencia'], 'one_shot');
    });

    test('reward calculada pelo balancer (rank E × medium × físico + repetível)',
        () async {
      final playerId = await _seedPlayer(db);
      final id = await service.createIndividual(_params(
        playerId,
        isRepetivel: true,
      ));
      final mission = (await repo.findById(id))!;
      // 2 × 30 × 1.0 × 0.4 × 0.7 = 16.8 → 17
      expect(mission.reward.xp, 17);
      // 2 × 20 × 1.0 × 0.35 × 0.7 = 9.8 → 10
      expect(mission.reward.gold, 10);
    });

    test('limite ${IndividualCreationBalance.kMaxActiveIndividualsFree} '
        'atingido → IndividualLimitExceededException', () async {
      final playerId = await _seedPlayer(db);
      // Seeda 5 ativas direto no repo.
      for (var i = 0; i < 5; i++) {
        await _seedActiveIndividual(repo, playerId);
      }
      expect(
        () => service.createIndividual(_params(playerId)),
        throwsA(isA<IndividualLimitExceededException>()),
      );
      // Nenhuma criada.
      final active = await repo.findActive(playerId);
      expect(active.length, 5);
    });

    test('nome vazio → ArgumentError, sem persistir', () async {
      final playerId = await _seedPlayer(db);
      expect(
        () => service.createIndividual(_params(playerId, name: '   ')),
        throwsA(isA<ArgumentError>()),
      );
      final active = await repo.findActive(playerId);
      expect(active, isEmpty);
    });

    test('requirements vazia → ArgumentError', () async {
      final playerId = await _seedPlayer(db);
      expect(
        () => service
            .createIndividual(_params(playerId, requirements: const [])),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('requirement.target <= 0 → ArgumentError', () async {
      final playerId = await _seedPlayer(db);
      expect(
        () => service.createIndividual(_params(
          playerId,
          requirements: [
            RequirementItem(label: 'Zero', target: 0, unit: 'reps'),
          ],
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('requirements múltiplos: targetValue = sum(targets)', () async {
      final playerId = await _seedPlayer(db);
      final id = await service.createIndividual(_params(
        playerId,
        requirements: [
          RequirementItem(label: 'Flexões', target: 20, unit: 'reps'),
          RequirementItem(label: 'Corrida', target: 3, unit: 'km'),
        ],
      ));
      final mission = (await repo.findById(id))!;
      expect(mission.targetValue, 23);
      final reqs = RequirementsHelper.parse(
          (jsonDecode(mission.metaJson)['requirements']) as String);
      expect(reqs, hasLength(2));
    });
  });
}
