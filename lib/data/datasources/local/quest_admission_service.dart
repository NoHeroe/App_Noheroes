import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/faction_events.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/models/reward_declared.dart';
import '../../../domain/repositories/mission_repository.dart';
import '../../database/app_database.dart';
import 'class_quest_service.dart';

/// Sprint 3.1 Bloco 7b — reescrita do QuestAdmissionService legado.
///
/// Responsabilidades:
///
///   1. `startClassQuests(playerId, classId)`: confirma a classe,
///      delega pra ClassQuestService pra criar 3 diárias, e **emite
///      `ClassSelected`** no bus (hook canônico da calibração — Bloco 9
///      escuta).
///
///   2. `startFactionAdmission(playerId, factionId)`: cria 3 missões
///      de admissão em `player_mission_progress` com tabOrigin=admission.
///      Jogador completa → `checkFactionAdmission` detecta e confirma.
///
///   3. `checkFactionAdmission(playerId, factionId)`: conta rows
///      admission completadas; se todas N → atualiza `players.faction_type`
///      de `pending:X` pra `X` e emite `FactionJoined`.
///
/// Fluxo `ClassSelected` fecha o gap do Bloco 9 (TutorialManager.phase13
/// escuta pra disparar quiz de calibração).
class QuestAdmissionService {
  final AppDatabase _db;
  final MissionRepository _missionRepo;
  final ClassQuestService _classQuests;
  final AppEventBus _eventBus;

  QuestAdmissionService(
    this._db,
    this._missionRepo,
    this._classQuests,
    this._eventBus,
  );

  /// Chamado na escolha de classe (nível 5). Confirma `classType`,
  /// dispara assignment de 3 diárias, e emite `ClassSelected`.
  Future<void> startClassQuests(int playerId, String classId) async {
    // Confirma classe imediatamente via UPDATE com invalidação de stream.
    await _db.customUpdate(
      'UPDATE players SET class_type = ? WHERE id = ?',
      variables: [
        Variable.withString(classId),
        Variable.withInt(playerId),
      ],
      updates: {_db.playersTable},
    );

    // Delega diárias.
    await _classQuests.assignDailyQuests(playerId, classId);

    // Hook canônico pro Bloco 9 (calibração).
    _eventBus.publish(ClassSelected(
      playerId: playerId,
      classId: classId,
    ));
  }

  /// Cria 3 missões de admissão em `player_mission_progress` com
  /// tabOrigin=admission. Idempotente: se já existem 3 ativas pro
  /// par (player, faction), não recria.
  Future<List<MissionProgress>> startFactionAdmission(
    int playerId,
    String factionId,
  ) async {
    // Idempotência.
    final existing = await _missionRepo.findByTab(playerId,
        MissionTabOrigin.admission);
    final active = existing
        .where((m) =>
            m.completedAt == null &&
            m.failedAt == null &&
            _metaFactionOf(m.metaJson) == factionId)
        .toList();
    if (active.length >= 3) return active.take(3).toList();

    final pool = await _loadAdmissionPool(factionId);
    if (pool.isEmpty) return const [];

    final now = DateTime.now();
    final created = <MissionProgress>[];
    for (var i = 0; i < 3 && i < pool.length; i++) {
      final q = pool[i];
      final id = await _missionRepo.insert(MissionProgress(
        id: 0,
        playerId: playerId,
        missionKey: (q['key'] as String?) ??
            'ADMISSION_${factionId.toUpperCase()}_${i + 1}',
        modality: MissionModality.internal,
        tabOrigin: MissionTabOrigin.admission,
        rank: GuildRank.e,
        targetValue: 1,
        currentValue: 0,
        reward: RewardDeclared(
          xp: (q['xp'] as int?) ?? 0,
          gold: (q['gold'] as int?) ?? 0,
        ),
        startedAt: now,
        rewardClaimed: false,
        // Sprint 3.4 Etapa A hotfix — persiste `title` + `description`
        // no metaJson pro `MissionCardBase._displayTitle` ler na UI.
        // Antes esses campos do JSON eram descartados e o card mostrava
        // a `missionKey` crua (`ADMISSION_MOON_CLAN_1`).
        metaJson: jsonEncode({
          'faction_id': factionId,
          if (q['title'] is String) 'title': q['title'],
          if (q['description'] is String) 'description': q['description'],
          if (q['check_type'] != null)
            'legacy_check_type': q['check_type'],
        }),
      ));
      final loaded = await _missionRepo.findById(id);
      if (loaded != null) created.add(loaded);
    }
    return created;
  }

  /// Verifica se todas as 3 missões de admissão pra [factionId] foram
  /// completadas. Se sim, promove `players.faction_type` de
  /// `pending:<id>` pra `<id>` e emite `FactionJoined`.
  Future<bool> checkFactionAdmission(
    int playerId,
    String factionId,
  ) async {
    final admissions = await _missionRepo.findByTab(
        playerId, MissionTabOrigin.admission);
    final forFaction = admissions
        .where((m) => _metaFactionOf(m.metaJson) == factionId)
        .toList();
    if (forFaction.length < 3) return false;
    final allCompleted = forFaction.every((m) => m.completedAt != null);
    if (!allCompleted) return false;

    // Promove faction_type (se estava pending).
    await _db.customUpdate(
      'UPDATE players SET faction_type = ? WHERE id = ?',
      variables: [
        Variable.withString(factionId),
        Variable.withInt(playerId),
      ],
      updates: {_db.playersTable},
    );

    _eventBus.publish(FactionJoined(
      playerId: playerId,
      factionId: factionId,
    ));
    return true;
  }

  String? _metaFactionOf(String metaJson) {
    try {
      final decoded = jsonDecode(metaJson);
      if (decoded is! Map) return null;
      return decoded['faction_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAdmissionPool(
      String factionId) async {
    // Sprint 3.4 Etapa A — fix path bug. O arquivo
    // `assets/data/faction_admission_quests.json` é keyado DIRETAMENTE
    // pela faction id (`{"guild": [...], "moon_clan": [...]}`), sem
    // wrapper `faction_admission_quests`. A leitura legacy usava
    // `json['faction_admission_quests']` que retornava sempre null,
    // pool vazio → admissão silenciosamente noop. Bug detectado
    // durante investigação Sprint 3.4 plan-first.
    try {
      final raw = await rootBundle
          .loadString('assets/data/faction_admission_quests.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final pool =
          (json[factionId] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      return List<Map<String, dynamic>>.from(pool);
    } catch (_) {
      return const [];
    }
  }
}
